# Shared Open Targets download helpers.
# Sourced by 01_probe.R and 02_extract.R.
# Release 26.06 is pinned. Do not follow the FTP "latest" alias.
# Later releases changed the target schema.

ot_release <- "26.06"

# Sheet step 3. Full datasets. No row filter. Filtering is step 7.
# These six datasets are the drug, disease, trial, and target bridge.
# Evidence and association tables are not part of this step.
ot_datasets <- c(
  "disease",
  "drug_molecule",
  "clinical_report",
  "clinical_target",
  "clinical_indication",
  "target"
)

# R on this Windows conda env does not see zoneinfo unless TZDIR is set.
set_utc_timezone <- function() {
  Sys.setenv(TZ = "UTC")
  conda_prefix <- Sys.getenv("CONDA_PREFIX", unset = "")
  candidates <- c(
    if (nzchar(conda_prefix)) file.path(conda_prefix, "share", "zoneinfo"),
    file.path(dirname(dirname(R.home())), "share", "zoneinfo")
  )
  found <- candidates[dir.exists(candidates)]
  if (length(found) >= 1) {
    Sys.setenv(TZDIR = found[[1]])
  }
}

set_utc_timezone()

find_repo_root <- function(start_dir) {
  dir <- normalizePath(start_dir, winslash = "/", mustWork = TRUE)
  repeat {
    if (dir.exists(file.path(dir, ".git"))) {
      return(dir)
    }
    parent <- dirname(dir)
    if (identical(parent, dir)) {
      stop("Could not find the repository root from ", start_dir)
    }
    dir <- parent
  }
}

script_path_from_rscript <- function() {
  file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(file_arg) != 1) {
    stop("Run this file with Rscript.")
  }
  normalizePath(sub("^--file=", "", file_arg), winslash = "/")
}

require_ot_packages <- function() {
  if (!requireNamespace("arrow", quietly = TRUE)) {
    stop(
      "Missing arrow. Update the env with: ",
      "mamba env update -n species-gap -f environment.yml"
    )
  }
}

ot_output_url <- function() {
  paste0(
    "https://ftp.ebi.ac.uk/pub/databases/opentargets/platform/",
    ot_release,
    "/output/"
  )
}

read_url_text <- function(url) {
  tryCatch(
    paste(readLines(url, warn = FALSE), collapse = "\n"),
    error = function(e) {
      stop("Could not read ", url, ": ", conditionMessage(e))
    }
  )
}

extract_parquet_names <- function(html) {
  found <- gregexpr('href="([^"]+\\.parquet)"', html, perl = TRUE)[[1]]
  if (found[[1]] == -1) {
    return(character())
  }
  starts <- attr(found, "capture.start")
  lengths <- attr(found, "capture.length")
  if (is.null(starts)) {
    stop("Could not parse parquet file names from the FTP index.")
  }
  names <- substring(html, starts[, 1], starts[, 1] + lengths[, 1] - 1)
  sort(unique(names[!grepl("/", names, fixed = TRUE)]))
}

content_length <- function(url) {
  headers <- tryCatch(curlGetHeaders(url), error = function(e) character())
  cl <- headers[grepl("^content-length:", headers, ignore.case = TRUE)]
  if (length(cl) < 1) {
    return(NA_real_)
  }
  as.numeric(trimws(sub("(?i)^content-length:\\s*", "", cl[[length(cl)]])))
}

ot_dataset_files <- function() {
  files <- list()
  for (dataset in ot_datasets) {
    index_url <- paste0(ot_output_url(), dataset, "/")
    names <- extract_parquet_names(read_url_text(index_url))
    if (length(names) < 1) {
      stop("No parquet files in ", index_url)
    }
    for (filename in names) {
      url <- paste0(index_url, filename)
      files[[length(files) + 1]] <- list(
        dataset = dataset,
        filename = filename,
        url = url,
        size_bytes = content_length(url)
      )
    }
  }
  files
}

format_bytes <- function(size_bytes) {
  format(size_bytes, scientific = FALSE, big.mark = ",", trim = TRUE)
}

same_size <- function(path, expected_bytes) {
  file.exists(path) &&
    is.finite(expected_bytes) &&
    as.numeric(file.info(path)$size) == as.numeric(expected_bytes)
}

download_if_needed <- function(url, dest, expected_bytes) {
  if (!is.finite(expected_bytes)) {
    stop("Open Targets did not report Content-Length for ", url)
  }
  if (same_size(dest, expected_bytes)) {
    message("using cached ", dest)
    return(invisible(NULL))
  }
  dir.create(dirname(dest), recursive = TRUE, showWarnings = FALSE)
  message("downloading ", url, " ...")
  options(timeout = max(2 * 3600, getOption("timeout")))
  utils::download.file(url, dest, mode = "wb", quiet = FALSE)
  got <- as.numeric(file.info(dest)$size)
  if (got != as.numeric(expected_bytes)) {
    stop(
      "Size mismatch for ", dest,
      ": expected ", format_bytes(expected_bytes),
      " bytes, got ", format_bytes(got), " bytes."
    )
  }
  invisible(NULL)
}

arrow_type_text <- function(field) {
  text <- field$type$ToString()
  gsub("[\r\n\t]", " ", text, perl = TRUE)
}

schema_lines_for <- function(dataset, schema) {
  lines <- character()
  for (name in schema$names) {
    if (grepl("[\r\n\t]", name, perl = TRUE)) {
      stop("Column name is not a single TSV field: ", dataset, " / ", name)
    }
    field <- schema$GetFieldByName(name)
    lines <- c(
      lines,
      paste(
        dataset,
        length(lines) + 1,
        name,
        arrow_type_text(field),
        sep = "\t"
      )
    )
  }
  lines
}

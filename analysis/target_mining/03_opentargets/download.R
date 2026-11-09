# Shared Open Targets download helpers.
# Sourced by 01_probe.R and 02_extract.R.

ot_platform_base <- "https://ftp.ebi.ac.uk/pub/databases/opentargets/platform/"

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

require_opentargets_packages <- function() {
  if (!requireNamespace("arrow", quietly = TRUE)) {
    stop(
      "Missing arrow. Recreate or update the env with: ",
      "mamba env update -n species-gap -f environment.yml"
    )
  }
}

ot_latest_release <- function() {
  listing <- readLines(ot_platform_base, warn = FALSE)
  hits <- regmatches(
    listing,
    gregexpr("[0-9]{2}\\.[0-9]{2}/", listing)
  )
  releases <- unique(sub("/$", "", unlist(hits)))
  if (length(releases) < 1) {
    stop("Could not find numbered Open Targets releases at ", ot_platform_base)
  }
  parts <- strsplit(releases, ".", fixed = TRUE)
  order_value <- vapply(
    parts,
    function(x) as.integer(x[[1]]) * 100L + as.integer(x[[2]]),
    integer(1)
  )
  releases[[which.max(order_value)]]
}

ot_release <- function() {
  requested <- Sys.getenv("OPEN_TARGETS_RELEASE", unset = "")
  if (nzchar(requested)) {
    return(requested)
  }
  ot_latest_release()
}

ot_selected_datasets <- function(available) {
  requested <- Sys.getenv("OPEN_TARGETS_DATASETS", unset = "")
  if (!nzchar(requested)) {
    return(available)
  }
  selected <- trimws(strsplit(requested, ",", fixed = TRUE)[[1]])
  selected <- selected[nzchar(selected)]
  unknown <- setdiff(selected, available)
  if (length(unknown) > 0) {
    stop("Unknown Open Targets dataset(s): ", paste(unknown, collapse = ", "))
  }
  unique(selected)
}

ot_dataset_urls <- function(release, dataset) {
  base <- paste0(ot_platform_base, release, "/output/", dataset, "/")
  listing <- readLines(base, warn = FALSE)
  matches <- regmatches(
    listing,
    gregexpr("[^\"'> ]+\\.parquet", listing)
  )
  files <- unique(basename(unlist(matches)))
  if (length(files) < 1) {
    stop("No Parquet files found at ", base)
  }
  data.frame(
    dataset = dataset,
    filename = files,
    url = paste0(base, files),
    stringsAsFactors = FALSE
  )
}

remote_size_bytes <- function(url) {
  headers <- tryCatch(
    curlGetHeaders(url, redirect = TRUE),
    error = function(e) character()
  )
  values <- headers[grepl("^content-length:", headers, ignore.case = TRUE)]
  if (length(values) < 1) {
    return(NA_real_)
  }
  as.numeric(sub("(?i)^content-length:\\s*", "", values[[length(values)]]))
}

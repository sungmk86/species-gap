# Shared ChEMBL FTP helpers. Sourced by 01_probe.R and 02_extract.R.

chembl_ftp_latest <- "https://ftp.ebi.ac.uk/pub/databases/chembl/ChEMBLdb/latest/"

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

require_chembl_packages <- function() {
  if (!requireNamespace("DBI", quietly = TRUE) ||
      !requireNamespace("RSQLite", quietly = TRUE)) {
    stop(
      "Missing DBI or RSQLite. Recreate the env with: ",
      "mamba env create -f environment.yml"
    )
  }
}

chembl_latest_sqlite <- function() {
  listing <- readLines(chembl_ftp_latest, warn = FALSE)
  hits <- grep("chembl_[0-9]+_sqlite\\.tar\\.gz", listing, value = TRUE)
  if (length(hits) < 1) {
    stop("Could not find chembl_*_sqlite.tar.gz on ", chembl_ftp_latest)
  }
  filename <- sub(".*(chembl_[0-9]+_sqlite\\.tar\\.gz).*", "\\1", hits[[1]])
  release <- sub("_sqlite\\.tar\\.gz$", "", filename)
  url <- paste0(chembl_ftp_latest, filename)
  size_bytes <- NA_real_
  headers <- tryCatch(curlGetHeaders(url), error = function(e) character())
  cl <- headers[grepl("^content-length:", headers, ignore.case = TRUE)]
  if (length(cl) >= 1) {
    size_bytes <- as.numeric(sub("(?i)^content-length:\\s*", "", cl[[1]]))
  }
  list(
    release = release,
    filename = filename,
    url = url,
    size_bytes = size_bytes
  )
}

find_sqlite_db <- function(root_dir) {
  dbs <- list.files(root_dir, pattern = "\\.db$", recursive = TRUE, full.names = TRUE)
  if (length(dbs) < 1) {
    stop("No .db file under ", root_dir)
  }
  dbs[[1]]
}

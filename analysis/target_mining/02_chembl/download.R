# Shared ChEMBL FTP helpers. Sourced by 01_probe.R and 02_extract.R.

chembl_ftp_latest <- "https://ftp.ebi.ac.uk/pub/databases/chembl/ChEMBLdb/latest/"
chembl_ftp_releases <- "https://ftp.ebi.ac.uk/pub/databases/chembl/ChEMBLdb/releases/"

# Release used by the analysis. Change this line (and commit it) to move to
# another release. CHEMBL_RELEASE overrides it for one run;
# CHEMBL_RELEASE=latest uses the newest release on the FTP server.
chembl_default_release <- "37"

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

require_packages <- function(packages) {
  missing <- packages[
    !vapply(packages, requireNamespace, logical(1), quietly = TRUE)
  ]
  if (length(missing) > 0) {
    stop(
      "Missing ", paste(missing, collapse = ", "),
      ". Recreate or update the env with: ",
      "mamba env update -n species-gap -f environment.yml"
    )
  }
}

chembl_latest_release <- function() {
  listing <- readLines(chembl_ftp_latest, warn = FALSE)
  hits <- grep("chembl_[0-9]+_sqlite\\.tar\\.gz", listing, value = TRUE)
  if (length(hits) < 1) {
    stop("Could not find chembl_*_sqlite.tar.gz on ", chembl_ftp_latest)
  }
  sub(".*chembl_([0-9]+)_sqlite\\.tar\\.gz.*", "\\1", hits[[1]])
}

chembl_release <- function() {
  requested <- Sys.getenv("CHEMBL_RELEASE", unset = "")
  if (!nzchar(requested)) {
    return(chembl_default_release)
  }
  if (identical(tolower(requested), "latest")) {
    return(chembl_latest_release())
  }
  sub("^chembl_", "", requested)
}

# File name, fixed release URL, size, and the official SHA256 of the
# SQLite dump for one release.
chembl_sqlite_info <- function(release) {
  base <- paste0(chembl_ftp_releases, "chembl_", release, "/")
  filename <- paste0("chembl_", release, "_sqlite.tar.gz")
  url <- paste0(base, filename)

  checksums <- readLines(paste0(base, "checksums.txt"), warn = FALSE)
  hit <- grep(paste0("\\s", filename, "$"), checksums, value = TRUE)
  if (length(hit) != 1) {
    stop("No SHA256 for ", filename, " in ", base, "checksums.txt")
  }
  sha256 <- tolower(sub("^([0-9a-fA-F]{64}).*", "\\1", hit))

  size_bytes <- NA_real_
  headers <- tryCatch(curlGetHeaders(url), error = function(e) character())
  cl <- headers[grepl("^content-length:", headers, ignore.case = TRUE)]
  if (length(cl) >= 1) {
    size_bytes <- as.numeric(sub("(?i)^content-length:\\s*", "", cl[[length(cl)]]))
  }
  list(
    release = paste0("chembl_", release),
    filename = filename,
    url = url,
    sha256 = sha256,
    size_bytes = size_bytes
  )
}

file_sha256 <- function(path) {
  con <- file(path, open = "rb")
  on.exit(close(con))
  hex <- as.character(openssl::sha256(con))
  attributes(hex) <- NULL
  hex
}

file_md5 <- function(path) {
  unname(tools::md5sum(path))
}

find_sqlite_db <- function(root_dir) {
  dbs <- list.files(root_dir, pattern = "\\.db$", recursive = TRUE, full.names = TRUE)
  if (length(dbs) < 1) {
    stop("No .db file under ", root_dir)
  }
  dbs[[1]]
}

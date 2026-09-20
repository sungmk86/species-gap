# Shared AACT connection helpers. Sourced by 01_probe.R and 02_extract.R.

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

load_aact_credentials <- function(repo_root) {
  renviron <- file.path(repo_root, ".Renviron")
  if (file.exists(renviron)) {
    readRenviron(renviron)
  }
  user <- Sys.getenv("AACT_USER", unset = "")
  password <- Sys.getenv("AACT_PASSWORD", unset = "")
  if (!nzchar(user) || !nzchar(password)) {
    stop(
      "Missing AACT_USER or AACT_PASSWORD.\n",
      "1. Create an account: https://aact.ctti-clinicaltrials.org/sign_up\n",
      "2. Copy .Renviron.example to .Renviron in the repository root.\n",
      "3. Fill AACT_USER and AACT_PASSWORD. Do not commit .Renviron."
    )
  }
  list(user = user, password = password)
}

require_aact_packages <- function() {
  if (!requireNamespace("DBI", quietly = TRUE) ||
      !requireNamespace("RPostgres", quietly = TRUE)) {
    stop(
      "Missing DBI or RPostgres. Recreate the env with: ",
      "mamba env create -f environment.yml"
    )
  }
}

connect_aact <- function(user, password) {
  set_utc_timezone()
  DBI::dbConnect(
    RPostgres::Postgres(),
    host = "aact-db.ctti-clinicaltrials.org",
    port = 5432L,
    dbname = "aact",
    user = user,
    password = password,
    sslmode = "require"
  )
}

aact_schema <- function(con) {
  if (DBI::dbExistsTable(con, DBI::Id(schema = "ctgov", table = "studies"))) {
    return("ctgov")
  }
  if (DBI::dbExistsTable(con, "studies")) {
    return("")
  }
  stop("Could not find table studies in schema ctgov or on the search_path.")
}

qualified_table <- function(schema, table) {
  if (nzchar(schema)) {
    paste0(schema, ".", table)
  } else {
    table
  }
}

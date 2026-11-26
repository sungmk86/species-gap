# Read selected tables from a dated AACT flat-file snapshot and write them
# into data/raw/aact/snapshot_YYYYMMDD/.
# Unlike 02_extract.R (live database, changes every day), this gives the
# same result every time it runs on the same snapshot file.
# Does not filter studies and does not build a case-set.
# Do not edit files under data/raw after they are written.
#
# The snapshot needs an AACT login, so download it by hand once:
#   https://aact.ctti-clinicaltrials.org -> Snapshots -> History -> 2026
#   -> Flat Text Files -> November 1, 2026 -> Download
# Put the zip, unrenamed, in data/raw/aact/_cache/.
# AACT does not publish a checksum, so the SHA256 below was computed from
# the file downloaded on 2026-11-26.

snapshot_date <- "20261101"
snapshot_file <- "20261101_export_ctgov.zip"
snapshot_sha256 <- "d0cbbea225d1c300fb9c5c1814ab51e9b1493113ba9dbcf5cbd05aebafa0d9d4"

# Tables listed on the Target mapping plan (sheet step 1), same as
# 02_extract.R. The zip in _cache keeps all 49 tables for later.
tables <- c(
  "studies",
  "interventions",
  "conditions",
  "browse_conditions",
  "browse_interventions",
  "sponsors",
  "designs"
)

source(file.path(dirname(sub("^--file=", "", grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE))), "connect.R"))

script_path <- script_path_from_rscript()
repo_root <- find_repo_root(dirname(script_path))

if (!requireNamespace("openssl", quietly = TRUE)) {
  stop(
    "Missing openssl. Recreate or update the env with: ",
    "mamba env update -n species-gap -f environment.yml"
  )
}

file_sha256 <- function(path) {
  con <- file(path, open = "rb")
  on.exit(close(con))
  hex <- as.character(openssl::sha256(con))
  attributes(hex) <- NULL
  hex
}

archive <- file.path(repo_root, "data", "raw", "aact", "_cache", snapshot_file)
if (!file.exists(archive)) {
  stop(
    "Missing ", archive, "\n",
    "Download the ", snapshot_date, " Flat Text Files snapshot from ",
    "https://aact.ctti-clinicaltrials.org (login needed) and put it there."
  )
}

message("checking SHA256 of ", archive, " ...")
archive_sha256 <- file_sha256(archive)
if (!identical(archive_sha256, snapshot_sha256)) {
  stop(
    "SHA256 mismatch for ", archive, "\n  file:     ", archive_sha256,
    "\n  expected: ", snapshot_sha256,
    "\nDownload the snapshot again."
  )
}
message("  SHA256 matches")

members <- paste0(tables, ".txt")
listed <- utils::unzip(archive, list = TRUE)$Name
missing <- setdiff(members, listed)
if (length(missing) >= 1) {
  stop("Snapshot is missing: ", paste(missing, collapse = ", "))
}

work <- tempfile("aact_snapshot_")
dir.create(work)
on.exit(unlink(work, recursive = TRUE), add = TRUE)

dest <- file.path(repo_root, "data", "raw", "aact", paste0("snapshot_", snapshot_date))
dir.create(dest, recursive = TRUE, showWarnings = FALSE)

stamp <- format(as.POSIXct(Sys.time(), tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ")
manifest <- c(paste(
  "table", "rows", "columns", "bytes", "md5", "path", "snapshot",
  "archive", "archive_sha256", "extracted_at_utc",
  sep = "\t"
))

for (table in tables) {
  message("reading ", table, " ...")
  member <- paste0(table, ".txt")
  utils::unzip(archive, files = member, exdir = work)
  txt <- file.path(work, member)

  # Pipe-separated; fields containing "|" or line breaks are in double
  # quotes. Keep every column as text; empty fields become NA.
  frame <- utils::read.table(
    txt,
    header = TRUE,
    sep = "|",
    quote = "\"",
    comment.char = "",
    na.strings = "",
    colClasses = "character",
    fill = FALSE,
    check.names = FALSE,
    encoding = "UTF-8",
    stringsAsFactors = FALSE
  )
  # Cross-check: each record starts a line with "[id|]NCTxxxxxxxx|".
  records <- sum(grepl(
    "^([0-9]+\\|)?NCT[0-9]{8}\\|",
    readLines(txt, encoding = "UTF-8", warn = FALSE),
    useBytes = TRUE
  ))
  unlink(txt)
  if (records != nrow(frame)) {
    stop(table, ": read ", nrow(frame), " rows but the file has ", records, " records.")
  }

  bad_nct <- sum(!grepl("^NCT[0-9]{8}$", frame$nct_id))
  if (bad_nct > 0) {
    stop(table, ": ", bad_nct, " rows have a malformed nct_id. Parsing failed.")
  }

  out <- file.path(dest, paste0(table, ".rds"))
  saveRDS(frame, out)
  rel <- paste0("data/raw/aact/snapshot_", snapshot_date, "/", table, ".rds")
  manifest <- c(
    manifest,
    paste(
      table, nrow(frame), ncol(frame), file.info(out)$size,
      unname(tools::md5sum(out)), rel, snapshot_date, snapshot_file,
      archive_sha256, stamp,
      sep = "\t"
    )
  )
  message("  ", format(nrow(frame), scientific = FALSE, big.mark = ","), " rows")
}

manifest_path <- file.path(dest, "manifest.tsv")
writeLines(manifest, manifest_path, useBytes = TRUE)
message("wrote ", manifest_path)

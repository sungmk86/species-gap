# Download the latest ChEMBL SQLite dump and write four tables
# into data/raw/chembl/YYYYMMDD/.
# Does not filter rows and does not build a case-set.
# Does not write the mouse-success column. That column is made later.
# Do not edit files under data/raw after they are written.

# Tables listed on the Target mapping plan (sheet step 2).
# Full tables. No row filter. Filtering is step 7.
# drug_mechanism has tid, not target_chembl_id.
# target_chembl_id is target_dictionary.chembl_id.
tables <- c(
  "molecule_dictionary",
  "molecule_synonyms",
  "target_dictionary",
  "drug_mechanism"
)

source(file.path(dirname(sub("^--file=", "", grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE))), "download.R"))

script_path <- script_path_from_rscript()
repo_root <- find_repo_root(dirname(script_path))
require_chembl_packages()

info <- chembl_latest_sqlite()
cache_dir <- file.path(repo_root, "data", "raw", "chembl", "_cache")
dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
archive <- file.path(cache_dir, info$filename)

if (!file.exists(archive)) {
  message("downloading ", info$url, " ...")
  options(timeout = max(24 * 3600, getOption("timeout")))
  utils::download.file(info$url, archive, mode = "wb", quiet = FALSE)
} else {
  message("using cached ", archive)
}

unpack_dir <- file.path(cache_dir, info$release)
if (!dir.exists(unpack_dir) || length(list.files(unpack_dir, recursive = TRUE)) < 1) {
  message("unpacking ", archive, " ...")
  dir.create(unpack_dir, recursive = TRUE, showWarnings = FALSE)
  utils::untar(archive, exdir = unpack_dir)
}

db_path <- find_sqlite_db(unpack_dir)
message("sqlite: ", db_path)

con <- DBI::dbConnect(RSQLite::SQLite(), db_path)
on.exit(DBI::dbDisconnect(con), add = TRUE)

have <- DBI::dbListTables(con)
missing <- setdiff(tables, have)
if (length(missing) >= 1) {
  stop("SQLite is missing tables: ", paste(missing, collapse = ", "))
}

day <- format(as.POSIXct(Sys.time(), tz = "UTC"), "%Y%m%d")
dest <- file.path(repo_root, "data", "raw", "chembl", day)
dir.create(dest, recursive = TRUE, showWarnings = FALSE)

stamp <- format(as.POSIXct(Sys.time(), tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ")
manifest <- c("table\trows\tcolumns\tbytes\tpath\trelease\tdownloaded_at_utc")

for (table in tables) {
  message("extracting ", table, " ...")
  frame <- DBI::dbReadTable(con, table)
  out <- file.path(dest, paste0(table, ".rds"))
  saveRDS(frame, out)
  rel <- paste0("data/raw/chembl/", day, "/", table, ".rds")
  manifest <- c(
    manifest,
    paste(table, nrow(frame), ncol(frame), file.info(out)$size, rel, info$release, stamp, sep = "\t")
  )
  message("  ", format(nrow(frame), scientific = FALSE, big.mark = ","), " rows")
}

manifest_path <- file.path(dest, "manifest.tsv")
writeLines(manifest, manifest_path, useBytes = TRUE)
message("wrote ", manifest_path)

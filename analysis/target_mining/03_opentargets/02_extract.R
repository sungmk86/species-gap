# Download Open Targets 26.06 parquet datasets into
# data/raw/opentargets/YYYYMMDD/.
# Does not filter rows and does not build a case-set.
# Does not uppercase clinical_report.id. The later join does that.
# Do not edit files under data/raw after they are written.

# Full datasets from the Target mapping plan (sheet step 3).
# Nested columns stay in the published Parquet files.
# This step writes manifest.tsv and schema.tsv beside those files.
# It does not write a flat RDS table.

source(file.path(dirname(sub("^--file=", "", grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE))), "download.R"))

script_path <- script_path_from_rscript()
repo_root <- find_repo_root(dirname(script_path))
require_ot_packages()

files <- ot_dataset_files()
cache_root <- file.path(repo_root, "data", "raw", "opentargets", "_cache", ot_release)
day <- format(as.POSIXct(Sys.time(), tz = "UTC"), "%Y%m%d")
dest_root <- file.path(repo_root, "data", "raw", "opentargets", day)

for (file in files) {
  cache <- file.path(cache_root, file$dataset, file$filename)
  download_if_needed(file$url, cache, file$size_bytes)
  dest <- file.path(dest_root, file$dataset, file$filename)
  dir.create(dirname(dest), recursive = TRUE, showWarnings = FALSE)
  if (!same_size(dest, file.info(cache)$size)) {
    ok <- file.copy(cache, dest, overwrite = TRUE)
    if (!isTRUE(ok)) {
      stop("Could not copy ", cache, " to ", dest)
    }
  }
  message("saved ", dest)
}

stamp <- format(as.POSIXct(Sys.time(), tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ")
schema_lines <- c("dataset\tcolumn_index\tcolumn_name\tarrow_type")
manifest <- c("dataset\tfile\trows\tcolumns\tbytes\tpath\trelease\tdownloaded_at_utc")

for (dataset in ot_datasets) {
  dataset_dir <- file.path(dest_root, dataset)
  parts <- sort(list.files(dataset_dir, pattern = "\\.parquet$", full.names = TRUE))
  if (length(parts) < 1) {
    stop("No parquet files in ", dataset_dir)
  }
  readers <- lapply(parts, arrow::ParquetFileReader$create)
  schemas <- lapply(readers, function(reader) reader$GetSchema())
  signatures <- vapply(schemas, function(schema) schema$ToString(), character(1))
  if (length(unique(signatures)) != 1) {
    stop("Parquet parts for ", dataset, " do not share one schema.")
  }
  schema_lines <- c(schema_lines, schema_lines_for(dataset, schemas[[1]]))
  for (i in seq_along(parts)) {
    rel <- paste0(
      "data/raw/opentargets/", day, "/", dataset, "/", basename(parts[[i]])
    )
    manifest <- c(
      manifest,
      paste(
        dataset,
        basename(parts[[i]]),
        format(readers[[i]]$num_rows, scientific = FALSE, trim = TRUE, big.mark = ""),
        length(schemas[[1]]$names),
        format(file.info(parts[[i]])$size, scientific = FALSE, trim = TRUE, big.mark = ""),
        rel,
        ot_release,
        stamp,
        sep = "\t"
      )
    )
    message(
      dataset, " ", basename(parts[[i]]), " rows: ",
      format(readers[[i]]$num_rows, scientific = FALSE, big.mark = ",", trim = TRUE)
    )
  }
}

schema_path <- file.path(dest_root, "schema.tsv")
manifest_path <- file.path(dest_root, "manifest.tsv")
writeLines(schema_lines, schema_path, useBytes = TRUE)
writeLines(manifest, manifest_path, useBytes = TRUE)
message("wrote ", schema_path)
message("wrote ", manifest_path)

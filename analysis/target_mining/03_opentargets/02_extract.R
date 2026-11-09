# Download the current Open Targets datasets into data/raw.
# Keeps the original Parquet files and does not filter rows.
# Do not edit files under data/raw after they are written.

datasets <- c(
  "disease",
  "drug_molecule",
  "clinical_report",
  "clinical_target",
  "clinical_indication",
  "target"
)

source(file.path(
  dirname(sub(
    "^--file=",
    "",
    grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  )),
  "download.R"
))

datasets <- ot_selected_datasets(datasets)
script_path <- script_path_from_rscript()
repo_root <- find_repo_root(dirname(script_path))
require_opentargets_packages()

release <- ot_release()
day <- format(as.POSIXct(Sys.time(), tz = "UTC"), "%Y%m%d")
dest <- file.path(repo_root, "data", "raw", "opentargets", day)
dir.create(dest, recursive = TRUE, showWarnings = FALSE)

stamp <- format(as.POSIXct(Sys.time(), tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ")
manifest <- c(
  "dataset\tfile\trows\tcolumns\tbytes\tpath\trelease\tdownloaded_at_utc"
)
schema_lines <- c("dataset\tcolumn\ttype")

options(timeout = max(24 * 3600, getOption("timeout")))

for (dataset in datasets) {
  files <- ot_dataset_urls(release, dataset)
  dataset_dir <- file.path(dest, dataset)
  dir.create(dataset_dir, recursive = TRUE, showWarnings = FALSE)

  for (i in seq_len(nrow(files))) {
    out <- file.path(dataset_dir, files$filename[[i]])
    if (!file.exists(out)) {
      message("downloading ", files$url[[i]], " ...")
      utils::download.file(files$url[[i]], out, mode = "wb", quiet = FALSE)
    } else {
      message("using cached ", out)
    }

    table <- arrow::read_parquet(out, as_data_frame = FALSE)
    rows <- nrow(table)
    columns <- ncol(table)
    fields <- table$schema$fields
    schema_lines <- c(
      schema_lines,
      vapply(
        fields,
        function(field) {
          paste(dataset, field$name, field$type$ToString(), sep = "\t")
        },
        character(1)
      )
    )

    rel <- paste0(
      "data/raw/opentargets/",
      day,
      "/",
      dataset,
      "/",
      files$filename[[i]]
    )
    manifest <- c(
      manifest,
      paste(
        dataset,
        files$filename[[i]],
        rows,
        columns,
        file.info(out)$size,
        rel,
        release,
        stamp,
        sep = "\t"
      )
    )
    message(
      "  ",
      format(rows, scientific = FALSE, big.mark = ","),
      " rows; ",
      columns,
      " columns"
    )
  }
}

manifest_path <- file.path(dest, "manifest.tsv")
schema_path <- file.path(dest, "schema.tsv")
writeLines(manifest, manifest_path, useBytes = TRUE)
writeLines(unique(schema_lines), schema_path, useBytes = TRUE)
message("wrote ", manifest_path)
message("wrote ", schema_path)

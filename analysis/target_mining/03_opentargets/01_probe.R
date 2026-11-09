# Probe the current Open Targets release and planned dataset files.
# Does not download Parquet files.

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
invisible(find_repo_root(dirname(script_path)))

release <- ot_release()
message("Open Targets FTP reachable.")
message("release: ", release)

for (dataset in datasets) {
  files <- ot_dataset_urls(release, dataset)
  sizes <- vapply(files$url, remote_size_bytes, numeric(1))
  message(dataset, ": ", nrow(files), " Parquet file(s)")
  for (i in seq_len(nrow(files))) {
    size <- if (is.finite(sizes[[i]])) {
      paste0(format(sizes[[i]], scientific = FALSE, big.mark = ","), " bytes")
    } else {
      "size unknown"
    }
    message("  ", files$filename[[i]], " (", size, ")")
  }
}

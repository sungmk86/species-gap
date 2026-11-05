# Probe the Open Targets 26.06 FTP folders.
# Prints each parquet file name, URL, and size.
# Does not download the files.

source(file.path(dirname(sub("^--file=", "", grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE))), "download.R"))

script_path <- script_path_from_rscript()
invisible(find_repo_root(dirname(script_path)))

files <- ot_dataset_files()
message("Open Targets FTP reachable.")
message("release: ", ot_release)

total <- 0
known <- 0L
for (file in files) {
  message("dataset: ", file$dataset)
  message("file: ", file$filename)
  message("url: ", file$url)
  if (is.finite(file$size_bytes)) {
    message("size_bytes: ", format_bytes(file$size_bytes))
    total <- total + file$size_bytes
    known <- known + 1L
  } else {
    message("size_bytes: unknown")
  }
}

message("files: ", length(files))
if (known == length(files)) {
  message("size_bytes_total: ", format_bytes(total))
} else {
  message("size_bytes_total: unknown")
}

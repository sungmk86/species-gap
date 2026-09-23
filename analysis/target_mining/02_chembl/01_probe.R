# Probe the ChEMBL FTP latest folder.
# Prints the current SQLite dump name and size.
# Does not download the dump.

source(file.path(dirname(sub("^--file=", "", grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE))), "download.R"))

script_path <- script_path_from_rscript()
invisible(find_repo_root(dirname(script_path)))

info <- chembl_latest_sqlite()
message("ChEMBL FTP reachable.")
message("release: ", info$release)
message("file: ", info$filename)
message("url: ", info$url)
if (is.finite(info$size_bytes)) {
  message("size_bytes: ", format(info$size_bytes, scientific = FALSE, big.mark = ","))
} else {
  message("size_bytes: unknown")
}

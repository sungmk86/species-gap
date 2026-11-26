# Probe the ChEMBL FTP folder for the pinned release (see download.R).
# Prints the SQLite dump name, size, official SHA256, and the newest
# release on the server.
# Does not download the dump.

source(file.path(dirname(sub("^--file=", "", grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE))), "download.R"))

script_path <- script_path_from_rscript()
invisible(find_repo_root(dirname(script_path)))

info <- chembl_sqlite_info(chembl_release())
message("ChEMBL FTP reachable.")
message("release: ", info$release)
message("file: ", info$filename)
message("url: ", info$url)
message("sha256: ", info$sha256)
message("newest release on the server: chembl_", chembl_latest_release())
if (is.finite(info$size_bytes)) {
  message("size_bytes: ", format(info$size_bytes, scientific = FALSE, big.mark = ","))
} else {
  message("size_bytes: unknown")
}

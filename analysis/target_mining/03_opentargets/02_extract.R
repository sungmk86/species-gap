# Download the Open Targets datasets into data/raw.
# Keeps the original Parquet files and does not filter rows.
# Do not edit files under data/raw after they are written.
#
# This step does not use arrow, so it also runs on old CPUs where the
# arrow binary crashes. Each file is checked against the SHA1 that
# Open Targets publishes for the release. Row counts and the schema are
# written by 03_inspect.R, which this script starts at the end.

datasets <- c(
  "disease",
  "drug_molecule",
  "drug_warning",
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
require_packages("openssl")

release <- ot_release()
dest <- ot_dest_dir(repo_root)
dir.create(dest, recursive = TRUE, showWarnings = FALSE)
message("release: ", release)
message("folder: ", dest)

official_sha1 <- ot_release_sha1(release)

stamp <- format(as.POSIXct(Sys.time(), tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ")
manifest <- c(paste(
  "dataset", "file", "bytes", "md5", "sha1", "path", "url", "release",
  "downloaded_at_utc",
  sep = "\t"
))

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

    key <- paste0("output/", dataset, "/", files$filename[[i]])
    sha1 <- file_sha1(out)
    expected <- unname(official_sha1[key])
    if (is.na(expected)) {
      stop("No official SHA1 for ", key, " in release ", release)
    }
    if (!identical(sha1, expected)) {
      stop(
        "SHA1 mismatch for ", out, "\n  file:     ", sha1,
        "\n  expected: ", expected,
        "\nDelete this file and run the script again."
      )
    }

    rel <- sub(
      paste0("^", normalizePath(repo_root, winslash = "/"), "/"),
      "",
      normalizePath(out, winslash = "/")
    )
    manifest <- c(
      manifest,
      paste(
        dataset,
        files$filename[[i]],
        file.info(out)$size,
        file_md5(out),
        sha1,
        rel,
        files$url[[i]],
        release,
        stamp,
        sep = "\t"
      )
    )
    message("  SHA1 matches the release checksum")
  }
}

manifest_path <- file.path(dest, "manifest.tsv")
writeLines(manifest, manifest_path, useBytes = TRUE)
message("wrote ", manifest_path)

# Row counts and schema need arrow. Run them in a separate R process so a
# crash on an unsupported CPU does not stop this script.
inspect_script <- file.path(dirname(script_path), "03_inspect.R")
rscript <- file.path(R.home("bin"), "Rscript")
log <- suppressWarnings(system2(
  rscript,
  c(shQuote(inspect_script), shQuote(dest)),
  stdout = TRUE,
  stderr = TRUE
))
status <- attr(log, "status")
if (is.null(status) || status == 0) {
  message(paste(log, collapse = "\n"))
} else {
  message(
    "Download finished, but 03_inspect.R failed (exit ", status, ").\n",
    "arrow needs a CPU with SSE4.2. Run this on a newer machine:\n",
    "  Rscript analysis/target_mining/03_opentargets/03_inspect.R ", dest,
    "\nLast lines:\n", paste(utils::tail(log, 5), collapse = "\n")
  )
}

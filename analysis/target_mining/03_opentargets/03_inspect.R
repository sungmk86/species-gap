# Count rows and record the schema of downloaded Open Targets files.
# Reads manifest.tsv written by 02_extract.R and writes counts.tsv and
# schema.tsv in the same folder. Does not change the Parquet files.
#
# Usage: Rscript analysis/target_mining/03_opentargets/03_inspect.R [folder]
# Without a folder, uses the newest data/raw/opentargets/YYYYMMDD folder.
# Needs arrow, which needs a CPU with SSE4.2.

source(file.path(
  dirname(sub(
    "^--file=",
    "",
    grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  )),
  "download.R"
))

script_path <- script_path_from_rscript()
repo_root <- find_repo_root(dirname(script_path))
require_packages("arrow")

args <- commandArgs(trailingOnly = TRUE)
if (length(args) >= 1) {
  dest <- args[[1]]
} else {
  folders <- list.files(
    file.path(repo_root, "data", "raw", "opentargets"),
    pattern = "^[0-9]{8}$",
    full.names = TRUE
  )
  if (length(folders) < 1) {
    stop("No data/raw/opentargets/YYYYMMDD folder. Run 02_extract.R first.")
  }
  dest <- sort(folders, decreasing = TRUE)[[1]]
}

manifest <- utils::read.delim(
  file.path(dest, "manifest.tsv"),
  colClasses = "character"
)

counts <- c("dataset\tfile\trows\tcolumns")
schema_lines <- c("dataset\tcolumn\ttype")

for (i in seq_len(nrow(manifest))) {
  dataset <- manifest$dataset[[i]]
  path <- file.path(dest, dataset, manifest$file[[i]])
  table <- arrow::read_parquet(path, as_data_frame = FALSE)
  counts <- c(
    counts,
    paste(dataset, manifest$file[[i]], nrow(table), ncol(table), sep = "\t")
  )
  schema_lines <- c(
    schema_lines,
    vapply(
      table$schema$fields,
      function(field) {
        paste(dataset, field$name, field$type$ToString(), sep = "\t")
      },
      character(1)
    )
  )
  message(
    dataset, " ", manifest$file[[i]], ": ",
    format(nrow(table), scientific = FALSE, big.mark = ","),
    " rows; ", ncol(table), " columns"
  )
}

writeLines(counts, file.path(dest, "counts.tsv"), useBytes = TRUE)
writeLines(unique(schema_lines), file.path(dest, "schema.tsv"), useBytes = TRUE)
message("wrote ", file.path(dest, "counts.tsv"))
message("wrote ", file.path(dest, "schema.tsv"))

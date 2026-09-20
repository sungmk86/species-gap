# Download selected AACT tables into data/raw/aact/YYYYMMDD/.
# Does not filter studies and does not build a case-set.
# Do not edit files under data/raw after they are written.

# Tables listed on the Target mapping plan (sheet step 1).
# Full tables. No row filter. Filtering is step 7.
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
creds <- load_aact_credentials(repo_root)
require_aact_packages()

con <- connect_aact(creds$user, creds$password)
on.exit(DBI::dbDisconnect(con), add = TRUE)

schema <- aact_schema(con)
day <- format(as.POSIXct(Sys.time(), tz = "UTC"), "%Y%m%d")
dest <- file.path(repo_root, "data", "raw", "aact", day)
dir.create(dest, recursive = TRUE, showWarnings = FALSE)

stamp <- format(as.POSIXct(Sys.time(), tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ")
manifest <- c("table\trows\tcolumns\tbytes\tpath\tdownloaded_at_utc")

for (table in tables) {
  qname <- qualified_table(schema, table)
  message("downloading ", qname, " ...")
  if (nzchar(schema)) {
    frame <- DBI::dbReadTable(con, DBI::Id(schema = schema, table = table))
  } else {
    frame <- DBI::dbReadTable(con, table)
  }
  out <- file.path(dest, paste0(table, ".rds"))
  saveRDS(frame, out)
  rel <- paste0("data/raw/aact/", day, "/", table, ".rds")
  manifest <- c(
    manifest,
    paste(table, nrow(frame), ncol(frame), file.info(out)$size, rel, stamp, sep = "\t")
  )
  message("  ", format(nrow(frame), scientific = FALSE, big.mark = ","), " rows")
}

manifest_path <- file.path(dest, "manifest.tsv")
writeLines(manifest, manifest_path, useBytes = TRUE)
message("wrote ", manifest_path)

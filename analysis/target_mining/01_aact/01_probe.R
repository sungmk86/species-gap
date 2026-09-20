# Probe the AACT cloud database.
# Prints a connection check and the row count of ctgov.studies.
# Does not write data files.

source(file.path(dirname(sub("^--file=", "", grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE))), "connect.R"))

script_path <- script_path_from_rscript()
repo_root <- find_repo_root(dirname(script_path))
creds <- load_aact_credentials(repo_root)
require_aact_packages()

con <- connect_aact(creds$user, creds$password)
on.exit(DBI::dbDisconnect(con), add = TRUE)

schema <- aact_schema(con)
label <- qualified_table(schema, "studies")
n <- DBI::dbGetQuery(con, paste("SELECT COUNT(*) AS n FROM", label))$n[[1]]
message("AACT connection succeeded.")
message(label, " rows: ", format(n, scientific = FALSE, big.mark = ","))

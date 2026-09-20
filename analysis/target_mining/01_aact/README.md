# 01_aact

First target-mining step: connect to AACT (Aggregate Analysis of
ClinicalTrials.gov) and confirm that `ctgov.studies` is readable.

From 2026-09-15 an AACT account is required.

## Once

1. Create an account: https://aact.ctti-clinicaltrials.org/sign_up
2. At the repository root, create the shared environment:

```text
mamba env create -f environment.yml
mamba activate species-gap
```

3. Copy `.Renviron.example` to `.Renviron` in the repository root.
4. Put `AACT_USER` and `AACT_PASSWORD` in `.Renviron`. Do not commit that file.

Packages for this step (`r-base`, `r-dbi`, `r-rpostgres`, `r-ggplot2`)
are pinned in `environment.yml`. Do not `install.packages()` for them.

## Run

From the repository root, with `species-gap` active:

```text
Rscript analysis/target_mining/01_aact/01_probe.R
Rscript analysis/target_mining/01_aact/02_extract.R
```

Or without activating:

```text
mamba run -n species-gap Rscript analysis/target_mining/01_aact/01_probe.R
mamba run -n species-gap Rscript analysis/target_mining/01_aact/02_extract.R
```

## Expected result

`01_probe.R`

- A line that the connection succeeded.
- The row count of `ctgov.studies` (on the order of 600,000).

`02_extract.R`

- Folder `data/raw/aact/YYYYMMDD/` with `.rds` files:
  studies, interventions, conditions, browse_conditions,
  browse_interventions, sponsors, designs.
- `manifest.tsv` with row counts and file sizes.
- No filtering. Do not edit files under `data/raw`.

Shared connection code is `connect.R`. This step does not build a case-set.

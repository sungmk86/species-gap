# 01_aact

First target-mining step: get AACT (Aggregate Analysis of
ClinicalTrials.gov) tables.

There are two ways:

- `03_snapshot.R` (use this for the analysis): reads a dated flat-file
  snapshot. The same snapshot file always gives the same tables.
- `02_extract.R`: reads the live cloud database. AACT updates it every
  day, so the result depends on the day it runs.

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

## Snapshot (reproducible)

The snapshot download needs an AACT login, so download it by hand once:

1. Sign in at https://aact.ctti-clinicaltrials.org
2. Snapshots -> History -> 2026 -> Flat Text Files ->
   November 1, 2026 -> Download (`20261101_export_ctgov.zip`, 2.4 GB).
3. Put the zip, unrenamed, in `data/raw/aact/_cache/`.

Then:

```text
mamba run -n species-gap Rscript analysis/target_mining/01_aact/03_snapshot.R
```

AACT does not publish checksums. The script checks the zip against the
SHA256 recorded in it
(`d0cbbea225d1c300fb9c5c1814ab51e9b1493113ba9dbcf5cbd05aebafa0d9d4`)
and stops if it differs. It writes `data/raw/aact/snapshot_20261101/`
with the same seven tables as `02_extract.R` and a `manifest.tsv`
(rows, columns, md5 of each `.rds`, snapshot SHA256). All columns are
text; empty fields are `NA`. The zip keeps all 49 tables for later.

Snapshot 2026-11-01 row counts: studies 609,544; interventions
1,031,111; conditions 1,097,935; browse_conditions 4,415,195;
browse_interventions 2,572,890; sponsors 971,165; designs 604,742.

## Live database

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

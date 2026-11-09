# 03_opentargets

Third target-mining step: identify the current Open Targets Platform
release and save the disease, drug, and clinical datasets.

No Open Targets account is required. Files are downloaded from the EBI
FTP server in their original Parquet format.

Release 26.06 changed the clinical data layout. These scripts downloaded
release 26.09. The old `known_drug` and ChEMBL evidence paths are replaced by:

- `clinical_report`
- `clinical_target`
- `clinical_indication`
- `target`

## Once

From the repository root:

```text
mamba env update -n species-gap -f environment.yml
mamba activate species-gap
```

The `arrow` package is pinned in `environment.yml`. Do not use
`install.packages()` for it.

## Run

From the repository root, with `species-gap` active:

```text
Rscript analysis/target_mining/03_opentargets/01_probe.R
Rscript analysis/target_mining/03_opentargets/02_extract.R
```

Or without activating:

```text
mamba run -n species-gap Rscript analysis/target_mining/03_opentargets/01_probe.R
mamba run -n species-gap Rscript analysis/target_mining/03_opentargets/02_extract.R
```

To download selected datasets from a fixed release in PowerShell.
Set `OPEN_TARGETS_RELEASE` to use another release. The example below is 26.09, the release these scripts downloaded.

```text
$env:OPEN_TARGETS_RELEASE = "26.09"
$env:OPEN_TARGETS_DATASETS = "target"
mamba run -n species-gap Rscript analysis/target_mining/03_opentargets/01_probe.R
mamba run -n species-gap Rscript analysis/target_mining/03_opentargets/02_extract.R
```

Unset these variables to return to the latest release and all datasets.

## Expected result

`01_probe.R`

- The current numbered Open Targets release.
- The Parquet file names and remote sizes.
- No data file is written.

`02_extract.R`

- Original Parquet files under `data/raw/opentargets/YYYYMMDD/`.
- Datasets: `disease`, `drug_molecule`, `clinical_report`,
  `clinical_target`, `clinical_indication`, and `target`.
- `manifest.tsv` with row counts, file sizes, and release.
- `schema.tsv` with source column names and Parquet types.
- No filtering and no case-set.

For release 26.09, `clinical_report` contains traceable clinical
evidence. Relevant source columns are:

- `id`: lowercase trial ID for AACT rows, for example `nct00000105`
- `url`: ClinicalTrials.gov URL
- `trialWhyStopped`: free-text stop reason
- `trialStopReasonCategories`: Open Targets stop-reason categories
- `drugs`: source drug name and ChEMBL drug ID
- `diseases`: source disease name and EFO disease ID

Match `toupper(clinical_report.id)` to `studies.nct_id`. Do not extract
the trial ID from `url` when `id` is available.

In release 26.09, `clinical_target` replaces the target role previously
described through `known_drug`. It provides `drugId`, `targetId`,
`diseases`, and linked `clinicalReportIds`.

The `target` dataset maps the Ensembl `targetId` to protein identifiers,
including UniProt accessions.

Do not edit files under `data/raw`.

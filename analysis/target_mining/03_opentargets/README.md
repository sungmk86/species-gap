# 03_opentargets

Third target-mining step: identify the current Open Targets Platform
release and save the disease, drug, and clinical datasets.

No Open Targets account is required. Files are downloaded from the EBI
FTP server in their original Parquet format.

Release 26.06 changed the clinical data layout. The scripts are fixed to
release 26.09 (`ot_default_release` in `download.R`). The old `known_drug`
and ChEMBL evidence paths are replaced by:

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

`02_extract.R` starts `03_inspect.R` at the end. Run `03_inspect.R` alone
only when the count step failed:

```text
mamba run -n species-gap Rscript analysis/target_mining/03_opentargets/03_inspect.R data/raw/opentargets/YYYYMMDD
```

## Settings

All are optional environment variables. Unset them for the default run.

| Variable | Default | Use |
|---|---|---|
| `OPEN_TARGETS_RELEASE` | `26.09` | Another release for one run; `latest` asks the FTP server for the newest |
| `OPEN_TARGETS_DATASETS` | all seven | Comma-separated subset, for example `target,drug_warning` |
| `OPEN_TARGETS_DEST` | `data/raw/opentargets/YYYYMMDD` | Another output folder, for example a test folder |

PowerShell example:

```text
$env:OPEN_TARGETS_DATASETS = "target"
mamba run -n species-gap Rscript analysis/target_mining/03_opentargets/02_extract.R
```

To move the analysis to a new release, change `ot_default_release` in
`download.R` and commit it, so the release is recorded in git.

## Old CPUs

The conda `arrow` binary needs a CPU with SSE4.2 and crashes on older ones
(for example Intel Core 2). `02_extract.R` does not use arrow, so the
download and checksum check still work there. Only `03_inspect.R`
fails; run it on a newer machine that can see the same folder.

## Expected result

`01_probe.R`

- The release in use and the Parquet file names and remote sizes.
- No data file is written.

`02_extract.R`

- Original Parquet files under `data/raw/opentargets/YYYYMMDD/`.
- Datasets: `disease`, `drug_molecule`, `drug_warning`, `clinical_report`,
  `clinical_target`, `clinical_indication`, and `target`.
- Each file is checked against the SHA1 in the release's
  `release_data_integrity` file. The script stops on a mismatch.
- `manifest.tsv`: `dataset`, `file`, `bytes`, `md5`, `sha1`, `path`,
  `url`, `release`, `downloaded_at_utc`.
- No filtering and no case-set.

`03_inspect.R`

- `counts.tsv`: `dataset`, `file`, `rows`, `columns`.
- `schema.tsv`: source column names and Parquet types.

Row counts for release 26.09 (checked 2026-11-25):

| Dataset | Rows |
|---|---|
| `disease` | 45,896 |
| `drug_molecule` | 19,170 |
| `drug_warning` | 2,009 |
| `clinical_report` | 289,954 |
| `clinical_target` | 13,261 |
| `clinical_indication` | 86,451 |
| `target` (3 files) | 78,733 |

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

`drug_warning` holds ChEMBL withdrawal and black-box rows; `warningType`
marks a withdrawal, `toxicityClass` is the short class, `description` is
the sentence, `chemblIds` links the drug.

Do not edit files under `data/raw`.

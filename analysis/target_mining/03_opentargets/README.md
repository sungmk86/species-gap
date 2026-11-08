# 03_opentargets

Third target-mining step: download six Open Targets 26.06
parquet datasets and record their schema.

No Open Targets account is required. The files are on the EBI FTP
server. The release is pinned to 26.06. Do not switch this step to
the FTP `latest` alias. Later releases changed the target schema.

The six datasets are about 194 MB together.

This step does not download evidence or association tables.
It does not filter rows and does not build a case-set.

## Once

From the repository root:

```text
mamba env create -f environment.yml
mamba activate species-gap
```

If the env already exists, add the new pin:

```text
mamba env update -n species-gap -f environment.yml
```

`r-arrow` is pinned in `environment.yml`. Do not
`install.packages()` for it. Arrow is used to read the parquet
schema and row counts. The nested columns stay in the parquet files.

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

## Expected result

`01_probe.R`

- A line that the Open Targets FTP folder is reachable.
- Release `26.06`.
- One file name, URL, and size for each parquet part.
- No dataset file is written.

`02_extract.R`

- Caches the parquet files under `data/raw/opentargets/_cache/26.06/`.
- Folder `data/raw/opentargets/YYYYMMDD/` with the same parquet files:
  disease, drug_molecule, clinical_report, clinical_target,
  clinical_indication, target.
- The `20261105` snapshot is committed. `_cache` is the same bytes
  kept locally and stays untracked.
- `manifest.tsv` with one row per parquet file: row count,
  top-level column count, size, and the release.
- `schema.tsv` with one row per top-level column and its Arrow type.
- No filtering. Do not edit files under `data/raw`.

`clinical_report.id` stays as published. For AACT-sourced rows it is
a lowercase NCT id. The later join uppercases it. This step does not.

List columns such as `drugs`, `diseases`, and `proteinIds` stay
nested. This step does not flatten them into a case-set.

A few `clinical_report` disease-name values in 26.06 contain a null
byte. They stay in the raw file. Filtering is step 7.

This step does not build a case-set.

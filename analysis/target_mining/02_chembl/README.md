# 02_chembl

Second target-mining step: find the current ChEMBL SQLite dump and
save four tables from it.

No ChEMBL account is required. The dump is on the EBI FTP server.

Current latest dump (May 2026): ChEMBL 37. The SQLite archive is
about 5.4 GB compressed. Unpacking needs more free disk. This step
does not download assay activity tables.

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

Packages for this step (`r-dbi`, `r-rsqlite`) are pinned in
`environment.yml`. Do not `install.packages()` for them.

## Run

From the repository root, with `species-gap` active:

```text
Rscript analysis/target_mining/02_chembl/01_probe.R
Rscript analysis/target_mining/02_chembl/02_extract.R
```

Or without activating:

```text
mamba run -n species-gap Rscript analysis/target_mining/02_chembl/01_probe.R
mamba run -n species-gap Rscript analysis/target_mining/02_chembl/02_extract.R
```

## Expected result

`01_probe.R`

- A line that the ChEMBL FTP folder is reachable.
- The current release name, file name, URL, and size.
- No dump file is written.

`02_extract.R`

- Caches `chembl_*_sqlite.tar.gz` under `data/raw/chembl/_cache/`.
- Folder `data/raw/chembl/YYYYMMDD/` with `.rds` files:
  molecule_dictionary, molecule_synonyms, target_dictionary,
  drug_mechanism.
- `manifest.tsv` with row counts, file sizes, and the ChEMBL release.
- No filtering. Do not edit files under `data/raw`.

`drug_mechanism` has `tid`, not `target_chembl_id`.
`target_chembl_id` is `target_dictionary.chembl_id`.
The later mouse-success column is not in this download.

This step does not build a case-set.

# 02_chembl

Second target-mining step: download the pinned ChEMBL SQLite dump,
check it against the official SHA256, and save four tables from it.

No ChEMBL account is required. The dump is on the EBI FTP server.

The release is pinned to ChEMBL 37 in `download.R`
(`chembl_default_release`). Files come from the fixed release folder
`ChEMBLdb/releases/chembl_37/`, not from `latest/`, so a new ChEMBL
release does not change the result.

| Setting | Default | Meaning |
|---|---|---|
| `CHEMBL_RELEASE` | `37` | Another release number for one run, or `latest`. |

The SQLite archive is 5.8 GB (5,764,252,857 bytes); unpacked it is
about 29 GB. This step does not download assay activity tables.

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

Packages for this step (`r-dbi`, `r-rsqlite`, `r-openssl`) are pinned in
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
- The pinned release, file name, URL, size, official SHA256, and the
  newest release on the server.
- No dump file is written.

`02_extract.R`

- Caches `chembl_37_sqlite.tar.gz` under `data/raw/chembl/_cache/`
  and stops if its SHA256 differs from the official
  `checksums.txt` value
  (`33c203740555f96067710cdfc1c3c55d890660e5908ec5cbf5817492c290d281`).
- Folder `data/raw/chembl/YYYYMMDD/` with `.rds` files:
  molecule_dictionary, molecule_synonyms, target_dictionary,
  drug_mechanism.
- `manifest.tsv` with row counts, file sizes, md5 of each `.rds`, the
  release, the archive URL, and the archive SHA256.

ChEMBL 37 row counts: molecule_dictionary 2,921,148;
molecule_synonyms 136,061; target_dictionary 18,552;
drug_mechanism 7,561.
- No filtering. Do not edit files under `data/raw`.

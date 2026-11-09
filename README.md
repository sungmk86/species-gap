# Species Gap

This repository supports research into the causes of discrepancies between animal experiments and human clinical outcomes and the development of a platform for predicting interspecies differences.

Analysis code is R. Comments, README files, and folder names are English.

## Setup

1. Install [Miniforge](https://github.com/conda-forge/miniforge) (conda + mamba, conda-forge by default).
2. From the repository root:

```text
mamba env create -f environment.yml
mamba activate species-gap
```

`environment.yml` is the shared package list. Recreate the same R version, database packages, and ggplot2 on another machine with that file. Do not use `.env` for packages.

3. Copy `.Renviron.example` to `.Renviron` and fill `AACT_USER` and `AACT_PASSWORD`. Do not commit `.Renviron`.

## Research Objectives

- Build a dataset of interspecies discrepancies from clinical and drug data.
- Analyze interspecies differences in protein structure.
- Analyze differences in genomic context and gene regulatory networks.
- Validate the results through experiments and retrospective clinical case studies.
- Develop an R Shiny web application for exploring the results.

## Repository Structure

```text
species-gap/
├─ environment.yml     # mamba env (R, AACT, ChEMBL, ggplot2)
├─ .Renviron.example   # AACT username/password template (not secrets)
├─ data/
│  ├─ raw/             # Downloaded source data
│  └─ processed/       # Processed data for analysis
├─ analysis/
│  ├─ target_mining/
│  │  ├─ 01_aact/      # AACT probe and extract
│  │  └─ 02_chembl/    # ChEMBL probe and extract
│  ├─ structural_gap/
│  ├─ genomic_context/
│  ├─ network_gap/
│  └─ validation/
├─ web/                # R Shiny web application
└─ outputs/            # Figures, reports, manuscripts, and releases
```

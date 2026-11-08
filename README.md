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
├─ environment.yml     # mamba env (R, AACT, ChEMBL, Open Targets, ggplot2)
├─ .Renviron.example   # AACT username/password template (not secrets)
├─ data/
│  ├─ raw/             # Downloaded source data
│  └─ processed/       # Processed data for analysis
├─ analysis/
│  ├─ target_mining/
│  │  ├─ 01_aact/      # AACT probe and extract
│  │  ├─ 02_chembl/    # ChEMBL probe and extract
│  │  └─ 03_opentargets/ # Open Targets 26.06 probe and extract
│  ├─ structural_gap/
│  ├─ genomic_context/
│  ├─ network_gap/
│  └─ validation/
├─ web/                # R Shiny web application
└─ outputs/            # Figures, reports, manuscripts, and releases
```

## Working Principles

- Do not modify source data in `data/raw`.
- Store reproducible analysis code in `analysis`.
- Store generated results in `outputs`.
- Do not commit personal information or Brain Pool administrative documents to this repository.

## Current Tasks

- [x] Local R environment via `environment.yml` (r-base, r-dbi, r-rpostgres, r-rsqlite, r-ggplot2).
- [x] Fill `.Renviron` and run `01_probe.R`.
- [x] Run `02_extract.R` (AACT tables in `data/raw/aact/YYYYMMDD/`).
- [x] Design the remaining target-mining pipeline.
- [x] Run `analysis/target_mining/02_chembl/01_probe.R`, then `02_extract.R`.
- [x] Update the env and run `analysis/target_mining/03_opentargets/01_probe.R`, then `02_extract.R`. The 26.06 snapshot is in `data/raw/opentargets/20261105/`.
- [ ] Create the initial R Shiny interface.

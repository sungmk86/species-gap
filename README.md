# Species Gap

This repository supports research into the causes of discrepancies between animal experiments and human clinical outcomes and the development of a platform for predicting interspecies differences.

## Research Objectives

- Build a dataset of interspecies discrepancies from clinical and drug data.
- Analyze interspecies differences in protein structure.
- Analyze differences in genomic context and gene regulatory networks.
- Validate the results through experiments and retrospective clinical case studies.
- Develop an R Shiny web application for exploring the results.

## Repository Structure

```text
species-gap/
├─ data/
│  ├─ raw/             # Downloaded source data
│  └─ processed/       # Processed data for analysis
├─ analysis/
│  ├─ target_mining/
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

- [ ] Document data sources and download procedures.
- [ ] Set up the analysis environment.
- [ ] Design the target-mining pipeline.
- [ ] Create the initial R Shiny interface.

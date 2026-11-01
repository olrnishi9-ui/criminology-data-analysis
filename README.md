# Criminology Data Analysis

A series of data analysis projects on crime and criminal justice, done in R (RStudio).

## How this repo is organized

One rule for everything, so any project is easy to find later:

- Projects live in `projects/`, numbered in the order they were added: `01-…`, `02-…`, …
- Every project folder has the same inside layout:
  - `README.md` — what the project is, its data, and its status. Start here.
  - `code/` — R scripts (`.R`) and R Markdown / Quarto sources (`.Rmd` / `.qmd`)
  - `data/` — data notes only. Raw datasets are not tracked (see each project's `data/README.md` for the source)
  - `output/` — finished reports, figures, and tables
- New project? Copy `00-project-template/`, give it the next number, and fill in its README.

## Projects

| # | Project | What it is | Status |
|---|---|---|---|
| 01 | [LEOKA — Officers Killed](projects/01-leoka-officers-killed/) | FBI LEOKA data: officers killed by state and region, 2003–2023 (HW 1) | Report complete |
| 02 | [Seattle Crime 2026](projects/02-seattle-crime-2026/) | Seattle Police Department crime data for 2026, starting with a full data-quality audit | In progress |

## Tools

- R / RStudio
- (packages listed per project)

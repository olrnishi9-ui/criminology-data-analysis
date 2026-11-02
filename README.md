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
| 01 | [LEOKA — Officers Killed](projects/01-leoka-officers-killed/) | FBI LEOKA data: officers killed by state and region, 2003–2023 | Report complete |
| 02 | [Regular Expressions I — Scrabble Words](projects/02-regular-expressions-scrabble-words/) | Learning `grep()` pattern matching on a list of four-letter Scrabble words | Complete |
| 03 | [Regular Expressions II — Word Patterns](projects/03-regular-expressions-word-patterns/) | Backreferences and `gsub()` transformations: palindromes, doubled letters, consonant/vowel patterns | Complete |
| 04 | [NCVS — Assault Victimization](projects/04-ncvs-assault-victimization/) | National Crime Victimization Survey: setting up the NCVS tables in class, then a weighted analysis of assault in the US | Complete |
| 05 | [Seattle Crime Hotspots](projects/05-seattle-crime-hotspots/) | Seattle Police 2026 offense records mapped two ways: 500 m hexagon rates and a KDE density surface | Complete |

More projects are in preparation and will be added with the next numbers.

## Tools

- R / RStudio
- (packages listed per project)

# Seattle Crime 2026

Analysis of Seattle Police Department crime data for 2026.

## Data

- Source file: `Seattle_Crime_2026_0_z7i3.csv` — 61,823 rows × 20 columns
- The raw CSV is not tracked in this repo by default. Put it in `data/` locally to run the code.

## Contents

- `code/` — R analysis scripts (to be added)
- `output/Seattle_Crime_2026_Data_Problems.xlsx` — data-quality audit: a column-by-column comparison of how each field looks now vs. how it should look, with counts and examples of every problem found (missing-value codes such as `-`, `REDACTED`, `999`, `UNKNOWN`; placeholder coordinates; midnight timestamps that likely mean "time unknown"; duplicated offense IDs, and more)

## Status

Data-quality audit complete. Cleaning and analysis in progress.

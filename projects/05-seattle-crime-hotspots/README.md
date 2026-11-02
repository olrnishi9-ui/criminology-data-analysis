# Project 5 — Seattle Crime Hotspots: Hexagon and KDE Maps

Where does reported crime concentrate in Seattle? This project takes the
Seattle Police Department's 2026 offense records (January 1 – October 30,
2026), cleans and audits them carefully, and maps the intensity of reported
offenses two ways: a 500 m hexagon grid and a smoothed kernel density
(KDE) surface. Both maps use the same scale — reported offenses per km²
per year — so they can be compared directly.

## The code file

### `code/seattle_crime_hotspots.R`

One script, run interactively in RStudio, in five parts:

1. **Download and validate.** Pulls all records with an offense date in
   2026 straight from the Seattle Open Data API (SPD Crime Data
   2008–Present) and validates the download: row count checked against
   the API's own count, date range, missing values per column, monthly
   counts, days with zero records, and duplicated report/offense pairs.
2. **Clean and audit.** Removes duplicate offenses (keeping a review file
   of them), flags records with impossible or out-of-period dates, and
   classifies every coordinate: `REDACTED`, missing, placeholder (−1/0),
   out of range, outside Seattle's land area, or usable. Records that are
   not crimes (NIBRS code 999, "NOT_A_CRIME") are excluded from the maps.
   Every excluded record is written to a review CSV rather than silently
   dropped, and the mapped set is what remains: **44,281 mapped offenses**.
3. **Hexagon map.** A grid of 500 m hexagons clipped to Seattle's land
   boundary (from the city's council-district geography). Each hexagon's
   rate is its offense count divided by its *land* area and annualized.
   Very small shoreline edge cells get no estimate instead of a wild rate.
4. **KDE map.** A kernel density surface (Gaussian kernel, 500 m
   bandwidth, 100 m pixels, edge-corrected, offenses at identical
   block-level coordinates counted with their full weight), drawn with
   the same density bands as the hexagon map.
5. **Hotspots and publication maps.** Picks the five highest-intensity
   hexagons that are at least 1 km apart (and have at least 10 offenses),
   labels each with the neighborhood most common inside it, and draws the
   two finished maps with scale bar, north arrow, and full source notes.

### What the maps show

Reported offenses concentrate overwhelmingly in the downtown core. The
five hotspot hexagons are:

1. **Belltown**
2. **Pioneer Square**
3. **Capitol Hill**
4. **Chinatown–International District**
5. **University** (University District)

The densest hexagons exceed 4,000 reported offenses per km² per year,
while most residential parts of the city sit below 100. The KDE map tells
the same story in smoothed form: one dominant downtown mass, a secondary
center around the University District, and smaller pockets in the north
and south.

### Read the maps carefully

- Locations are **block-blurred** by the police department (coordinates
  are approximate, some are `REDACTED`), so a hexagon says "this area,"
  not "this address."
- The rates are **descriptive intensity, not risk**: they are not adjusted
  for how many people live, work, or pass through an area. Downtown has
  more people and more reporting, not just more crime.
- Records with unusable locations are excluded from the maps, never
  treated as zero.

## Data

- Seattle Police Department, *SPD Crime Data 2008–Present*, via Seattle
  Open Data (dataset `tazs-3rd5`): https://data.seattle.gov/Public-Safety/SPD-Crime-Data-2008-Present/tazs-3rd5
- The script downloads the 2026 records itself; the offense period
  analyzed is 2026-01-01 to 2026-10-30. The dataset is updated daily and
  only includes finalized, UCR-approved reports, so counts can shift
  slightly between downloads.
- City boundary: Seattle City Council Districts, Seattle GIS (ArcGIS).
- Raw data is not tracked in this repo. See `data/README.md`.
- Intermediate review tables (duplicates, date issues, boundary cases,
  exclusions, per-hexagon intensities) are written by the script to a
  local `seattle_results/` folder and are not tracked either.

## Output

- `output/seattle_crime_hotspots_hexagons.png` — hexagon map (the script
  saves it as `seattle_hexagons.png`)
- `output/seattle_crime_hotspots_kde.png` — KDE map (saved by the script
  as `seattle_kde.png`)

## Packages

`data.table`, `sf`, `ggplot2`, `spatstat.geom`, `spatstat.explore`,
`isoband`, `viridisLite`.

## Notes on the file in this repo

The script is the author's original, with two presentation changes only:
the file is renamed from its original `HWK5.R` to match this series'
naming, and one garbled comment line just above the `ggsave()` calls was
restored as a readable comment. No code was changed. (One thing to know
before running it: part 4 opens the downloaded CSV with `file.choose()`,
so it expects an interactive RStudio session.)

## Status

Complete.

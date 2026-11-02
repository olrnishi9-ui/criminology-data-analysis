# Data notes — Seattle Crime Hotspots

Source: Seattle Police Department, *SPD Crime Data 2008–Present*, via
Seattle Open Data (Socrata dataset `tazs-3rd5`):
https://data.seattle.gov/Public-Safety/SPD-Crime-Data-2008-Present/tazs-3rd5/about_data

- The analysis script (`../code/seattle_crime_hotspots.R`) downloads the
  data itself from the Socrata API, filtering to offense dates in 2026,
  and analyzes the period 2026-01-01 to 2026-10-30.
- The dataset is updated daily. It contains only finalized, UCR-approved
  police reports; reports still in draft or awaiting approval appear in
  later updates, and some 2026 offenses were reported late (report dates
  can lag the offense date). Download on a different day and the row
  counts will differ slightly.
- Coordinates are blurred by SPD to the 100-block level — approximate
  locations, not exact addresses. Some records have coordinates marked
  `REDACTED`; the script treats those as unlocated and excludes them
  from the maps.
- City boundary: Seattle City Council Districts from Seattle GIS
  (ArcGIS FeatureServer), downloaded by the script and cached locally
  under `seattle_results/cache/`.

Raw data files in this folder are ignored by git (see the repo
`.gitignore`). Keep this file updated with the dataset's source, download
date, and any notes about versions, so the analysis stays reproducible.

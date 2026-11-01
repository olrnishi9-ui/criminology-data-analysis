# Data notes — NCVS

- Source: National Crime Victimization Survey (Bureau of Justice Statistics,
  conducted by the Census Bureau), distributed by ICPSR.
  - 2022 files: ICPSR study 38603
  - 2023 files: ICPSR study 38962
- Each year has four files: DS0002 household, DS0003 person, DS0004 incident,
  DS0005 incident-level extract.
- The analysis uses a prepared extract object (`dataExt`) saved as
  `NCVS2022.RData`. Estimates use the `SERIES_WEIGHT` variable.
- Raw data files in this folder are ignored by git (see the repo `.gitignore`).

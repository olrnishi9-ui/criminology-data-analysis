# Project 4 — NCVS: Assault Victimization in the United States

Working with the National Crime Victimization Survey (NCVS) — the Bureau of
Justice Statistics survey that counts crimes *reported by victims*, including
ones never reported to the police. This project has two code files: a
classroom setup file that builds the dataset, and an analysis file that uses
it to study assault.

## The two code files

### 1. `code/working_with_ncvs_data_in_class.R` — setting the data up (in-class, CRIM 6002)

The "plumbing" file, worked through in class. It explains what the NCVS is
(design, response rates, cost, how households rotate through the sample), then:

- Downloads the 2022 and 2023 NCVS files from ICPSR (studies 38603 and 38962)
- Loads the four related tables — household, person, incident, and the
  incident-level extract that joins them together — and inspects their
  variable labels from the codebook
- Combines the 2022 and 2023 collection years so the result covers *calendar*
  year 2022, fixing the variable-type mismatches between years (e.g. V2061,
  V4126) that otherwise stop the tables from stacking

### 2. `code/ncvs_assault_victimization_project.R` — the analysis

Loads the prepared incident extract (`NCVS2022.RData`) and estimates national
totals for **assault victimizations** using the survey's `SERIES_WEIGHT`, so
the sample counts stand for the whole US population. It asks:

- **Where** do assaults happen? About 35.1% at or near the victim's home, 16.9% on an open street, 8.7% at school
- **When**? The largest shares fall in the afternoon (noon–3 p.m. 19.3%, 3–6 p.m. 18.1%)
- **Who is the offender**? In an estimated 52.6% of victimizations the victim knew or had seen at least one offender; strangers 40.0%
- **Weapons**? 25.7% involved a weapon; among those, firearms were most common (32.5%), then blunt objects (26.9%), then knives (18.2%)
- **Reported to police**? 43.4% yes, 53.6% no
- **Defensive gun use**? An estimated ~29,300 assault victimizations — but based on only 15 sample cases, so highly uncertain (the code says so itself)
- **Race and crime type**: builds weighted cross-tables of crime type by victim race, and compares the *composition* of victimizations — e.g. aggravated assault with injury is 10.1% of victimizations among Black victims vs 6.4% among other groups

## Data

- NCVS 2022/2023, from ICPSR studies 38603 and 38962; the analysis file uses a prepared extract saved as `NCVS2022.RData`.
- Raw NCVS files are large and are not tracked in this repo. See `data/README.md`.

## Status

Complete.

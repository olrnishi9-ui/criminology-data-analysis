# Working with National Crime Victimization Survey data
# CRIM 6002

# NCVS overview
#   https://bjs.ojp.gov/document/cv23_rev.pdf
# In 2023 226,480 persons in about 142,028 households
#  12 years-old and older
#  63% response rate for households
#  82% response rate for individuals
# Households remain in the sample for 3½ years
#    Eligible persons interviewed every 6 months, in person or by phone
#       for a total of seven interviews
# Cost
#   $62M annually
#   123,200 hours of respondent time
# organized by the Bureau of Justice Statistics
# conducted by the Census Bureau

# basic instrument https://bjs.ojp.gov/content/pub/pdf/ncvs22_bsq.pdf
# crime instrument https://bjs.ojp.gov/content/pub/pdf/ncvs22_cir.pdf

# Organize the datasets where you can find them
# Browse the Codebook
#   starting in 2022 ICPSR made separate codebooks for each file
#   Examine the categories of fields available in the NCVS
#   Absent is anything about place, BJS/Census do not release census tract
#   Need to go to Census RDC (Penn RDC) for access
#      https://web.sas.upenn.edu/pfsrdc/
#
# Setup NCVS data -------------------------------------------------------------
#   NCVS data collected constantly
#   The "2022" data are those collected in 2022, not crime in 2022
#   Need 2022 and 2023 NCVS data to get all of calendar year 2022
#      BJS reports "collection year" statistics
#      We use "calendar year" to compate with NIBRS

# Acquiring the NCVS data -------------------------------------------------

# Download the 2022 NCVS R files from ICPSR study 38603
# https://www.icpsr.umich.edu/web/NACJD/studies/38603
#
# Download the 2023 NCVS R files from ICPSR study 38962
# https://www.icpsr.umich.edu/web/NACJD/studies/38962
# 2023 data posted on September 11, 2024
#
# Extract the archives and name the folders NCVS2022 and NCVS2023
# The folders must be in the working directory before continuing
# DS0002 contains household data
# DS0003 contains person data
# DS0004 contains incident data
# DS0005 contains the incident-level extract

list.files("NCVS2022/", recursive = TRUE)
list.files("NCVS2023/", recursive = TRUE)

getwd()

library(dplyr)
library(tidyr)

dir.exists("NCVS2022")  # Should return TRUE
dir.exists("NCVS2023")  # Should return TRUE

list.files("NCVS2022", recursive = TRUE)
list.files("NCVS2023", recursive = TRUE)

# Household data ----------------------------------------------------------

load("NCVS2022/DS0002/38603-0002-Data.rda")
load("NCVS2023/DS0002/38962-0002-Data.rda")

# Give the imported objects clearer names
dataHH22 <- da38603.0002
dataHH23 <- da38962.0002

# Inspect a subset of household columns
dataHH22 |>
  head() |>
   select(V2001, YEARQ, IDHH, V2003, V2014, V2016, V2018, V2020,
          V2030, V2031, V2032, V2034, V2036, V2038, V2040A, V2127B, V2129)

# Extract the variable labels stored in the data-frame attributes
#   the household data frame has a somewhat hidden list of
#   variable name details

varsHH <- dataHH22 |>
  attr("variable.labels") |>
  data.frame() |>
  tibble::rownames_to_column() |>
  setNames(c("varname", "details")) |>
  filter(!grepl("^HHREP", varname)) # exclude replicate-weight columns

# Look up descriptions for the selected household variables
varsHH |>
  filter(varname %in% c("V2001",  "YEARQ", "IDHH",  "V2003", "V2014",
                        "V2016",  "V2018", "V2020", "V2030", "V2031",
                        "V2032",  "V2034", "V2036", "V2038", "V2040A",
                        "V2127B", "V2129"))

# Person data -------------------------------------------------------------

load("NCVS2022/DS0003/38603-0003-Data.rda")
load("NCVS2023/DS0003/38962-0003-Data.rda")
dataPers22 <- da38603.0003
dataPers23 <- da38962.0003

# Look up respondents from one household
#    two surveys six months apart of the same divorced male
dataPers22 |>
  filter(IDHH == "1809000258543680568236125") |>
  select(!starts_with("PERREP")) # drop replicate-weight columns

# Look up respondents from another household
#    two surveys at the same time, reference person + husband
dataPers22 |>
  filter(IDHH == "1809000284384631568236124") |>
  select(!starts_with("PERREP"))

# Extract person-file variable labels
#   skip the incident file and go straight to the incident extract file
varsPers <- dataPers22 |>
  attr("variable.labels") |>
  data.frame() |>
  tibble::rownames_to_column() |>
  setNames(c("varname", "details")) |>
  filter(!grepl("^(PERREP|PINTTYPE)", varname))
varsPers


# Incident data -----------------------------------------------------------

# The incident file overlaps with the more useful extract file below
load("NCVS2022/DS0004/38603-0004-Data.rda")
load("NCVS2023/DS0004/38962-0004-Data.rda")
dataInc22 <- da38603.0004
dataInc23 <- da38962.0004

dataInc22 |>
  select(IDHH, IDPER, V4014, V4529) |>
  head()


# Incident-level extract -------------------------------------------------
# Incident-level extract file combines household-level and person-level
#   information with incident-level information

# extract combines (some) household, person, and incident information
load("NCVS2022/DS0005/38603-0005-Data.rda")
load("NCVS2023/DS0005/38962-0005-Data.rda")
dataExt22 <- da38603.0005
dataExt23 <- da38962.0005

# Extract incident-extract variable labels
varsExt <- dataExt22 |>
  attr("variable.labels") |>
  data.frame() |>
  tibble::rownames_to_column() |>
  setNames(c("varname", "details")) |>
  filter(!grepl("INCREPWGT|VICREPWGT", varname))

# Inspect age, marital status, sex, location, and crime type
#   not all info from HH and Person file merged
dataExt22 |>
  select(V3014, V3015, V3018, V4022, V4529) |>
  slice(1:3)

# Remove the original imported object names
rm(da38603.0002, da38603.0003, da38603.0004, da38603.0005,
   da38962.0002, da38962.0003, da38962.0004, da38962.0005)


# Combining 2022 and 2023 data -------------------------------------------

# Respondents report victimizations from the previous six months
# Both survey years contain records for crimes occurring in 2022
dataExt22 |> count(V4015, V4014)
dataExt23 |> count(V4015, V4014)

# Verify that the files have the same column names
identical(names(dataExt22), names(dataExt23))

# stack 2022 on top of 2023
#   Error... complains about V2061
dataExt <- dataExt22 |>
  bind_rows(dataExt23)

# V2061 is a factor in one year and a double in the other
dataExt22 |> count(V2061)
dataExt23 |> count(V2061)
# Q.13.b.4 Line number of proxy respondent (fourth person)
#   not important... let's drop this one
varsExt |> filter(varname == "V2061")

# Error... complains about V4126
#   In 2022 it was saved as a factor, in 2023 as numeric (double)
dataExt <- dataExt22 |>
  select(-V2061) |>
  bind_rows(dataExt23 |> select(-V2061))

# V4126: WHICH INJURY FROM OTHER WEAPON (3RD)
# Q.33.3 Which injuries were caused by a weapon OTHER than a gun or knife?
#   no 2023 respondents said there was a third weapon that injured them
varsExt   |> filter(varname == "V4126")
dataExt22 |> count(V4126)
dataExt23 |> count(V4126)

# Try again, dropping V2061, force factor type for V4126
#    Error... complains about V4313
dataExt <- dataExt22 |>
   select(-V2061) |>
   bind_rows(dataExt23 |>
                select(-V2061) |>
                mutate(V4126 = as.factor(V4126)))

varsExt   |> filter(varname == "V4313")
# V4313: 3RD "LINE NUMBER" OF OTHER OWNER THEFT ITEMS
# Jc. Besides the respondent, which household member(s) owned the
#     (property/money) the offender tried to take?
dataExt22 |> count(V4313)
dataExt23 |> count(V4313)

# Try again
#   Error... complains about V4357A
dataExt <- dataExt22 |>
  select(-V2061) |>
  mutate(V4313 = recode_values(V4313,
                               "(06) 6" ~ 6,
                               default = NA)) |>
   bind_rows(dataExt23 |>
                select(-V2061) |>
                mutate(V4126 = as.factor(V4126)))

# V4357A: HOW MANY HANDGUNS WERE TAKEN
varsExt   |> filter(varname == "V4357A")
dataExt22 |> count(V4357A)
dataExt23 |> count(V4357A)

# Residue indicates an unusable or out-of-range response
# RESIDUE - data entry error resulting in an out-of-range code,
#     an incorrect or unusable answer by the respondent,
#     or the absence of an entry for a question that should have been asked

# Out of universe means the respondent was not supposed to receive the item
# OUT OF UNIVERSE/BLANK - case is outside the range of questions to be answered.
#     "Received Medical Care for Injury", only victims who report being
#     injured are asked whether they received medical care.
#     All other victims are skipped past this question

# Resolve all column-type conflicts and combine the years
dataExt <- dataExt22 |>
  select(-V2061) |>
   mutate(V4313 = recode_values(V4313,
                                "(06) 6" ~ 6,
                                default = NA)) |>
   bind_rows(dataExt23 |>
                select(-V2061) |>
                mutate(V4126 = as.factor(V4126),
                       V4357A = recode_values(V4357A,
                                              "(001) 1" ~ 1,
                                              "(998) Residue" ~ 998,
                                              default = NA)))

# Check the repaired variables
dataExt |> count(V4126)
dataExt |> count(V4313)
dataExt |> count(V4357A)

# Keep victimizations that occurred in calendar year 2022
table(dataExt$V4015)
dataExt <- dataExt |>
  filter(V4015 == 2022)

# These calendar-year estimates differ from official survey-year estimates

# Exclude victimizations that occurred outside the United States
# V4022 asks for the city, town, or village where the incident occurred
dataExt |> count(V4022)

dataExt <- dataExt |>
  filter(is.na(V4022) | V4022 != "(1) Outside U.S.")


# Sampling weights --------------------------------------------------------

# Always use sampling weights for NCVS population estimates
# Unweighted counts are useful only for checking the sample data
#
# SERIES_WEIGHT estimates criminal victimizations
# SERIES_IWEIGHT estimates criminal incidents
# WGTPERCY is the population denominator for personal victimization rates
# WGTHHCY is the household denominator for property victimization rates
# Replicate weights are needed for valid standard errors and intervals
#
# Weighted total = sum(weights)
# Weighted mean = sum(weight * value) / sum(weight)
# Weighted percentage = 100 * subgroup weights / all relevant weights

# Series crimes can represent repeated similar victimizations
# BJS counts up to 10 occurrences for a series crime
# SERIES_WEIGHT includes this adjustment
# WGTVICCY counts each incident-extract record once

# Inspect records affected by the series adjustment
dataExt |>
   mutate(seriesMultiplier = SERIES_WEIGHT / WGTVICCY) |>
   filter(seriesMultiplier > 1) |>
   select(V4016, V4019, WGTVICCY, SERIES_WEIGHT,
          seriesMultiplier) |>
   head()


# Exercises 1-2 -----------------------------------------------------------

# 1. Compare nrow(dataExt), sum(dataExt$WGTVICCY), and
#    sum(dataExt$SERIES_WEIGHT), what does each number represent?

sample_records <- nrow(dataExt)

total_without_series <- sum(dataExt$WGTVICCY, na.rm = TRUE)

total_with_series <- sum(dataExt$SERIES_WEIGHT, na.rm = TRUE)

# Display the results
c(
  sample_records = sample_records,
  total_without_series = total_without_series,
  total_with_series = total_with_series
)

# 2. Calculate the percentage increase from WGTVICCY to SERIES_WEIGHT
#    This is the effect of accounting for series victimizations
# 2. Percentage increase from accounting for series victimizations
percentage_increase <- (
  (total_with_series - total_without_series) /
    total_without_series
) * 100

percentage_increase


# Tabulating victimizations -----------------------------------------------

# Victimizations count affected people or households
# Incidents count criminal events and can involve multiple victims

# Estimated total number of victimizations
sum(dataExt$SERIES_WEIGHT)

# Estimated totals by detailed crime type
dataExt |>
  group_by(V4529) |>
  summarize(total = sum(SERIES_WEIGHT)) |>
  print(n = Inf)

# Extract the two-digit crime code and create three broad categories
# Codes 01-20 are violent crimes
# Codes 21-23 are personal larceny
# Remaining codes are household property crimes
dataExt <- dataExt |>
   mutate(crimeCode = as.integer(
      gsub("^\\(([0-9]{2})\\).*", "\\1", V4529)),
      crimeType = case_when(
         crimeCode <= 20 ~ "violent",
         crimeCode <= 23 ~ "personal larceny",
         .default = "property"))

dataExt |>
  select(V4529, crimeCode, crimeType) |>
  head()

# Estimated totals by broad crime type
dataExt |>
   group_by(crimeType) |>
   summarize(estTotal = sum(SERIES_WEIGHT))


# Attempted and completed motor vehicle thefts
dataExt |>
  filter(V4529 %in% c("(40) Motor veh theft", "(41) At mtr veh theft")) |>
  summarize(sum(SERIES_WEIGHT))

# Attempted and completed rape
# how many rapes?
#   Note UCR change in rape definition starting in 2013
#   http://www.fbi.gov/about-us/cjis/cjis-link/march-2012/ucr-program-changes-definition-of-rape
#   NCVS has changed definition and survey instrument frequently
#      most recently in 2024
#      Fisher, B. S., & Gross, R. L. (2024). "The Evolution of the Measurement of Rape and Sexual Assault Over 50 Years: Milestones, Definitions, Operationalizations, and Classifications," Journal of Contemporary Criminal Justice, 41(1), 166-195.
dataExt |>
  filter(V4529 %in% c("(01) Completed rape", "(02) Attempted rape")) |>
  summarize(sum(SERIES_WEIGHT))

# Inspect all detailed crime categories
unique(dataExt$V4529)

# NCVS official reports combine all rape and sexual assaults
dataExt |>
  filter(grepl("rape|[Ss]ex", V4529)) |>
  distinct(V4529)

# Estimated rape and sexual assault victimizations
dataExt |>
  filter(grepl("rape|[Ss]ex", V4529)) |>
  summarize(sum(SERIES_WEIGHT))


# Official BJS report at https://bjs.ojp.gov/document/cv22.pdf
# Since 2019 we have no national crime estimates based on police reporting


# if you want a victimization *rate*
#   for personal crimes divide by weighted number of persons (12+) at risk
sum(dataPers22$WGTPERCY, na.rm = TRUE)
#   for household crimes divide by weighted number of households at risk
sum(dataHH22$WGTHHCY, na.rm = TRUE)

# Exercises 3-4 -----------------------------------------------------------

# 3. Using crimeType, calculate the weighted percentage of victimizations in
#    the violent crime, personal larceny, and household property categories
# 4. Estimate the number and weighted percentage of motor vehicle thefts
#    that were attempts rather than completed thefts



# Victimization by demographics ------------------------------------------

# Give demographic variables clearer names
dataExt <- dataExt |>
   rename(age = V3014,
          marital = V3015,
          sex = V3018)

# Household property crimes are assigned to households
# Use only personal crimes for respondent demographic comparisons

# Weighted personal victimizations by crime type and sex
dataExt |>
   filter(crimeCode <= 23) |>
   group_by(V4529, sex) |>
   summarize(count = sum(SERIES_WEIGHT)) |>
   print(n = Inf)

# Put male and female totals in side-by-side columns
dataExt |>
   filter(crimeCode <= 23) |>
   group_by(V4529, sex) |>
   summarize(count = sum(SERIES_WEIGHT)) |>
   pivot_wider(names_from = sex,
               values_from = count,
               values_fill = 0) |>
   print(n = Inf)

# Convert each sex column to a distribution that sums to 100 percent
dataExt |>
   filter(crimeCode <= 23) |>
   group_by(V4529, sex) |>
   summarize(count = sum(SERIES_WEIGHT)) |>
   ungroup() |> # otherwise percentages are computed within crime type
   pivot_wider(names_from = sex,
               values_from = count,
               values_fill = 0) |>
   rename(male = `(1) Male`,
          female = `(2) Female`) |>
   mutate(male = 100 * male / sum(male),
          female = 100 * female / sum(female),
          ratio = female / male) |>
   arrange(desc(ratio)) |>
   print(n = Inf)

# The .by argument replaces group_by(), summarize(), and ungroup()
dataExt |>
   filter(crimeCode <= 23) |>
   summarize(count = sum(SERIES_WEIGHT),
             .by = c(V4529, sex)) |>
   pivot_wider(names_from = sex,
               values_from = count,
               values_fill = 0) |>
   rename(male = `(1) Male`,
          female = `(2) Female`) |>
   mutate(male = 100 * male / sum(male),
          female = 100 * female / sum(female),
          ratio = female / male) |>
   arrange(desc(ratio)) |>
   print(n = Inf)

# Repeat the distribution calculation by age group
dataExt |>
   filter(crimeCode <= 23) |>
   mutate(ageGroup = cut(age,
                         breaks = c(0, 17, 24, 34, 49, 64, Inf),
                         labels = c("12-17", "18-24", "25-34",
                                    "35-49", "50-64", "65+"))) |>
   summarize(count = sum(SERIES_WEIGHT),
             .by = c(V4529, ageGroup)) |>
   pivot_wider(names_from = ageGroup,
               values_from = count,
               values_fill = 0,
               names_sort = TRUE) |>
   mutate(across(-V4529, function(x) 100 * x / sum(x))) |>
   arrange(desc(`18-24`)) |>
   print(n = Inf)


# Exercise 5 --------------------------------------------------------------

# 5. Repeat the demographic analysis using marital status
#    Calculate the weighted percentage of personal victimizations in each
#    crime category for every marital-status group
#    Which crime types have a larger percentage among divorced respondents
#    than among married respondents?



# Save the cleaned calendar-year dataset ----------------------------------

# This file is used in later lessons
# Writing it can take a few moments
save(dataExt, file = "NCVS2022.RData", compress = TRUE)
# 保存清理后的数据，其中包含 SERIES_WEIGHT
saveRDS(dataExt, file = "NCVS2022_clean.rds")


# Review ------------------------------------------------------------------

# NCVS data levels
# Household file
# Person file
# Incident file
# Incident-level extract
#


# ____ 
# Combining data
# bind_rows()
# recode_values()
#
# Weighted estimates
# SERIES_WEIGHT
# SERIES_IWEIGHT
# WGTPERCY
# WGTHHCY
#
# Tabulation and reshaping
# summarize(.by = ...)
# pivot_wider()
# across()

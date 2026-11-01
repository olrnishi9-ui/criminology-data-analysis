load("NCVS2022.RData")
library(dplyr)
head(dataExt)
sum(dataExt$SERIES_WEIGHT)
nrow(dataExt)
head(dataExt[c("V4529", "SERIES_WEIGHT")])
library(tidyr)

#1a 
# 1. search for the assault related crimes 
dataExt |>
  distinct(crimeCode, V4529) |>
  filter(grepl("aslt|assault|asl", V4529, ignore.case = TRUE)) |>
  arrange(crimeCode) |>
  tibble::as_tibble() |>
  print(n = Inf)

# 2. Confirming that these variables are assault related
assaults <- dataExt |>
  filter(crimeCode %in% c(11, 12, 13, 14, 17, 20))

# 3. add weight by locations
assault_locations <- assaults |>
  group_by(V4024) |>
  summarise(
    estimated_total = sum(SERIES_WEIGHT),
    .groups = "drop"
  )

# 4. calculate the proportion of every locations assault rate and arrage them in order
assault_locations <- assault_locations |>
  mutate(
    percent = 100 * estimated_total / sum(estimated_total)
  ) |>
  arrange(desc(estimated_total))

# 5. demonstrate the result
assault_locations |>
  mutate(
    estimated_total = round(estimated_total),
    percent = round(percent, 2)
  ) |>
  tibble::as_tibble() |>
  print(n = Inf)

#Don't make too many variables ***VERY IMPORTANT

# About 35.1% of assault victimization occurred at or near the
# victim's home. Another 16.9% occurred on an open street away
# from home, 8.7% at school, and 15.0% at "other" locations.




#1b
assaults |>
  distinct(V4021B) |>
  arrange(V4021B) |>
  tibble::as_tibble() |>
  print(n = Inf)

# Give the time categories clearer labels
assaults <- assaults |>
  mutate(
    time_code = as.integer(
      sub("^\\(([0-9]+)\\).*", "\\1", as.character(V4021B))
    ),
    time_of_day = case_when(
      time_code == 1 ~ "6 a.m.–noon",
      time_code == 2 ~ "Noon–3 p.m.",
      time_code == 3 ~ "3–6 p.m.",
      time_code == 4 ~ "Daytime, exact time unknown",
      time_code == 5 ~ "6–9 p.m.",
      time_code == 6 ~ "9 p.m.–midnight",
      time_code == 7 ~ "Midnight–6 a.m.",
      time_code == 8 ~ "Nighttime, exact time unknown",
      time_code == 9 ~ "Day/night unknown",
      TRUE ~ "Missing / invalid response"
    )
  )

# Estimate victimizations by time of day
assault_times <- assaults |>
  group_by(time_code, time_of_day) |>
  summarise(
    estimated_total = sum(SERIES_WEIGHT),
    .groups = "drop"
  ) |>
  mutate(
    percent = 100 * estimated_total / sum(estimated_total)
  ) |>
  arrange(time_code)

# Show all results
assault_times |>
  mutate(
    estimated_total = round(estimated_total),
    percent = round(percent, 2)
  ) |>
  tibble::as_tibble() |>
  print(n = Inf)

#The largest estimated share occurred between noon and 3 p.m. (19.28%), followed 
#by 3–6 p.m. (18.05%). These are shares within time intervals; the intervals have 
#different lengths, so they do not measure risk per hour.

#1c
# Solo-Offender : Did the victim know perpetrator 
assaults |>
  distinct(V4241) |>
  arrange(V4241) |>
  tibble::as_tibble() |>
  print(n = Inf)

# Offenses involving multiple perpetrators: Were they all strangers?
assaults |>
  distinct(V4256) |>
  arrange(V4256) |>
  tibble::as_tibble() |>
  print(n = Inf)

assaults <- assaults |>
  mutate(
    offender_relationship = case_when(
      V4241 %in% "(1) Knew/had seen" |
        V4256 %in% c(
          "(1) All known",
          "(2) Some known",
          "(6) DK if 1 or 2"
        ) ~ "At least one offender known / seen before",
      
      V4241 %in% "(2) Stranger" |
        V4256 %in% "(3) All strangers" ~ "Stranger(s)",
      
      TRUE ~ "Unknown / invalid / missing"
    )
  )

assault_offenders <- assaults |>
  group_by(offender_relationship) |>
  summarise(
    estimated_total = sum(SERIES_WEIGHT),
    .groups = "drop"
  ) |>
  mutate(
    percent = 100 * estimated_total / sum(estimated_total)
  ) |>
  arrange(desc(estimated_total))

assault_offenders |>
  mutate(
    estimated_total = round(estimated_total),
    percent = round(percent, 2)
  ) |>
  tibble::as_tibble() |>
  print(n = Inf)

#Using SERIES_WEIGHT, an estimated 52.55% of assault victimizations involved at
#least one offender whom the victim knew or had seen before. Strangers accounted for 39.95%, 
#while the offender relationship was unknown or unavailable for 7.50%.

#1d
# Weapons? 
assaults |>
  distinct(V4049) |>
  tibble::as_tibble() |>
  print(n = Inf)

# What kind of weapons? 
assaults |>
  distinct(V4051) |>
  tibble::as_tibble() |>
  print(n = Inf)

weapon_presence <- assaults |>
  group_by(V4049) |>
  summarise(
    estimated_total = sum(SERIES_WEIGHT),
    .groups = "drop"
  ) |>
  mutate(
    percent = 100 * estimated_total / sum(estimated_total)
  )

weapon_presence |>
  mutate(
    estimated_total = round(estimated_total),
    percent = round(percent, 2)
  ) |>
  tibble::as_tibble() |>
  print(n = Inf)

assaults <- assaults |>
  mutate(
    firearm = V4051 %in% "(1) Yes" |
      V4052 %in% "(1) Yes" |
      V4057 %in% "(1) Yes"
  )

weapon_types <- assaults |>
  summarise(
    Firearm = sum(SERIES_WEIGHT[firearm]),
    Knife = sum(SERIES_WEIGHT[V4053 %in% "(1) Yes"]),
    Other_sharp_object = sum(SERIES_WEIGHT[V4054 %in% "(1) Yes"]),
    Blunt_object = sum(SERIES_WEIGHT[V4055 %in% "(1) Yes"]),
    Other_weapon = sum(SERIES_WEIGHT[V4056 %in% "(1) Yes"])
  ) |>
  tidyr::pivot_longer(
    everything(),
    names_to = "weapon",
    values_to = "estimated_total"
  ) |>
  mutate(
    percent = 100 * estimated_total / sum(assaults$SERIES_WEIGHT[assaults$V4049 %in% "(1) Yes"])
  ) |>
  arrange(desc(estimated_total))

weapon_types |>
  mutate(
    estimated_total = round(estimated_total),
    percent = round(percent, 2)
  ) |>
  tibble::as_tibble() |>
  print(n = Inf)

# An estimated 25.7% of assault victimizations involved a weapon,
# 66.0% did not, and 8.4% had unknown weapon status.
# Among assaults with a weapon, firearms were the most common
# (32.5%), followed by blunt objects (26.9%) and knives (18.2%).

#1e
assaults |>
  distinct(V4399) |>
  tibble::as_tibble() |>
  print(n = Inf)

assaults |>
  count(V4399, wt = SERIES_WEIGHT, name = "estimated_total") |>
  mutate(
    percent = 100 * estimated_total / sum(estimated_total)
  ) |>
  tibble::as_tibble() |>
  print(n = Inf)

# An estimated 43.4% of assault victimizations were reported
# to police, 53.6% were not, 2.3% were "don't know",
# and 0.7% were coded as residue.

#1f
assaults |>
  filter(
    V4144 %in% "(1) Yes" |
      V4147 %in% "(1) Yes"
  ) |>
  summarise(
    estimated_total = sum(SERIES_WEIGHT)
  )

#Using SERIES_WEIGHT, an estimated 29,328 assault victimizations involved defensive 
#firearm use, defined as attacking or threatening the offender with a gun.
#This estimate rests on only 15 sample cases and is highly uncertain.

#2a
dataExt |>
  distinct(V3023A) |>
  arrange(V3023A) |>
  tibble::as_tibble() |>
  print(n = Inf)

race_crime_table <- dataExt |>
  filter(crimeCode %in% 1:23) |>
  count(
    V4529, V3023A,
    wt = SERIES_WEIGHT,
    name = "estimated_total"
  ) |>
  tidyr::pivot_wider(
    names_from = V3023A,
    values_from = estimated_total,
    values_fill = 0
  )

race_crime_table |>
  mutate(across(where(is.numeric), round)) |>
  tibble::as_tibble() |>
  print(n = Inf, width = Inf)

#In the largest groups (White, Black, Asian), verbal threats of assault and
#assaults without weapon or injury are the most common types.

#2b
race_share <- dataExt |>
  filter(crimeCode %in% 1:23) |>
  mutate(black = if_else(V3023A == "(02) Black only", "Black", "Other")) |>
  summarize(count = sum(SERIES_WEIGHT),   # weighted national estimate
            n     = n(),                  # unweighted sample cases
            .by   = c(V4529, black)) |>
  pivot_wider(names_from  = black,
              values_from = c(count, n),
              values_fill = 0) |>
  mutate(pct_Black = 100 * count_Black / sum(count_Black),
         pct_Other = 100 * count_Other / sum(count_Other),
         ratio     = pct_Black / pct_Other) |>
  arrange(desc(ratio))

race_share |>
  mutate(across(c(count_Black, count_Other), round),
         across(c(pct_Black, pct_Other, ratio), \(x) round(x, 2))) |>
  tibble::as_tibble() |>
  print(n = Inf, width = Inf)

# Among Black-only victims, aggravated assault with injury
# accounted for 10.1% of personal victimizations, compared
# with 6.4% among other race groups. Simple assault with injury
# accounted for 11.7% versus 8.4%, and threatened assault
# with a weapon accounted for 12.0% versus 9.4%.
# These compare the composition of victimizations,
# not population victimization rates.
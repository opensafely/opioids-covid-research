##############################################################
# This script downloads and restructures mid-year 2020 pop 
# estimates to be used for age/sex standardisation.
# Mid-year pop downloaded from ONS.
#
# (From Linda Nab)
##############################################################


library('tidyverse')
library('onsr')
library('here')

## create output directories ----
fs::dir_create(here("ONS-data"))

# download mid year pop estimates ----
ons_pop_estimates <- ons_get("mid-year-pop-est")

# restructure to same format as our estimates are in ----
ons_pop_est <-
  ons_pop_estimates %>%
  filter(
    `administrative-geography` %in% c(
      "E12000001",
      "E12000002",
      "E12000003",
      "E12000004",
      "E12000005",
      "E12000006",
      "E12000007",
      "E12000008",
      "E12000009" 
    ), # nine regions in England
    sex %in% c("male", "female"),
    `single-year-of-age` %in% c(18:89, "90+"),
    `calendar-years` == 2020
  ) %>%
  transmute(
    year = `calendar-years`,
    age = `single-year-of-age`,
    age_stand = case_when(
      age >= 18 & age < 25 ~ "18-24 y",
      age >= 25 & age < 30 ~ "25-29 y",
      age >= 30 & age < 35 ~ "30-34 y",
      age >= 35 & age < 40 ~ "35-39 y",
      age >= 40 & age < 45 ~ "40-44 y",
      age >= 45 & age < 50 ~ "45-49 y",
      age >= 50 & age < 55 ~ "50-54 y",
      age >= 55 & age < 60 ~ "55-59 y",
      age >= 60 & age < 65 ~ "60-64 y",
      age >= 65 & age < 70 ~ "65-69 y",
      age >= 70 & age < 75 ~ "70-74 y",
      age >= 75 & age < 80 ~ "75-79 y",
      age >= 80 & age < 85 ~ "80-84 y",
      age >= 85 & age < 90 ~ "85-89 y",
      age >= 90 ~ "90+ y",
    ),
    age_stand = factor(age_stand,
                          levels = c("18-24 y", "25-29 y", "30-34 y",
                                     "35-39 y", "40-44 y", "45-49 y",
                                     "50-54 y", "55-59 y", "60-64 y",
                                     "65-69 y", "70-74 y", "75-79 y",
                                     "80-84 y", "85-89 y", "90+ y")),
    sex = `Sex`,
    region = str_replace(str_to_title(`Geography`), "And The", "and The"), # TPP
    mid_year_pop = `v4_0`,
  ) %>%
  arrange(year, age, sex, region)

# Aggregate by age, sex
ons_pop_est_agesex <- ons_pop_est %>%
  group_by(age_stand, sex) %>%
  summarise(uk_pop = sum(mid_year_pop)) 

# Total
ons_pop_est_tot <- ons_pop_est %>%
  summarise(uk_pop = sum(mid_year_pop)) %>%
  mutate(age_stand = "Total", sex = "Total")

# Age only
ons_pop_est_age <- ons_pop_est %>%
  group_by(age_stand) %>%
  summarise(uk_pop = sum(mid_year_pop)) %>%
  mutate(sex = "Total")

# Sex only
ons_pop_est_sex <- ons_pop_est %>%
  group_by(sex) %>%
  summarise(uk_pop = sum(mid_year_pop)) %>%
  mutate(age_stand = "Total")

# Combine
ons_pop_est_stand <- rbind(
  ons_pop_est_agesex, ons_pop_est_age,
  ons_pop_est_sex, ons_pop_est_tot)

# save restructured estimates ----
write.csv(ons_pop_est_stand, here("ONS-data", "ons_pop_stand.csv"), row.names = FALSE)
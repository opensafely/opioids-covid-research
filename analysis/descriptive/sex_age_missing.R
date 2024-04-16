####################################################################################################
# This script:
# - Produces counts of patients prescribed opioids by demographic characteristics (Apr-Jun 2022)
# - Both overall in full population, and people without a cancer diagnosis
# - Both crude and age/sex standardised
####################################################################################################

## For running locally only
# setwd("C:/Users/aschaffer/OneDrive - Nexus365/Documents/GitHub/opioids-covid-research")
# getwd()

## Import libraries
library('tidyverse')
library('lubridate')
library('reshape2')
library('here')
library('fs')

## Custom functions
source(here("analysis", "lib", "custom_functions.R"))

## Create directories if needed
dir_create(here::here("output", "tables"), showWarnings = FALSE, recurse = TRUE)
dir_create(here::here("output", "data"), showWarnings = FALSE, recurse = TRUE)

## Read in data 
cohort <- read_csv(here::here("output", "data", "dataset_missing.csv.gz")) %>%
  mutate(age_wrong = case_when(
                      (age >= 18 & age <110) ~ "Included", 
                      (age >= 0 & age < 18) ~ "Excluded",
                      TRUE ~ "Incorrect"))

cohort_sex <- cohort %>%
    mutate(total = rounding(n())) %>%
    group_by(sex) %>%
    summarise(
      count = rounding(n())
    ) %>%
    ungroup() %>%
    mutate(variable = "Sex") %>%
    rename(category = sex)

cohort_age <- cohort %>%
  mutate(total = rounding(n())) %>%
  group_by(age_wrong) %>%
  summarise(
    count = rounding(n())
  ) %>%
  ungroup() %>%
  mutate(variable = "Age") %>%
  rename(category = age_wrong)

both <- rbind(cohort_sex, cohort_age)


write.csv(both, here::here("output", "tables", "cohort_sex_age_missing.csv"),
          row.names = FALSE)

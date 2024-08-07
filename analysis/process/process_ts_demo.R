######################################################
# This script:
# - imports measures data for prescribing stratified by demographics
# - cleans up data 
# - applies rounding and redaction
# - saves processed dataset(s)
#
# Author: Andrea Schaffer 
#   Bennett Institute for Applied Data Science
#   University of Oxford, 2024
#####################################################################


# For running locally only #
#setwd("C:/Users/aschaffer/OneDrive - Nexus365/Documents/GitHub/opioids-covid-research")
#getwd()

# Import libraries #
library('tidyverse')
library('lubridate')
library('arrow')
library('here')
library('reshape2')
library('dplyr')
library('fs')


## Custom functions
source(here("analysis", "lib", "custom_functions.R"))

# Create directory
dir_create(here::here("output", "timeseries"), showWarnings = FALSE, recurse = TRUE)
dir_create(here::here("output", "measures"), showWarnings = FALSE, recurse = TRUE)

# Custom functions
source(here("analysis", "lib", "custom_functions.R"))


###############################
# Clean up measures datasets  #
###############################

# By demographics
## Prevalent 
demo_prev <- read_csv(here::here("output", "measures", "measures_demo_prev.csv")) %>%
  mutate(month = as.Date(interval_start, format="%Y-%m-%d"),
         period = ifelse(month < as.Date("2020-03-01"), "Pre-COVID", 
                         ifelse(month >= as.Date("2021-04-01"), "Recovery", "Lockdown")),
         cat = coalesce(age_group, sex, region, imd, ethnicity6),
         var = gsub("opioid_any_", "", measure),
         measure = substr(measure,1,10)) %>%
  dplyr::select(c(measure, month, cat, var, numerator, denominator, period)) %>%
  pivot_wider(names_from = measure, values_from = c(numerator, denominator)) %>%
  rename(opioid_any = numerator_opioid_any,
         pop_total = denominator_opioid_any) 

## New
demo_new <- read_csv(here::here("output", "measures", "measures_demo_new.csv")) %>%
  mutate(month = as.Date(interval_start, format="%Y-%m-%d"),
         cat = coalesce(age_group, sex, region, imd, ethnicity6),
         var = gsub("opioid_new_", "", measure),
         measure = substr(measure,1,10)) %>%
  dplyr::select(c(measure, month, cat, var, numerator, denominator)) %>%
  pivot_wider(names_from = measure, values_from = c(numerator, denominator)) %>%
  rename(opioid_new = numerator_opioid_new,
         pop_naive = denominator_opioid_new)

demo <- merge(demo_new, demo_prev, by.x = c("month", "cat", "var"),
              by.y = c("month",  "cat", "var")) %>%
  arrange(month, var, cat)


write.csv(demo, file = here::here("output", "timeseries", "ts_demo.csv"),
          row.names = FALSE)


###########################
# Rounding and redaction  #
###########################

# By demographics
demo_round <- read_csv(here::here("output", "timeseries", "ts_demo.csv")) %>%
  mutate(opioid_any_round = rounding(opioid_any),
         opioid_new_round = rounding(opioid_new),
         pop_total_round = rounding(pop_total),
         pop_naive_round = rounding(pop_naive)) %>%
  dplyr::select(!c(opioid_any, opioid_new, pop_total, pop_naive)) %>%
  arrange(month, var, cat)

demo_round <- demo_round[,c("month", "period", "var", "cat", "opioid_any_round", "opioid_new_round",
                "pop_total_round", "pop_naive_round")]

write.csv(demo_round, here::here("output", "timeseries", "ts_demo_rounded.csv"), row.names = FALSE)

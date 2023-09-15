######################################################
# This script:
# - imports measures data for overall prescribing
# - cleans up data 
# - applies rounding and redaction
# - saves processed dataset(s)
#######################################################


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


###############################
# Clean up measures datasets  #
###############################

# Overall counts 
overall <- read_csv(here::here("output", "measures", "measures_overall.csv")) %>% 
  filter(str_detect(measure, "_nocancer", negate = TRUE)) %>%
  mutate(month = as.Date(interval_start, format="%Y-%m-%d"),
         period = ifelse(month < as.Date("2020-03-01"), "Pre-COVID", 
                         ifelse(month >= as.Date("2021-04-01"), "Recovery", "Lockdown"))) %>%
  dplyr::select(!c(interval_start, interval_end, ratio)) %>%
  pivot_wider(names_from = measure, values_from = c(numerator, denominator)) %>%
  rename(opioid_any = numerator_opioid_any,
         hi_opioid_any = numerator_hi_opioid_any,
         opioid_new = numerator_opioid_new,
         pop_total = denominator_opioid_any,
         pop_naive = denominator_opioid_new) %>%
  dplyr::select(!c(denominator_hi_opioid_any)) %>%
  mutate(rate_opioid_any = (opioid_any / pop_total * 1000),
         rate_hi_opioid_any = (hi_opioid_any / pop_total * 1000),
         rate_opioid_new = (opioid_new / pop_naive * 1000))

write.csv(overall, file = here::here("output", "timeseries", "ts_overall.csv"),
          row.names = FALSE)

# Overall counts - without cancer
overall_noca <- read_csv(here::here("output", "measures", "measures_overall.csv")) %>%
  filter(str_detect(measure, "_nocancer", negate = FALSE)) %>%
  mutate(month = as.Date(interval_start, format="%Y-%m-%d"),
         period = ifelse(month < as.Date("2020-03-01"), "Pre-COVID", 
                         ifelse(month >= as.Date("2021-04-01"), "Recovery", "Lockdown")),
         measure = gsub("_nocancer", "", measure)) %>%
  dplyr::select(!c(interval_start, interval_end, ratio)) %>%
  pivot_wider(names_from = measure, values_from = c(numerator, denominator)) %>%
  rename(opioid_any = numerator_opioid_any,
         hi_opioid_any = numerator_hi_opioid_any,
         opioid_new = numerator_opioid_new,
         pop_total = denominator_opioid_any,
         pop_naive = denominator_opioid_new) %>%
  dplyr::select(!c(denominator_hi_opioid_any)) %>%
  mutate(rate_opioid_any = (opioid_any / pop_total * 1000),
         rate_hi_opioid_any = (hi_opioid_any / pop_total * 1000),
         rate_opioid_new = (opioid_new / pop_naive * 1000))

write.csv(overall_noca, file = here::here("output", "timeseries", "ts_overall_nocancer.csv"),
          row.names = FALSE)


###########################
# Rounding and redaction  #
###########################

overall_round <- read_csv(here::here("output", "timeseries", "ts_overall.csv")) %>%
  mutate(opioid_any_round = rounding(opioid_any),
         hi_opioid_any_round = rounding(hi_opioid_any),
         opioid_new_round = rounding(opioid_new),
         pop_total_round = rounding(pop_total),
         pop_naive_round = rounding(pop_naive),
         rate_opioid_any_round = (opioid_any_round / pop_total_round * 1000),
         rate_hi_opioid_any_round = (hi_opioid_any_round / pop_total_round * 1000),
         rate_opioid_new_round = (opioid_new_round / pop_naive_round * 1000),
         pcent_new = opioid_new_round / opioid_any_round * 100,
         pcent_hi = hi_opioid_any_round / opioid_any_round) %>%
  dplyr::select(!c(opioid_any, hi_opioid_any, opioid_new, pop_total, pop_naive,
              rate_opioid_any, rate_hi_opioid_any, rate_opioid_new))

write.csv(overall_round, here::here("output", "timeseries", "ts_overall_rounded.csv"),
          row.names = FALSE)

overall_nocancer_round <- read_csv(here::here("output", "timeseries", "ts_overall_nocancer.csv")) %>%
  mutate(opioid_any_round = rounding(opioid_any),
         hi_opioid_any_round = rounding(hi_opioid_any),
         opioid_new_round = rounding(opioid_new),
         pop_total_round = rounding(pop_total),
         pop_naive_round = rounding(pop_naive),
         rate_opioid_any_round = (opioid_any_round / pop_total_round * 1000),
         rate_hi_opioid_any_round = (hi_opioid_any_round / pop_total_round * 1000),
         rate_opioid_new_round = (opioid_new_round / pop_naive_round * 1000),
         pcent_new = opioid_new_round / opioid_any_round * 100,
         pcent_hi = hi_opioid_any_round / opioid_any_round) %>%
  dplyr::select(!c(opioid_any, hi_opioid_any, opioid_new, pop_total, pop_naive,
              rate_opioid_any, rate_hi_opioid_any, rate_opioid_new))

write.csv(overall_nocancer_round, here::here("output", "timeseries", "ts_overall_nocancer_rounded.csv"))


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

dia <- read_csv(here::here("output", "measures", "measures_test.csv")) %>%
  mutate(month = as.Date(interval_start, format="%Y-%m-%d"),
         period = ifelse(month < as.Date("2020-03-01"), "Pre-COVID",
                         ifelse(month >= as.Date("2021-04-01"), "Recovery", "Lockdown"))) %>%
  dplyr::select(!c(interval_start, interval_end, ratio)) %>%
  group_by(month, measure) %>%
  summarise(count = sum(numerator)) %>%
  mutate(count = case_when(count> 10 ~ round(count / 7) * 7))
  

write.csv(dia, file = here::here("output", "timeseries", "ts_diamorphine.csv"),
          row.names = FALSE)




dmd <- read_csv(here::here("output", "measures", "measures_test_3.csv")) %>%
  mutate(month = as.Date(interval_start, format="%Y-%m-%d"),
         period = ifelse(month < as.Date("2020-03-01"), "Pre-COVID",
                         ifelse(month >= as.Date("2021-04-01"), "Recovery", "Lockdown"))) %>%
  dplyr::select(!c(interval_start, interval_end, ratio)) %>%
  subset(!is.na(dmd_code)) %>%
  group_by(month, dmd_code) %>%
  summarise(count = sum(numerator)) %>%
  mutate(count = case_when(count> 10 ~ round(count / 7) * 7))

write.csv(dmd, file = here::here("output", "timeseries", "ts_dmd.csv"),
          row.names = FALSE)

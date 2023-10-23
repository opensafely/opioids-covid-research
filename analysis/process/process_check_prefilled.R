
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

# type <- read_csv(here::here("output", "measures", "measures_test_3.csv")) %>%
#   mutate(month = as.Date(interval_start, format="%Y-%m-%d"),
#          period = ifelse(month < as.Date("2020-03-01"), "Pre-COVID", 
#                          ifelse(month >= as.Date("2021-04-01"), "Recovery", "Lockdown")),
#          prefilled = ifelse(dmd_code = 1075511000001100, "Pre-filled", "Other")) %>%
#   dplyr::select(!c(interval_start, interval_end, ratio)) %>%
#   group_by(month, prefilled) %>%
#   summarise(count = sum(numerator))
# 
# write.csv(type, file = here::here("output", "timeseries", "ts_prefilled.csv"),
#           row.names = FALSE)


type2 <- read_csv(here::here("output", "measures", "measures_test_3.csv")) %>%
  mutate(month = as.Date(interval_start, format="%Y-%m-%d"),
         period = ifelse(month < as.Date("2020-03-01"), "Pre-COVID", 
                         ifelse(month >= as.Date("2021-04-01"), "Recovery", "Lockdown")),
         prefilled = ifelse(dmd_code %in% c("1075511000001100"), "Pre-filled", "Other")) %>%
  dplyr::select(!c(interval_start, interval_end, ratio)) %>%
  group_by(month, prefilled) %>%
  summarise(count = sum(numerator))

write.csv(type2, file = here::here("output", "timeseries", "ts_prefilled2.csv"),
          row.names = FALSE)


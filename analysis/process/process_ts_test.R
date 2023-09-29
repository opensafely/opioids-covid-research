######################################################
# This script:
# - checks overall prescribing (no. items)
# for comparison with OpenPrescribing
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

# By admin route
test <- read_csv(here::here("output", "measures", "measures_test.csv")) %>%
  mutate(month = as.Date(interval_start, format="%Y-%m-%d"),
         measure = case_when(
           measure == "par_opioid" ~ "Parenteral",
           measure == "any_opioid" ~ "Any",
           measure == "trans_opioid" ~ "Transdermal",
          )) %>%
  rename(no_items = numerator, pop_total = denominator) %>%
  dplyr::select(!c(interval_start, interval_end, ratio)) 

write.csv(test, file = here::here("output", "timeseries", "ts_test.csv"),
          row.names = FALSE)


###########################
# Rounding and redaction  #
###########################

# By admin route
test_round <- read_csv(here::here("output", "timeseries", "ts_test.csv")) %>%
  mutate(no_items_round = rounding(no_items),
         pop_total_round = rounding(pop_total)) %>%
  dplyr::select(!c(no_items, pop_total)) 

write.csv(test_round, here::here("output", "timeseries", "ts_test_rounded.csv"), 
          row.names = FALSE)

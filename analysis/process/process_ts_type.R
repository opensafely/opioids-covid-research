######################################################
# This script:
# - imports measures data for prescribing by admin route
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

# By admin route
type <- read_csv(here::here("output", "measures", "measures_type.csv")) %>%
  filter(str_detect(measure, "_nocancer", negate = TRUE)) %>%
  mutate(month = as.Date(interval_start, format="%Y-%m-%d"),
         period = ifelse(month < as.Date("2020-03-01"), "Pre-COVID", 
                         ifelse(month >= as.Date("2021-04-01"), "Recovery", "Lockdown")),
         measure = case_when(
           measure == "par_opioid" ~ "Parenteral",
           measure == "buc_opioid" ~ "Buccal",
           measure == "oral_opioid" ~ "Oral",
           measure == "trans_opioid" ~ "Transdermal",
           measure == "rec_opioid" ~ "Rectal",
           measure == "oth_opioid" ~ "Other",
           measure == "inh_opioid" ~ "Inhaled"
          ),
         rate_opioid_any = (numerator / denominator * 1000)) %>%
  rename(opioid_any = numerator, pop_total = denominator) %>%
  dplyr::select(!c(interval_start, interval_end, ratio)) 

write.csv(type, file = here::here("output", "timeseries", "ts_type.csv"),
          row.names = FALSE)


###########################
# Rounding and redaction  #
###########################

# By admin route
type_round <- read_csv(here::here("output", "timeseries", "ts_type.csv")) %>%
  mutate(opioid_any_round = rounding(opioid_any),
         pop_total_round = rounding(pop_total),
         rate_opioid_any_round = (opioid_any_round / pop_total_round * 1000)) %>%
  dplyr::select(!c(opioid_any, pop_total, rate_opioid_any)) %>%
  subset(!(measure %in% c("Buccal", "Inhaled", "Rectal") ))

write.csv(type_round, here::here("output", "timeseries", "ts_type_rounded.csv"), row.names = FALSE)

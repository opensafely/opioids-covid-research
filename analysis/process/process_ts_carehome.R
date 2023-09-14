######################################################
# This script:
# - imports measures data for prescribing to people
#       in care home
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

# In carehome
carehome <- read_csv(here::here("output", "measures", "measures_carehome.csv")) %>%
  filter(str_detect(measure, "carehome_age", negate = TRUE)) %>%
  mutate(month = as.Date(interval_start, format="%Y-%m-%d"),
         period = ifelse(month < as.Date("2020-03-01"), "Pre-COVID", 
                         ifelse(month >= as.Date("2021-04-01"), "Recovery", "Lockdown"))) %>%
  dplyr::select(!c(interval_start, interval_end, ratio, age_group, carehome)) %>%
  pivot_wider(names_from = measure, values_from = c(numerator, denominator)) %>%
  rename(opioid_any = numerator_opioid_any,
         hi_opioid_any = numerator_hi_opioid_any,
         opioid_new = numerator_opioid_new,
         oral_opioid_any = numerator_oral_opioid,
         trans_opioid_any = numerator_trans_opioid,
         par_opioid_any = numerator_par_opioid,
         
         pop_total = denominator_opioid_any,
         pop_naive = denominator_opioid_new) %>%
  dplyr::select(!c(denominator_hi_opioid_any, denominator_oral_opioid,
                   denominator_trans_opioid, denominator_par_opioid)) %>%
  mutate(pcent_new = opioid_new / opioid_any * 100,
         pcent_hi = hi_opioid_any / opioid_any,
         pcent_par = par_opioid_any / opioid_any,
         pcent_trans = trans_opioid_any / opioid_any,
         
         rate_opioid_any = (opioid_any / pop_total * 1000),
         rate_hi_opioid_any = (hi_opioid_any / pop_total * 1000),
         rate_opioid_new = (opioid_new / pop_total * 1000),
         rate_oral_opioid_any = (oral_opioid_any / pop_total * 1000),
         rate_trans_opioid_any = (trans_opioid_any / pop_total * 1000),
         rate_par_opioid_any = (par_opioid_any / pop_total * 1000))

write.csv(carehome, file = here::here("output", "timeseries", "ts_carehome.csv"),
          row.names = FALSE)


# In/not in carehome - sensitivity analysis 
carehome_sens <- read_csv(here::here("output", "measures", "measures_carehome.csv")) %>%
  filter(str_detect(measure, "_carehome_age", negate = FALSE)) %>%
  mutate(month = as.Date(interval_start, format="%Y-%m-%d"),
         period = ifelse(month < as.Date("2020-03-01"), "Pre-COVID", 
                         ifelse(month >= as.Date("2021-04-01"), "Recovery", "Lockdown")),
         carehome = if_else(carehome == T, "Yes", "No", "No"),
         measure = substr(measure, 1, 10),
         rate_opioid_any = (numerator / denominator * 1000)) %>%
  rename(opioid_any = numerator, pop_total = denominator) %>%
  dplyr::select(!c(interval_start, interval_end, ratio, measure)) 

write.csv(carehome_sens, file = here::here("output", "timeseries", "ts_carehome_sens.csv"),
          row.names = FALSE)


###########################
# Rounding and redaction  #
###########################

# In care home
carehome_round <- read_csv(here::here("output", "timeseries", "ts_carehome.csv")) %>%
  mutate(opioid_any_round = rounding(opioid_any),
         hi_opioid_any_round = rounding(hi_opioid_any),
         opioid_new_round = rounding(opioid_new),
         trans_opioid_any_round = rounding(trans_opioid_any),
         par_opioid_any_round = rounding(par_opioid_any),
         oral_opioid_any_round = rounding(oral_opioid_any),
         
         pop_total_round = rounding(pop_total),
         pop_naive_round = rounding(pop_naive),
         
         rate_opioid_any_round = (opioid_any_round / pop_total_round * 1000),
         rate_hi_opioid_any_round = (hi_opioid_any_round / pop_total_round * 1000),
         rate_opioid_new_round = (opioid_new_round / pop_naive_round * 1000),
         rate_trans_opioid_any_round = (trans_opioid_any_round / pop_total_round * 1000),
         rate_par_opioid_any_round = (par_opioid_any_round / pop_total_round * 1000),
         rate_oral_opioid_any_round = (oral_opioid_any_round / pop_total_round * 1000)) %>%
  dplyr::select(!c(opioid_any, opioid_new, hi_opioid_any, trans_opioid_any,
                   par_opioid_any, oral_opioid_any, pop_naive, pop_total))

write.csv(carehome_round, here::here("output", "timeseries", "ts_carehome_rounded.csv"))

# By care home (sensitivity analysis)
carehome_sens_round <- read_csv(here::here("output", "timeseries", "ts_carehome_sens.csv")) %>%
  mutate(opioid_any_round = rounding(opioid_any),
         pop_total_round = rounding(pop_total),
         rate_opioid_any_round = (opioid_any_round / pop_total_round * 1000)) %>%
  dplyr::select(!c(opioid_any, pop_total))

write.csv(carehome_sens_round, here::here("output", "timeseries", "ts_carehome_sens_rounded.csv"))

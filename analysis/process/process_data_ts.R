######################################################
# This script:
# - imports data extracted by the cohort extractor
# - combines all datasets into one
# - formats variables as appropriate
# - saves processed dataset(s)
#
# Updated: 19 Jul 2023
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

# Create directory
dir_create(here::here("output", "processed"), showWarnings = FALSE, recurse = TRUE)
dir_create(here::here("output", "data"), showWarnings = FALSE, recurse = TRUE)

# Custom functions
source(here("analysis", "lib", "custom_functions.R"))



###############################
# Clean up measures datasets
###############################

# Overall counts 
overall <- read_csv(here::here("output", "measures_overall.csv")) %>%
  mutate(month = as.Date(interval_start, format="%Y-%m-%d")) %>%
  dplyr::select(!c(interval_start, interval_end, ratio)) 

# Overall counts - without cancer
overall_noca <- read_csv(here::here("output", "measures_overall_nocancer.csv")) %>%
  mutate(month = as.Date(interval_start, format="%Y-%m-%d")) %>%
  dplyr::select(!c(interval_start, interval_end, ratio)) 

# By demographics
demo <- read_csv(here::here("output", "measures_demo.csv")) %>%
  mutate(month = as.Date(interval_start, format="%Y-%m-%d"),
         carehome = if_else(carehome == TRUE, "Yes", "No", ""),
         cat = coalesce(age_group, sex, region, imd, ethnicity6, carehome),
         var = gsub("opioid_any_", "", measure),
         var = gsub("opioid_new_", "", var),
         measure = substr(measure,1,10)) %>%
  dplyr::select(c(measure, month, cat, var, numerator, denominator))

# By demographics - without cancer
demo_noca <- read_csv(here::here("output", "measures_demo_nocancer.csv")) %>%
  mutate(month = as.Date(interval_start, format="%Y-%m-%d"),
         carehome = if_else(carehome == TRUE, "Yes", "No", ""),
         cat = coalesce(age_group, sex, region, imd, ethnicity6, carehome),
         var = gsub("opioid_any_", "", measure),
         var = gsub("opioid_new_", "", var),
         measure = substr(measure,1,10)) %>%
  dplyr::select(c(measure, month, cat, var, numerator, denominator))
  
# By admin route
type <- read_csv(here::here("output", "measures_type.csv")) %>%
  mutate(month = as.Date(interval_start, format="%Y-%m-%d"),
         carehome = if_else(carehome == TRUE, "Yes", "No", ""),
         admin = gsub("_opioid", "", measure),
         admin = gsub("_carehome", "", admin)) %>%
  dplyr::select(!c(interval_start, interval_end, ratio, measure)) 

# By admin route - without cancer
type_noca <- read_csv(here::here("output", "measures_type_nocancer.csv")) %>%
  mutate(month = as.Date(interval_start, format="%Y-%m-%d"),
         admin = gsub("_opioid", "", measure)) %>%
  dplyr::select(!c(interval_start, interval_end, ratio, measure)) 

# In/not in carehome - sensitivity analysis 
carehome <- read_csv(here::here("output", "measures_sens.csv")) %>%
  mutate(month = as.Date(interval_start, format="%Y-%m-%d"),
         carehome = if_else(carehome == TRUE, "Yes", "No", "")) %>%
  dplyr::select(!c(interval_start, interval_end, ratio, measure)) 


# Save files
write.csv(overall, file = here::here("output", "processed", "final_ts_overall.csv"))
write.csv(overall_noca, file = here::here("output", "processed", "final_ts_overall_nocancer.csv"))

write.csv(demo, file = here::here("output", "processed", "final_ts_demo.csv"))
write.csv(demo_noca, file = here::here("output", "processed", "final_ts_demo_nocancer.csv"))

write.csv(type, file = here::here("output", "processed", "final_ts_type.csv"))
write.csv(type_noca, file = here::here("output", "processed", "final_ts_type_nocancer.csv"))

write.csv(carehome, file = here::here("output", "processed", "final_ts_carehome_sens.csv"))

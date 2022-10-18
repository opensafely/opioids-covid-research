
######################################################
# This script:
# - Creates four datasets :
#    1. Prevalence of opioid prescribing in full population;
#    2. Prevalence of opioid prescribing in people without cancer;
#    3. Incidence of opioid prescribing in full population;
#    4. Incidence of opioid prescribing in people without cancer.
# - each dataset contains monthly time series of both 
#     any and high dose opioid prescribing, 
#     broken down by various characteristics
#######################################################


# For running locally only #
# setwd("C:/Users/aschaffer/OneDrive - Nexus365/Documents/GitHub/opioids-covid-research")
# getwd()

# Import libraries #
library('tidyverse')
library('lubridate')
library('arrow')
library('here')
library('reshape2')
library('dplyr')
library('fs')
library('ggplot2')
library('RColorBrewer')

## Create directories
dir_create(here::here("output", "time series"), showWarnings = FALSE, recurse = TRUE)

# Read in data
prev_ts <- read_csv(here::here("output", "joined", "final_ts_prev_agesex.csv"),
   col_types = cols(
                      group  = col_character(),
                      label = col_character(),
                      sex = col_character(),
                      date = col_date(format = "%Y-%m-%d"))) %>%
   dplyr::select(c("cancer", "group", "label", "sex", "age_cat", "date", "population", "opioid_any",
                  "hi_opioid_any")) 


###################################
# Prevalence
###################################


## Create dataset for opioid prescribing in 
##  full population (combine cancer/no cancer)
prev_full <- prev_ts %>%
  group_by(date, group, label, age_cat, sex) %>%
  summarise(opioid_any = sum(opioid_any), hi_opioid_any = sum(hi_opioid_any), 
            population = sum(population)) %>%
  mutate(
    
    hi_opioid_any = ifelse(group %in% c("Ethnicity16", "SCD"), NA, hi_opioid_any),

    # Suppression and rounding 
    opioid_any = case_when(opioid_any > 5 ~ opioid_any), 
      opioid_any = round(opioid_any / 7) * 7,
    hi_opioid_any = case_when(hi_opioid_any > 5 ~ hi_opioid_any), 
      hi_opioid_any = round(hi_opioid_any / 7) * 7,
    population = case_when(population > 5 ~ population), 
      population = round(population / 7) * 7,
    
    # calculating rates
    prev_rate = opioid_any / population * 1000, 
    prev_hi_rate = hi_opioid_any / population * 1000
    )   %>%
    rename(any_opioid_prescribing = opioid_any,
               any_high_dose_opioid_prescribing = hi_opioid_any,
               total_population = population,
               prevalence_per_1000 = prev_rate,
               high_dose_prevalence_per_1000 = prev_hi_rate)


## Create dataset for any opioid prescribing in people without cancer only
prev_nocancer <- prev_ts %>%
  subset(cancer == 0) %>%
  mutate(

    # Suppression and rounding 
    opioid_any = case_when(opioid_any > 5 ~ opioid_any), 
     opioid_any = round(opioid_any / 7) * 7,
    hi_opioid_any = case_when(hi_opioid_any > 5 ~ hi_opioid_any), 
     hi_opioid_any = round(hi_opioid_any / 7) * 7,
    population = case_when(population > 5 ~ population), 
     population = round(population / 7) * 7,
    
    # calculating rates
    prev_rate = opioid_any / population * 1000, 
    prev_hi_rate = hi_opioid_any / population * 1000
  ) %>%
  rename(any_opioid_prescribing = opioid_any,
         any_high_dose_opioid_prescribing = hi_opioid_any,
         total_population = population,
         prevalence_per_1000 = prev_rate,
         high_dose_prevalence_per_1000 = prev_hi_rate) 

print(dim(prev_full))
print(dim(prev_nocancer))


###############################
## Sort and save as .csv
###############################

prev_full <- prev_full %>%
  arrange(group, label, sex, date)

write.csv(prev_full, file = here::here("output", "time series", "ts_prev_full_agesex.csv"),
          row.names = FALSE)

prev_nocancer <- prev_nocancer %>%
  arrange(group, label, sex, date) %>%
    subset(!(group %in% c("SCD")))

write.csv(prev_nocancer, file = here::here("output", "time series", "ts_prev_nocancer_agesex.csv"),
          row.names = FALSE)


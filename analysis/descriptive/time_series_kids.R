
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


## Create directories
dir_create(here::here("output", "kids", "time series"), showWarnings = FALSE, recurse = TRUE)
dir_create(here::here("output", "kids", "for release"), showWarnings = FALSE, recurse = TRUE)

# Read in data
prev_ts <- read_csv(here::here("output", "kids", "joined", "final_ts_prev_kids.csv"),
   col_types = cols(
               group  = col_character(),
               label = col_character(),
               date = col_date(format="%Y-%m-%d"))) %>%
  select(c("date", "group", "label", "population", "opioid_any"))


###################################
# Prevalence
###################################

## Create dataset for opioid prescribing in 
##  full population (combine cancer/no cancer)
prev_full <- prev_ts %>%
  group_by(date, group, label) %>%
  summarise(opioid_any = sum(opioid_any), population = sum(population)) %>%
  mutate(
    
    # Suppression and rounding 
    opioid_any = case_when(opioid_any > 5 ~ opioid_any), 
      opioid_any = round(opioid_any / 7) * 7,
    population = case_when(population > 5 ~ population), 
      population = round(population / 7) * 7,
    
    # calculating rates
    prev_rate = opioid_any / population * 1000
    ) 
  
print(dim(prev_full))


###############################
## Sort and save as .csv
###############################

# Remove children and sickle cell disease (due to small numbers) 

prev_full <- prev_full %>%
  arrange(group, label, date)

write.csv(prev_full, file = here::here("output", "kids", "for release", "ts_prev_full_kids.csv"),
          row.names = FALSE)

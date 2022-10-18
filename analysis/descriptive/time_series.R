
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
prev_ts <- read_csv(here::here("output", "joined", "final_ts_prev.csv"),
   col_types = cols(
                      group  = col_character(),
                      label = col_character(),
                      date = col_date(format = "%Y-%m-%d"))) %>%
   select(c("cancer", "group", "label", "date", "population", "opioid_any",
                  "hi_opioid_any")) 

new_ts <- read_csv(here::here("output", "joined", "final_ts_new.csv"),
  col_types = cols(
                      group  = col_character(),
                      label = col_character(),
                      date = col_date(format = "%Y-%m-%d"))) %>%
  select(c("cancer", "group", "label", "date", "opioid_naive",
                 "opioid_new" )) 
  

###################################
# Prevalence
###################################


## Create dataset for opioid prescribing in 
##  full population (combine cancer/no cancer)
prev_full <- prev_ts %>%
  group_by(date, group, label) %>%
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
  ) %>%
  rename(any_opioid_prescribing = opioid_any,
         any_high_dose_opioid_prescribing = hi_opioid_any,
         total_population = population,
         prevalence_per_1000 = prev_rate,
         high_dose_prevalence_per_1000 = prev_hi_rate) 

print(dim(prev_full))
print(dim(prev_nocancer))


###################################
# Incidence
###################################

## Create dataset for new opioid prescribing in
##  full population (combine cancer/no cancer)
new_full <- new_ts %>%
  group_by(date, group, label) %>%
  summarise(
    opioid_new = sum(opioid_new),
    opioid_naive = sum(opioid_naive)
    ) %>%
  mutate(

    # Suppression and rounding
    opioid_new = case_when(opioid_new > 5 ~ opioid_new),
      opioid_new = round(opioid_new / 7) * 7,
    opioid_naive = case_when(opioid_naive > 5 ~ opioid_naive),
      opioid_naive = round(opioid_naive / 7) * 7,
    
    # calculating rates
    new_rate = opioid_new / opioid_naive * 1000
  ) %>%
  rename(new_opioid_prescribing = opioid_new, 
       incidence_per_1000 = new_rate)

## Create dataset for new opioid prescribing in people without cancer only
new_nocancer <- new_ts %>%
  subset(cancer == 0) %>%
  mutate(
    
    # Suppression and rounding
    opioid_new = case_when(opioid_new > 5 ~ opioid_new),
      opioid_new = round(opioid_new / 7) * 7,
    opioid_naive = case_when(opioid_naive > 5 ~ opioid_naive),
      opioid_naive = round(opioid_naive / 7) * 7,
    
    # calculating rates
    new_rate = opioid_new / opioid_naive * 1000
  ) %>%
  rename(new_opioid_prescribing = opioid_new, 
         incidence_per_1000 = new_rate) %>%
  select(!c(cancer))

print(dim(new_full))
print(dim(new_nocancer))


###############################
## Sort and save as .csv
###############################

prev_full <- prev_full %>%
  arrange(group, label, date)

write.csv(prev_full, file = here::here("output", "time series", "ts_prev_full.csv"),
          row.names = FALSE)

prev_nocancer <- prev_nocancer %>%
  arrange(group, label, date) %>%
    subset(!(group %in% c("SCD")))

write.csv(prev_nocancer, file = here::here("output", "time series", "ts_prev_nocancer.csv"),
          row.names = FALSE)

new_full <- new_full %>%
  arrange(group, label, date) %>%
  subset(!(group %in% c("Ethnicity16", "SCD")))

write.csv(new_full, file = here::here("output", "time series", "ts_new_full.csv"),
          row.names = FALSE)

new_nocancer <- new_nocancer %>%
  arrange(group, label, date) %>%
  subset(!(group %in% c("Ethnicity16", "SCD")))

write.csv(new_nocancer, file = here::here("output", "time series", "ts_new_nocancer.csv"),
          row.names = FALSE)



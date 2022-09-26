
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
dir_create(here::here("output", "joined"), showWarnings = FALSE, recurse = TRUE)

# Read in data
prev_ts <- read_csv(here::here("output", "joined", "final_timeseries_prev.csv"),
   col_types = cols(
                      region  = col_character(),
                      imdq10 = col_character(),
                      ethnicity  = col_character(),
                      carehome  = col_character(),
                      scd  = col_character(),
                      age_cat  = col_character(),
                      sex = col_character(),
                      date = col_date(format="%Y-%m-%d")))
  
new_ts <- read_csv(here::here("output", "joined", "final_timeseries_new.csv"),
  col_types = cols(
                      region  = col_character(),
                      imdq10= col_character(),
                      ethnicity  = col_character(),
                      carehome  = col_character(),
                      scd  = col_character(),
                      age_cat  = col_character(),
                      sex = col_character(),
                      date = col_date(format="%Y-%m-%d")))
  

###################################
# Prevalence
###################################

## Create dataset for opioid prescribing in 
##  full population (combine cancer/no cancer)
prev_full <- prev_ts %>%
  group_by(date, region, imdq10, ethnicity, carehome, scd, age_cat, sex) %>%
  summarise(opioid_any = sum(opioid_any), hi_opioid_any = sum(hi_opioid_any), 
            population = sum(population)) %>%
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
    ) 
  
## Create dataset for any opioid prescribing in people without cancer only
prev_nocancer <- prev_ts %>%
  subset(cancer == 0) %>%
  select(c(date, region, imdq10, ethnicity, carehome, scd, age_cat, sex,
           opioid_any, hi_opioid_any, population)) %>%
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
  ) 

print(dim(prev_full))
print(dim(prev_nocancer))


###################################
# Incidence
###################################

## Create dataset for new opioid prescribing in
##  full population (combine cancer/no cancer)
new_full <- new_ts %>%
  group_by(date, region, imdq10, ethnicity, carehome, scd, age_cat, sex) %>%
  summarise(
    opioid_new = sum(opioid_new),
    hi_opioid_new = sum(hi_opioid_new),
    opioid_naive = sum(opioid_naive),
    hi_opioid_naive = sum(hi_opioid_naive)
    ) %>%
  mutate(
    
    # Suppression and rounding
    opioid_new = case_when(opioid_new > 5 ~ opioid_new),
      opioid_new = round(opioid_new / 7) * 7,
    hi_opioid_new = case_when(hi_opioid_new > 5 ~ hi_opioid_new),
     hi_opioid_new = round(hi_opioid_new / 7) * 7,
    opioid_naive = case_when(opioid_naive > 5 ~ opioid_naive),
      opioid_naive = round(opioid_naive / 7) * 7,
    hi_opioid_naive = case_when(hi_opioid_naive > 5 ~ hi_opioid_naive),
      hi_opioid_naive = round(hi_opioid_naive / 7) * 7,
    
    # calculating rates
    new_rate = opioid_new / opioid_naive * 1000,
    new_hi_rate = hi_opioid_new  / hi_opioid_naive * 1000
  ) 

## Create dataset for new opioid prescribing in people without cancer only
new_nocancer <- new_ts %>%
  subset(cancer == 0) %>%
  select(c(date, region, imdq10, ethnicity, carehome, scd, age_cat, sex,
           opioid_new, hi_opioid_new, opioid_naive, hi_opioid_naive)) %>%
  mutate(
    
    # Suppression and rounding
    opioid_new = case_when(opioid_new > 5 ~ opioid_new),
      opioid_new = round(opioid_new / 7) * 7,
    hi_opioid_new = case_when(hi_opioid_new > 5 ~ hi_opioid_new),
      hi_opioid_new = round(hi_opioid_new / 7) * 7,
    opioid_naive = case_when(opioid_naive > 5 ~ opioid_naive),
      opioid_naive = round(opioid_naive / 7) * 7,
    hi_opioid_naive = case_when(hi_opioid_naive > 5 ~ hi_opioid_naive),
      hi_opioid_naive = round(hi_opioid_naive / 7) * 7,
    
    # calculating rates
    new_rate = opioid_new / opioid_naive * 1000,
    new_hi_rate = hi_opioid_new  / hi_opioid_naive * 1000
  ) 

print(dim(new_full))
print(dim(new_nocancer))


###############################
## Sort and save as .csv
###############################

# Remove children and sickle cell disease (due to small numbers) 

prev_full <- prev_full %>%
  subset(!(scd %in% c("No","Yes"))) %>%
  arrange(age_cat, sex, region, imdq10, ethnicity, carehome, date)

write.csv(prev_full, file = here::here("output", "time series", "timeseries_prev_full.csv"))

prev_nocancer <- prev_nocancer %>%
  subset(!(scd %in% c("No","Yes"))) %>%
  arrange(age_cat, sex, region, imdq10, ethnicity, carehome, date)

write.csv(prev_nocancer, file = here::here("output", "time series", "timeseries_prev_nocancer.csv"))

new_full <- new_full %>%
  subset(!(scd %in% c("No","Yes"))) %>%
  arrange(age_cat, sex, region, imdq10, ethnicity, carehome, date)

write.csv(new_full, file = here::here("output", "time series", "timeseries_new_full.csv"))

new_nocancer <- new_nocancer %>%
  subset(!(scd %in% c("No","Yes"))) %>%
  arrange(age_cat, sex, region, imdq10, ethnicity, carehome, date)

write.csv(new_nocancer, file = here::here("output", "time series", "timeseries_new_nocancer.csv"))



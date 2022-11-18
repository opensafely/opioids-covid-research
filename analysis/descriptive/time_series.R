
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
   dplyr::select(c("cancer", "group", "label", "date", "population", "opioid_any",
                  "hi_opioid_any", "long_opioid_any", "oral_opioid_any",
                  "trans_opioid_any", "par_opioid_any", "buc_opioid_any")) 

new_ts <- read_csv(here::here("output", "joined", "final_ts_new.csv"),
  col_types = cols(
                      group  = col_character(),
                      label = col_character(),
                      date = col_date(format = "%Y-%m-%d"))) %>%
  dplyr::select(c("cancer", "group", "label", "date", "opioid_naive",
                 "opioid_new" )) 
  

###################################
# Prevalence
###################################

redact <- function(vars) {
 case_when(vars >5 ~ vars )
}
rounding <- function(vars) {
  round(vars/7)*7
}

## Create dataset for opioid prescribing in 
##  full population (combine cancer/no cancer)
prev_full <- prev_ts %>%
  group_by(date, group, label) %>%
  summarise(opioid_any = sum(opioid_any), 
            hi_opioid_any = sum(hi_opioid_any), 
            long_opioid_any = sum(long_opioid_any),
            oral_opioid_any = sum(oral_opioid_any),
            trans_opioid_any = sum(trans_opioid_any),
            par_opioid_any = sum(par_opioid_any),
            buc_opioid_any = sum(buc_opioid_any),
            population = sum(population)) %>%
    # Suppression and rounding 
  mutate_at(c(vars(c("population", contains("opioid")))), redact) %>%
  mutate_at(c(vars(c("population", contains("opioid")))), rounding) %>%
  mutate(
    # calculating rates
    prev_rate = opioid_any / population * 1000, 
    prev_hi_rate = hi_opioid_any / population * 1000,
    prev_long_rate = long_opioid_any / population * 1000,
    prev_oral_rate = oral_opioid_any / population * 1000,
    prev_trans_rate = trans_opioid_any / population * 1000,
    prev_par_rate = par_opioid_any / population * 1000,
    prev_buc_rate = buc_opioid_any / population * 1000,

  )   %>%
    rename(any_opioid = opioid_any,
               high_dose_opioid = hi_opioid_any,
               long_act_opioid = long_opioid_any,
               oral_opioid = oral_opioid_any,
               transdermal_opioid = trans_opioid_any,
               parenteral_opioid = par_opioid_any,
              buccal_opioid = buc_opioid_any,
               total_population = population,
               prevalence_per_1000 = prev_rate,
               high_dose_prevalence_per_1000 = prev_hi_rate,
               long_act_prevalence_per_1000 = prev_long_rate,
               oral_prevalence_per_1000 = prev_oral_rate,
               parenteral_prevalence_per_1000 = prev_par_rate,
               transdermal_prevalence_per_1000 = prev_trans_rate, 
               buccal_prevalence_per_1000 = prev_buc_rate)


## Create dataset for any opioid prescribing in people without cancer only
prev_nocancer <- prev_ts %>%
  subset(cancer == 0) %>%
  # Suppression and rounding 
  mutate_at(c(vars(c("population", contains("opioid")))), redact) %>%
  mutate_at(c(vars(c("population", contains("opioid")))), rounding) %>%
  mutate(
    # calculating rates
    prev_rate = opioid_any / population * 1000, 
    prev_hi_rate = hi_opioid_any / population * 1000,
    prev_long_rate = long_opioid_any / population * 1000,
    prev_oral_rate = oral_opioid_any / population * 1000,
    prev_trans_rate = trans_opioid_any / population * 1000,
    prev_par_rate = par_opioid_any / population * 1000,
    prev_buc_rate = buc_opioid_any / population * 1000
    
  )   %>%
  rename(any_opioid = opioid_any,
         high_dose_opioid = hi_opioid_any,
         long_act_opioid = long_opioid_any,
         oral_opioid = oral_opioid_any,
         transdermal_opioid = trans_opioid_any,
         parenteral_opioid = par_opioid_any,
         buccal_opioid = buc_opioid_any,
         total_population = population,
         prevalence_per_1000 = prev_rate,
         high_dose_prevalence_per_1000 = prev_hi_rate,
         long_act_prevalence_per_1000 = prev_long_rate,
         oral_prevalence_per_1000 = prev_oral_rate,
         parenteral_prevalence_per_1000 = prev_par_rate,
         transdermal_prevalence_per_1000 = prev_trans_rate,
         buccal_prevalence_per_1000 = prev_buc_rate)

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
  # Suppression and rounding 
  mutate_at(c(vars(contains("opioid"))), redact) %>%
  mutate_at(c(vars(contains("opioid"))), rounding) %>%
  mutate(
    # calculating rates
    new_rate = opioid_new / opioid_naive * 1000
  ) %>%
  rename(new_opioid_prescribing = opioid_new, 
       incidence_per_1000 = new_rate)

## Create dataset for new opioid prescribing in people without cancer only
new_nocancer <- new_ts %>%
  subset(cancer == 0) %>%
  # Suppression and rounding 
  mutate_at(c(vars(contains("opioid"))), redact) %>%
  mutate_at(c(vars(contains("opioid"))), rounding) %>%
  mutate(
    # calculating rates
    new_rate = opioid_new / opioid_naive * 1000
  ) %>%
  rename(new_opioid = opioid_new, 
         incidence_per_1000 = new_rate) %>%
  dplyr::select(!c(cancer))

print(dim(new_full))
print(dim(new_nocancer))

#################################################
# Sensitivity analysis - age not in care home
#################################################

# Read in data
agecare_ts <- read_csv(here::here("output", "joined", "final_ts_agecare.csv"),
                       col_types = cols(
                         age_cat = col_character(),
                         carehome = col_character(),
                         date = col_date(format = "%Y-%m-%d"))) %>%
  dplyr::select(c("age_cat", "carehome", "date", "opioid_naive", "population",
                  "opioid_new", "opioid_any" )) 


## Create dataset for opioid prescribing by care home
agecare <- agecare_ts %>%
  group_by(date, age_cat, carehome) %>%
  # Suppression and rounding 
  mutate_at(c(vars(c("population", contains("opioid")))), redact) %>%
  mutate_at(c(vars(c("population", contains("opioid")))), rounding) %>%
  mutate(
    # calculating rates
    prev_rate = opioid_any / population * 1000, 
    new_rate = opioid_new / opioid_naive * 1000
    )   %>%
    rename(any_opioid = opioid_any,
               new_opioid = opioid_new,
               total_population = population,
               prevalence_per_1000 = prev_rate,
               incidence_per_1000 = new_rate)


###############################
## Sort and save as .csv
###############################

prev_full <- prev_full %>%
  arrange(group, label, date)

write.csv(prev_full, file = here::here("output", "time series", "ts_prev_full.csv"),
          row.names = FALSE)

prev_nocancer <- prev_nocancer %>%
  arrange(group, label, date) 

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

agecare <- agecare %>%
  arrange(age_cat, carehome, date) 

write.csv(agecare, file = here::here("output", "time series", "ts_agecare.csv"),
          row.names = FALSE)
  

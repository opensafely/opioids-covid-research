
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
                      age_stand = col_character(),
                      sex = col_character(),
                      date = col_date(format = "%Y-%m-%d"))
   ) %>%
   dplyr::select(c("cancer", "group", "label", "date", "age_stand", "sex",
                  "population", "opioid_any",
                  "hi_opioid_any", "long_opioid_any", "oral_opioid_any",
                  "trans_opioid_any", "par_opioid_any", "buc_opioid_any")) 

new_ts <- read_csv(here::here("output", "joined", "final_ts_new.csv"),
  col_types = cols(
                      group  = col_character(),
                      label = col_character(),
                      age_stand = col_character(),
                      sex = col_character(),
                      date = col_date(format = "%Y-%m-%d"))
  ) %>%
  dplyr::select(c("cancer", "group", "label", "date", "age_stand", "sex",
                  "opioid_naive", "opioid_new" )) 
  
ons_pop_stand <- read_csv(here::here("ONS-data", "ons_pop_stand.csv"))

###################################
# Prevalence
###################################

redact <- function(vars) {
  case_when(vars > 5 ~ vars)
}
rounding <- function(vars) {
  round(vars / 7) * 7
}

# Prepare for standarisation
prev_ts <- prev_ts %>% 
  mutate(age_stand = ifelse(is.na(age_stand) & group == "Age", "Total", age_stand),
         sex = ifelse(is.na(sex) & group == "Sex", "Total", sex))

# Combine with UK population
combined <- left_join(prev_ts,
            ons_pop_stand,
            by = c("age_stand", "sex"))

# FUll population - aggregate over cancer/no cancer 
prev_full <- combined %>%
  group_by(date, label, age_stand, sex, group, uk_pop) %>%
  summarise_at(c(vars(c("population", contains("opioid")))), sum) 

# Summarise by categories, and perform standardisation
prev_stand <- prev_full %>%
  mutate(opioid_std = opioid_any / population * uk_pop, #expected values in standard pop
         hi_opioid_std = (hi_opioid_any / population) * uk_pop,
         long_opioid_std = (long_opioid_any / population) * uk_pop, 
         oral_opioid_std = (oral_opioid_any / population) * uk_pop, 
         trans_opioid_std = (trans_opioid_any / population) * uk_pop, 
         par_opioid_std = (par_opioid_any / population) * uk_pop, 
         buc_opioid_std = (buc_opioid_any / population) * uk_pop) %>%
  group_by(group, label, date) %>%
  summarise_at(c(vars(c("uk_pop", "population", contains("opioid")))), sum) %>%
  # Suppression and rounding 
  mutate_at(c(vars(c("population", contains("opioid")))), redact) %>%
  mutate_at(c(vars(c("population", contains("opioid")))), rounding) %>%
  mutate(
    #crude rate (using redacted/rounded values)
    opioid_per_1000 = opioid_any / population * 1000,
    hi_opioid_per_1000 = hi_opioid_any / population * 1000,
    long_opioid_per_1000 = long_opioid_any / population * 1000,
    par_opioid_per_1000 = par_opioid_any / population * 1000,
    trans_opioid_per_1000 = trans_opioid_any / population * 1000,
    buc_opioid_per_1000 = buc_opioid_any / population * 1000,
    oral_opioid_per_1000 = oral_opioid_any / population * 1000,
    
    #standardised rate if same age/sex distribution as standard pop
    opioid_per_1000_std = opioid_std / uk_pop * 1000,
    hi_opioid_per_1000_std = hi_opioid_std / uk_pop * 1000,
    long_opioid_per_1000_std = long_opioid_std / uk_pop * 1000,
    par_opioid_per_1000_std = par_opioid_std / uk_pop * 1000,
    trans_opioid_per_1000_std = trans_opioid_std / uk_pop * 1000,
    buc_opioid_per_1000_std = buc_opioid_std / uk_pop * 1000,
    oral_per_1000_std = oral_opioid_std / uk_pop * 1000 
  ) %>%
  select(!c(uk_pop, contains("opioid_std"))) %>%
  # Rename for export
  rename(any_opioid = opioid_any,
               highdose_opioid = hi_opioid_any,
               longacting_opioid = long_opioid_any,
               oral_opioid = oral_opioid_any,
               transdermal_opioid = trans_opioid_any,
               parenteral_opioid = par_opioid_any,
               buccal_opioid = buc_opioid_any,
               total_population = population)


## Create dataset for any opioid prescribing in people without cancer only
prev_nocancer <- combined %>%
  subset(cancer == 0) %>%
  select(!cancer)

# Summarise by categories, and perform standardisation
prev_nocancer_stand <- prev_nocancer %>%
  mutate(opioid_std = opioid_any / population * uk_pop, #expected values in standard pop
         hi_opioid_std = (hi_opioid_any / population) * uk_pop,
         long_opioid_std = (long_opioid_any / population) * uk_pop, 
         oral_opioid_std = (oral_opioid_any / population) * uk_pop, 
         trans_opioid_std = (trans_opioid_any / population) * uk_pop, 
         par_opioid_std = (par_opioid_any / population) * uk_pop, 
         buc_opioid_std = (buc_opioid_any / population) * uk_pop) %>%
  group_by(group, label, date) %>%
  summarise_at(c(vars(c("uk_pop", "population", contains("opioid")))), sum) %>%
  # Suppression and rounding 
  mutate_at(c(vars(c("population", contains("opioid")))), redact) %>%
  mutate_at(c(vars(c("population", contains("opioid")))), rounding) %>%
  mutate(
    #crude rate (using redacted/rounded values)
    opioid_per_1000 = opioid_any / population * 1000,
    hi_opioid_per_1000 = hi_opioid_any / population * 1000,
    long_opioid_per_1000 = long_opioid_any / population * 1000,
    par_opioid_per_1000 = par_opioid_any / population * 1000,
    trans_opioid_per_1000 = trans_opioid_any / population * 1000,
    buc_opioid_per_1000 = buc_opioid_any / population * 1000,
    oral_opioid_per_1000 = oral_opioid_any / population * 1000,
    
    #standardised rate if same age/sex distribution as standard pop
    opioid_per_1000_std = opioid_std / uk_pop * 1000,
    hi_opioid_per_1000_std = hi_opioid_std / uk_pop * 1000,
    long_opioid_per_1000_std = long_opioid_std / uk_pop * 1000,
    par_opioid_per_1000_std = par_opioid_std / uk_pop * 1000,
    trans_opioid_per_1000_std = trans_opioid_std / uk_pop * 1000,
    buc_opioid_per_1000_std = buc_opioid_std / uk_pop * 1000,
    oral_per_1000_std = oral_opioid_std / uk_pop * 1000 
  ) %>%
  select(!c(uk_pop, contains("opioid_std"))) %>%
  # Rename for export
  rename(any_opioid = opioid_any,
         highdose_opioid = hi_opioid_any,
         longacting_opioid = long_opioid_any,
         oral_opioid = oral_opioid_any,
         transdermal_opioid = trans_opioid_any,
         parenteral_opioid = par_opioid_any,
         buccal_opioid = buc_opioid_any,
         total_population = population)



print(dim(prev_stand))
print(dim(prev_nocancer_stand))

###### Save
prev_stand <- prev_stand %>%
  arrange(group, label, date)

write.csv(prev_stand, file = here::here("output", "time series", "ts_prev_full.csv"),
          row.names = FALSE)

prev_nocancer_stand <- prev_nocancer_stand %>%
  arrange(group, label, date) 

write.csv(prev_nocancer_stand, file = here::here("output", "time series", "ts_prev_nocancer.csv"),
          row.names = FALSE)


###################################
# Incidence
###################################

## Create dataset for new opioid prescribing in
##  full population (combine cancer/no cancer)


# Prepare for standarisation
new_ts <- new_ts %>% 
  mutate(age_stand = ifelse(is.na(age_stand) & group == "Age", "Total", age_stand),
         sex = ifelse(is.na(sex) & group == "Sex", "Total", sex))


# Combine with UK population
combined <- left_join(new_ts, ons_pop_stand, by = c("age_stand", "sex"))
  

# FUll population - aggregate over cancer/no cancer 
new_full <- combined %>%
  group_by(date, label, age_stand, sex, group, uk_pop) %>%
  summarise_at(c(vars(c(contains("opioid")))), sum) 

# Summarise by categories, and perform standardisation
new_stand <- new_full %>%
  mutate(
    new_opioid_std = opioid_new / opioid_naive * uk_pop #expected values in standard pop
         ) %>%
  group_by(group, label, date) %>%
  summarise(uk_pop = sum(uk_pop), 
            opioid_naive = sum(opioid_naive),
            new_opioid = sum(opioid_new),
            new_opioid_std = sum(new_opioid_std)) %>%
  # Suppression and rounding 
  mutate_at(c(vars(c(contains("opioid")))), redact) %>%
  mutate_at(c(vars(c(contains("opioid")))), rounding) %>%
  mutate(
    #crude rate (using redacted/rounded values)
    new_opioid_per_1000 = new_opioid / opioid_naive * 1000,
   
    #standardised rate if same age/sex distribution as standard pop
    new_opioid_per_1000_std = new_opioid_std / uk_pop * 1000
  ) %>%
  select(!c(uk_pop, contains("opioid_std"))) 
 

  
# Summarise by categories, and perform standardisation
new_nocancer <- combined %>%
  subset(cancer == 0) %>%
  select(!cancer)

new_nocancer_stand <- new_nocancer %>%
  mutate(
    new_opioid_std = opioid_new / opioid_naive * uk_pop #expected values in standard pop
  ) %>%
  group_by(group, label, date) %>%
  summarise(uk_pop = sum(uk_pop), 
            opioid_naive = sum(opioid_naive),
            new_opioid = sum(opioid_new),
            new_opioid_std = sum((opioid_new / opioid_naive) * uk_pop)) %>%
  # Suppression and rounding 
  mutate_at(c(vars(c(contains("opioid")))), redact) %>%
  mutate_at(c(vars(c(contains("opioid")))), rounding) %>%
  mutate(
    #crude rate (using redacted/rounded values)
    new_opioid_per_1000 = new_opioid / opioid_naive * 1000,
    
    #standardised rate if same age/sex distribution as standard pop
    new_opioid_per_1000_std = new_opioid_std / uk_pop * 1000
  ) %>%
  select(!c(uk_pop, contains("opioid_std"))) 
  
print(dim(new_stand))
print(dim(new_nocancer_stand))


###### Save
new_stand <- new_stand %>%
  arrange(group, label, date)

write.csv(new_stand, file = here::here("output", "time series", "ts_new_full.csv"),
          row.names = FALSE)

new_nocancer_stand <- new_nocancer_stand %>%
  arrange(group, label, date) 

write.csv(new_nocancer_stand, file = here::here("output", "time series", "ts_new_nocancer.csv"),
          row.names = FALSE)



#################################################
# Sensitivity analysis - age not in care home 
# Note - not standardised
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

agecare <- agecare %>%
  arrange(age_cat, carehome, date) 

write.csv(agecare, file = here::here("output", "time series", "ts_agecare.csv"),
          row.names = FALSE)
  

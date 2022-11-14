######################################################
# This script:
# - imports data extracted by the cohort extractor
# - combines all datasets into one
# - formats variables as appropriate
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

# Create directory
dir_create(here::here("output", "kids", "joined"), showWarnings = FALSE, recure = TRUE)
dir_create(here::here("output", "kids", "data"), showWarnings = FALSE, recure = TRUE)

# Custom functions
source(here("analysis", "lib", "custom_functions.R"))


###############################
# Prevalence datasets
###############################

# Combine data on any opioid prescribing
prevalence <- bind_rows(
    read_csv(here::here("output", "kids", "data", "measure_opioid_all_any.csv")),
    read_csv(here::here("output", "kids", "data", "measure_opioid_sex_any.csv")),
    read_csv(here::here("output", "kids", "data", "measure_opioid_reg_any.csv")),
    read_csv(here::here("output", "kids", "data", "measure_opioid_imd_any.csv")),
    read_csv(here::here("output", "kids", "data", "measure_opioid_age_any.csv"))
  ) %>%
  mutate(date = as.Date(as.character(date), format = "%Y-%m-%d"),     
    # Sex
    sex = fct_case_when(
     sex == "F" ~ "Female",
      sex == "M" ~ "Male",
      TRUE ~ NA_character_),

    # Age
    age_cat = fct_case_when(
      age_cat == 0 ~ "Missing",
      age_cat == 1 ~ "<13 y",
      age_cat == 2 ~ "13+ y"
      ),
         
    # IMD deciles
    imdq10 = fct_case_when(
      imdq10 == 0 ~ "Missing",
      imdq10 == 1 ~ "1 most deprived",
      imdq10 == 2 ~ "2",
      imdq10 == 3 ~ "3",
      imdq10 == 4 ~ "4",
      imdq10 == 5 ~ "5",
      imdq10 == 6 ~ "6",
      imdq10 == 7 ~ "7",
      imdq10 == 8 ~ "8",
      imdq10 == 9 ~ "9",
      imdq10 == 10 ~ "10 least deprived"
      ),
         
    # Convert to integer to avoid scientific notation in csv
    population = as.integer(population),
    opioid_any = as.integer(opioid_any),
    
    label = coalesce(region, imdq10,sex, age_cat),
    label = ifelse(is.na(label), "Total", label),
    group = ifelse(!is.na(region), "Region",
                   ifelse(!is.na(imdq10), "IMD decile",
                                 ifelse(!is.na(sex), "Sex", 
                                      ifelse(!is.na(age_cat), "Age","Total"))))
                                      ) %>%
  select(!c(region, imdq10, sex, age_cat, value))
  


###############################
## Save as .csv
###############################

write.csv(prevalence, file = here::here("output", "kids", "joined", "final_ts_prev_kids.csv"))

###############################
# Read in data for tables
###############################

## Read in data before COVID and combine
# apr19 <- read_csv(here::here("output", "data", "input_2019-04-01.csv")) 
# may19 <- read_csv(here::here("output", "data", "input_2019-05-01.csv")) %>%
#   filter(!(patient_id %in% apr19$patient_id))
# jun19 <- read_csv(here::here("output", "data", "input_2019-06-01.csv")) %>%
#   filter(!(patient_id %in% c(apr19$patient_id, may19$patient_id)))
# 
# cohort_before <- rbind(apr19, may19, jun19) %>%
#   select(!(c(opioid_any_date, hi_opioid_any_date))) %>%
#   mutate(time = 0)

## Read in data and combine - people prescribed opioids during COVID and combine
jan22 <- read_csv(here::here("output", "kids", "data", "input_kids_2022-01-01.csv")) 
feb22 <- read_csv(here::here("output", "kids", "data", "input_kids_2022-02-01.csv")) %>%
  filter(!patient_id %in% jan22$patient_id)
mar22 <- read_csv(here::here("output", "kids", "data", "input_kids_2022-03-01.csv")) %>%
  filter(!patient_id %in% c(jan22$patient_id, feb22$patient_id))

cohort <- rbind(jan22, feb22, mar22) %>%
  select(!(c(opioid_any_date))) 


# Number check----
print(dim(cohort))
head(cohort)


#################################################
# Create base dataset for producing tables, 
# including formatting variables as appropriate
#################################################

for_tables <- 
  cohort %>%
  mutate(
    
    # Sex
    sex = fct_case_when(
      sex == "F" ~ "Female",
      sex == "M" ~ "Male",
      TRUE ~ NA_character_),
    
    ## Sex
    sex = fct_case_when(
      sex == "F" ~ "Female",
      sex == "M" ~ "Male",
      TRUE ~ NA_character_),
    
    # Age
    age_cat = fct_case_when(
      age_cat == 0 ~ "Missing",
      age_cat == 1 ~ "<13 y",
      age_cat == 2 ~ "14+ y",
      TRUE ~ NA_character_
    ),
    
    # IMD
    imdq10 = fct_case_when(
      imdq10 == 0 ~ "Missing",
      imdq10 == 1 ~ "1 most deprived",
      imdq10 == 2 ~ "2",
      imdq10 == 3 ~ "3",
      imdq10 == 4 ~ "4",
      imdq10 == 5 ~ "5",
      imdq10 == 6 ~ "6",
      imdq10 == 7 ~ "7",
      imdq10 == 8 ~ "8",
      imdq10 == 9 ~ "9",
      imdq10 == 10 ~ "10 least deprived",
      TRUE ~ NA_character_
    )
  )


###############################
## Save as .csv
###############################

write.csv(for_tables, file = here::here("output", "kids", "joined", "final_for_tables_kids.csv"))


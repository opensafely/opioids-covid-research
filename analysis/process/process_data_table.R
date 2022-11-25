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
dir_create(here::here("output", "joined"), showWarnings = FALSE, recurse = TRUE)
dir_create(here::here("output", "data"), showWarnings = FALSE, recurse = TRUE)

# Custom functions
source(here("analysis", "lib", "custom_functions.R"))



###############################
# Read in data for tables
###############################

## Read in data and combine - people prescribed opioids during COVID and combine
apr22 <- read_csv(here::here("output", "data", "input_2022-01-01.csv")) 
may22 <- read_csv(here::here("output", "data", "input_2022-02-01.csv")) %>%
  filter(!patient_id %in% apr22$patient_id)
jun22 <- read_csv(here::here("output", "data", "input_2022-03-01.csv")) %>%
  filter(!patient_id %in% c(apr22$patient_id, may22$patient_id))

cohort <- rbind(apr22, may22, jun22) 


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
    
    # Ethnicity
    ethnicity16 = ifelse(ethnicity16 == "", "Missing", ethnicity16),
    ethnicity6 = ifelse(ethnicity6 == "", "Missing", ethnicity6),
    
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
    ),
    
    # Age
    age_cat = fct_case_when(
      age_cat == 0 ~ "Missing",
      age_cat == 1 ~ "18-29 y",
      age_cat == 2 ~ "30-39 y",
      age_cat == 3 ~ "40-49 y",
      age_cat == 4 ~ "50-59 y",
      age_cat == 5 ~ "60-69 y",
      age_cat == 6 ~ "70-79 y",
      age_cat == 7 ~ "80-89 y",
      age_cat == 8 ~ "90+ y",
      TRUE ~ NA_character_
    ),
    
    # Age for standardisation
    age_stand = fct_case_when(
      age_stand == 0 ~ "Missing",
      age_stand == 1 ~ "18-24 y",
      age_stand == 2 ~ "25-29 y", 
      age_stand == 3 ~ "30-34 y",
      age_stand == 4 ~ "35-39 y",
      age_stand == 5 ~ "40-44 y",
      age_stand == 6 ~ "45-49 y",
      age_stand == 7 ~ "50-54 y",
      age_stand == 8 ~ "55-59 y",
      age_stand == 9 ~ "60-64 y",
      age_stand == 10 ~ "65-69 y",
      age_stand == 11 ~ "70-74 y",
      age_stand == 12 ~ "75-79 y",
      age_stand == 13 ~ "80-84 y",
      age_stand == 14 ~ "85-89 y",
      age_stand == 15 ~ "90+ y",     
      TRUE ~ NA_character_
    ),
    
    #Carehome
    carehome = fct_case_when(
      carehome == 0 ~ "No",
      carehome == 1 ~ "Yes"
    ),
    
    #Cancer
    cancer = fct_case_when(
      cancer == 0 ~ "No",
      cancer == 1 ~ "Yes"
    ),
    
    #Sickle cell
    scd = fct_case_when(
      scd == 0 ~ "No",
      scd == 1 ~ "Yes"
    )
  ) %>%
  dplyr::select(!c(contains("any_date")))


###############################
## Save as .csv
###############################

write.csv(for_tables, file = here::here("output", "joined", "final_for_tables.csv"))




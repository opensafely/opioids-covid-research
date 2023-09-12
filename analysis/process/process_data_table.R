######################################################
# This script:
# - imports data extracted by the cohort extractor
# - combines all datasets into one
# - formats variables as appropriate
# - saves processed dataset(s)
#
# Updated: 18 Jul 2023
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
library(data.table)

# Create directory
dir_create(here::here("output", "processed"), showWarnings = FALSE, recurse = TRUE)
dir_create(here::here("output", "data"), showWarnings = FALSE, recurse = TRUE)

# Custom functions
source(here("analysis", "lib", "custom_functions.R"))


###############################
# Read in data for tables
###############################

## Read in data 
cohort <- read_csv(here::here("output", "data", "dataset_table.csv.gz"))

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
      sex == "female" ~ "Female",
      sex == "male" ~ "Male",
      TRUE ~ NA_character_),
    
    # Ethnicity
    ethnicity16 = ifelse(ethnicity16 == "", "Missing", ethnicity16),
    ethnicity6 = ifelse(ethnicity6 == "", "Missing", ethnicity6),
    
    #Carehome
    carehome = fct_case_when(
      carehome == FALSE ~ "No",
      carehome == TRUE ~ "Yes"
    ),
    
    #Cancer
    cancer = fct_case_when(
      cancer == FALSE ~ "No",
      cancer == TRUE ~ "Yes"
    )
  ) 


###############################
## Save as .csv
###############################

write.csv(for_tables, file = here::here("output", "processed", "final_tables.csv"))

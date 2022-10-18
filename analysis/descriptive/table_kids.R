######################################

# This script:
# - Produces counts of patients prescribed opioids (prevalence and incidence)
#     by demographic characteristics before and during COVID (Apr-Jun 2019 vs 2020)
# - Both overall in full population, and people without a cancer diagnosis
# - saves data summaries (as table)

######################################

## For running locally only
# setwd("C:/Users/aschaffer/OneDrive - Nexus365/Documents/GitHub/opioids-covid-research")
# getwd()

## Import libraries
library('tidyverse')
library('lubridate')
library('reshape2')
library('here')
library('fs')

## Custom functions
source(here("analysis", "lib", "custom_functions.R"))

## Create directories if needed
dir_create(here::here("output", "kids", "tables"), showWarnings = FALSE, recurse = TRUE)
dir_create(here::here("output", "kids", "joined"), showWarnings = FALSE, recurse = TRUE)

## Read in data
for_tables <- read_csv(here::here("output", "kids", "joined", "final_for_tables_kids.csv")) 


##############################################
# SUmmarise data by groups
##############################################

# Function to summarise data over each variable
f <- function(var,name) {
  df <- for_tables %>%
    group_by(!!enquo(var)) %>%
    summarise(
      tot = n(),
      opioid_any = sum(opioid_any))  %>%
    rename(label := {{var}}) %>%
    mutate(group = name)
  return(df)
}

combined <- rbind(
  f(sex, "Sex"),
  f(region, "Region"),
  f(imdq10, "IMD decile"),
  f(ethnicity6, "Ethnicity")
  ) 

########################################################
# Rounding and redaction
########################################################



# Full population
fullpop <- combined %>%
  mutate(
    opioid_any = case_when(opioid_any > 5 ~ opioid_any), 
      opioid_any = round(opioid_any / 7) * 7,
    tot = case_when(tot > 5 ~ tot), 
      tot = round(tot / 7) * 7,
    
    # Calculate rates
    p_prev = opioid_any / tot * 1000
  ) %>%
  rename(any_opioid_prescribing = opioid_any, total_population = tot, 
                 prevalence_per_1000 = p_prev)

head(fullpop)


###################
# Save tables
###################

fullpop <- fullpop %>% arrange(group, label)
write.csv(fullpop, here::here("output", "kids", "tables", "table_full_kids.csv"),
          row.names = FALSE)






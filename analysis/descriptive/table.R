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

## Custom functions
source(here("analysis", "lib", "custom_functions.R"))

## Create directories if needed
dir.create(here::here("output", "tables"), showWarnings = FALSE, recursive = TRUE)
dir.create(here::here("output", "joined"), showWarnings = FALSE, recursive = TRUE)

## Read in data
for_tables <- read_csv(here::here("output", "joined", "final_for_tables.csv"))

##############################################
# SUmmarise data by groups
##############################################

# Function to summarise data over each variable
f <- function(var,name) {
  for_tables %>%
    group_by(!!enquo(var), cancer) %>%
    summarise(
      tot = n(),
      opioid_any = sum(opioid_any),
      hi_opioid_any = sum(hi_opioid_any),
      opioid_new = sum(opioid_new),
      hi_opioid_new = sum(hi_opioid_new),
      opioid_naive = sum(opioid_naive),
      hi_opioid_naive = sum(hi_opioid_naive)
    )  %>%
    rename(label := {{var}}) %>%
    mutate(group = name)
}

combined <- rbind(
  f(age_cat, "Age"),
  f(sex, "Sex"),
  f(ethnicity, "Ethnicity"),
  f(region, "Region"),
  f(imdq10, "IMD decile"),
  f(carehome, "Care home"),
  f(scd, "Sickle cell disease"),
  ) 

########################################################
# Rounding and redaction
########################################################

# People without cancer
bycancer <- combined %>%
  mutate(
    # Rounding and suppression
    opioid_any = case_when(opioid_any > 5 ~ opioid_any), 
      opioid_any = round(opioid_any / 7) * 7,
    hi_opioid_any = case_when(hi_opioid_any > 5 ~ hi_opioid_any), 
      hi_opioid_any = round(hi_opioid_any / 7) * 7,
    tot = case_when(tot > 5 ~ tot), 
      tot = round(tot / 7) * 7,
    opioid_any = case_when(opioid_any > 5 ~ opioid_any), 
      opioid_any = round(opioid_any / 7) * 7,
    hi_opioid_any = case_when(hi_opioid_any > 5 ~ hi_opioid_any), 
      hi_opioid_any = round(hi_opioid_any / 7) * 7,
    tot = case_when(tot > 5 ~ tot), 
      tot = round(tot / 7) * 7,
         
    # Calculate percentages
    p_prev = opioid_any / tot * 100,
    p_prev_hi = hi_opioid_any / tot * 100,
    p_new = opioid_new / opioid_naive * 100,
    p_new_hi = hi_opioid_new / hi_opioid_naive * 100
  )

# Full population
fullpop <- combined %>%
  group_by(group, label) %>%
  summarise(
    tot = sum(tot),
    opioid_any = sum(opioid_any),
    hi_opioid_any = sum(hi_opioid_any),
    opioid_new = sum(opioid_new),
    hi_opioid_new = sum(hi_opioid_new),
    opioid_naive = sum(opioid_naive),
    hi_opioid_naive = sum(hi_opioid_naive)
    ) %>%
  
    mutate(
    # Rounding and suppression
    opioid_any = case_when(opioid_any > 5 ~ opioid_any), 
      opioid_any = round(opioid_any / 7) * 7,
    hi_opioid_any = case_when(hi_opioid_any > 5 ~ hi_opioid_any), 
      hi_opioid_any = round(hi_opioid_any / 7) * 7,
    tot = case_when(tot > 5 ~ tot), 
      tot = round(tot / 7) * 7,
    opioid_any = case_when(opioid_any > 5 ~ opioid_any), 
      opioid_any = round(opioid_any / 7) * 7,
    hi_opioid_any = case_when(hi_opioid_any > 5 ~ hi_opioid_any), 
      hi_opioid_any = round(hi_opioid_any / 7) * 7,
    tot = case_when(tot > 5 ~ tot), 
      tot = round(tot / 7) * 7,
    
    # Calculate percentages
    p_prev = opioid_any / tot * 100,
    p_prev_hi = hi_opioid_any / tot * 100,
    p_new = opioid_new / opioid_naive * 100,
    p_new_hi = hi_opioid_new / hi_opioid_naive * 100
  )

head(bycancer)
head(fullpop)

###################
# Save tables
###################

fullpop <- fullpop %>% arrange(group, label)
write.csv(fullpop, here::here("output", "tables", "table_full_population.csv"))

bycancer <- bycancer %>% arrange(group, label)
write.csv(bycancer, here::here("output", "tables", "table_by_cancer.csv"))




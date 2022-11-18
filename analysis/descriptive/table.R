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
dir_create(here::here("output", "tables"), showWarnings = FALSE, recurse = TRUE)
dir_create(here::here("output", "joined"), showWarnings = FALSE, recurse = TRUE)

## Read in data
for_tables <- read_csv(here::here("output", "joined", "final_for_tables.csv"))

##############################################
# SUmmarise data by groups
##############################################

# Function to summarise data over each variable
f <- function(var,name) {
  df <- for_tables %>%
    group_by(!!enquo(var), cancer) %>%
    summarise(
      tot = n(),
      opioid_any = sum(opioid_any),
      opioid_new = sum(opioid_new),
      opioid_naive = sum(opioid_naive),
    )  %>%
    rename(label := {{var}}) %>%
    mutate(group = name)
  return(df)
}

combined <- rbind(
  f(age_cat, "Age"),
  f(sex, "Sex"),
  f(ethnicity16, "Ethnicity16"),
  f(ethnicity6, "Ethnicity6"),
  f(region, "Region"),
  f(imdq10, "IMD decile"),
  f(carehome, "Care home"),
  f(scd, "Sickle cell disease")
  ) 

########################################################
# Rounding and redaction
########################################################

redact <- function(vars) {
  case_when(vars >5 ~ vars )
}
rounding <- function(vars) {
  round(vars/7)*7
}

# People without cancer - overall prescribing
bycancer <- combined %>%
  # Suppression and rounding 
  mutate_at(c(vars(c("tot", "opioid_any"))), redact) %>%
  mutate_at(c(vars(c("tot", "opioid_any"))), rounding) %>%
  mutate(
   # Calculate rates
    p_prev = opioid_any / tot * 1000,
  ) %>%
  dplyr::select(contains(c("cancer", "label",
          "tot", "group", "p_prev", "opioid_any"))) %>%
  rename(cancer_diagnosis = cancer,
         any_opioid = opioid_any, 
         total_population = tot, 
         prevalence_per_1000 = p_prev)

# Full population - overall prescribing
fullpop <- combined %>%
  group_by(group, label) %>%
  summarise(
    tot = sum(tot),
    opioid_any = sum(opioid_any)) %>%
  mutate_at(c(vars(c("tot", "opioid_any"))), redact) %>%
  mutate_at(c(vars(c("tot", "opioid_any"))), rounding) %>%
  mutate(    
      # Calculate rates
    p_prev = opioid_any / tot * 1000,
  ) %>%
  rename(
       any_opioid = opioid_any, 
       total_population = tot, 
       prevalence_per_1000 = p_prev)

# Full population - breakdown of admin route

admin <- rbind(
  cbind(sum(for_tables$opioid_any), "Any"),
  cbind(sum(for_tables$hi_opioid_any), "High dose"),
  cbind(sum(for_tables$long_opioid_any), "Long acting"),
  cbind(sum(for_tables$oral_opioid_any), "Oral"),
  cbind(sum(for_tables$par_opioid_any), "Parenteral"),
  cbind(sum(for_tables$trans_opioid_any), "Transdermal"),
  cbind(sum(for_tables$buc_opioid_any), "Buccal")
  ) %>%
  as.data.frame() %>%
  rename(no_people = V1, formulation = V2) %>%
  mutate(no_people = as.numeric(no_people),
         tot = as.numeric(count(for_tables))) %>%
       mutate( prevalence_per_1000 = no_people/tot*1000)



###################
# Save tables
###################

fullpop <- fullpop %>% arrange(group, label) 
write.csv(fullpop, here::here("output", "tables", "table_full_population.csv"),
          row.names = FALSE)

bycancer <- bycancer %>% arrange(group, label) 
write.csv(bycancer, here::here("output", "tables", "table_by_cancer.csv"),
          row.names = FALSE)

write.csv(admin, here::here("output", "tables", "table_by_admin_route.csv"),
          row.names = FALSE)





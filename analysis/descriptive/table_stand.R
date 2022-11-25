######################################

# This script:
# - Produces counts of patients prescribed opioids (prevalence and incidence)
#     by demographic characteristics before and during COVID (Apr-Jun 2019 vs 2020)
# - Both overall in full population, and people without a cancer diagnosis
# - Both crude and age/sex standardised
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
ons_pop_stand <- read_csv(here::here("ONS-data", "ons_pop_stand.csv"))


##############################################
# SUmmarise data by groups 
##############################################

# Function to summarise data over each variable
#  and by age (5-year bands) and sex for standardisation
f <- function(var, name) {
  df <- for_tables %>%
    group_by({{var}}, cancer, age_stand, sex) %>%
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

# Need to do age/sex separately
# Age is sex-standardised only
age <- for_tables %>%
  group_by(age_cat, cancer, sex) %>%
  summarise(
    tot = n(),
    opioid_any = sum(opioid_any),
    opioid_new = sum(opioid_new),
    opioid_naive = sum(opioid_naive),
  )  %>%
  rename(label = age_cat) %>%
  mutate(group = "Age", 
         age_stand = as.character("Total")) %>%
  dplyr::select(contains(c("cancer", "label", "age_stand", 
                           "sex", "tot", "group", "opioid_any")))

# Sex is age-standardised only
sex <- for_tables %>%
  group_by(sex, cancer, age_stand) %>%
  summarise(
    tot = n(),
    opioid_any = sum(opioid_any),
    opioid_new = sum(opioid_new),
    opioid_naive = sum(opioid_naive),
  )  %>%
  rename(label = sex) %>%
  mutate(group = "Sex", sex = as.character("Total")) %>%
  dplyr::select(contains(c("cancer", "label", "age_stand", 
                           "sex", "tot", "group", "opioid_any")))

# Combine
combined <- rbind(age, sex,
  f(ethnicity16, "Ethnicity16"),
  f(ethnicity6, "Ethnicity6"),
  f(region, "Region"),
  f(imdq10, "IMD decile"),
  f(carehome, "Care home")  
) %>%
  dplyr::select(contains(c("cancer", "label", "age_stand", 
                           "sex", "tot", "group", "opioid_any")))



##### FUNCTIONS ##################

# Rounding and redaction
redact <- function(vars) {
  case_when(vars >5 ~ vars)
}
rounding <- function(vars) {
  round(vars/7)*7
}

# Function for summarising and standardising data
std <- function(data, ...){
  
  # Combine with standard population
  stand <- rbind(
    left_join(subset(data, age_stand != "Missing"), 
              ons_pop_stand,
              by = c("age_stand", "sex"))
  ) 
  
  # Summarise by categories, and perform standardisation
  stand_final <- stand %>%
    group_by(...) %>%
    summarise(
      opioid_any_std = sum((opioid_any / tot) * uk_pop), #expected values in standard pop
      opioid_any = sum(opioid_any),
      uk_pop = sum(uk_pop), 
      total_population = sum(tot)
    ) %>%
    # Suppression and rounding 
    mutate_at(c(vars(c("total_population", "opioid_any"))), redact) %>%
    mutate_at(c(vars(c("total_population", "opioid_any"))), rounding) %>%
    mutate(#crude rate (using redacted/rounded values)
      opioid_per_1000 = opioid_any / total_population * 1000,
      #standardised rate if same age/sex distribution as standard pop
      opioid_per_1000_std = opioid_any_std / uk_pop * 1000 
    ) %>%
    select(!c(uk_pop, opioid_any_std))
  
  return(stand_final)
}



############################################################
# Summarise data for tables (including standardising rates)
############################################################

### By cancer diagnosis - overall prescribing ###

# Summarise and standardise                 
bycancer_stand <- std(combined, group, label, cancer)

# Save
bycancer_stand <- bycancer_stand %>% arrange(group, label) 
write.csv(bycancer_stand, here::here("output", "tables", "table_by_cancer.csv"),
          row.names = FALSE)


### Full population - overall prescribing     ###

# First combine for people with/without cancer
fullpop <- combined %>%
  group_by(group, label, age_stand, sex) %>%
  summarise(
    tot = sum(tot),
    opioid_any = sum(opioid_any)) %>%
  dplyr::select(c("label", "age_stand", "sex", "tot", "group", "opioid_any")) 

# Summarise and standardise    
fullpop_stand <- std(fullpop, group, label)

# Save
fullpop_stand <- fullpop_stand %>% arrange(group, label) 
write.csv(fullpop_stand, here::here("output", "tables", "table_full_population.csv"),
          row.names = FALSE)



###############################################
# Administration route (not standardised)
#################################################

# Full population - breakdown of admin route
admin <- rbind(
    # Count number of people with each formulation type
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
         tot = as.numeric(count(for_tables)) #Total sample size
         ) %>%
  mutate_at(c(vars(c("no_people", "tot"))), redact) %>%
  mutate_at(c(vars(c("tot", "no_people"))), rounding) %>%
  mutate(prevalence_per_1000 = no_people / tot*1000,
         group = "Full population") 


# in care home - breakdown of admin route
admin.care <- rbind(
  # Count number of people with each formulation type
    cbind(sum(subset(for_tables, carehome == "Yes")$opioid_any), "Any"),
    cbind(sum(subset(for_tables, carehome == "Yes")$hi_opioid_any), "High dose"),
    cbind(sum(subset(for_tables, carehome == "Yes")$long_opioid_any), "Long acting"),
    cbind(sum(subset(for_tables, carehome == "Yes")$oral_opioid_any), "Oral"),
    cbind(sum(subset(for_tables, carehome == "Yes")$par_opioid_any), "Parenteral"),
    cbind(sum(subset(for_tables, carehome == "Yes")$trans_opioid_any), "Transdermal"),
    cbind(sum(subset(for_tables, carehome == "Yes")$buc_opioid_any), "Buccal")
  ) %>%
  as.data.frame() %>%
  rename(no_people = V1, formulation = V2) %>%
  mutate(no_people = as.numeric(no_people),
         tot = as.numeric(count(subset(for_tables, carehome == "Yes"))) # Total sample size
         ) %>%
  mutate_at(c(vars(c("no_people", "tot"))), redact) %>%
  mutate_at(c(vars(c("tot", "no_people"))), rounding) %>%
  mutate(prevalence_per_1000 = no_people / tot*1000,
         group = "Care home")

admin.both <- rbind(admin, admin.care)

# Save
write.csv(admin.both, here::here("output", "tables", "table_by_admin_route.csv"),
          row.names = FALSE)

####################################################################################################
# This script:
# - Produces counts of patients prescribed opioids by demographic characteristics (Apr-Jun 2022)
# - Both overall in full population, and people without a cancer diagnosis
# - Both crude and age/sex standardised
####################################################################################################

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
dir_create(here::here("output", "processed"), showWarnings = FALSE, recurse = TRUE)

## Read in data 
cohort <- read_csv(here::here("output", "data", "dataset_table.csv.gz"))
ons_pop_stand <- read_csv(here::here("ONS-data", "ons_pop_stand.csv"))

# Number check----
print(dim(cohort))
head(cohort)


#################################################
# Format variables as appropriate
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
    
    # Region
    region = ifelse(region == "", "Missing", region),
    region = ifelse(region == "", "Missing", region),
    
    # IMD decile
    imd10 = ifelse(imd10 == "", "Missing", imd10),
    imd10 = ifelse(imd10 == "", "Missing", imd10),
    
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


##############################################
# Summarise data by groups 
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
  group_by(age_group, cancer, sex) %>%
  summarise(
    tot = n(),
    opioid_any = sum(opioid_any),
    opioid_new = sum(opioid_new),
    opioid_naive = sum(opioid_naive),
  )  %>%
  rename(label = age_group) %>%
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
  f(imd10, "IMD decile"),
  f(carehome, "Care home")  
) %>%
  dplyr::select(contains(c("cancer", "label", "age_stand", 
                           "sex", "tot", "group", "opioid_any"))) %>%
  mutate(age_stand = ifelse(age_stand != "Total", paste(age_stand, "y"), "Total"))



############################################################
# Summarise data for tables (including standardising rates)
############################################################

### By cancer diagnosis - overall prescribing ###

# Summarise 
bycancer <- combined %>%
  group_by(group, label, cancer) %>%
  summarise(opioid_any = sum(opioid_any), total_population = sum(tot)) %>%
  # Suppression and rounding 
  mutate(
    total_pop_round = rounding(total_population),
    opioid_any_round = rounding(opioid_any)) %>%
  dplyr::select(!c(total_population, opioid_any))

# Save
write.csv(bycancer, here::here("output", "tables", "table_by_cancer.csv"),
          row.names = FALSE)


### Full population - overall prescribing     ###

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
    mutate(
      total_pop_round = rounding(total_population),
      opioid_any_round = rounding(opioid_any),
      opioid_any_std_round = rounding(opioid_any_std)
    ) %>%
    dplyr::select(!c(total_population, opioid_any, opioid_any_std))
  
  return(stand_final)
}

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

for_tables <- for_tables %>%
  mutate(oth_opioid_any = (buc_opioid_any | inh_opioid_any | rec_opioid_any))

# Full population - breakdown of admin route
admin <- rbind(
    # Count number of people with each formulation type
    cbind(sum(for_tables$opioid_any), "Any"),
    cbind(sum(for_tables$hi_opioid_any), "High dose"),
    cbind(sum(for_tables$long_opioid_any), "Long acting"),
    cbind(sum(for_tables$oral_opioid_any), "Oral"),
    cbind(sum(for_tables$par_opioid_any), "Parenteral"),
    cbind(sum(for_tables$trans_opioid_any), "Transdermal"),
    cbind(sum(for_tables$oth_opioid_any), "Other")
  ) %>%
  as.data.frame() %>%
  rename(no_people = V1, formulation = V2) %>%
  mutate(no_people = as.numeric(no_people),
         tot = as.numeric(count(for_tables)) #Total sample size
         ) %>%
  mutate(tot_round = rounding(tot),
         no_people_round = rounding(no_people),
         group = "Full population") %>%
  dplyr::select(!c("tot", "no_people"))


# in care home - breakdown of admin route
admin.care <- rbind(
  # Count number of people with each formulation type
    cbind(sum(subset(for_tables, carehome == "Yes")$opioid_any), "Any"),
    cbind(sum(subset(for_tables, carehome == "Yes")$hi_opioid_any), "High dose"),
    cbind(sum(subset(for_tables, carehome == "Yes")$long_opioid_any), "Long acting"),
    cbind(sum(subset(for_tables, carehome == "Yes")$oral_opioid_any), "Oral"),
    cbind(sum(subset(for_tables, carehome == "Yes")$par_opioid_any), "Parenteral"),
    cbind(sum(subset(for_tables, carehome == "Yes")$trans_opioid_any), "Transdermal"),
    cbind(sum(subset(for_tables, carehome == "Yes")$oth_opioid_any), "Other")
  ) %>%
  as.data.frame() %>%
  rename(no_people = V1, formulation = V2) %>%
  mutate(no_people = as.numeric(no_people),
         tot = as.numeric(count(subset(for_tables, carehome == "Yes"))) # Total sample size
         ) %>%
  mutate(tot_round = rounding(tot),
         no_people_round = rounding(no_people),
         group = "Care home") %>%
  dplyr::select(!c("tot","no_people"))

admin.both <- rbind(admin, admin.care)

# Save
write.csv(admin.both, here::here("output", "tables", "table_by_admin_route.csv"),
          row.names = FALSE)

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
# Prevalence datasets 
###############################

## Combine data for different measures by subgroup

# Overall
total <- Reduce(function(x,y) 
  merge(x, y, by = c("date", "population", "cancer"), all = TRUE),
      list(dplyr::select(read_csv(here::here("output", "data", "measure_opioid_all_any.csv")), !value),
           dplyr::select(read_csv(here::here("output", "data", "measure_hi_opioid_all_any.csv")), !value),
           dplyr::select(read_csv(here::here("output", "data", "measure_long_opioid_all_any.csv")), !value),
           dplyr::select(read_csv(here::here("output", "data", "measure_oral_opioid_all_any.csv")), !value),
           dplyr::select(read_csv(here::here("output", "data", "measure_buc_opioid_all_any.csv")), !value),
           dplyr::select(read_csv(here::here("output", "data", "measure_trans_opioid_all_any.csv")), !value),
           dplyr::select(read_csv(here::here("output", "data", "measure_par_opioid_all_any.csv")), !value)
           )
  ) %>%
  group_by(date, cancer) %>%
  mutate(date = as.Date(as.character(date), format = "%Y-%m-%d"),
         group = "Total", label = "Total", age_stand = as.character("Total"), sex = as.character("Total")) 

# By age
age <- Reduce(function(x,y) 
           merge(x, y, by = c("date", "population", "cancer", "age_cat", "sex"), all = TRUE),
           list(dplyr::select(read_csv(here::here("output", "data", "measure_opioid_age_any.csv")), !value),
                dplyr::select(read_csv(here::here("output", "data", "measure_hi_opioid_age_any.csv")), !value),
                dplyr::select(read_csv(here::here("output", "data", "measure_long_opioid_age_any.csv")), !value),
                dplyr::select(read_csv(here::here("output", "data", "measure_oral_opioid_age_any.csv")), !value),
                dplyr::select(read_csv(here::here("output", "data", "measure_buc_opioid_age_any.csv")), !value),
                dplyr::select(read_csv(here::here("output", "data", "measure_trans_opioid_age_any.csv")), !value),
                dplyr::select(read_csv(here::here("output", "data", "measure_par_opioid_age_any.csv")), !value)
           )
          ) %>%
        mutate(date = as.Date(as.character(date), format = "%Y-%m-%d"),
           group = "Age", 
           age_cat = fct_case_when(
            age_cat == 0 ~ "Missing",
            age_cat == 1 ~ "18-29 y",
            age_cat == 2 ~ "30-39 y",
            age_cat == 3 ~ "40-49 y",
            age_cat == 4 ~ "50-59 y",
            age_cat == 5 ~ "60-69 y",
            age_cat == 6 ~ "70-79 y",
            age_cat == 7 ~ "80-89 y",
            age_cat == 8 ~ "90+ y"
            )
           ) %>%
        group_by(date, group, cancer, age_cat, sex) %>%
        summarise_at(c(vars(c("population", contains("opioid")))), sum) %>%
        rename(label = age_cat) %>%
        mutate(age_stand = as.character("Total"))

# By sex
sex <- Reduce(function(x,y) 
  merge(x, y, by = c("date", "population", "cancer", "age_stand", "sex"), all = TRUE),
  list(dplyr::select(read_csv(here::here("output", "data", "measure_opioid_sex_any.csv")), !value),
       dplyr::select(read_csv(here::here("output", "data", "measure_hi_opioid_sex_any.csv")), !value),
       dplyr::select(read_csv(here::here("output", "data", "measure_long_opioid_sex_any.csv")), !value),
       dplyr::select(read_csv(here::here("output", "data", "measure_oral_opioid_sex_any.csv")), !value),
       dplyr::select(read_csv(here::here("output", "data", "measure_buc_opioid_sex_any.csv")), !value),
       dplyr::select(read_csv(here::here("output", "data", "measure_trans_opioid_sex_any.csv")), !value),
       dplyr::select(read_csv(here::here("output", "data", "measure_par_opioid_sex_any.csv")), !value)
  )
  ) %>%
  mutate(date = as.Date(as.character(date), format = "%Y-%m-%d"),
         age_stand = as.character(age_stand),
         group = "Sex", 
         sex = fct_case_when(
           sex == "F" ~ "Female",
           sex == "M" ~ "Male",
           TRUE ~ NA_character_)
  ) %>%
  group_by(date, cancer, group, sex, age_stand) %>%
  summarise_at(c(vars(c("population", contains("opioid")))), sum) %>%
  mutate(label = sex, sex = as.character("Total"))

# By IMD Decile
imd <- Reduce(function(x,y) 
  merge(x, y, by = c("date", "population", "cancer", "age_stand", "imdq10", "sex"), all = TRUE),
  list(dplyr::select(read_csv(here::here("output", "data", "measure_opioid_imd_any.csv")), !value),
       dplyr::select(read_csv(here::here("output", "data", "measure_hi_opioid_imd_any.csv")), !value),
       dplyr::select(read_csv(here::here("output", "data", "measure_long_opioid_imd_any.csv")), !value),
       dplyr::select(read_csv(here::here("output", "data", "measure_oral_opioid_imd_any.csv")), !value),
       dplyr::select(read_csv(here::here("output", "data", "measure_buc_opioid_imd_any.csv")), !value),
       dplyr::select(read_csv(here::here("output", "data", "measure_trans_opioid_imd_any.csv")), !value),
       dplyr::select(read_csv(here::here("output", "data", "measure_par_opioid_imd_any.csv")), !value)
    )
  ) %>%
  mutate(date = as.Date(as.character(date), format = "%Y-%m-%d"),
         age_stand = as.character(age_stand),
         group = "IMD decile", 
         imdq10 = ifelse(imdq10 %in% c(NA), "Missing", imdq10),
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
         )
    ) %>%
  group_by(date, cancer, group, age_stand, sex, imdq10) %>%
  summarise_at(c(vars(c("population", contains("opioid")))), sum) %>%
  rename(label = imdq10) 

# BY region
region <- Reduce(function(x,y) 
  merge(x, y, by = c("date", "population", "cancer", "age_stand", "region", "sex"), all = TRUE),
  list(dplyr::select(read_csv(here::here("output", "data", "measure_opioid_reg_any.csv")), !value),
       dplyr::select(read_csv(here::here("output", "data", "measure_hi_opioid_reg_any.csv")), !value),
       dplyr::select(read_csv(here::here("output", "data", "measure_long_opioid_reg_any.csv")), !value),
       dplyr::select(read_csv(here::here("output", "data", "measure_oral_opioid_reg_any.csv")), !value),
       dplyr::select(read_csv(here::here("output", "data", "measure_buc_opioid_reg_any.csv")), !value),
       dplyr::select(read_csv(here::here("output", "data", "measure_trans_opioid_reg_any.csv")), !value),
       dplyr::select(read_csv(here::here("output", "data", "measure_par_opioid_reg_any.csv")), !value)
    )
  ) %>%
  mutate(date = as.Date(as.character(date), format = "%Y-%m-%d"),
         age_stand = as.character(age_stand),
         group = "Region", 
         region = ifelse(region %in% c(NA), "Missing", region)) %>%
  group_by(date, cancer, region, group, age_stand, sex) %>%
  summarise_at(c(vars(c("population", contains("opioid")))), sum) %>%
  rename(label = region)

# By ethnicity (6 categories)
ethnicity <- Reduce(function(x,y) 
  merge(x, y, by = c("date", "population", "cancer", "age_stand", "ethnicity6", "sex"), all = TRUE),
  list(dplyr::select(read_csv(here::here("output", "data", "measure_opioid_eth6_any.csv")), !value),
       dplyr::select(read_csv(here::here("output", "data", "measure_hi_opioid_eth6_any.csv")), !value),
       dplyr::select(read_csv(here::here("output", "data", "measure_long_opioid_eth6_any.csv")), !value),
       dplyr::select(read_csv(here::here("output", "data", "measure_oral_opioid_eth6_any.csv")), !value),
       dplyr::select(read_csv(here::here("output", "data", "measure_buc_opioid_eth6_any.csv")), !value),
       dplyr::select(read_csv(here::here("output", "data", "measure_trans_opioid_eth6_any.csv")), !value),
       dplyr::select(read_csv(here::here("output", "data", "measure_par_opioid_eth6_any.csv")), !value)
  )
  ) %>%
  mutate(date = as.Date(as.character(date), format = "%Y-%m-%d"),
         age_stand = as.character(age_stand),
         group = "Ethnicity", 
         ethnicity6 = ifelse(ethnicity6 %in% c(NA), "Missing", ethnicity6)) %>%
  group_by(date, cancer, ethnicity6, group, age_stand, sex) %>%
  summarise_at(c(vars(c("population", contains("opioid")))), sum) %>%
  rename(label = ethnicity6)

# By care home residence
care <- Reduce(function(x,y) 
  merge(x, y, by = c("date", "population", "cancer", "age_stand", "carehome", "sex"), all = TRUE),
  list(dplyr::select(read_csv(here::here("output", "data", "measure_opioid_care_any.csv")), !value),
       dplyr::select(read_csv(here::here("output", "data", "measure_hi_opioid_care_any.csv")), !value),
       dplyr::select(read_csv(here::here("output", "data", "measure_long_opioid_care_any.csv")), !value),
       dplyr::select(read_csv(here::here("output", "data", "measure_oral_opioid_care_any.csv")), !value),
       dplyr::select(read_csv(here::here("output", "data", "measure_buc_opioid_care_any.csv")), !value),
       dplyr::select(read_csv(here::here("output", "data", "measure_trans_opioid_care_any.csv")), !value),
       dplyr::select(read_csv(here::here("output", "data", "measure_par_opioid_care_any.csv")), !value)
  )
  ) %>%
  mutate(date = as.Date(as.character(date), format = "%Y-%m-%d"),
         age_stand = as.character(age_stand),
         group = "Care home", 
         carehome = fct_case_when(
           carehome == 0 ~ "No",
           carehome == 1 ~ "Yes"
         )) %>%
  group_by(date, cancer, carehome, group,  age_stand, sex) %>%
  summarise_at(c(vars(c("population", contains("opioid")))), sum) %>%
  rename(label = carehome)
        
  
## Combine data from all subgroups into one data frame
prevalence <- rbind(
    total, age, sex, imd, region, ethnicity, care
    ) %>%
    mutate_at(c(vars(c("population", contains("opioid")))), as.integer) %>%
    mutate(sex = fct_case_when(
            sex == "M" ~ "Male",
            sex == "F" ~ "Female"
          ),
          
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
              age_stand == 15 ~ "90+ y"
            ))


###############################
# Incidence datasets
###############################

# Overall
total <- dplyr::select(read_csv(here::here("output", "data", "measure_opioid_all_new.csv")), !value) %>%
    mutate(date = as.Date(as.character(date), format = "%Y-%m-%d"),
           group = "Total", label = "Total", age_stand = as.character("Total"), sex = as.character("Total")) 
  
# By age
age <- dplyr::select(read_csv(here::here("output", "data", "measure_opioid_age_new.csv")), !value) %>%
  mutate(date = as.Date(as.character(date), format = "%Y-%m-%d"),
         group = "Age",
         age_cat = fct_case_when(
           age_cat == 0 ~ "Missing",
           age_cat == 1 ~ "18-29 y",
           age_cat == 2 ~ "30-39 y",
           age_cat == 3 ~ "40-49 y",
           age_cat == 4 ~ "50-59 y",
           age_cat == 5 ~ "60-69 y",
           age_cat == 6 ~ "70-79 y",
           age_cat == 7 ~ "80-89 y",
           age_cat == 8 ~ "90+ y"
         )
     ) %>%
    group_by(date, cancer, group, age_cat, sex) %>%
    summarise_at(c(vars(c(contains("opioid")))), sum) %>%
    rename(label = age_cat) %>%
    mutate(age_stand = as.character("Total"))
  
  # By sex
sex <- dplyr::select(read_csv(here::here("output", "data", "measure_opioid_sex_new.csv")), !value) %>%
     mutate(date = as.Date(as.character(date), format = "%Y-%m-%d"),
            age_stand = as.character(age_stand),
         group = "Sex", 
         sex = fct_case_when(
           sex == "F" ~ "Female",
           sex == "M" ~ "Male",
           TRUE ~ NA_character_)
      ) %>%
    group_by(date, cancer, group, sex, age_stand) %>%
    summarise_at(c(vars(c(contains("opioid")))), sum) %>%
    rename(label = sex) %>%
    mutate(sex = as.character("Total"))
  
# By IMD Decile
imd <- dplyr::select(read_csv(here::here("output", "data", "measure_opioid_imd_new.csv")), !value) %>%
    mutate(date = as.Date(as.character(date), format = "%Y-%m-%d"),
           age_stand = as.character(age_stand),
         group = "IMD decile", 
         imdq10 = ifelse(imdq10 %in% c(NA), "Missing", imdq10),
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
         )
     ) %>%
    group_by(date, cancer, group, imdq10, age_stand, sex) %>%
    summarise_at(c(vars(c(contains("opioid")))), sum) %>%
    rename(label = imdq10) 
  
# BY region
region <- dplyr::select(read_csv(here::here("output", "data", "measure_opioid_reg_new.csv")), !value) %>%
    mutate(date = as.Date(as.character(date), format = "%Y-%m-%d"),
           age_stand = as.character(age_stand),
         group = "Region", 
         region = ifelse(region %in% c(NA), "Missing", region)) %>%
    group_by(date, cancer, group, region, age_stand, sex) %>%
    summarise_at(c(vars(c(contains("opioid")))), sum) %>%
    rename(label = region)
  
# By ethnicity (6 categories)
ethnicity <- dplyr::select(read_csv(here::here("output", "data", "measure_opioid_eth6_new.csv")), !value) %>%
    mutate(date = as.Date(as.character(date), format = "%Y-%m-%d"),
           age_stand = as.character(age_stand),
         group = "Ethnicity", 
         ethnicity6 = ifelse(ethnicity6 %in% c(NA), "Missing", ethnicity6)) %>%
    group_by(date, cancer, group, ethnicity6, age_stand, sex) %>%
    summarise_at(c(vars(c(contains("opioid")))), sum) %>%
    rename(label = ethnicity6)
  
# By care home residence
care <- dplyr::select(read_csv(here::here("output", "data", "measure_opioid_care_new.csv")), !value) %>%
    mutate(date = as.Date(as.character(date), format = "%Y-%m-%d"),
           age_stand = as.character(age_stand),
         group = "Care home", 
         carehome = fct_case_when(
           carehome == 0 ~ "No",
           carehome == 1 ~ "Yes"
         )) %>%
    group_by(date, cancer, group, carehome, age_stand, sex) %>%
    summarise_at(c(vars(c(contains("opioid")))), sum) %>%
    rename(label = carehome)
  

## Combine data from all subgroups into one data frame
incidence <- rbind(
    total, age, sex, imd, region, ethnicity, care
    ) %>%
    mutate_at(c(vars(c(contains("opioid")))), as.integer) %>%
    mutate(sex = fct_case_when(
      sex == "M" ~ "Male",
      sex == "F" ~ "Female"
    ),
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
    age_stand == 15 ~ "90+ y"
  ))


###############################
## Save as .csv
###############################

write.csv(prevalence, file = here::here("output", "joined", "final_ts_prev.csv"))
write.csv(incidence, file = here::here("output", "joined", "final_ts_new.csv"))


###########################################
## Sensitivity - age in/not in aged care
###########################################

###############################
# Prevalence datasets - with/without care home
###############################

# Combine data on any opioid prescribing
carehome <- full_join(
    dplyr::select(read_csv(here::here("output", "data", "measure_opioid_age_care_any.csv")), !value), 
    dplyr::select(read_csv(here::here("output", "data", "measure_opioid_age_care_new.csv")), !value),
    by = c("date", "age_cat", "carehome")
  ) %>%
  group_by(date, age_cat, carehome) %>%
  summarise_at(c(vars(c("population", contains("opioid")))), sum) %>%
  subset(age_cat >=5) %>%
  mutate(date = as.Date(as.character(date), format = "%Y-%m-%d"), 
         
    # Age
    age_cat = fct_case_when(
      age_cat == 5 ~ "60-69 y",
      age_cat == 6 ~ "70-79 y",
      age_cat == 7 ~ "80-89 y",
      age_cat == 8 ~ "90+ y"
      ),
         
    #Carehome
    carehome = fct_case_when(
      carehome == 0 ~ "No",
      carehome == 1 ~ "Yes"
      )) %>%
  mutate_at(c(vars(c("population", contains("opioid")))), as.integer)

# Save
write.csv(carehome, file = here::here("output", "joined", "final_ts_agecare.csv"))






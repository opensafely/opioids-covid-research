######################################

# This script:
# - Produces counts of patients prescribed opioids (prevalence and incidence)
#     by demographic characteristics before and during COVID (Apr-Jun 2019 vs 2020)
# - Both overall in full population, and people without a cancer diagnosis
# - saves data summaries (as table)

######################################


## FOr running locally only
# setwd("C:/Users/aschaffer/OneDrive - Nexus365/Documents/GitHub/opioids-covid-research")

## Import libraries
library('tidyverse')
library('lubridate')
library('reshape2')
library('here')
library('gt')
library('gtsummary')

## Custom functions
source(here("analysis", "lib", "custom_functions.R"))

## Set theme so no commas in counts
theme_gtsummary_language("en", big.mark = "")


###############################
# Read in data
###############################

## Read in data before COVID and combine
apr19 <- read.csv(here::here("output", "data", "input_2019-04-01.csv")) 
may19 <- read.csv(here::here("output", "data", "input_2019-05-01.csv")) %>%
  filter(!(patient_id %in% apr19$patient_id))
jun19 <- read.csv(here::here("output", "data", "input_2019-06-01.csv")) %>%
  filter(!(patient_id %in% c(apr19$patient_id, may19$patient_id)))

cohort_before <- rbind(apr19, may19, jun19) %>%
  select(!(c(opioid_any_date, hi_opioid_any_date))) %>%
  mutate(time = 0)

## Read in data during COVID and combine
apr20 <- read.csv(here::here("output", "data", "input_2020-04-01.csv")) 
may20 <- read.csv(here::here("output", "data", "input_2020-05-01.csv")) %>%
  filter(!patient_id %in% apr20$patient_id)
jun20 <- read.csv(here::here("output", "data", "input_2020-06-01.csv")) %>%
  filter(!patient_id %in% c(apr20$patient_id, may20$patient_id))

cohort_after <- rbind(apr20, may20, jun20) %>%
  select(!(c(opioid_any_date, hi_opioid_any_date))) %>%
  mutate(time = 1)

## Combine cohorts before/during COVID
cohort <- rbind(cohort_after, cohort_before)

# Number check----
print(dim(cohort_before))
head(cohort_before)
print(dim(cohort_after))
head(cohort_after)

#################################################
# Create base dataset for producing tables, 
# including formatting variables as appropriate
#################################################

for_tables <- cohort %>%
  mutate(
    
    # Time
    time = as.character(time),
    time = fct_case_when(
      time == "0" ~ "Before",
      time == "1" ~ "During",
      TRUE ~ NA_character_
    ),
  
    # Sex
    sex = fct_case_when(
          sex == "F" ~ "Female",
          sex == "M" ~ "Male",
          TRUE ~ NA_character_),
        
    # Ethnicity
    ethnicity = ifelse(ethnicity == "", "Missing", ethnicity),
        
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
          age_cat == 1 ~ "5-17 y",
          age_cat == 2 ~ "18-29 y",
          age_cat == 3 ~ "30-39 y",
          age_cat == 4 ~ "40-49 y",
          age_cat == 5 ~ "50-59 y",
          age_cat == 6 ~ "60-69 y",
          age_cat == 7 ~ "70-79 y",
          age_cat == 8 ~ "80-89 y",
          age_cat == 9 ~ "90+ y",
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
)

#######################################
# Prevalence full population
#######################################

## Total
table_tot <- select(for_tables,
                    time, age_cat, sex, region, imdq10,
                    ethnicity, carehome, scd) %>% 
  tbl_summary(by = time, statistic = all_categorical() ~ "{n}")

## People prescribed any opioid
table_prev <- select(subset(for_tables, opioid_any == 1),
                     time, age_cat, sex, region, imdq10,
                     ethnicity, carehome, scd) %>% 
  tbl_summary(by = time, statistic = all_categorical() ~ "{n}")

## People prescribed any opioid (high dose)
table_hi_prev <- select(subset(for_tables, hi_opioid_any == 1),
                     time, age_cat, sex, region, imdq10,
                     ethnicity, carehome, scd) %>% 
  tbl_summary(by = time, statistic = all_categorical() ~ "{n}") 

table_prev_full <- tbl_merge(tbls = list(table_prev, table_hi_prev, table_tot),
                       tab_spanner = c("**Any opioid prescribing**",
                                       "**High dose opioid prescribing**",
                                       "**Total population**"))
table_prev_full

#######################################
# Incidence full population
########################################

## People opioid naive
table_naive <- select(subset(for_tables, opioid_naive == 1),
                      time, age_cat, sex, region, imdq10,
                      ethnicity, carehome, scd) %>%
  tbl_summary(by = time, statistic = all_categorical() ~ "{n}")
  
## People high dose opioid naive
table_hi_naive <- select(subset(for_tables, hi_opioid_naive == 1),
                      time, age_cat, sex, region, imdq10,
                      ethnicity, carehome, scd) %>%
  tbl_summary(by = time, statistic = all_categorical() ~ "{n}")

## People initiating an opioid
table_new <- select(subset(for_tables, opioid_new == 1),
                     time, age_cat, sex, region, imdq10,
                     ethnicity, carehome, scd) %>%
  tbl_summary(by = time, statistic = all_categorical() ~ "{n}")

## People initiating an opioid (high dose)
table_hi_new <- select(subset(for_tables, hi_opioid_new == 1),
                        time, age_cat, sex, region, imdq10,
                        ethnicity, carehome, scd) %>% 
  tbl_summary(by = time,statistic = all_categorical() ~ "{n}")

table_new_full <- tbl_merge(
                    tbls = list(table_new, table_hi_prev, table_naive, table_hi_naive),
                    tab_spanner = c("**New opioid prescribing**",
                                   "**New high dose opioid prescribing**",
                                   "**Opioid naive population**",
                                   "**High dose opioid naive**")
                  )
table_new_full


#######################################
# Prevalence people without cancer
#######################################

## Total
table_tot2 <- select(subset(for_tables, cancer == "No"),
                    time, age_cat, sex, region, imdq10,
                    ethnicity, carehome, scd) %>% 
  tbl_summary(by = time, statistic = all_categorical() ~ "{n}")

## People prescribed any opioid
table_prev2 <- select(subset(for_tables, opioid_any == 1 & cancer == "No"),
                     time, age_cat, sex, region, imdq10,
                     ethnicity, carehome, scd) %>% 
  tbl_summary(by = time, statistic = all_categorical() ~ "{n}")

## People prescribed any opioid (high dose)
table_hi_prev2 <- select(subset(for_tables, hi_opioid_any == 1 & cancer == "No"),
                        time, age_cat, sex, region, imdq10,
                        ethnicity, carehome, scd) %>% 
  tbl_summary(by = time, statistic = all_categorical() ~ "{n}")

## Combine 
table_prev_nocancer <- tbl_merge(
                        tbls = list(table_prev2, table_hi_prev2, table_tot2),
                        tab_spanner = c("**Any opioid prescribing**",
                                        "**High dose opioid prescribing**",
                                        "**Total population**")
                      )
table_prev_nocancer

#######################################
# Incidence people without cancer
########################################

## People opioid naive
table_naive2 <- select(subset(for_tables, opioid_naive == 1 & cancer == "No"),
                      time, age_cat, sex, region, imdq10,
                      ethnicity, carehome, scd) %>%
  tbl_summary(by = time, statistic = all_categorical() ~ "{n}")

## People high dose opioid naive
table_hi_naive2 <- select(subset(for_tables, hi_opioid_naive == 1 & cancer == "No"),
                      time, age_cat, sex, region, imdq10,
                      ethnicity, carehome, scd) %>%
  tbl_summary(by = time, statistic = all_categorical() ~ "{n}")

## People prescribed any opioid
table_new2 <- select(subset(for_tables, opioid_new == 1 & cancer == "No"),
                    time, age_cat, sex, region, imdq10,
                    ethnicity, carehome, scd) %>% 
  tbl_summary(by = time, statistic = all_categorical() ~ "{n}")

## People prescribed any opioid (high dose)
table_hi_new2 <- select(subset(for_tables, hi_opioid_new == 1 & cancer == "No"),
                       time, age_cat, sex, region, imdq10,
                       ethnicity, carehome, scd) %>% 
  tbl_summary(by = time, statistic = all_categorical() ~ "{n}")

## Combine
table_new_nocancer <- tbl_merge(tbls = list(table_new2, table_hi_prev2, table_naive2, table_hi_naive2),
                               tab_spanner = c("**New opioid prescribing**",
                                               "**New high dose opioid prescribing**",
                                               "**Opioid naive population**",
                                               "**High dose opioid naive population**"))
table_new_nocancer


########################################################
# Convert to data frames to facilitate new calculations
########################################################

# Prevalence in full population
df_prev_full <- table_prev_full$table_body %>%
  select(variable, label, stat_1_1, stat_2_1, stat_1_2, stat_2_2, stat_1_3, stat_2_3) %>%
  rename(
    any_before = stat_1_1, 
    any_during = stat_2_1,
    hi_any_before = stat_1_2, 
    hi_any_during = stat_2_2,
    tot_before = stat_1_3, 
    tot_during = stat_2_3
    ) %>%
  na.omit() %>%
  mutate(
    prev_rate_before = as.numeric(any_before) / as.numeric(tot_before)*1000,
    prev_rate_during = as.numeric(any_during) / as.numeric(tot_during)*1000,
    hi_prev_rate_before = as.numeric(hi_any_before) / as.numeric(tot_before)*1000,
    hi_prev_rate_during = as.numeric(hi_any_during) / as.numeric(tot_during)*1000
  )

# INcident use in full population
df_new_full <- table_new_full$table_body %>%
  select(variable, label, stat_1_1, stat_2_1, stat_1_2, 
    stat_2_2, stat_1_3, stat_2_3, stat_1_4, stat_2_4) %>%
  rename(
    new_before = stat_1_1,
     new_during = stat_2_1,
     hi_new_before = stat_1_2, 
     hi_new_during = stat_2_2,
     naive_before = stat_1_3,
     naive_during = stat_2_3,
     hi_naive_before = stat_1_4,
     hi_naive_during = stat_2_4
      ) %>%
    na.omit() %>%
    mutate(
      new_rate_before = as.numeric(new_before) / as.numeric(naive_before)*1000,
      new_rate_during = as.numeric(new_during) / as.numeric(naive_during)*1000,
      hi_new_rate_before = as.numeric(hi_new_before) / as.numeric(hi_naive_before)*1000,
      hi_new_rate_during = as.numeric(hi_new_during) / as.numeric(hi_naive_during)*1000
    )

# Prevalence in people without cancer
df_prev_nocancer <- table_prev_nocancer$table_body %>%
  select(variable, label, stat_1_1, stat_2_1, stat_1_2, stat_2_2, stat_1_3, stat_2_3) %>%
  rename(
    any_before = stat_1_1,
    any_during = stat_2_1,
    hi_any_before = stat_1_2,
    hi_any_during = stat_2_2,
    tot_before = stat_1_3,
    tot_during = stat_2_3) %>%
  na.omit() %>%
  mutate(
    prev_rate_before = as.numeric(any_before) / as.numeric(tot_before)*1000,
    prev_rate_during = as.numeric(any_during) / as.numeric(tot_during)*1000,
    hi_prev_rate_before = as.numeric(hi_any_before) / as.numeric(tot_before)*1000,
    hi_prev_rate_during = as.numeric(hi_any_during) / as.numeric(tot_during)*1000
  )

# Incidence in people without cancer
df_new_nocancer <-table_new_nocancer$table_body %>%
  select(variable, label, stat_1_1, stat_2_1, stat_1_2, 
    stat_2_2, stat_1_3, stat_2_3, stat_1_4, stat_2_4) %>%
  rename(
    new_before = stat_1_1, 
    new_during = stat_2_1,
    hi_new_before = stat_1_2, 
    hi_new_during = stat_2_2,
    naive_before = stat_1_3, 
    naive_during = stat_2_3,
    hi_naive_before = stat_2_4,
    hi_naive_during = stat_1_4
  ) %>%
  na.omit() %>%
  mutate(
    new_rate_before = as.numeric(new_before) / as.numeric(naive_before)*1000,
    new_rate_during = as.numeric(new_during) / as.numeric(naive_during)*1000,
    hi_new_rate_before = as.numeric(hi_new_before) / as.numeric(hi_naive_before)*1000,
    hi_new_rate_during = as.numeric(hi_new_during) / as.numeric(hi_naive_during)*1000
  )

################### 
# Save tables 
###################

write.csv(df_prev_full, here::here("output", "tables", "table_prev_full.csv"))
write.csv(df_new_full, here::here("output", "tables", "table_new_full.csv"))
write.csv(df_prev_nocancer, here::here("output", "tables", "table_prev_nocancer.csv"))
write.csv(df_new_nocancer, here::here("output", "tables", "table_new_nocancer.csv"))




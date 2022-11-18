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

# Combine data on any opioid prescribing
any <- bind_rows(
    read_csv(here::here("output", "data", "measure_opioid_all_any.csv")),
    replace_na(read_csv(here::here("output", "data", "measure_opioid_reg_any.csv")), list(region = "Missing")), 
    replace_na(read_csv(here::here("output", "data", "measure_opioid_imd_any.csv")), list(imd = "Missing")),
    replace_na(read_csv(here::here("output", "data", "measure_opioid_eth6_any.csv")), list(ethnicity6 = "Missing")),
    read_csv(here::here("output", "data", "measure_opioid_care_any.csv")), 
    replace_na(read_csv(here::here("output", "data", "measure_opioid_sex_any.csv")), list(sex = "Missing")),
    read_csv(here::here("output", "data", "measure_opioid_age_any.csv"))) %>%
    dplyr::select(!c(value))

hi <- bind_rows(
    read_csv(here::here("output", "data", "measure_hi_opioid_all_any.csv")),
    replace_na(read_csv(here::here("output", "data", "measure_hi_opioid_reg_any.csv")), list(region = "Missing")), 
    replace_na(read_csv(here::here("output", "data", "measure_hi_opioid_imd_any.csv")), list(imd = "Missing")),
    replace_na(read_csv(here::here("output", "data", "measure_hi_opioid_eth6_any.csv")), list(ethnicity6 = "Missing")),
    read_csv(here::here("output", "data", "measure_hi_opioid_care_any.csv")),
    replace_na(read_csv(here::here("output", "data", "measure_hi_opioid_sex_any.csv")), list(sex = "Missing")),
    read_csv(here::here("output", "data", "measure_hi_opioid_age_any.csv"))) %>%
    dplyr::select(!c(value))

long <- bind_rows(
    read_csv(here::here("output", "data", "measure_long_opioid_all_any.csv")),
    replace_na(read_csv(here::here("output", "data", "measure_long_opioid_reg_any.csv")), list(region = "Missing")), 
    replace_na(read_csv(here::here("output", "data", "measure_long_opioid_imd_any.csv")), list(imd = "Missing")),
    replace_na(read_csv(here::here("output", "data", "measure_long_opioid_eth6_any.csv")), list(ethnicity6 = "Missing")),
    read_csv(here::here("output", "data", "measure_long_opioid_care_any.csv")),
    replace_na(read_csv(here::here("output", "data", "measure_long_opioid_sex_any.csv")), list(sex = "Missing")),
    read_csv(here::here("output", "data", "measure_long_opioid_age_any.csv"))) %>%
    dplyr::select(!c(value))
  
oral <- bind_rows(
    read_csv(here::here("output", "data", "measure_oral_opioid_all_any.csv")),
    replace_na(read_csv(here::here("output", "data", "measure_oral_opioid_reg_any.csv")), list(regionion = "Missing")), 
    replace_na(read_csv(here::here("output", "data", "measure_oral_opioid_imd_any.csv")), list(imd = "Missing")),
    replace_na(read_csv(here::here("output", "data", "measure_oral_opioid_eth6_any.csv")), list(ethnicity6 = "Missing")),
    read_csv(here::here("output", "data", "measure_oral_opioid_care_any.csv")),
    replace_na(read_csv(here::here("output", "data", "measure_oral_opioid_sex_any.csv")), list(sex = "Missing")),
    read_csv(here::here("output", "data", "measure_oral_opioid_age_any.csv")))  %>%
    dplyr::select(!c(value))

buc <- bind_rows(
    read_csv(here::here("output", "data", "measure_buc_opioid_all_any.csv")),
    replace_na(read_csv(here::here("output", "data", "measure_buc_opioid_reg_any.csv")), list(regionion = "Missing")), 
    replace_na(read_csv(here::here("output", "data", "measure_buc_opioid_imd_any.csv")), list(imd = "Missing")),
    replace_na(read_csv(here::here("output", "data", "measure_buc_opioid_eth6_any.csv")), list(ethnicity6 = "Missing")),
    read_csv(here::here("output", "data", "measure_buc_opioid_care_any.csv")),
    replace_na(read_csv(here::here("output", "data", "measure_buc_opioid_sex_any.csv")), list(sex = "Missing")),
    read_csv(here::here("output", "data", "measure_buc_opioid_age_any.csv")))  %>%
    dplyr::select(!c(value))

trans <- bind_rows(
    read_csv(here::here("output", "data", "measure_trans_opioid_all_any.csv")),
    replace_na(read_csv(here::here("output", "data", "measure_trans_opioid_reg_any.csv")), list(regionion = "Missing")), 
    replace_na(read_csv(here::here("output", "data", "measure_trans_opioid_imd_any.csv")), list(imd = "Missing")),
    replace_na(read_csv(here::here("output", "data", "measure_trans_opioid_eth6_any.csv")), list(ethnicity6 = "Missing")),
    read_csv(here::here("output", "data", "measure_trans_opioid_care_any.csv")),
    replace_na(read_csv(here::here("output", "data", "measure_trans_opioid_sex_any.csv")), list(sex = "Missing")),
    read_csv(here::here("output", "data", "measure_trans_opioid_age_any.csv")))  %>%
    dplyr::select(!c(value))

par <- bind_rows(
    read_csv(here::here("output", "data", "measure_par_opioid_all_any.csv")),
    replace_na(read_csv(here::here("output", "data", "measure_par_opioid_reg_any.csv")), list(regionion = "Missing")), 
    replace_na(read_csv(here::here("output", "data", "measure_par_opioid_imd_any.csv")), list(imd = "Missing")),
    replace_na(read_csv(here::here("output", "data", "measure_par_opioid_eth6_any.csv")), list(ethnicity6 = "Missing")),
    read_csv(here::here("output", "data", "measure_par_opioid_care_any.csv")),
    replace_na(read_csv(here::here("output", "data", "measure_par_opioid_sex_any.csv")), list(sex = "Missing")),
    read_csv(here::here("output", "data", "measure_par_opioid_age_any.csv")))  %>%
    dplyr::select(!c(value))


prevalence <- Reduce(function(x,y) 
  merge(x, y, by=c("date", "population", "cancer", "age_cat", "sex", "region", 
               "ethnicity6", "carehome", "imdq10"), all=TRUE) ,
          list(any, oral, par, trans, hi, long, inh, rec, buc)) %>%
  mutate(date = as.Date(as.character(date), format = "%Y-%m-%d"),     
    # Sex
    sex = fct_case_when(
     sex == "F" ~ "Female",
     sex == "M" ~ "Male",
     TRUE ~ NA_character_),
         
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
      age_cat == 8 ~ "90+ y"
      ),
         
    #Carehome
    carehome = fct_case_when(
      carehome == 0 ~ "No",
      carehome == 1 ~ "Yes"
      ),
         
    # Convert to integer to avoid scientific notation in csv
    population = as.integer(population),
    opioid_any = as.integer(opioid_any),
    hi_opioid_any = as.integer(hi_opioid_any),
    long_opioid_any = as.integer(long_opioid_any),    
    oral_opioid_any = as.integer(oral_opioid_any),
    trans_opioid_any = as.integer(trans_opioid_any),
    par_opioid_any = as.integer(par_opioid_any),
    buc_opioid_any = as.integer(buc_opioid_any),

    label = coalesce(region, imdq10, ethnicity6,  carehome, sex, age_cat),
    group = ifelse(!is.na(region), "Region",
              ifelse(!is.na(imdq10), "IMD decile",
                ifelse(!is.na(ethnicity6), "Ethnicity6",
                  ifelse(!is.na(carehome), "Care home",
                      ifelse(!is.na(age_cat), "Age", 
                          ifelse(!is.na(sex), "Sex", "Total"))))))
    ) %>%
    dplyr::select(!c(region, imdq10, ethnicity6, carehome, age_cat, sex))


###############################
# Incidence datasets
###############################


incidence <- bind_rows(
    read_csv(here::here("output", "data", "measure_opioid_all_new.csv")),
    replace_na(read_csv(here::here("output", "data", "measure_opioid_reg_new.csv")), list(region = "Missing")),
    replace_na(read_csv(here::here("output", "data", "measure_opioid_imd_new.csv")), list(imd = "Missing")),
    replace_na(read_csv(here::here("output", "data", "measure_opioid_eth6_new.csv")), list(ethnicity6 = "Missing")),
    read_csv(here::here("output", "data", "measure_opioid_care_new.csv")),
    read_csv(here::here("output", "data", "measure_opioid_age_new.csv")),
    replace_na(read_csv(here::here("output", "data", "measure_opioid_sex_new.csv")), list(sex = "Missing"))
    ) %>%
  dplyr::select(!value) %>%
  mutate(date = as.Date(as.character(date), format = "%Y-%m-%d"),
    # Sex
    sex = fct_case_when(
      sex == "F" ~ "Female",
      sex == "M" ~ "Male",
      TRUE ~ NA_character_),
         
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
      age_cat == 8 ~ "90+ y"
      ),
         
    #Carehome
    carehome = fct_case_when(
      carehome == 0 ~ "No",
      carehome == 1 ~ "Yes"
      ),

    # Convert to integer to avoid scientific notation in csv
    opioid_new = as.integer(opioid_new),
    opioid_naive = as.integer(opioid_naive),
    
    label = coalesce(region, imdq10, ethnicity6, carehome, age_cat),
    label = ifelse(is.na(label) & is.na(sex), "Total", 
                   ifelse(is.na(label) &  sex == "Male", "Male",
                          ifelse(is.na(label) & sex == "Female", "Female", label))),
    group = ifelse(!is.na(region), "Region",
                   ifelse(!is.na(imdq10), "IMD decile",
                                 ifelse(!is.na(ethnicity6), "Ethnicity6",
                                        ifelse(!is.na(carehome), "Care home",
                                                      ifelse(!is.na(age_cat), "Age", 
                                                             ifelse(!is.na(sex), "Sex","Total"))))))) %>%
  dplyr::select(!c(region, imdq10, ethnicity6,  carehome, sex, age_cat))



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
  read_csv(here::here("output", "data", "measure_opioid_age_care_any.csv")), 
  read_csv(here::here("output", "data", "measure_opioid_age_care_new.csv")),
  by = c("date", "age_cat", "carehome")) %>%
  dplyr::select(!c(value.x, value.y)) %>%
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
      ),

    # Convert to integer to avoid scientific notation in csv
    population = as.integer(population),
    opioid_any = as.integer(opioid_any),
    opioid_naive = as.integer(opioid_naive),
    opioid_new = as.integer(opioid_new)) 


write.csv(carehome, file = here::here("output", "joined", "final_ts_agecare.csv"))



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


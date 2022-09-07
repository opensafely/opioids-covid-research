######################################################
# This script:
# - imports data extracted by the cohort extractor
# - combines datasets into four:
#    1. Prevalence of opioid prescribing in full population;
#    2. Prevalence of opioid prescribing in people without cancer;
#    3. Incidence of opioid prescribing in full population;
#    4. Incidence of opioid prescribing in people without cancer.
# - each dataset contains monthly time series of both 
#     any and high dose opioid
#   prescribing, broken down by various characteristics
# - saves processed dataset(s)
#######################################################


# For running locally only #
# setwd("C:/Users/aschaffer/OneDrive - Nexus365/Documents/GitHub/opioids-covid-research")

dir.create(here::here("output", "time series"), showWarnings = FALSE, recursive=TRUE)


# Import libraries #
library('tidyverse')
library('lubridate')
library('arrow')
library('here')
library('reshape2')
library('dplyr')

# Custom functions
source(here("analysis", "lib", "custom_functions.R"))


###############################
# Prevalence datasets
###############################

# Combine data on any opioid prescribing
prev_any <- bind_rows(
    read.csv(here::here("output", "data", "measure_opioid_all_any.csv")),
    read.csv(here::here("output", "data", "measure_opioid_reg_any.csv")),
    read.csv(here::here("output", "data", "measure_opioid_imd_any.csv")),
    read.csv(here::here("output", "data", "measure_opioid_eth_any.csv")),
    read.csv(here::here("output", "data", "measure_opioid_care_any.csv")),
    read.csv(here::here("output", "data", "measure_opioid_scd_any.csv")),
    read.csv(here::here("output", "data", "measure_opioid_age_any.csv"))
    ) %>%
  mutate(date = as.Date(as.character(date), format = "%Y-%m-%d"))

## Create dataset for any opioid prescribing in 
##  full population (combine cancer/no cancer)
prev_any_full <- prev_any %>%
  group_by(date, region, imdq10, ethnicity, carehome, scd, age_cat, sex) %>%
  summarise(opioid_any = sum(opioid_any), population = sum(population)) %>%
  mutate(rate_any = opioid_any / population)

## Create dataset for any opioid prescribing in people without cancer only
prev_any_nocancer <- prev_any %>%
  subset(cancer == 0) %>%
  select(!cancer) %>%
  rename(rate_any = value)

print(dim(prev_any_full))
print(dim(prev_any_nocancer))

##################################

## Combine data on high dose opioid prescribing
prev_hi <- bind_rows(
      read.csv(here::here("output", "data", "measure_hi_opioid_all_any.csv")),
      read.csv(here::here("output", "data", "measure_hi_opioid_reg_any.csv")),
      read.csv(here::here("output", "data", "measure_hi_opioid_imd_any.csv")),
      read.csv(here::here("output", "data", "measure_hi_opioid_eth_any.csv")),
      read.csv(here::here("output", "data", "measure_hi_opioid_care_any.csv")),
      read.csv(here::here("output", "data", "measure_hi_opioid_scd_any.csv")),
      read.csv(here::here("output", "data", "measure_hi_opioid_age_any.csv"))
    ) %>%
  mutate(date = as.Date(as.character(date), format = "%Y-%m-%d"))

## Create dataset for high dose opioid prescribing 
##   in full population (combine cancer/no cancer)
prev_hi_full <- prev_hi %>%
  group_by(date, region, imdq10, ethnicity, carehome, scd, age_cat, sex) %>%
  summarise(
    hi_opioid_any = sum(hi_opioid_any),
    population = sum(population)
    ) %>%
  mutate(rate_hi = hi_opioid_any/population)

## Create dataset for high dose opioid prescribing in people without cancer only
prev_hi_nocancer <- prev_hi %>%
  subset(cancer == 0) %>%
  select(!cancer) %>%
  rename(rate_hi = value)

print(dim(prev_hi_full))
print(dim(prev_hi_nocancer))

## Combine and replace NA values 
##   (Note: if value is NA, this is because it represents the 
##   full population (not stratified) estimate)
##   (For ethnicity, "blank" means missing value)

## Prevalence of opioid prescribing - full population
prev_full <-
  merge(
    prev_any_full, prev_hi_full,
    by = c("population", "date", "region", "imdq10",
      "ethnicity", "carehome", "age_cat", "sex", "scd"),
    all = TRUE
  ) %>%
  replace_na(list(region = "All", imdq10 = -9, ethnicity = "All",
             carehome = -9, age_cat = -9, sex = "All", scd = -9)) %>%
  mutate(
    # Convert to integer to avoid scientific notation
    population = as.integer(population),
    opioid_any = as.integer(opioid_any),
    hi_opioid_any = as.integer(hi_opioid_any),

    # Sex
    sex = fct_case_when(
      sex == "All" ~ "All",
      sex == "F" ~ "Female",
      sex == "M" ~ "Male"),
    
    # Ethnicity
    ethnicity = ifelse(ethnicity == "", "Missing", ethnicity),
    
    # imdq10
    imdq10 = fct_case_when(
      imdq10 == -9 ~ "All",
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
      age_cat == -9 ~ "All",
      age_cat == 0 ~ "Missing",
      age_cat == 1 ~ "5-17 y",
      age_cat == 2 ~ "18-29 y",
      age_cat == 3 ~ "30-39 y",
      age_cat == 4 ~ "40-49 y",
      age_cat == 5 ~ "50-59 y",
      age_cat == 6 ~ "60-69 y",
      age_cat == 7 ~ "70-79 y",
      age_cat == 8 ~ "80-89 y",
      age_cat == 9 ~ "90+ y"
    ),
    
    #Carehome
    carehome = fct_case_when(
      carehome == -9 ~ "All",
      carehome == 0 ~ "No",
      carehome == 1 ~ "Yes"
    ),
    
    #Sickle cell
    scd = fct_case_when(
      scd == -9 ~ "All",
      scd == 0 ~ "No",
      scd == 1 ~ "Yes"
    )
)

head(prev_full)

## Prevalence of opioid prescribing - people without cancer
prev_nocancer <- 
  merge(
    prev_any_nocancer, prev_hi_nocancer,
    by = c("population", "date", "region", "imdq10", "ethnicity",
      "carehome", "age_cat", "sex", "scd"),
    all = TRUE
  ) %>%
  replace_na(list(region = "All", imdq10 = -9, ethnicity = "All",
    carehome = -9, age_cat = -9, sex = "All", scd = -9)) %>%
  mutate(
    # Convert to integer to avoid scientific notation
    population = as.integer(population),
    opioid_any = as.integer(opioid_any),
    hi_opioid_any = as.integer(hi_opioid_any),
    
    # Sex
    sex = fct_case_when(
      sex == "All" ~ "All",
      sex == "F" ~ "Female",
      sex == "M" ~ "Male"),
    
    # Ethnicity
    ethnicity = ifelse(ethnicity == "", "Missing", ethnicity),
    
    # imdq10
    imdq10 = fct_case_when(
      imdq10 == -9 ~ "All",
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
      age_cat == -9 ~ "All",
      age_cat == 0 ~ "Missing",
      age_cat == 1 ~ "5-17 y",
      age_cat == 2 ~ "18-29 y",
      age_cat == 3 ~ "30-39 y",
      age_cat == 4 ~ "40-49 y",
      age_cat == 5 ~ "50-59 y",
      age_cat == 6 ~ "60-69 y",
      age_cat == 7 ~ "70-79 y",
      age_cat == 8 ~ "80-89 y",
      age_cat == 9 ~ "90+ y"
    ),
    
    #Carehome
    carehome = fct_case_when(
      carehome == -9 ~ "All",
      carehome == 0 ~ "No",
      carehome == 1 ~ "Yes"
    ),
    
    #Sickle cell
    scd = fct_case_when(
      scd == -9 ~ "All",
      scd == 0 ~ "No",
      scd == 1 ~ "Yes"
    )
  )

head(prev_nocancer)

##############################################################
# Incidence datasets
##############################################################

# Combine data on incident opioid prescribing
new_any <- bind_rows(
  read.csv(here::here("output", "data", "measure_opioid_all_new.csv")),
  read.csv(here::here("output", "data", "measure_opioid_reg_new.csv")),
  read.csv(here::here("output", "data", "measure_opioid_imd_new.csv")),
  read.csv(here::here("output", "data", "measure_opioid_eth_new.csv")),
  read.csv(here::here("output", "data", "measure_opioid_care_new.csv")),
  read.csv(here::here("output", "data", "measure_opioid_scd_new.csv")),
  read.csv(here::here("output", "data", "measure_opioid_age_new.csv"))
  ) %>%
  mutate(date = as.Date(as.character(date), format = "%Y-%m-%d"))

## Create dataset for any incident opioid prescribing 
##    in full population (combine cancer/no cancer)
new_any_full <- new_any %>%
  group_by(date, region, imdq10, ethnicity, carehome, scd, age_cat, sex) %>%
  summarise(opioid_new = sum(opioid_new), opioid_naive = sum(opioid_naive)) %>%
  mutate(rate_any = opioid_new / opioid_naive)

## Create dataset for any incident opioid prescribing 
##    in people without cancer
new_any_nocancer <- new_any %>%
  subset(cancer == 0) %>%
  select(!cancer) %>%
  rename(rate_any = value) 

print(dim(new_any_full))
print(dim(new_any_nocancer))

##################################

# Combine data on incident high dose opioid prescribing
new_hi <- bind_rows(
  read.csv(here::here("output", "data", "measure_hi_opioid_all_new.csv")),
  read.csv(here::here("output", "data", "measure_hi_opioid_reg_new.csv")),
  read.csv(here::here("output", "data", "measure_hi_opioid_imd_new.csv")),
  read.csv(here::here("output", "data", "measure_hi_opioid_eth_new.csv")),
  read.csv(here::here("output", "data", "measure_hi_opioid_care_new.csv")),
  read.csv(here::here("output", "data", "measure_hi_opioid_scd_new.csv")),
  read.csv(here::here("output", "data", "measure_hi_opioid_age_new.csv"))
  ) %>% 
  mutate(date = as.Date(as.character(date), format = "%Y-%m-%d"))

## Create dataset for high dose incident opioid prescribing 
##   in full population (combine cancer/no cancer)
new_hi_full <- new_hi %>%
  group_by(date, region, imdq10, ethnicity, carehome, scd, age_cat, sex) %>%
  summarise(
    hi_opioid_new = sum(hi_opioid_new), 
    hi_opioid_naive = sum(hi_opioid_naive)
  ) %>%
  mutate(rate_hi = hi_opioid_new / hi_opioid_naive)

## Create dataset for high dose incident opioid prescribing 
##   in people without cancer only
new_hi_nocancer <- new_hi %>%
  subset(cancer == 0) %>%
  select(!cancer) %>%
  rename(rate_hi = value) 

print(dim(new_hi_full))
print(dim(new_hi_nocancer))

## Combine and replace NA values 
##   (Note: if value is NA, this is because it represents the 
##   full (not stratified) estimate)
##   (For ethnicity, "blank" means missing value)

## New opioid prescribing - full population
new_full <- 
  merge(
    new_any_full, new_hi_full,
    by = c("date", "region", "imdq10", "ethnicity",
      "carehome", "age_cat", "sex", "scd"),
    all = TRUE
  ) %>%
  replace_na(list(region = "All", imdq10 = -9, ethnicity = "All",
    carehome = -9, age_cat = -9, sex = "All", scd = -9)) %>%
  mutate(
    # Convert to integer to avoid scientific notation
    opioid_naive = as.integer(opioid_naive),
    hi_opioid_naive = as.integer(opioid_naive),
    opioid_new = as.integer(opioid_new),
    hi_opioid_new = as.integer(hi_opioid_new),
  
    # Sex
    sex = fct_case_when(
      sex == "All" ~ "All",
      sex == "F" ~ "Female",
      sex == "M" ~ "Male"),
    
    # Ethnicity
    ethnicity = ifelse(ethnicity == "", "Missing", ethnicity),
    
    # imdq10
    imdq10 = fct_case_when(
      imdq10 == -9 ~ "All",
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
      age_cat == -9 ~ "All",
      age_cat == 0 ~ "Missing",
      age_cat == 1 ~ "5-17 y",
      age_cat == 2 ~ "18-29 y",
      age_cat == 3 ~ "30-39 y",
      age_cat == 4 ~ "40-49 y",
      age_cat == 5 ~ "50-59 y",
      age_cat == 6 ~ "60-69 y",
      age_cat == 7 ~ "70-79 y",
      age_cat == 8 ~ "80-89 y",
      age_cat == 9 ~ "90+ y"
    ),
    
    #Carehome
    carehome = fct_case_when(
      carehome == -9 ~ "All",
      carehome == 0 ~ "No",
      carehome == 1 ~ "Yes"
    ),
    
    #Sickle cell
    scd = fct_case_when(
      scd == -9 ~ "All",
      scd == 0 ~ "No",
      scd == 1 ~ "Yes"
    )
  )

head(new_full)

## New opioid prescribing - no cancer
new_nocancer <- 
  merge(
    new_any_nocancer, new_hi_nocancer,
    by = c("date", "region", "imdq10", "ethnicity",
        "carehome", "age_cat", "sex", "scd"),
    all = TRUE
  ) %>%
  replace_na(list(region = "All", imdq10 = -9, ethnicity = "All",
                  carehome = -9, age_cat = -9, sex = "All", scd = -9)) %>%
  mutate(
    opioid_naive = as.integer(opioid_naive),
    hi_opioid_naive = as.integer(hi_opioid_naive),
    opioid_new = as.integer(opioid_new),
    hi_opioid_new = as.integer(hi_opioid_new),
    
    # Sex
    sex = fct_case_when(
      sex == "All" ~ "All",
      sex == "F" ~ "Female",
      sex == "M" ~ "Male"),
    
    # Ethnicity
    ethnicity = ifelse(ethnicity == "", "Missing", ethnicity),
    
    # imdq10
    imdq10 = fct_case_when(
      imdq10 == -9 ~ "All",
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
      age_cat == -9 ~ "All",
      age_cat == 0 ~ "Missing",
      age_cat == 1 ~ "5-17 y",
      age_cat == 2 ~ "18-29 y",
      age_cat == 3 ~ "30-39 y",
      age_cat == 4 ~ "40-49 y",
      age_cat == 5 ~ "50-59 y",
      age_cat == 6 ~ "60-69 y",
      age_cat == 7 ~ "70-79 y",
      age_cat == 8 ~ "80-89 y",
      age_cat == 9 ~ "90+ y"
    ),
    
    #Carehome
    carehome = fct_case_when(
      carehome == -9 ~ "All",
      carehome == 0 ~ "No",
      carehome == 1 ~ "Yes"
    ),
    
    #Sickle cell
    scd = fct_case_when(
      scd == -9 ~ "All",
      scd == 0 ~ "No",
      scd == 1 ~ "Yes"
    )
  )

head(new_nocancer)

###############################
## Sort and save as .csv
###############################

prev_full <- prev_full %>% 
  arrange(age_cat, sex, region, imdq10, ethnicity, carehome, scd, date)
write.csv(prev_full,file = here::here("output", "time series", "timeseries_prev_full.csv"))

prev_nocancer <- prev_nocancer %>% 
  arrange(age_cat, sex, region, imdq10, ethnicity, carehome, scd, date)
write.csv(prev_nocancer,file = here::here("output", "time series", "timeseries_prev_nocancer.csv"))

new_full <- new_full %>% 
  arrange(age_cat, sex, region, imdq10, ethnicity, carehome, scd, date)
write.csv(new_full,file = here::here("output", "time series", "timeseries_new_full.csv"))

new_nocancer <- new_nocancer %>% 
  arrange(age_cat, sex, region, imdq10, ethnicity, carehome, scd, date)
write.csv(new_nocancer,file = here::here("output", "time series", "timeseries_new_nocancer.csv"))

###############################
## Example graph to check
###############################

ggplot(subset(prev_full, !(sex %in% c("All", "Missing"))
              & !(age_cat %in% c("All", "Missing")))) +
  geom_line(aes(x = date, y=rate_any*10, col=age_cat, linetype=sex)) +
  geom_vline(xintercept = as.Date("2020-03-01"), col="gray70", linetype="longdash") +
  facet_wrap(~ age_cat) +
  scale_y_continuous(expand = c(.02,.02)) +
  ylab("People prescribed an opioid per\n1000 registered patients") +
  xlab("Month") +
  theme_bw() +
  theme(strip.background = element_blank(),
        strip.text = element_text(hjust = 0),
        axis.text.x = element_text(angle=45, hjust=1),
        legend.title = element_blank(),
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank()) +
  guides(color = "none")
  
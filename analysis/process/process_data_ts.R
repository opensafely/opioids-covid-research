######################################################
# This script:
# - imports data extracted by the cohort extractor
# - combines all datasets into one
# - formats variables as appropriate
# - saves processed dataset(s)
#
# Updated: 19 Jul 2023
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
dir_create(here::here("output", "timeseries"), showWarnings = FALSE, recurse = TRUE)
dir_create(here::here("output", "measures"), showWarnings = FALSE, recurse = TRUE)

# Custom functions
source(here("analysis", "lib", "custom_functions.R"))


###############################
# Clean up measures datasets  #
###############################

# Overall counts 
overall <- read_csv(here::here("output", "measures", "measures_overall.csv")) %>% 
  filter(str_detect(measure, "_nocancer", negate = TRUE)) %>%
  mutate(month = as.Date(interval_start, format="%Y-%m-%d"),
         period = ifelse(month < as.Date("2020-03-01"), "Pre-COVID", 
                         ifelse(month >= as.Date("2021-04-01"), "Recovery", "Lockdown"))) %>%
  dplyr::select(!c(interval_start, interval_end, ratio)) %>%
  pivot_wider(names_from = measure, values_from = c(numerator, denominator)) %>%
  rename(opioid_any = numerator_opioid_any,
         hi_opioid_any = numerator_hi_opioid_any,
         opioid_new = numerator_opioid_new,
         pop_total = denominator_opioid_any,
         pop_naive = denominator_opioid_new) %>%
  dplyr::select(!c(denominator_hi_opioid_any)) %>%
  mutate(pcent_new = opioid_new / opioid_any * 100,
         pcent_hi = hi_opioid_any / opioid_any,
         rate_opioid_any = (opioid_any / pop_total * 1000),
         rate_hi_opioid_any = (hi_opioid_any / pop_total * 1000),
         rate_opioid_new = (opioid_new / pop_naive * 1000))

write.csv(overall, file = here::here("output", "timeseries", "ts_overall.csv"),
          row.names = FALSE)


# Overall counts - without cancer
overall_noca <- read_csv(here::here("output", "measures", "measures_overall_nocancer.csv")) %>%
  filter(str_detect(measure, "_nocancer", negate = FALSE)) %>%
  mutate(month = as.Date(interval_start, format="%Y-%m-%d"),
         period = ifelse(month < as.Date("2020-03-01"), "Pre-COVID", 
                         ifelse(month >= as.Date("2021-04-01"), "Recovery", "Lockdown")),
         measure = gsub("_nocancer", "", measure)) %>%
  dplyr::select(!c(interval_start, interval_end, ratio)) %>%
  pivot_wider(names_from = measure, values_from = c(numerator, denominator)) %>%
  rename(opioid_any = numerator_opioid_any,
         hi_opioid_any = numerator_hi_opioid_any,
         opioid_new = numerator_opioid_new,
         pop_total = denominator_opioid_any,
         pop_naive = denominator_opioid_new) %>%
  dplyr::select(!c(denominator_hi_opioid_any)) %>%
  mutate(pcent_new = opioid_new / opioid_any * 100,
         pcent_hi = hi_opioid_any / opioid_any,
         rate_opioid_any = (opioid_any / pop_total * 1000),
         rate_hi_opioid_any = (hi_opioid_any / pop_total * 1000),
         rate_opioid_new = (opioid_new / pop_naive * 1000))

write.csv(overall_noca, file = here::here("output", "timeseries", "ts_overall_nocancer.csv"),
          row.names = FALSE)


# By demographics
## Prevalent 
demo_prev <- read_csv(here::here("output", "measures", "measures_demo_prev.csv")) %>%
  mutate(month = as.Date(interval_start, format="%Y-%m-%d"),
         period = ifelse(month < as.Date("2020-03-01"), "Pre-COVID", 
                         ifelse(month >= as.Date("2021-04-01"), "Recovery", "Lockdown")),
         cat = coalesce(age_group, sex, region, imd, ethnicity6),
         var = gsub("opioid_any_", "", measure),
         measure = substr(measure,1,10)) %>%
  dplyr::select(c(measure, month, cat, var, numerator, denominator, period)) %>%
  pivot_wider(names_from = measure, values_from = c(numerator, denominator)) %>%
  rename(opioid_any = numerator_opioid_any,
         pop_total = denominator_opioid_any) %>%
  mutate(rate_opioid_any = (opioid_any / pop_total * 1000))

## New
demo_new <- read_csv(here::here("output", "measures", "measures_demo_new.csv")) %>%
  mutate(month = as.Date(interval_start, format="%Y-%m-%d"),
         cat = coalesce(age_group, sex, region, imd, ethnicity6),
         var = gsub("opioid_new_", "", measure),
         measure = substr(measure,1,10)) %>%
  dplyr::select(c(measure, month, cat, var, numerator, denominator)) %>%
  pivot_wider(names_from = measure, values_from = c(numerator, denominator)) %>%
  rename(opioid_new = numerator_opioid_new,
         pop_naive = denominator_opioid_new) %>%
  mutate(rate_opioid_new = (opioid_new / pop_naive * 1000))

demo <- merge(demo_new, demo_prev, by.x = c("month", "cat", "var"),
              by.y = c("month",  "cat", "var"))

write.csv(demo, file = here::here("output", "timeseries", "ts_demo.csv"),
          row.names = FALSE)

# By admin route
type <- read_csv(here::here("output", "measures", "measures_type.csv")) %>%
  filter(str_detect(measure, "_nocancer", negate = TRUE)) %>%
  mutate(month = as.Date(interval_start, format="%Y-%m-%d"),
         period = ifelse(month < as.Date("2020-03-01"), "Pre-COVID", 
                         ifelse(month >= as.Date("2021-04-01"), "Recovery", "Lockdown")),
         measure = case_when(
           measure == "par_opioid" ~ "Parenteral",
           measure == "buc_opioid" ~ "Buccal",
           measure == "oral_opioid" ~ "Oral",
           measure == "trans_opioid" ~ "Transdermal",
           measure == "rec_opioid" ~ "Rectal",
           measure == "oth_opioid" ~ "Other",
           measure == "inh_opioid" ~ "Inhaled"
          ),
         rate_opioid_any = (numerator / denominator * 1000)) %>%
  rename(opioid_any = numerator, pop_total = denominator) %>%
  dplyr::select(!c(interval_start, interval_end, ratio)) 

write.csv(type, file = here::here("output", "timeseries", "ts_type.csv"),
          row.names = FALSE)

# # By admin route - without cancer
# type_noca <- read_csv(here::here("output", "measures", "measures_type.csv")) %>%
#   filter(str_detect(measure, "_nocancer", negate = FALSE)) %>%
#   mutate(month = as.Date(interval_start, format="%Y-%m-%d"),
#          period = ifelse(month < as.Date("2020-03-01"), "Pre-COVID", 
#                          ifelse(month >= as.Date("2021-04-01"), "Recovery", "Lockdown")),
#          measure = case_when(
#            measure == "par_opioid_nocancer" ~ "Parenteral",
#            measure == "buc_opioid_nocancer" ~ "Buccal",
#            measure == "oral_opioid_nocancer" ~ "Oral",
#            measure == "trans_opioid_nocancer" ~ "Transdermal",
#            measure == "rec_opioid_nocancer" ~ "Rectal",
#            measure == "oth_opioid_nocancer" ~ "Other",
#            measure == "inh_opioid_nocancer" ~ "Inhaled"
#          ),
#          rate_opioid_any = (numerator / denominator * 1000)) %>%
#   rename(opioid_any = numerator, pop_total = denominator) %>%
#   dplyr::select(!c(interval_start, interval_end, ratio)) 

# write.csv(type_noca, file = here::here("output", "timeseries", "ts_type_nocancer.csv"),
#           row.names = FALSE)


# In carehome
carehome <- read_csv(here::here("output", "measures", "measures_carehome.csv")) %>%
  filter(str_detect(measure, "carehome_age", negate = TRUE)) %>%
  mutate(month = as.Date(interval_start, format="%Y-%m-%d"),
         period = ifelse(month < as.Date("2020-03-01"), "Pre-COVID", 
                         ifelse(month >= as.Date("2021-04-01"), "Recovery", "Lockdown"))) %>%
  dplyr::select(!c(interval_start, interval_end, ratio, age_group, carehome)) %>%
  pivot_wider(names_from = measure, values_from = c(numerator, denominator)) %>%
  rename(opioid_any = numerator_opioid_any,
         hi_opioid_any = numerator_hi_opioid_any,
         opioid_new = numerator_opioid_new,
         oral_opioid_any = numerator_oral_opioid,
         trans_opioid_any = numerator_trans_opioid,
         par_opioid_any = numerator_par_opioid,
         
         pop_total = denominator_opioid_any,
         pop_naive = denominator_opioid_new) %>%
  dplyr::select(!c(denominator_hi_opioid_any, denominator_oral_opioid,
                   denominator_trans_opioid, denominator_par_opioid)) %>%
  mutate(pcent_new = opioid_new / opioid_any * 100,
         pcent_hi = hi_opioid_any / opioid_any,
         pcent_par = par_opioid_any / opioid_any,
         pcent_trans = trans_opioid_any / opioid_any,
         
         rate_opioid_any = (opioid_any / pop_total * 1000),
         rate_hi_opioid_any = (hi_opioid_any / pop_total * 1000),
         rate_opioid_new = (opioid_new / pop_total * 1000),
         rate_oral_opioid_any = (oral_opioid_any / pop_total * 1000),
         rate_trans_opioid_any = (trans_opioid_any / pop_total * 1000),
         rate_par_opioid_any = (par_opioid_any / pop_total * 1000))

write.csv(carehome, file = here::here("output", "timeseries", "ts_carehome.csv"),
          row.names = FALSE)


# In/not in carehome - sensitivity analysis 
carehome_sens <- read_csv(here::here("output", "measures", "measures_carehome.csv")) %>%
  filter(str_detect(measure, "_carehome_age", negate = FALSE)) %>%
  mutate(month = as.Date(interval_start, format="%Y-%m-%d"),
         period = ifelse(month < as.Date("2020-03-01"), "Pre-COVID", 
                         ifelse(month >= as.Date("2021-04-01"), "Recovery", "Lockdown")),
         carehome = if_else(carehome == T, "Yes", "No", "No"),
         measure = substr(measure, 1, 10),
         rate_opioid_any = (numerator / denominator * 1000)) %>%
  rename(opioid_any = numerator, pop_total = denominator) %>%
  dplyr::select(!c(interval_start, interval_end, ratio, measure)) 

write.csv(carehome_sens, file = here::here("output", "timeseries", "ts_carehome_sens.csv"),
          row.names = FALSE)



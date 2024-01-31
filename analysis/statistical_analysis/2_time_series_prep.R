#######################################################
# This script prepares data for interrupted time series analysis
#######################################################

# For running locally only #
# setwd("C:/Users/aschaffer/OneDrive - Nexus365/Documents/GitHub/opioids-covid-research")
# getwd()

library('tidyverse')
library('lubridate')
library('here')
library('reshape2')
library('dplyr')
library('fs')
library('ggplot2')
library('RColorBrewer')
library('TSA')
library('tseries')
library('forecast')
library('astsa')
library(MASS)
library(sandwich)
library(lmtest)

## Create directories
dir_create(here::here("output", "released_outputs", "final"), showWarnings = FALSE, recurse = TRUE)


## Read in data and calculate rates
overall <- read_csv(here::here("output", "released_outputs", "final", "ts_overall_rounded.csv"),
                      col_types = cols(month = col_date(format="%Y-%m-%d"))) %>%
  mutate(rate_opioid_any_round = opioid_any_round / pop_total_round * 1000,
         rate_opioid_new_round = opioid_new_round / pop_naive_round * 1000,
         rate_hi_opioid_round = hi_opioid_any_round / pop_total_round * 1000)

overall.nocancer <- read_csv(here::here("output", "released_outputs", "final", "ts_overall_nocancer_rounded.csv"),
                    col_types = cols(month = col_date(format="%Y-%m-%d"))) %>%
  mutate(rate_opioid_any_round = opioid_any_round / pop_total_round * 1000,
         rate_opioid_new_round = opioid_new_round / pop_naive_round * 1000,
         rate_hi_opioid_round = hi_opioid_any_round / pop_total_round * 1000)

demo <- read_csv(here::here("output", "released_outputs", "final", "ts_demo_rounded.csv"),
                    col_types = cols(month = col_date(format="%Y-%m-%d"))) %>%
  mutate(rate_opioid_any_round = opioid_any_round / pop_total_round * 1000,
         rate_opioid_new_round = opioid_new_round / pop_naive_round * 1000)

type <- read_csv(here::here("output", "released_outputs", "final", "ts_type_rounded.csv"),
                    col_types = cols(month = col_date(format="%Y-%m-%d"))) %>%
  mutate(rate_opioid_any_round = opioid_any_round / pop_total_round * 1000)

carehome <- read_csv(here::here("output", "released_outputs", "final", "ts_carehome_rounded.csv"),
                    col_types = cols(month = col_date(format="%Y-%m-%d"))) %>%
  mutate(rate_opioid_any_round = opioid_any_round / pop_total_round * 1000,
         rate_opioid_new_round = opioid_new_round / pop_naive_round * 1000,
         rate_hi_opioid_round = hi_opioid_any_round / pop_total_round * 1000,
         rate_trans_opioid_round = trans_opioid_any_round / pop_total_round * 1000,
         rate_par_opioid_round = par_opioid_any_round / pop_total_round * 1000,
         rate_oral_opioid_round = oral_opioid_any_round / pop_total_round * 1000)


## Create ITS variables
its.vars <- overall %>%
            dplyr::select(month) %>%
            mutate(mar20 = ifelse(month == as.Date("2020-03-01"), 1, 0),
                    apr20 = ifelse(month == as.Date("2020-04-01"), 1, 0),
                    may20 = ifelse(month == as.Date("2020-05-01"), 1, 0),
                    step = ifelse(month < as.Date("2020-03-01"), 0, 1),
                    step2 = ifelse(month < as.Date("2021-04-01"), 0, 1),
                    month_dummy = as.factor(month(month)),
                    time = seq(1, by = 1, length.out = nrow(overall)),
                    slope = ifelse(as.Date(month, format="%Y-%m-%d") < as.Date("2020-03-01"), 0, 
                                  time - sum(step == 0)),
                    slope2 = ifelse(as.Date(month, format="%Y-%m-%d") < as.Date("2021-04-01"), 0, 
                                   time - sum(step2 == 0)))

## Merge ITS vars into datasets and save

# Overall
overall.its <- overall %>% 
  arrange(month) %>% 
  merge(its.vars, by = "month")

write.csv(overall.its, file = here::here("output", "released_outputs", "final", "ts_overall_its.csv"),
          row.names = FALSE)

# People without cancer
overall.nocancer.its <- overall.nocancer %>% 
  arrange(month) %>% 
  merge(its.vars, by = "month")

write.csv(overall.nocancer.its, file = here::here("output", "released_outputs", "final", "ts_overall_nocancer_its.csv"),
          row.names = FALSE)

# By demographics
demo.its <- demo %>%
  arrange(month) %>%
  merge(its.vars, by = "month")

write.csv(demo.its, file = here::here("output", "released_outputs", "final", "ts_demo_its.csv"),
          row.names = FALSE)

# By opioid type
type.its <- type %>%
  arrange(month) %>%
  merge(its.vars, by = "month")

write.csv(type.its, file = here::here("output", "released_outputs", "final", "ts_type_its.csv"),
          row.names = FALSE)

# Peoplein care home
carehome.its <- carehome %>%
  arrange(month) %>%
  merge(its.vars, by = "month")

write.csv(carehome.its, file = here::here("output", "released_outputs", "final", "ts_carehome_its.csv"),
          row.names = FALSE)


#############################

# Check seasonality of data
ggseasonplot(ts(overall.its$opioid_any_round, start = c(2018,01), frequency = 12))
ggseasonplot(ts(overall.its$hi_opioid_any_round, start = c(2018,01), frequency = 12))
ggseasonplot(ts(overall.its$opioid_new_round, start = c(2018,01), frequency = 12))

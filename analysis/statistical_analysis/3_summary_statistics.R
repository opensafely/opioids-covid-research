#####################################################################
# This script calculates summary statistics for all 
#    relevant time series variables, 
#    both overall and by time period (pre-COVID, lockdown, recovery)
#
# Author: Andrea Schaffer 
#   Bennett Institute for Applied Data Science
#   University of Oxford, 2024
#####################################################################

# For running locally only #
# setwd("C:/Users/aschaffer/OneDrive - Nexus365/Documents/GitHub/opioids-covid-research")
# getwd()


library('tidyverse')
library('lubridate')
library('here')
library('fs')


## Create directories
dir_create(here::here("output", "released_outputs", "final"), showWarnings = FALSE, recurse = TRUE)


##########################

## Function to calculate median/IQR
options(scipen = 999)

stats <- function(data){
  
  quantile <- scales::percent(c(.25,.5,.75))
  
  byperiod <- data %>% 
    group_by(cat, var, period) %>%
    summarise_at(vars(-c(month)), list(p25 = ~quantile(., .25, na.rm=TRUE),
                                       p50 = ~quantile(., .5, na.rm=TRUE),
                                       p75 = ~quantile(., .75, na.rm=TRUE)))
  
  overall <- data %>% 
    group_by(cat, var) %>%
    summarise_at(vars(-c(month,period)),list(p25 = ~quantile(., .25, na.rm=TRUE),
                                             p50 = ~quantile(., .5, na.rm=TRUE),
                                             p75 = ~quantile(., .75, na.rm=TRUE))) %>%
    mutate(period = "Overall")
  
  stats <- rbind(byperiod, overall)
  
  return(stats)
}


#############################

## Read in data 

# Overall
overall <- read_csv(here::here("output", "released_outputs", "final", "ts_overall_its.csv"),
                      col_types = cols(month = col_date(format="%Y-%m-%d"))) %>%
  mutate(cat = "Overall", var = "Overall")

# People without cancer
overall_nocancer <- read_csv(here::here("output", "released_outputs", "final", "ts_overall_nocancer_its.csv"),
                    col_types = cols(month = col_date(format="%Y-%m-%d"))) %>%
  mutate(cat = "No cancer", var = "Overall")

# By demographics
demo <-  read_csv(here::here("output", "released_outputs", "final", "ts_demo_its.csv"),
                  col_types = cols(month = col_date(format="%Y-%m-%d"))) %>%
  mutate(cat = ifelse(is.na(cat), "Missing", cat))

# BY admin route
type <-  read_csv(here::here("output", "released_outputs", "final", "ts_type_its.csv"),
                  col_types = cols(month = col_date(format="%Y-%m-%d"))) %>%
  mutate(cat = measure, var = "Admin route") %>%
  dplyr::select(!measure)

# People in care home
carehome <-  read_csv(here::here("output", "released_outputs", "final", "ts_carehome_its.csv"),
                  col_types = cols(month = col_date(format="%Y-%m-%d"))) %>%
  mutate(cat = "Care home", var = "Care home")


################################


## Calculate summary statistics and save in one file
overall_stats <- stats(overall)
overall_nocancer_stats <- stats(overall_nocancer)
demo_stats <- stats(demo)
type_stats <- stats(type)
carehome_stats <- stats(carehome)

all_stats <- rbind(overall_stats, overall_nocancer_stats, demo_stats, type_stats, carehome_stats) %>%
  arrange( var, period, cat)

write.csv(all_stats, file = here::here("output", "released_outputs", "final", "summary_stats.csv"),
          row.names = FALSE)
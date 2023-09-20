#######################################################
#
# This script creates and save working datasets
#    and calculates summary statistics for all 
#    relevant variables in the study
#
#######################################################

# For running locally only #
setwd("C:/Users/aschaffer/OneDrive - Nexus365/Documents/GitHub/opioids-covid-research")
# getwd()


library('tidyverse')
library('lubridate')
library('arrow')
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

## Create directories
dir_create(here::here("output", "released_outputs"), showWarnings = FALSE, recurse = TRUE)
dir_create(here::here("output", "released_outputs", "final"), showWarnings = FALSE, recurse = TRUE)


##########################

## Calculate summary statistics

# Function for median/IQR
options(scipen = 999)

stats <- function(data){
  
  quantile <- scales::percent(c(.25,.5,.75))
  
  byperiod <- data %>% 
    group_by(cat, var, period) %>%
    summarise_at(vars(-c(month)), list(p25 = ~quantile(., .25, na.rm=TRUE),
                                       p50 = ~quantile(., .25, na.rm=TRUE),
                                       p75 = ~quantile(., .25, na.rm=TRUE)))
  
  overall <- data %>% 
    group_by(cat, var) %>%
    summarise_at(vars(-c(month,period)),list(p25 = ~quantile(., .25, na.rm=TRUE),
                                             p50 = ~quantile(., .25, na.rm=TRUE),
                                             p75 = ~quantile(., .25, na.rm=TRUE))) %>%
    mutate(period = "Overall")
  
  stats <- rbind(byperiod, overall)
  
  return(stats)
}



#############################

## Read in data 
overall <- read_csv(here::here("output", "released_outputs", "ts_overall_rounded.csv"),
                      col_types = cols(month = col_date(format="%Y-%m-%d"))) %>%
  mutate(cat = "Overall", var = "Overall") 

overall_nocancer <- read_csv(here::here("output", "released_outputs", "ts_overall_nocancer_rounded.csv"),
                    col_types = cols(month = col_date(format="%Y-%m-%d"))) %>%
  mutate(cat = "No cancer", var = "Overall") 

demo <-  read_csv(here::here("output", "released_outputs", "ts_demo_rounded.csv"),
                  col_types = cols(month = col_date(format="%Y-%m-%d")))

type <-  read_csv(here::here("output", "released_outputs", "ts_type_rounded.csv"),
                  col_types = cols(month = col_date(format="%Y-%m-%d"))) %>%
  mutate(cat = measure, var = "Admin route") %>%
  dplyr::select(!measure)

carehome <-  read_csv(here::here("output", "released_outputs", "ts_carehome_rounded.csv"),
                  col_types = cols(month = col_date(format="%Y-%m-%d"))) %>%
  mutate(cat = "Care home", var = "Care home") 


################################

## Calculate summary statistics
overall_stats <- stats(overall)
overall_nocancer_stats <- stats(overall_nocancer)
demo_stats <- stats(demo)
type_stats <- stats(type)
carehome_stats <- stats(carehome)

all_stats <- rbind(overall_stats, overall_nocancer_stats, demo_stats, type_stats, carehome_stats) %>%
  arrange(var, cat)


write.csv(all_stats, file = here::here("output", "released_outputs", "final", "summary_stats.csv"),
          row.names = FALSE)
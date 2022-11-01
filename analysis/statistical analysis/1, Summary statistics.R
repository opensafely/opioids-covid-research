
#######################################################
#
# This script creates time series graphs by subgroups
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


# Read in data and create working dataset
prev_full <- read_csv(here::here("output", "released_outputs", "ts_prev_full.csv"),
                      col_types = cols(
                        group  = col_character(),
                        label = col_character(),
                        date = col_date(format="%Y-%m-%d"))) %>% 
  mutate(period = ifelse(date < as.Date("2020-03-01"), "Pre-COVID", 
                         ifelse(date >= as.Date("2021-04-01"), "Recovery", "Lockdown")))


new_full <- read_csv(here::here("output", "released_outputs", "ts_new_full.csv"),
                     col_types = cols(
                       group  = col_character(),
                       label = col_character(),
                       date = col_date(format="%Y-%m-%d"))) %>%
  mutate(period = ifelse(date < as.Date("2020-03-01"), "Pre-COVID",
                          ifelse(date >= as.Date("2021-04-01"), "Recovery", "Lockdown")))

combined <- merge(prev_full, new_full, by = c("group", "label", "date", "period")) 

write.csv(combined, file = here::here("output", "released_outputs", "ts_combined_full.csv"),
          row.names = FALSE)


##############

# Calculate summary statistics

# Function for median/IQR
options(scipen = 999)
stats <- function(data, x){
  quantile <- scales::percent(c(.25,.5,.75))
  
  stats <- data %>% group_by(group, label, period) %>%
    summarise( p25 = quantile({{x}}, .25, na.rm = TRUE),
                      median = quantile({{x}}, .5, na.rm = TRUE),
                      p75 = quantile({{x}}, .75, na.rm = TRUE)) 
  return(stats)
}

stats_all <- rbind(
            stats(data = combined, x = prevalence_per_1000) %>% mutate(var = "Prevalence"),
            stats(data = combined, x = high_dose_prevalence_per_1000) %>% mutate(var = "High dose prevalence"),
            stats(data = combined, x = incidence_per_1000) %>% mutate(var = "Incidence"),
            stats(data = combined, x = total_population) %>% mutate(var = "Population"),
            stats(data = combined, x = opioid_naive) %>% mutate(var = "Opioid naive"),
            stats(data = combined, x = new_opioid_prescribing) %>% mutate(var = "Incidence (n)"),
            stats(data = combined, x = any_opioid_prescribing) %>% mutate(var = "Prevalence (n)"),
            stats(data = combined, x = any_high_dose_opioid_prescribing) %>% mutate(var = "High dose prevalence (n)"))


write.csv(stats_all, file = here::here("output", "released_outputs", "summary_stats.csv"),
          row.names = FALSE)



#####################

# Check for seasonality
ggseasonplot(ts(subset(combined, group == "Total")$prevalence_per_1000, start = c(2018,1), frequency=12))

# Check for seasonality
ggseasonplot(ts(subset(combined, group == "Total")$incidence_per_1000, start = c(2018,1), frequency=12))
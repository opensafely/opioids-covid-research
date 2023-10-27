
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

## Custom functions
source(here("analysis", "lib", "custom_functions.R"))

# Create directory
dir_create(here::here("output", "timeseries"), showWarnings = FALSE, recurse = TRUE)
dir_create(here::here("output", "measures"), showWarnings = FALSE, recurse = TRUE)


###############################
# Clean up measures datasets  #
###############################


dmd <- read_csv(here::here("output", "measures", "measures_test_6.csv")) %>%
  mutate(month = as.Date(interval_start, format="%Y-%m-%d"),
         period = ifelse(month < as.Date("2020-03-01"), "Pre-COVID",
                         ifelse(month >= as.Date("2021-04-01"), "Recovery", "Lockdown"))) %>%
  dplyr::select(!c(interval_start, interval_end, ratio)) %>%
  subset(!is.na(dmd_code)) %>%
  group_by(month, dmd_code) %>%
  summarise(count = sum(numerator)) %>%
  mutate(count = case_when(count> 10 ~ round(count / 7) * 7))

write.csv(dmd, file = here::here("output", "timeseries", "ts_dmd_diamorphine.csv"),
          row.names = FALSE)

ggplot(dmd) +
  geom_line(aes(x = month, y = count)) +
  facet_wrap(~ dmd_code, scales = "free_y") +
  theme_bw()

ggsave(here::here("output", "timeseries", "diamorphine_dmd.png"), height = 10,
       width = 10)
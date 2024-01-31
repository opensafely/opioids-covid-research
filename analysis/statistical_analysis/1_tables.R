#######################################################
# This script creates Table 1
#######################################################

# For running locally only #
# setwd("C:/Users/aschaffer/OneDrive - Nexus365/Documents/GitHub/opioids-covid-research")
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
dir_create(here::here("output", "released_outputs", "final"), showWarnings = FALSE, recurse = TRUE)


###########################

table_admin <- read_csv(here::here("output", "released_outputs", "final", "table_by_admin_route.csv"))

# Extract total population from table_admin
pop <- as.numeric(table_admin[1,2])

table <- read_csv(here::here("output", "released_outputs", "final", "table_full_population.csv")) %>%
  mutate(opioid_per_1000 = round(opioid_any_round / total_pop_round * 1000, 1),
         opioid_per_1000_std = round(opioid_any_std_round / uk_pop * 1000, 1),
         pcent_opioid = round(opioid_any_round / total_pop_round * 100, 1),
         pcent_tot = round(total_pop_round / pop * 100, 1),
         n_pcent = paste0(total_pop_round, " (", pcent_tot, ")"),
         n_opioid_pcent = paste0(opioid_any_round," (", pcent_opioid, ")"),) %>%
  dplyr::select(c(group, label, n_pcent, n_opioid_pcent, opioid_per_1000, opioid_per_1000_std))

table$label <- replace(table$label, is.na(table$label), "Missing")

write.csv(table, here::here("output", "released_outputs", "final", "table1.csv"))


##############################

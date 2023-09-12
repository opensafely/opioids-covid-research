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


# Rounding and redaction
rounding <- function(vars) {
  case_when(vars > 5 ~ round(vars / 7) * 7)
}

## Calculate rates

# Overall
overall_round <- read_csv(here::here("output", "timeseries", "ts_overall.csv")) %>%
  mutate(opioid_any_round = rounding(opioid_any),
         hi_opioid_any_round = rounding(hi_opioid_any),
         opioid_new_round = rounding(opioid_new),
         pop_total_round = rounding(pop_total),
         pop_naive_round = rounding(pop_naive),
         rate_opioid_any_round = (opioid_any_round / pop_total_round * 1000),
         rate_hi_opioid_any_round = (hi_opioid_any_round / pop_total_round * 1000),
         rate_opioid_new_round = (opioid_new_round / pop_naive_round * 1000))

write.csv(overall_round, here::here("output", "timeseries", "ts_overall_rounded.csv"),
          row.names = FALSE)

overall_nocancer_round <- read_csv(here::here("output", "timeseries", "ts_overall_nocancer.csv")) %>%
  mutate(opioid_any_round = rounding(opioid_any),
         hi_opioid_any_round = rounding(hi_opioid_any),
         opioid_new_round = rounding(opioid_new),
         pop_total_round = rounding(pop_total),
         pop_naive_round = rounding(pop_naive),
         rate_opioid_any_round = (opioid_any_round / pop_total_round * 1000),
         rate_hi_opioid_any_round = (hi_opioid_any_round / pop_total_round * 1000),
         rate_opioid_new_round = (opioid_new_round / pop_naive_round * 1000))

write.csv(overall_nocancer_round, here::here("output", "timeseries", "ts_overall_nocancer_rounded.csv"))

# By demographics
# demo_round <- read_csv(here::here("output", "timeseries", "ts_demo.csv")) %>%
#   mutate(opioid_any_round = rounding(opioid_any),
#          opioid_new_round = rounding(opioid_new),
#          pop_total_round = rounding(pop_total),
#          pop_naive_round = rounding(pop_naive),
#          rate_opioid_any_round = (opioid_any_round / pop_total_round * 1000),
#          rate_opioid_new_round = (opioid_new_round / pop_naive_round * 1000))

# write.csv(demo_round, here::here("output", "timeseries", "ts_demo_rounded.csv"))

# demo_nocancer_round <- read_csv(here::here("output", "timeseries", "ts_demo_nocancer.csv")) %>%
#   mutate(opioid_any_round = rounding(opioid_any),
#          opioid_new_round = rounding(opioid_new),
#          pop_total_round = rounding(pop_total),
#          pop_naive_round = rounding(pop_naive),
#          rate_opioid_any_round = (opioid_any_round / pop_total_round * 1000),
#          rate_opioid_new_round = (opioid_new_round / pop_naive_round * 1000))

# write.csv(demo_nocancer_round, here::here("output", "timeseries", "ts_demo_nocancer_rounded.csv"))

# By admin route
type_round <- read_csv(here::here("output", "timeseries", "ts_type.csv")) %>%
  mutate(opioid_any_round = rounding(opioid_any),
         pop_total_round = rounding(pop_total),
         rate_opioid_any_round = (opioid_any_round / pop_total_round * 1000))

write.csv(type_round, here::here("output", "timeseries", "ts_type_rounded.csv"))

type_nocancer_round <- read_csv(here::here("output", "timeseries", "ts_type_nocancer.csv")) %>%
  mutate(opioid_any_round = rounding(opioid_any),
         pop_total_round = rounding(pop_total),
         rate_opioid_any_round = (opioid_any_round / pop_total_round * 1000))

write.csv(type_nocancer_round, here::here("output", "timeseries", "ts_type_nocancer_rounded.csv"))


# IN care home
carehome_round <- read_csv(here::here("output", "timeseries", "ts_carehome.csv")) %>%
  mutate(opioid_any_round = rounding(opioid_any),
         hi_opioid_any_round = rounding(hi_opioid_any),
         opioid_new_round = rounding(opioid_new),
         trans_opioid_any_round = rounding(trans_opioid_any),
         par_opioid_any_round = rounding(par_opioid_any),
         oral_opioid_any_round = rounding(oral_opioid_any),
         
         pop_total_round = rounding(pop_total),
         pop_naive_round = rounding(pop_naive),
         
         rate_opioid_any_round = (opioid_any_round / pop_total_round * 1000),
         rate_hi_opioid_any_round = (hi_opioid_any_round / pop_total_round * 1000),
         rate_opioid_new_round = (opioid_new_round / pop_naive_round * 1000),
         rate_trans_opioid_any_round = (trans_opioid_any_round / pop_total_round * 1000),
         rate_par_opioid_any_round = (par_opioid_any_round / pop_total_round * 1000),
         rate_oral_opioid_any_round = (oral_opioid_any_round / pop_total_round * 1000))

write.csv(carehome_round, here::here("output", "timeseries", "ts_carehome_rounded.csv"))

# By care home (sensitivity analysis)
carehome_sens_round <- read_csv(here::here("output", "timeseries", "ts_carehome_sens.csv")) %>%
  mutate(opioid_any_round = rounding(opioid_any),
         pop_total_round = rounding(pop_total),
         rate_opioid_any_round = (opioid_any_round / pop_total_round * 1000))

write.csv(carehome_sens_round, here::here("output", "timeseries", "ts_carehome_sens_rounded.csv"))

##########################################################
# This script plots time series in secure environment to check for 
# errors or other issues (not for final publication)
#
# Author: Andrea Schaffer 
#   Bennett Institute for Applied Data Science
#   University of Oxford, 2024
##########################################################

## For running locally only
# setwd("C:/Users/aschaffer/OneDrive - Nexus365/Documents/GitHub/opioids-covid-research")
# getwd()

## Import libraries
library('tidyverse')
library('lubridate')
library('here')
library('dplyr')
library('ggplot2')
library('fs')

## Custom functions
source(here("analysis", "lib", "custom_functions.R"))

## Create directories if needed
dir_create(here::here("output", "timeseries"), showWarnings = FALSE, recurse = TRUE)
dir_create(here::here("output", "descriptive"), showWarnings = FALSE, recurse = TRUE)


## Read in data

# Overall 
overall.ts <- read_csv(here::here("output", "timeseries", "ts_overall_rounded.csv"),
                      col_types = cols(month = col_date(format = "%Y-%m-%d"))) %>%
                mutate(cat = "Overall", var = "Overall")

# People without a history of cancer
nocancer.ts <- read_csv(here::here("output", "timeseries", "ts_overall_nocancer_rounded.csv"),
                       col_types = cols(month = col_date(format = "%Y-%m-%d"))) %>%
                mutate(cat = "No cancer", var = "No cancer")
  
# By admin route
type.ts <- read_csv(here::here("output", "timeseries", "ts_type_rounded.csv"),
                      col_types = cols(month = col_date(format = "%Y-%m-%d"))) %>%
                mutate(var = "Admin route", cat = measure) %>%
                dplyr::select(!measure)

# People in care home
carehome.ts <- read_csv(here::here("output", "timeseries", "ts_carehome_rounded.csv"),
                    col_types = cols(month = col_date(format = "%Y-%m-%d"))) %>%
                mutate(cat = "Carehome", var = "Carehome")

# By demographics
demo.ts <- read_csv(here::here("output", "timeseries", "ts_demo_rounded.csv"),
                       col_types = cols(month = col_date(format = "%Y-%m-%d")))


######################################

# Function to create and save figures
fig <- function(data, subset, measure, suffix){
  
  graph <- ggplot(subset(data, var == subset), aes(x =month)) +
    geom_point(aes(y={{measure}}, col = cat), alpha = .5, size = .8, na.rm = TRUE) +
    geom_line(aes(y={{measure}}, col = cat), size = .5, na.rm = TRUE) +
    geom_vline(aes(xintercept = as.Date("2020-03-01")), linetype = "longdash", col = "black") +
    geom_vline(aes(xintercept = as.Date("2021-04-01")), linetype = "longdash", col = "black") +
    scale_y_continuous(expand = expansion(mult = c(0,.2), add = c(10,0))) +
    facet_wrap(~ cat, ncol = 2) +
    xlab(NULL) + ylab("Measure")+
    theme_bw() +
    theme(text = element_text(size=10),
          strip.background = element_blank(), 
          strip.text = element_text(hjust=0),
          axis.title.y = element_text(size=8),
          axis.text.x = element_text(angle=45, hjust=1),
          legend.title = element_blank(),
          legend.text = element_text(size=6),
          legend.key.size = unit(.4, "cm"),
          panel.grid.major.x = element_blank(),
          panel.grid.minor.x = element_blank(),
          panel.grid.major.y = element_line(color = "gray90"),
          legend.position = "none"
    ) +
    guides(colour = guide_legend(nrow = 2)) 
  
  ggsave(here::here("output", "descriptive", paste0("ts_plot_",suffix,".png")))
  
}

######################################


fig(overall.ts, "Overall", opioid_any_round, "overall_any")
fig(overall.ts, "Overall", opioid_new_round, "overall_new")
fig(overall.ts, "Overall", hi_opioid_any_round, "overall_hi")
fig(overall.ts, "Overall", pop_total_round, "overall_pop")
fig(overall.ts, "Overall", pop_naive_round, "overall_naive")

fig(type.ts, "Admin route", opioid_any_round, "type_any")
fig(type.ts, "Admin route", pop_total_round, "type_pop")

fig(demo.ts, "age", opioid_any_round, "age_any")
fig(demo.ts, "age", opioid_new_round, "age_new")
fig(demo.ts, "age", pop_total_round, "age_pop")
fig(demo.ts, "age", pop_naive_round, "age_naive")

fig(demo.ts, "eth6", opioid_any_round, "eth6_any")
fig(demo.ts, "eth6", opioid_new_round, "eth6_new")
fig(demo.ts, "eth6", pop_total_round, "eth6_pop")
fig(demo.ts, "eth6", pop_naive_round, "eth6_naive")

fig(demo.ts, "region", opioid_any_round, "region_any")
fig(demo.ts, "region", opioid_new_round, "region_new")
fig(demo.ts, "region", pop_total_round, "region_pop")
fig(demo.ts, "region", pop_naive_round, "region_naive")

fig(demo.ts, "imd", opioid_any_round, "imd_any")
fig(demo.ts, "imd", opioid_new_round, "imd_new")
fig(demo.ts, "imd", pop_total_round, "imd_pop")
fig(demo.ts, "imd", pop_naive_round, "imd_naive")

fig(demo.ts, "sex", opioid_any_round, "sex_any")
fig(demo.ts, "sex", opioid_new_round, "sex_new")
fig(demo.ts, "sex", pop_total_round, "sex_pop")
fig(demo.ts, "sex", pop_naive_round, "sex_naive")

fig(carehome.ts, "Carehome", opioid_any_round, "carehome_any")
fig(carehome.ts, "Carehome", opioid_new_round, "carehome_new")
fig(carehome.ts, "Carehome", hi_opioid_any_round, "carehome_hi")
fig(carehome.ts, "Carehome", trans_opioid_any_round, "carehome_trans")
fig(carehome.ts, "Carehome", par_opioid_any_round, "carehome_par")
fig(carehome.ts, "Carehome", oral_opioid_any_round, "carehome_oral")
fig(carehome.ts, "Carehome", pop_total_round, "carehome_pop")
fig(carehome.ts, "Carehome", pop_naive_round, "carehome_naive")

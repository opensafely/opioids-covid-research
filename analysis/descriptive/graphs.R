#######################################################
#
# This script creates time series graphs by subgroups
#
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

## Create directories
dir_create(here::here("output", "time series"), showWarnings = FALSE, recurse = TRUE)
dir_create(here::here("output", "time series", "graphs"), showWarnings = FALSE, recurse = TRUE)


# Read in data
prev_full <- read_csv(here::here("output", "time series", "ts_prev_full.csv"),
                    col_types = cols(
                      group  = col_character(),
                      label = col_character(),
                      sex = col_character(),
                      date = col_date(format="%Y-%m-%d")))

prev_nocancer <- read_csv(here::here("output", "time series", "ts_prev_nocancer.csv"),
                   col_types = cols(
                     group  = col_character(),
                     label = col_character(),
                     sex = col_character(),
                     date = col_date(format="%Y-%m-%d")))

new_full <- read_csv(here::here("output", "time series", "ts_new_full.csv"),
                      col_types = cols(
                        group  = col_character(),
                        label = col_character(),
                        sex = col_character(),
                        date = col_date(format="%Y-%m-%d")))

new_nocancer <- read_csv(here::here("output",  "time series", "ts_new_nocancer.csv"),
                          col_types = cols(
                            group  = col_character(),
                            label = col_character(),
                            sex = col_character(),
                            date = col_date(format="%Y-%m-%d")))


###############################
# Create list of colours
##############################

pal24 <- c("#A6CEE3", "#1F78B4", "#B2DF8A", "#33A02C", "#FB9A99", "#E31A1C",
             "#FDBF6F", "#FF7F00", "#CAB2D6", "#6A3D9A", "#FFFF99", "#B15928",
             "#8DD3C7", "#FFFFB3", "#BEBADA", "#FB8072", "#80B1D3", "#FDB462",
             "#B3DE69", "#FCCDE5", "#D9D9D9", "#BC80BD", "#CCEBC5", "#FFED6F")


##############################
## Graphs to check
###############################

# Custom function
line_graph <- function(data, y){
  
  graph <-  ggplot() +
    geom_line(data = subset(data, !(label %in% c("Missing", "Unknown"))), 
                            aes(x = date, y = {{y}} , col = label)) +
    geom_vline(xintercept = as.Date("2020-03-01"), col = "gray70",
               linetype = "longdash") +
                   geom_vline(xintercept = as.Date("2020-11-01"), col = "gray70",
               linetype = "longdash") +
    geom_vline(xintercept = as.Date("2021-01-01"), col = "gray70",
               linetype = "longdash") +
    scale_color_manual(values =  pal24) +
    scale_y_continuous(expand = c(.1,0)) +
    ylab("People prescribed an opioid per\n1000 registered patients") +
    xlab("Month") +
    theme_bw() +
    theme(
      strip.background = element_blank(),
      strip.text = element_text(hjust = 0),
      axis.text.x = element_text(angle = 45, hjust = 1),
      legend.title = element_blank(),
      panel.grid.major.x = element_blank(),
      panel.grid.minor.x = element_blank()
    ) 
  return(graph)
}

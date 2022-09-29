#######################################################
#
# This script creates time series graphs by subgroups
#
#######################################################


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
dir_create(here::here("output", "kids", "time series"), showWarnings = FALSE, recurse = TRUE)
dir_create(here::here("output", "kids", "time series", "graphs"), showWarnings = FALSE, recurse = TRUE)


# Read in data
prev_full <- read_csv(here::here("output", "kids", "time series", "ts_prev_full_kids.csv"),
                    col_types = cols(
                      region  = col_character(),
                      imdq10 = col_character(),
                      ethnicity  = col_character(),
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
line_graph <- function(data, y, gp){
  
  graph <-  ggplot() +
    geom_line(data = data, aes(x = date, y = {{y}} , col = {{gp}})) +
    geom_vline(xintercept = as.Date("2020-03-01"), col = "gray70",
               linetype = "longdash") +
                   geom_vline(xintercept = as.Date("2020-11-01"), col = "gray70",
               linetype = "longdash") +
    geom_vline(xintercept = as.Date("2021-01-01"), col = "gray70",
               linetype = "longdash") +
    scale_color_manual(values =  pal24) +
    scale_y_continuous(expand = c(.1,0)) +
    ylab("People prescribed an opioid per\n1000 registered children") +
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


######################################
# Full population
######################################

# Prevalence by age/sex
line_graph(subset(prev_full, (sex %in% c("Male", "Female"))), prev_rate, sex) 

ggsave(filename = here::here("output/kids/time series/graphs/graph_kids_prev_sex.png"),
       width = 8, height = 4, unit = "in", dpi = 300)

####

# Prevalence by IMD
line_graph(subset(prev_full, !(imdq10 %in% c("Missing",NA))), prev_rate, imdq10) 

ggsave(filename = here::here("output/kids/time series/graphs/graph_kids_prev_imd.png"),
       width = 6, height = 4, unit = "in", dpi = 300)



####

# Prevalence by ethnicity
line_graph(subset(prev_full, !(ethnicity %in% c("Missing",NA))), prev_rate, ethnicity) 

ggsave(filename = here::here("output/kids/time series/graphs/graph_kids_prev_eth.png"),
       width = 6, height = 4, unit = "in", dpi = 300)


####

# Prevalence by region
line_graph(subset(prev_full, !(region %in% c("Missing",NA))), prev_rate, region) 

ggsave(filename = here::here("output/kids/time series/graphs/graph_kids_prev_region.png"),
       width = 6, height = 4, unit = "in", dpi = 300)


####


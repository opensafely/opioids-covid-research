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
dir_create(here::here("output", "time series"), showWarnings = FALSE, recurse = TRUE)

# Read in data
prev_full <- read_csv(here::here("output", "time series", "timeseries_prev_full.csv"),
                    col_types = cols(
                      region  = col_character(),
                      imdq10 = col_character(),
                      ethnicity  = col_character(),
                      carehome  = col_character(),
                      age_cat  = col_character(),
                      sex = col_character(),
                      date = col_date(format="%Y-%m-%d")))

prev_nocancer <- read_csv(here::here("output", "time series", "timeseries_prev_nocancer.csv"),
                   col_types = cols(
                     region  = col_character(),
                     imdq10= col_character(),
                     ethnicity  = col_character(),
                     carehome  = col_character(),
                     age_cat  = col_character(),
                     sex = col_character(),
                     date = col_date(format="%Y-%m-%d")))

new_full <- read_csv(here::here("output", "time series", "timeseries_new_full.csv"),
                      col_types = cols(
                        region  = col_character(),
                        imdq10 = col_character(),
                        ethnicity  = col_character(),
                        carehome  = col_character(),
                        age_cat  = col_character(),
                        sex = col_character(),
                        date = col_date(format="%Y-%m-%d")))

new_nocancer <- read_csv(here::here("output", "time series", "timeseries_new_nocancer.csv"),
                          col_types = cols(
                            region  = col_character(),
                            imdq10= col_character(),
                            ethnicity  = col_character(),
                            carehome  = col_character(),
                            age_cat  = col_character(),
                            sex = col_character(),
                            date = col_date(format="%Y-%m-%d")))

##############################
## Graphs to check
###############################

# Custom function
line_graph <- function(data, y, gp){
  
  graph <-  ggplot() +
    geom_line(data = data, aes(x = date, y = {{y}} , col = {{gp}})) +
    geom_vline(xintercept = as.Date("2020-03-01"), col = "gray70",
               linetype = "longdash") +
    scale_color_brewer(palette =  "Paired") +
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

# Prevalence by age/sex
line_graph(subset(prev_nocancer, (sex %in% c("Male", "Female"))
                    & !(age_cat %in% c("Missing"))), prev_rate, age_cat) +
  facet_wrap(~ sex, scales = "free_y")

ggsave(filename = here::here("output/time series/graph_prev_age.png"),
       width = 8, height = 4, unit = "in", dpi = 300)

# Prevalence of high dose opioids by age/sex
line_graph(subset(prev_nocancer, (sex %in% c("Male", "Female"))
                    & !(age_cat %in% c("Missing"))), prev_hi_rate, age_cat) +
  facet_wrap(~ sex, scales = "free_y")

ggsave(filename = here::here("output/time series/graph_prev_hi_age.png"),
       width = 8, height = 4, unit = "in", dpi = 300)

# Incidence by age/sex
line_graph(subset(new_nocancer, (sex %in% c("Male", "Female"))
                    & !(age_cat %in% c("Missing"))), new_rate, age_cat) +
  facet_wrap(~ sex, scales = "free_y")

ggsave(filename = here::here("output/time series/graph_new_age.png"),
       width = 8, height = 4, unit = "in", dpi = 300)

# Incidence of high dose opioids by age/sex
line_graph(subset(new_nocancer, (sex %in% c("Male", "Female"))
                    & !(age_cat %in% c("Missing"))), new_hi_rate, age_cat) +
  facet_wrap(~ sex, scales = "free_y")

ggsave(filename = here::here("output/time series/graph_new_hi_age.png"),
       width = 8, height = 4, unit = "in", dpi = 300)


# Prevalence by IMD
line_graph(subset(prev_nocancer, !(imdq10 %in% c("Missing",NA))), prev_rate, imdq10) 

ggsave(filename = here::here("output/time series/graph_prev_imd.png"),
       width = 6, height = 4, unit = "in", dpi = 300)

# Prevalence (high dose) by IMD
line_graph(subset(prev_nocancer, !(imdq10 %in% c("Missing",NA))), prev_hi_rate, imdq10) 

ggsave(filename = here::here("output/time series/graph_prev_hi_imd.png"),
       width = 6, height = 4, unit = "in", dpi = 300)

# Incidence by IMD
line_graph(subset(new_nocancer, !(imdq10 %in% c("Missing",NA))), new_rate, imdq10) 

ggsave(filename = here::here("output/time series/graph_new_imd.png"),
       width = 6, height = 4, unit = "in", dpi = 300)

# Incidence (high dose) by IMD
line_graph(subset(new_nocancer, !(imdq10 %in% c("Missing",NA))), new_hi_rate, imdq10) 

ggsave(filename = here::here("output/time series/graph_new_hi_imd.png"),
      width = 6, height = 4, unit = "in", dpi = 300)


# Prevalence by ethnicity
line_graph(subset(prev_nocancer, !(ethnicity %in% c("Missing",NA))), prev_rate, ethnicity) 

ggsave(filename = here::here("output/time series/graph_prev_eth.png"),
      width = 6, height = 4, unit = "in", dpi = 300)

# Prevalence (high dose) by eth
line_graph(subset(prev_nocancer, !(ethnicity %in% c("Missing",NA))), prev_hi_rate, ethnicity) 

ggsave(filename = here::here("output/time series/graph_prev_hi_eth.png"),
       width = 6, height = 4, unit = "in", dpi = 300)

# Incidence by eth
line_graph(subset(new_nocancer, !(ethnicity %in% c("Missing",NA))), new_rate, ethnicity) 

ggsave(filename = here::here("output/time series/graph_new_eth.png"),
       width = 6, height = 4, unit = "in", dpi = 300)

# Incidence (high dose) by eth
line_graph(subset(new_nocancer, !(ethnicity %in% c("Missing",NA))), new_hi_rate, ethnicity) 

ggsave(filename = here::here("output/time series/graph_new_hi_eth.png"),
       width = 6, height = 4, unit = "in", dpi = 300)



# Prevalence by region
line_graph(subset(prev_nocancer, !(region %in% c("Missing",NA))), prev_rate, region) 

ggsave(filename = here::here("output/time series/graph_prev_region.png"),
       width = 6, height = 4, unit = "in", dpi = 300)

# Prevalence (high dose) by region
line_graph(subset(prev_nocancer, !(region %in% c("Missing",NA))), prev_hi_rate, region) 

ggsave(filename = here::here("output/time series/graph_prev_hi_region.png"),
       width = 6, height = 4, unit = "in", dpi = 300)

# Incidence by region
line_graph(subset(new_nocancer, !(region %in% c("Missing",NA))), new_rate, region) 

ggsave(filename = here::here("output/time series/graph_new_region.png"),
       width = 6, height = 4, unit = "in", dpi = 300)

# Incidence (high dose) by region
line_graph(subset(new_nocancer, !(region %in% c("Missing",NA))), new_hi_rate, region) 

ggsave(filename = here::here("output/time series/graph_new_hi_region.png"),
       width = 6, height = 4, unit = "in", dpi = 300)

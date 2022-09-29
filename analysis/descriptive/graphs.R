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

new_nocancer <- read_csv(here::here("output", "time series", "ts_new_nocancer.csv"),
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


######################################
# No cancer 
######################################

# Prevalence by age/sex
line_graph(subset(prev_nocancer, group == "Age"), prev_rate) +
  facet_wrap(~ sex, scales = "free_y")

ggsave(filename = here::here("output/time series/graphs/graph_noca_prev_age.png"),
       width = 8, height = 4, unit = "in", dpi = 300)

# Prevalence of high dose opioids by age/sex
line_graph(subset(prev_nocancer, group == "Age"), prev_hi_rate) +
  facet_wrap(~ sex, scales = "free_y")

ggsave(filename = here::here("output/time series/graphs/graph_noca_prev_hi_age.png"),
       width = 8, height = 4, unit = "in", dpi = 300)

# Incidence by age/sex
line_graph(subset(new_nocancer, group == "Age"), new_rate) +
  facet_wrap(~ sex, scales = "free_y")

ggsave(filename = here::here("output/time series/graphs/graph_noca_new_age.png"),
       width = 8, height = 4, unit = "in", dpi = 300)

# Incidence of high dose opioids by age/sex
#line_graph(subset(new_nocancer, (sex %in% c("Male", "Female"))
#                    & !(age_cat %in% c("Missing"))), new_hi_rate, age_cat) +
#  facet_wrap(~ sex, scales = "free_y")

#ggsave(filename = here::here("output/time series/graphs/graph_noca_new_hi_age.png"),
#      width = 8, height = 4, unit = "in", dpi = 300)

####

# Prevalence by IMD
line_graph(subset(prev_nocancer, group == "IMD decile"), prev_rate) 

ggsave(filename = here::here("output/time series/graphs/graph_noca_prev_imd.png"),
       width = 6, height = 4, unit = "in", dpi = 300)

# Prevalence (high dose) by IMD
line_graph(subset(prev_nocancer, group == "IMD decile"), prev_hi_rate) 

ggsave(filename = here::here("output/time series/graphs/graph_noca_prev_hi_imd.png"),
       width = 6, height = 4, unit = "in", dpi = 300)

# Incidence by IMD
line_graph(subset(new_nocancer, group == "IMD decile"), new_rate) 

ggsave(filename = here::here("output/time series/graphs/graph_noca_new_imd.png"),
       width = 6, height = 4, unit = "in", dpi = 300)

# Incidence (high dose) by IMD
#line_graph(subset(new_nocancer, !(imdq10 %in% c("Missing",NA))), new_hi_rate, imdq10) 

#ggsave(filename = here::here("output/time series/graphs/graph_noca_new_hi_imd.png"),
#      width = 6, height = 4, unit = "in", dpi = 300)

####

# Prevalence by ethnicity
line_graph(subset(prev_nocancer, group == "Ethnicity"), prev_rate) 

ggsave(filename = here::here("output/time series/graphs/graph_noca_prev_eth.png"),
      width = 6, height = 4, unit = "in", dpi = 300)

# Prevalence (high dose) by eth
line_graph(subset(prev_nocancer, group == "Ethnicity"), prev_hi_rate) 

ggsave(filename = here::here("output/time series/graphs/graph_noca_prev_hi_eth.png"),
       width = 6, height = 4, unit = "in", dpi = 300)

# Incidence by eth
line_graph(subset(new_nocancer, group == "Ethnicity"), new_rate)

ggsave(filename = here::here("output/time series/graphs/graph_noca_new_eth.png"),
       width = 6, height = 4, unit = "in", dpi = 300)

# Incidence (high dose) by eth
#line_graph(subset(new_nocancer, !(ethnicity %in% c("Missing",NA))), new_hi_rate, ethnicity) 

#ggsave(filename = here::here("output/time series/graphs/graph_noca_new_hi_eth.png"),
#       width = 6, height = 4, unit = "in", dpi = 300)

####

# Prevalence by region
line_graph(subset(prev_nocancer, group == "Region"), prev_rate) 

ggsave(filename = here::here("output/time series/graphs/graph_noca_prev_region.png"),
       width = 6, height = 4, unit = "in", dpi = 300)

# Prevalence (high dose) by region
line_graph(subset(prev_nocancer, group == "Region"), prev_hi_rate) 

ggsave(filename = here::here("output/time series/graphs/graph_noca_prev_hi_region.png"),
       width = 6, height = 4, unit = "in", dpi = 300)

# Incidence by region
line_graph(subset(new_nocancer, group == "Region"), new_rate) 

ggsave(filename = here::here("output/time series/graphs/graph_noca_new_region.png"),
       width = 6, height = 4, unit = "in", dpi = 300)

# Incidence (high dose) by region
#line_graph(subset(new_nocancer, !(region %in% c("Missing",NA))), new_hi_rate, region) 

#ggsave(filename = here::here("output/time series/graphs/graph_noca_new_hi_region.png"),
#       width = 6, height = 4, unit = "in", dpi = 300)

####

# Prevalence by carehome
line_graph(subset(prev_nocancer, group == "Care home" & label == "Yes"), prev_rate) 

ggsave(filename = here::here("output/time series/graphs/graph_noca_prev_carehome.png"),
       width = 6, height = 4, unit = "in", dpi = 300)

# Prevalence (high dose) by carehome
line_graph(subset(prev_nocancer, group == "Care home" & label == "Yes"), prev_hi_rate) 

ggsave(filename = here::here("output/time series/graphs/graph_noca_prev_hi_carehome.png"),
       width = 6, height = 4, unit = "in", dpi = 300)

# Incidence by carehome
line_graph(subset(new_nocancer, group == "Care home" & label == "Yes"), new_rate) 

ggsave(filename = here::here("output/time series/graphs/graph_noca_new_carehome.png"),
       width = 6, height = 4, unit = "in", dpi = 300)

# Incidence (high dose) by carehome
#line_graph(subset(new_nocancer, (carehome == "Yes")), new_hi_rate, carehome) 

#ggsave(filename = here::here("output/time series/graphs/graph_noca_new_hi_carehome.png"),
#       width = 6, height = 4, unit = "in", dpi = 300)


######################################
# Full population
######################################

# Prevalence by age/sex
line_graph(subset(prev_full, group == "Age"), prev_rate) +
  facet_wrap(~ sex, scales = "free_y")

ggsave(filename = here::here("output/time series/graphs/graph_prev_age.png"),
       width = 8, height = 4, unit = "in", dpi = 300)

# Prevalence of high dose opioids by age/sex
line_graph(subset(prev_full, group == "Age"), prev_hi_rate) +
  facet_wrap(~ sex, scales = "free_y")

ggsave(filename = here::here("output/time series/graphs/graph_prev_hi_age.png"),
       width = 8, height = 4, unit = "in", dpi = 300)

# Incidence by age/sex
line_graph(subset(new_full, group == "Age"), new_rate) +
  facet_wrap(~ sex, scales = "free_y")

ggsave(filename = here::here("output/time series/graphs/graph_new_age.png"),
       width = 8, height = 4, unit = "in", dpi = 300)

# Incidence of high dose opioids by age/sex
#line_graph(subset(new_full, (sex %in% c("Male", "Female"))
#                  & !(age_cat %in% c("Missing"))), new_hi_rate, age_cat) +
#  facet_wrap(~ sex, scales = "free_y")

#ggsave(filename = here::here("output/time series/graphs/graph_new_hi_age.png"),
#       width = 8, height = 4, unit = "in", dpi = 300)

####

# Prevalence by IMD
line_graph(subset(prev_full, group == "IMD decile"), prev_rate) 

ggsave(filename = here::here("output/time series/graphs/graph_prev_imd.png"),
       width = 6, height = 4, unit = "in", dpi = 300)

# Prevalence (high dose) by IMD
line_graph(subset(prev_full, group == "IMD decile"), prev_hi_rate) 

ggsave(filename = here::here("output/time series/graphs/graph_prev_hi_imd.png"),
       width = 6, height = 4, unit = "in", dpi = 300)

# Incidence by IMD
line_graph(subset(new_full, group == "IMD decile"), new_rate) 

ggsave(filename = here::here("output/time series/graphs/graph_new_imd.png"),
       width = 6, height = 4, unit = "in", dpi = 300)

# Incidence (high dose) by IMD
#line_graph(subset(new_full, !(imdq10 %in% c("Missing",NA))), new_hi_rate, imdq10) 

#ggsave(filename = here::here("output/time series/graphs/graph_new_hi_imd.png"),
#       width = 6, height = 4, unit = "in", dpi = 300)

####

# Prevalence by ethnicity
line_graph(subset(prev_full, group == "Ethnicity"), prev_rate) 

ggsave(filename = here::here("output/time series/graphs/graph_prev_eth.png"),
       width = 6, height = 4, unit = "in", dpi = 300)

# Prevalence (high dose) by eth
line_graph(subset(prev_full, group == "Ethnicity"), prev_hi_rate) 

ggsave(filename = here::here("output/time series/graphs/graph_prev_hi_eth.png"),
       width = 6, height = 4, unit = "in", dpi = 300)

# Incidence by eth
line_graph(subset(new_full, group == "Ethnicity"), new_rate) 

ggsave(filename = here::here("output/time series/graphs/graph_new_eth.png"),
       width = 6, height = 4, unit = "in", dpi = 300)

# Incidence (high dose) by eth
#line_graph(subset(new_full, !(ethnicity %in% c("Missing",NA))), new_hi_rate, ethnicity) 

#ggsave(filename = here::here("output/time series/graphs/graph_new_hi_eth.png"),
#       width = 6, height = 4, unit = "in", dpi = 300)

####

# Prevalence by region
line_graph(subset(prev_full, group == "Region"), prev_rate) 

ggsave(filename = here::here("output/time series/graphs/graph_prev_region.png"),
       width = 6, height = 4, unit = "in", dpi = 300)

# Prevalence (high dose) by region
line_graph(subset(prev_full, group == "Region"), prev_hi_rate) 

ggsave(filename = here::here("output/time series/graphs/graph_prev_hi_region.png"),
       width = 6, height = 4, unit = "in", dpi = 300)

# Incidence by region
line_graph(subset(new_full,  group == "Region"), new_rate) 

ggsave(filename = here::here("output/time series/graphs/graph_new_region.png"),
       width = 6, height = 4, unit = "in", dpi = 300)

# Incidence (high dose) by region
#line_graph(subset(new_full, !(region %in% c("Missing",NA))), new_hi_rate, region) 

#ggsave(filename = here::here("output/time series/graphs/graph_new_hi_region.png"),
#       width = 6, height = 4, unit = "in", dpi = 300)

####

# Prevalence by carehome
line_graph(subset(prev_full, group == "Care home" & label == "Yes"), prev_rate) 

ggsave(filename = here::here("output/time series/graphs/graph_prev_carehome.png"),
       width = 6, height = 4, unit = "in", dpi = 300)

# Prevalence (high dose) by carehome
line_graph(subset(prev_full, group == "Care home" & label == "Yes"), prev_hi_rate) 

ggsave(filename = here::here("output/time series/graphs/graph_prev_hi_carehome.png"),
       width = 6, height = 4, unit = "in", dpi = 300)

# Incidence by carehome
line_graph(subset(new_full, group == "Care home" & label == "Yes"), new_rate) 

ggsave(filename = here::here("output/time series/graphs/graph_new_carehome.png"),
       width = 6, height = 4, unit = "in", dpi = 300)

# Incidence (high dose) by carehome
#line_graph(subset(new_full, (carehome == "Yes")), new_hi_rate, carehome) 

#ggsave(filename = here::here("output/time series/graphs/graph_new_hi_carehome.png"),
#       width = 6, height = 4, unit = "in", dpi = 300)


####

# Prevalence by scd
line_graph(subset(prev_full, group == "SCD" & label == "Yes"), prev_rate) 

ggsave(filename = here::here("output/time series/graphs/graph_prev_scd.png"),
       width = 6, height = 4, unit = "in", dpi = 300)

# Prevalence (high dose) by scd
#line_graph(subset(prev_full, (scd == "Yes")), prev_hi_rate, scd) 

#ggsave(filename = here::here("output/time series/graphs/graph_prev_hi_scd.png"),
#       width = 6, height = 4, unit = "in", dpi = 300)

# Incidence by scd
#line_graph(subset(new_full, (scd == "Yes")), new_rate, scd) 

#ggsave(filename = here::here("output/time series/graphs/graph_new_scd.png"),
#       width = 6, height = 4, unit = "in", dpi = 300)

# Incidence (high dose) by scd
#line_graph(subset(new_full, (scd == "Yes")), new_hi_rate, scd) 

#ggsave(filename = here::here("output/time series/graphs/graph_new_hi_scd.png"),
#       width = 6, height = 4, unit = "in", dpi = 300)

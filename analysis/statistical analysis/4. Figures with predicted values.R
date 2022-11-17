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
library('PNWColors')
library(viridis)
library(ggpubr)
library(cowplot)
library(patchwork)


## Create directories
dir_create(here::here("output", "released_outputs"), showWarnings = FALSE, recurse = TRUE)
dir_create(here::here("output", "released_outputs", "graphs"), showWarnings = FALSE, recurse = TRUE)

# Read in data
predicted <- read_csv(here::here("output", "released_outputs", "predicted_vals_bygroup.csv"),
                    col_types = cols(
                      group  = col_character(),
                      label = col_character(),
                      date = col_date(format = "%Y-%m-%d")))

predicted$label <- factor(predicted$label,
                        levels= c("90+ y", "80-89 y","70-79 y","60-69 y","50-59 y",
                                  "40-49 y","30-39 y","18-29 y","Female","Male",
                                  "1 most deprived","2","3","4","5","6","7","8","9","10 least deprived",
                                  "Yorkshire and The Humber","West Midlands","South West",
                                  "South East","North West","North East","London",
                                  "East Midlands","East","Unknown","Other","Mixed","Black or Black British",
                                  "Asian or Asian British","White"),
                        labels= c("90+ y", "80-89 y","70-79 y","60-69 y","50-59 y",
                                  "40-49 y","30-39 y","18-29 y","Female","Male",
                                  "1 most deprived","2","3","4","5","6","7","8","9","10 least deprived",
                                  "Yorkshire & The Humber","West Midlands","South West",
                                  "South East","North West","North East","London",
                                  "East Midlands","East","Unknown","Other","Mixed","Black/Black British",
                                  "Asian/Asian British","White"))


######################################
# Prevalent prescribing
######################################


fig <- function(grp, typ, pal, ylab){
  graph <- ggplot(subset(predicted, group == grp & !(label %in% c("Missing", NA)) 
                & type == typ), aes(x = date)) +
    geom_point(aes(y = obs, col = label, fill = label), alpha = .3, size = .8) +
    geom_ribbon(aes(ymin = pred_lci, ymax = pred_uci, group = label), 
                alpha = .5, fill = "gray90")+
    geom_line(aes(y = pred, col = label), size = .5) +
    geom_vline(aes(xintercept = as.Date("2020-03-01")), 
               linetype = "longdash", col = "black") +
    geom_vline(aes(xintercept = as.Date("2021-04-01")), 
               linetype = "longdash", col = "black") +
    scale_color_manual(values =  pal) +
    scale_y_continuous(expand = expansion(mult = c(0,.2), add = c(10,0))) +
    xlab(NULL) + ylab(ylab)+
    theme_bw() +
    theme(text = element_text(size=10),
          strip.background = element_blank(), 
          strip.text = element_text(hjust = 0),
          axis.title.y = element_text(size = 8),
          axis.text.x = element_text(angle = 45, hjust = 1),
          legend.title = element_blank(),
          legend.text = element_text(size = 6),
          legend.key.size = unit(.4, "cm"),
          panel.grid.major.x = element_blank(),
          panel.grid.minor.x = element_blank(),
          panel.grid.major.y = element_line(color = "gray90"),
          legend.position = "bottom",
          legend.margin = margin(c(1,1,1,1)) 
    ) +
    guides(colour = guide_legend(nrow = 2)) 
   return(graph)
}

# By age
graph1 <- fig("Age", "Prevalent",  
              pnw_palette("Sailboat", n = 8, "continuous"), NULL)

# By sex
graph2 <- fig("Sex", "Prevalent", 
              pnw_palette("Sailboat", n = 2, "continuous"), NULL)
  
# By IMD
graph3 <- fig("IMD decile", "Prevalent", 
              pnw_palette("Sailboat", n = 10, "continuous"),
              ylab = "No. people prescribed opioids per 1000 registered patients") 

# By region
graph4 <- fig("Region", "Prevalent", 
              pnw_palette("Sailboat", n = 10, "continuous"), NULL)

# By ethnicity
graph5 <- fig("Ethnicity6", "Prevalent", 
              pnw_palette("Sailboat", n = 6, "continuous"), NULL)

# Combined figure 
png(here::here("output", "released_outputs", "graphs", "Figure2.png"), 
    res = 300, units = "in", width = 6.8, height = 8)

graph1 + theme(plot.tag.position  = c(.06,1.03)) +
  graph2 +  theme(plot.tag.position  = c(0,1.03)) +
  graph3 +  theme(plot.tag.position  = c(.06,1.03)) +
  graph5 +  theme(plot.tag.position  = c(0,1.03)) +
  graph4 +  theme(plot.tag.position  = c(.06,1.03)) +
  plot_layout(ncol = 2) +
  plot_annotation(tag_levels = 'a') & 
  theme(plot.tag = element_text(face = "bold"))

dev.off()


######################################
# New prescribing
######################################


# By age
graph1 <- fig("Age", "Incident",  
              pnw_palette("Sailboat", n = 8, "continuous"), NULL)

# By sex
graph2 <- fig("Sex", "Incident", 
              pnw_palette("Sailboat", n = 2, "continuous"), NULL)

# By IMD
graph3 <- fig("IMD decile", "Incident", 
              pnw_palette("Sailboat", n = 10, "continuous"),
              ylab = "No. people prescribed opioids per 1000 registered patients") 

# By region
graph4 <- fig("Region", "Incident", 
              pnw_palette("Sailboat", n = 10, "continuous"), NULL)

# By ethnicity
graph5 <- fig("Ethnicity6", "Incident", 
              pnw_palette("Sailboat", n = 6, "continuous"), NULL)


png(here::here("output", "released_outputs", "graphs","Figure3.png"), 
    res = 300, units = "in", width = 6.8, height = 8)

graph1 + theme(plot.tag.position  = c(.06,1.03)) +
  graph2 +  theme(plot.tag.position  = c(0,1.03)) +
  graph3 +  theme(plot.tag.position  = c(.06,1.03)) +
  graph5 +  theme(plot.tag.position  = c(0,1.03)) +
  graph4 +  theme(plot.tag.position  = c(.06,1.03)) +
  plot_layout(ncol=2) +
  plot_annotation(tag_levels = 'a') & 
  theme(plot.tag = element_text(face = "bold"))

dev.off()



######################################
# By care home residence
######################################


pred.care <- read_csv(here::here("output", "released_outputs", "predicted_vals_bycarehome.csv"),
                      col_types = cols(
                        group  = col_character(),
                        label = col_character(),
                        date = col_date(format = "%Y-%m-%d")))

pred.care$label <- factor(pred.care$label,
                          levels= c("90+ y", "80-89 y","70-79 y"),
                          labels= c("90+ y", "80-89 y","70-79 y"))

pred.care$type <- factor(pred.care$type, levels =c("Prevalence", "Incidence"),
                            labels = c("Any opioid prescribing", "New opioid prescribing"))



png(here::here("output", "released_outputs", "graphs","Figure3.png"), 
    res = 300, units = "in", width = 6, height = 2.5)

ggplot(pred.care, aes(x=date)) +
  geom_point(aes( y = obs, col = label, fill = label), alpha=.3, size=.8) +
  geom_ribbon(aes(ymin = pred_lci, ymax = pred_uci, group = label), 
              alpha=.7, fill = "gray90")+
  geom_line(aes(y = pred, col = label), size = .5) +
  geom_vline(aes(xintercept = as.Date("2020-03-01")), 
             linetype = "longdash", col = "black") +
  geom_vline(aes(xintercept = as.Date("2021-03-01")), 
             linetype = "longdash", col = "black") +
  scale_color_manual(values =  pnw_palette("Bay", n = 3, "discrete")) +
  scale_y_continuous(expand = expansion(mult = c(.2,.2), add = c(0,0))) +
  facet_wrap(~ type , scales = "free_y") +
  xlab(NULL) + 
  ylab("No. people prescribed opioids\nper 1000 registered patients")+
  theme_bw() +
  theme(text = element_text(size = 10),
        strip.background = element_blank(), 
        strip.text = element_text(hjust = 0),
        axis.title.y = element_text(size = 8),
        axis.text.x = element_text(angle = 45, hjust = 1),
        legend.title = element_blank(),
        legend.text = element_text(size = 6),
        legend.key.size = unit(.4, "cm"),
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank(),
        panel.grid.major.y = element_line(color = "gray90"),
        legend.position = "bottom",
        legend.margin = margin(c(1,1,1,1))) +
  guides(colour = guide_legend(nrow = 1)) 

dev.off()
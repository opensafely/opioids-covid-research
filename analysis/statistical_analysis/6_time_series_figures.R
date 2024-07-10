#######################################################
# This script creates time series graphs by subgroups
# with predicted values from models
#
# Author: Andrea Schaffer
#   Bennett Institute for Applied Data Science
#   University of Oxford, 2024
#####################################################################

# For running locally only #
# setwd("C:/Users/aschaffer/OneDrive - Nexus365/Documents/GitHub/opioids-covid-research")
# getwd()


library('tidyverse')
library('here')
library('fs')
library('ggplot2')
library('PNWColors')
library(patchwork)


## Create directories
dir_create(here::here("output", "released_outputs", "final"), showWarnings = FALSE, recurse = TRUE)

# Read in data
predicted <- read_csv(here::here("output", "released_outputs", "final", "predicted_vals_bygroup.csv"),
                    col_types = cols(
                      var = col_character(),
                      cat = col_character(),
                      month = col_date(format = "%Y-%m-%d"))) %>%
  subset(!(var == "imd" & cat == "Unknown"))

# Set levels
predicted$cat <- factor(predicted$cat,
                        levels= c("90+", "80-89","70-79","60-69","50-59",
                                  "40-49","30-39","18-29",
                                  
                                  "female","male",
                                  
                                  "1 (most deprived)","2","3","4","5","6","7","8","9","10 (least deprived)",
                                  
                                  "East",
                                  "East Midlands",
                                  "London","North East",
                                  "North West","South East","South West",
                                  "West Midlands","Yorkshire and The Humber",
                                  
                                 
                                  "White","Black",
                                  "South Asian","Mixed","Other","Unknown"),
                        
                        labels= c("90+ y", "80-89 y","70-79 y","60-69 y","50-59 y",
                                  "40-49 y","30-39 y","18-29 y",
                                  
                                  "Female","Male",
                                  
                                  "1 most deprived","2","3","4","5","6","7","8","9","10 least deprived",
                                  
                                  "East",
                                  "East Midlands",
                                  "London","North East",
                                  "North West","South East","South West",
                                  "West Midlands","Yorkshire and The Humber",
                                  
                                  "White","Black","Asian or British Asian","Mixed","Other","Unknown"))



######################################
# Prevalent prescribing
######################################

fig <- function(grp, typ, pal, ylab){
  graph <- ggplot(subset(predicted, var == grp & !(cat %in% c("Missing", NA)) 
                & type == typ), aes(x =month)) +
    geom_point(aes(y = obs, col = cat, fill = cat), alpha = .3, size = .8, shape = 16) +
    geom_ribbon(aes(ymin = pred_lci, ymax = pred_uci,  fill = cat), 
                alpha = .2)+
    geom_line(aes(y = pred, col = cat), linewidth = .5) +
    geom_vline(aes(xintercept = as.Date("2020-03-01")), 
               linetype = "longdash", col = "black") +
    geom_vline(aes(xintercept = as.Date("2021-04-01")), 
               linetype = "longdash", col = "black") +
    scale_color_manual(values = pal) +
    scale_fill_manual(values = pal) +
    scale_y_continuous(expand = expansion(mult = c(.2,.2))) +
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
    guides(colour = guide_legend(nrow = 3)) 
   return(graph)
}


# By age
graph1 <- fig("age", "Prevalent",  
              c("#9E0142", "#D53E4F", "#FF7c00", "#FFD23B","#66C2A5",
                "#3288BD", "#5E4FA2", "navy"),
              NULL)

# By sex
graph2 <- fig("sex", "Prevalent", 
              c("#9E0142", "#3288BD"), NULL)
  
# By IMD
graph3 <- fig("imd", "Prevalent", 
              c("#9E0142", "#D53E4F", "#FF7c00", "#FFD23B","#66C2A5",
                "#3288BD", "mediumorchid3", "#5E4FA2", "navy","gray20"),
              ylab = "No. people prescribed opioids per 1000 registered patients") 

# By region
graph4 <- fig("region", "Prevalent", 
              c("#9E0142", "#D53E4F", "#FF7c00", "#FFD23B","#66C2A5",
                "#3288BD",  "#5E4FA2", "navy","gray20"),
              NULL)

# By ethnicity
graph5 <- fig("eth6", "Prevalent", 
              c("#9E0142", "#FFD23B","#66C2A5",
                "#3288BD", "#5E4FA2", "navy"),
              NULL)


# Combined figure 
png(here::here("output", "released_outputs", "final", "suppfigure3.png"), 
   width = 6.8, height = 10, res = 300, units = "in")

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

fig.new <- function(grp, typ, pal, ylab){
  graph <- ggplot(subset(predicted, var == grp & !(cat %in% c("Missing",  NA)) 
                         & type == typ), aes(x =month)) +
    geom_point(aes(y = obs, col = cat, fill = cat), alpha = .3, size = .8, shape =16) +
    geom_ribbon(aes(ymin = pred_lci, ymax = pred_uci,  fill = cat), alpha = .2)+
    geom_line(aes(y = pred, col = cat), size = .5) +
    geom_vline(aes(xintercept = as.Date("2020-03-01")), 
               linetype = "longdash", col = "black") +
    geom_vline(aes(xintercept = as.Date("2021-04-01")), 
               linetype = "longdash", col = "black") +
    scale_color_manual(values = pal) +
    scale_fill_manual(values = pal) +
    scale_y_continuous(expand = expansion(mult = c(.1,.1))) +
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
    guides(colour = guide_legend(nrow = 3)) 
  return(graph)
}

# By age
graph1 <- fig.new("age", "Incident",  
              c("#9E0142", "#D53E4F", "#FF7c00", "#FFD23B","#66C2A5",
                "#3288BD", "#5E4FA2", "navy"), NULL)

# By sex
graph2 <- fig.new("sex", "Incident", 
              c("#9E0142", "#3288BD"), NULL)

# By IMD
graph3 <- fig.new("imd", "Incident", 
              c("#9E0142", "#D53E4F", "#FF7c00", "#FFD23B","#66C2A5",
                "#3288BD", "mediumorchid3", "#5E4FA2", "navy","gray20"),
              ylab = "No. people prescribed opioids per 1000 registered patients") 

# By region
graph4 <- fig.new("region", "Incident", 
              c("#9E0142", "#D53E4F", "#FF7c00", "#FFD23B","#66C2A5",
                "#3288BD",  "#5E4FA2", "navy","gray20"),NULL)

# By ethnicity
graph5 <- fig.new("eth6", "Incident", 
              c("#9E0142", "#FFD23B","#66C2A5",
                "#3288BD", "#5E4FA2", "navy"), NULL)


png(here::here("output", "released_outputs", "final", "suppfigure4.png"), 
     width = 6.8, height = 10, res = 300, units = "in")

graph1 + theme(plot.tag.position  = c(.06,1.03)) +
  graph2 +  theme(plot.tag.position  = c(0,1.03)) +
  graph3 +  theme(plot.tag.position  = c(.06,1.03)) +
  graph5 +  theme(plot.tag.position  = c(0,1.03)) +
  graph4 +  theme(plot.tag.position  = c(.06,1.03)) +
  plot_layout(ncol=2) +
  plot_annotation(tag_levels = 'a') & 
  theme(plot.tag = element_text(face = "bold"))

dev.off()



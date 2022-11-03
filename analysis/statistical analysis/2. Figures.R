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


## Create directories
dir_create(here::here("output", "released_outputs"), showWarnings = FALSE, recurse = TRUE)
dir_create(here::here("output", "released_outputs", "graphs"), showWarnings = FALSE, recurse = TRUE)

# Read in data
combined <- read_csv(here::here("output", "released_outputs", "ts_combined_full.csv"),
                    col_types = cols(
                      group  = col_character(),
                      label = col_character(),
                      date = col_date(format="%Y-%m-%d")))

imd <- subset(combined, group == "IMD decile" & !(label %in% c("Missing",NA)))
age <- subset(combined, group == "Age" & !(label %in% c("Missing",NA))) 
sex <- subset(combined, group == "Sex" & !(label %in% c("Missing",NA))) 
ethnicity <- subset(combined, group == "Ethnicity6" & !(label %in% c(NA))) %>%
    mutate(label = ifelse(label %in% c("Missing","Unknown"), "Missing/Unknown", label))
region <- subset(combined, group == "Region" & !(label %in% c("Missing",NA))) 



imd$label <- factor(imd$label,
                    levels= c("1 most deprived","2","3","4","5","6","7","8","9","10 least deprived"))


ethnicity$label <- factor(ethnicity$label,
                          levels= c("White","Asian or Asian British",
                                    "Black or Black British", "Mixed",
                                    "Other", "Missing/Unknown"),
                          labels= c("White","Asian/Asian British",
                                    "Black/Black British", "Mixed",
                                    "Other", "Missing/Unknown"))

######################################
# Overall
######################################


graph1 <- ggplot(age) +
  geom_line(aes(x = date, y = prevalence_per_1000 , col = label)) +
  geom_vline(xintercept = as.Date("2020-03-01"), col = "gray70",
             linetype = "longdash") +
  geom_vline(xintercept = as.Date("2021-04-01"), col = "gray70",
             linetype = "longdash") +
  scale_color_manual(values =  pnw_palette("Sailboat",n=8, "continuous")) +
  scale_y_continuous(limits= c(0,160)) +
  ylab("Opioid prescribing per\n1000 registered patients") +
  xlab(NULL) +
  theme_bw() +
  theme(text = element_text(size=10),
        strip.background = element_blank(), 
        strip.text = element_text(hjust = 0),
        axis.title.y = element_text(size = 8),
        axis.text.x = element_text(angle = 45, hjust = 1),
        legend.title = element_blank(),
        legend.text = element_text(size=6),
        legend.key.size = unit(.4, "cm"),
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank(),
        panel.grid.major.y = element_line(color = "gray90"),
        legend.position = "bottom",legend.margin=margin(c(1,1,1,1)) 
  ) +
  guides(colour = guide_legend(nrow = 2)) 


graph2 <- ggplot(sex) +
  geom_line(aes(x = date, y = prevalence_per_1000 , col = label)) +
  geom_vline(xintercept = as.Date("2020-03-01"), col = "gray70",
             linetype = "longdash") +
  geom_vline(xintercept = as.Date("2021-04-01"), col = "gray70",
             linetype = "longdash") +
  scale_color_manual(values =  pnw_palette("Sailboat",n=2, "continuous")) +
  scale_y_continuous(limits= c(0,90)) +
  ylab(NULL) +
  xlab(NULL) +
  theme_bw() +
  theme(text = element_text(size=10),
        strip.background = element_blank(), 
        strip.text = element_text(hjust = 0),
        axis.title.y = element_text(size = 8),
        axis.text.x = element_text(angle = 45, hjust = 1),
        legend.title = element_blank(),
        legend.text = element_text(size=6),
        legend.key.size = unit(.4, "cm"),
        
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank(),
        panel.grid.major.y = element_line(color = "gray90"),
        legend.position = "bottom",legend.margin=margin(c(1,1,1,1)) 
  )+
  guides(colour = guide_legend(nrow = 2))


graph3 <- ggplot(imd) +
  geom_line(aes(x = date, y = prevalence_per_1000 , col = label)) +
  geom_vline(xintercept = as.Date("2020-03-01"), col = "gray70",
             linetype = "longdash") +
  geom_vline(xintercept = as.Date("2021-04-01"), col = "gray70",
             linetype = "longdash") +
  scale_color_manual(values =  pnw_palette("Sailboat",n=10, "continuous")) +
  scale_y_continuous(limits= c(0,90)) +
  ylab("Opioid prescribing per\n1000 registered patients") +
  xlab(NULL) +
  theme_bw() +
  theme(text = element_text(size=10),
        strip.background = element_blank(), 
        strip.text = element_text(hjust = 0),
        axis.title.y = element_text(size = 8),
        axis.text.x = element_text(angle = 45, hjust = 1),
        legend.title = element_blank(),    legend.key.size = unit(.4, "cm"),
        
        legend.text = element_text(size=6),
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank(),
        panel.grid.major.y = element_line(color = "gray90"),
        legend.position = "bottom",legend.margin=margin(c(1,1,1,1)) 
  )+
  guides(colour = guide_legend(nrow = 2))




graph4 <- ggplot(region) +
  geom_line(aes(x = date, y = prevalence_per_1000 , col = label)) +
  geom_vline(xintercept = as.Date("2020-03-01"), col = "gray70",
             linetype = "longdash") +
  geom_vline(xintercept = as.Date("2021-04-01"), col = "gray70",
             linetype = "longdash") +
  scale_color_manual(values =  pnw_palette("Sailboat",n=10, "continuous")) +
  scale_y_continuous(limits= c(0,90)) +
  ylab("Opioid prescribing per\n1000 registered patients") +
  xlab(NULL) +
  theme_bw() +
  theme(text = element_text(size=10),
        strip.background = element_blank(), 
        strip.text = element_text(hjust = 0),
        axis.title.y = element_text(size = 8),
        axis.text.x = element_text(angle = 45, hjust = 1),
        legend.title = element_blank(),    legend.key.size = unit(.4, "cm"),
        
        legend.text = element_text(size=6),
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank(),
        panel.grid.major.y = element_line(color = "gray90"),
        legend.position = "bottom",legend.margin=margin(c(1,1,1,1)) 
  )+
  guides(colour = guide_legend(nrow =3))



graph5 <- ggplot(ethnicity) +
  geom_line(aes(x = date, y = prevalence_per_1000 , col = label)) +
  geom_vline(xintercept = as.Date("2020-03-01"), col = "gray70",
             linetype = "longdash") +
  geom_vline(xintercept = as.Date("2021-04-01"), col = "gray70",
             linetype = "longdash") +
  scale_color_manual(values =  pnw_palette("Sailboat",n=6, "continuous")) +
  scale_y_continuous(limits= c(0,90)) +
  ylab(NULL) +
  xlab(NULL) +
  theme_bw() +
  theme(text = element_text(size=10),
        strip.background = element_blank(), 
        strip.text = element_text(hjust = 0),
        axis.title.y = element_text(size = 8),
        axis.text.x = element_text(angle = 45, hjust = 1),
        legend.title = element_blank(),    legend.key.size = unit(.4, "cm"),
        
        legend.text = element_text(size=6),
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank(),
        panel.grid.major.y = element_line(color = "gray90"),
        legend.position = "bottom",legend.margin=margin(c(1,1,1,1)) 
  )+
  guides(colour = guide_legend(nrow = 2))




# graph7 <- ggplot(subset(combined, (group %in% c("Care home")))) +
#   geom_line(aes(x = date, y = prevalence_per_1000 , col = label)) +
#   geom_vline(xintercept = as.Date("2020-03-01"), col = "gray70",
#              linetype = "longdash") +
#   geom_vline(xintercept = as.Date("2020-11-01"), col = "gray70",
#              linetype = "longdash") +
#   geom_vline(xintercept = as.Date("2021-01-01"), col = "gray70",
#              linetype = "longdash") +
#   scale_color_manual(values =  pal24) +
#   scale_y_continuous(limits= c(0,90)) +
#   ylab("") +
#   xlab("") +
#   theme_bw() +
#   theme(text = element_text(size=10),
#         strip.background = element_blank(), 
#         strip.text = element_text(hjust = 0),
#         axis.title.y = element_text(size = 8),
#         axis.text.x = element_text(angle = 45, hjust = 1),
#         legend.title = element_blank(),
#         panel.grid.major.x = element_blank(),
#         panel.grid.minor.x = element_blank(),
#         panel.grid.major.y = element_line(color = "gray90"),
#         legend.position = "bottom"
#   )+
#   guides(colour = guide_legend(ncol = 3))
# 
# 
# graph8 <- ggplot(subset(combined, (group %in% c("Sickle cell disease")))) +
#   geom_line(aes(x = date, y = prevalence_per_1000 , col = label)) +
#   geom_vline(xintercept = as.Date("2020-03-01"), col = "gray70",
#              linetype = "longdash") +
#   geom_vline(xintercept = as.Date("2020-11-01"), col = "gray70",
#              linetype = "longdash") +
#   geom_vline(xintercept = as.Date("2021-01-01"), col = "gray70",
#              linetype = "longdash") +
#   scale_color_manual(values =  pal24) +
#   scale_y_continuous(limits= c(0,90)) +
#   ylab("People prescribed an opioid per\n1000 registered patients") +
#   xlab("") +
#   theme_bw() +
#   theme(text = element_text(size=10),
#         strip.background = element_blank(), 
#         strip.text = element_text(hjust = 0),
#         axis.title.y = element_text(size = 8),
#         axis.text.x = element_text(angle = 45, hjust = 1),
#         legend.title = element_blank(),
#         panel.grid.major.x = element_blank(),
#         panel.grid.minor.x = element_blank(),
#         panel.grid.major.y = element_line(color = "gray90"),
#         legend.position = "bottom"
#   )+
#   guides(colour = guide_legend(ncol = 3))




png("combined.png", res = 300, units = "in", width = 6.8, height = 8)

ggarrange(graph1, graph2, graph3, graph5, graph4, ncol = 2, nrow = 3, 
          widths = c(1.1,1), heights = c(1,1,1.05),labels = "auto", label.y =1.02, label.x = .0 )

dev.off()


######################################
# New prescribing
######################################

graph1 <- ggplot(age) +
  geom_line(aes(x = date, y = incidence_per_1000 , col = label)) +
  geom_vline(xintercept = as.Date("2020-03-01"), col = "gray70",
             linetype = "longdash") +
  geom_vline(xintercept = as.Date("2021-04-01"), col = "gray70",
             linetype = "longdash") +
  scale_color_manual(values =  pnw_palette("Sailboat",n=8, "continuous")) +
  scale_y_continuous(limits=c(0,15)) +
  ylab("New opioid prescribing per\n1000 registered patients") +
  xlab(NULL) +
  theme_bw() +
  theme(text = element_text(size=10),
        strip.background = element_blank(), 
        strip.text = element_text(hjust = 0),
        axis.title.y = element_text(size = 8),
        axis.text.x = element_text(angle = 45, hjust = 1),
        legend.title = element_blank(),
        legend.text = element_text(size=6),
        legend.key.size = unit(.4, "cm"),
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank(),
        panel.grid.major.y = element_line(color = "gray90"),
        legend.position = "bottom",legend.margin=margin(c(1,1,1,1)) 
  ) +
  guides(colour = guide_legend(nrow = 2)) 


graph2 <- ggplot(sex) +
  geom_line(aes(x = date, y = incidence_per_1000 , col = label)) +
  geom_vline(xintercept = as.Date("2020-03-01"), col = "gray70",
             linetype = "longdash") +
  geom_vline(xintercept = as.Date("2021-04-01"), col = "gray70",
             linetype = "longdash") +
  scale_color_manual(values =  pnw_palette("Sailboat",n=2, "continuous")) +
  scale_y_continuous(limits = c(0,6.4)) +
  ylab(NULL) +
  xlab(NULL) +
  theme_bw() +
  theme(text = element_text(size=10),
        strip.background = element_blank(), 
        strip.text = element_text(hjust = 0),
        axis.title.y = element_text(size = 8),
        axis.text.x = element_text(angle = 45, hjust = 1),
        legend.title = element_blank(),
        legend.text = element_text(size=6),
        legend.key.size = unit(.4, "cm"),
        
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank(),
        panel.grid.major.y = element_line(color = "gray90"),
        legend.position = "bottom",legend.margin=margin(c(1,1,1,1)) 
  )+
  guides(colour = guide_legend(nrow = 2))


graph3 <- ggplot(imd) +
  geom_line(aes(x = date, y = incidence_per_1000 , col = label)) +
  geom_vline(xintercept = as.Date("2020-03-01"), col = "gray70",
             linetype = "longdash") +
  geom_vline(xintercept = as.Date("2021-04-01"), col = "gray70",
             linetype = "longdash") +
  scale_color_manual(values =  pnw_palette("Sailboat",n=10, "continuous")) +
  scale_y_continuous(limits = c(0,6.4)) +
  ylab("Opioid prescribing per\n1000 registered patients") +
  xlab(NULL) +
  theme_bw() +
  theme(text = element_text(size=10),
        strip.background = element_blank(), 
        strip.text = element_text(hjust = 0),
        axis.title.y = element_text(size = 8),
        axis.text.x = element_text(angle = 45, hjust = 1),
        legend.title = element_blank(),    legend.key.size = unit(.4, "cm"),
        
        legend.text = element_text(size=6),
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank(),
        panel.grid.major.y = element_line(color = "gray90"),
        legend.position = "bottom",legend.margin=margin(c(1,1,1,1)) 
  )+
  guides(colour = guide_legend(nrow = 2))




graph4 <- ggplot(region) +
  geom_line(aes(x = date, y = incidence_per_1000 , col = label)) +
  geom_vline(xintercept = as.Date("2020-03-01"), col = "gray70",
             linetype = "longdash") +
  geom_vline(xintercept = as.Date("2021-04-01"), col = "gray70",
             linetype = "longdash") +
  scale_color_manual(values =  pnw_palette("Sailboat",n=10, "continuous")) +
  scale_y_continuous(limits = c(0,6.4)) +
  ylab("New opioid prescribing per\n1000 registered patients") +
  xlab(NULL) +
  theme_bw() +
  theme(text = element_text(size=10),
        strip.background = element_blank(), 
        strip.text = element_text(hjust = 0),
        axis.title.y = element_text(size = 8),
        axis.text.x = element_text(angle = 45, hjust = 1),
        legend.title = element_blank(),    legend.key.size = unit(.4, "cm"),
        
        legend.text = element_text(size=6),
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank(),
        panel.grid.major.y = element_line(color = "gray90"),
        legend.position = "bottom",legend.margin=margin(c(1,1,1,1)) 
  )+
  guides(colour = guide_legend(nrow =3))


graph5 <- ggplot(ethnicity) +
  geom_line(aes(x = date, y = incidence_per_1000 , col = label)) +
  geom_vline(xintercept = as.Date("2020-03-01"), col = "gray70",
             linetype = "longdash") +
  geom_vline(xintercept = as.Date("2021-04-01"), col = "gray70",
             linetype = "longdash") +
  scale_color_manual(values =  pnw_palette("Sailboat",n=6, "continuous")) +
  scale_y_continuous(limits = c(0,6.4)) +
  ylab(NULL) +
  xlab(NULL) +
  theme_bw() +
  theme(text = element_text(size=10),
        strip.background = element_blank(), 
        strip.text = element_text(hjust = 0),
        axis.title.y = element_text(size = 8),
        axis.text.x = element_text(angle = 45, hjust = 1),
        legend.title = element_blank(),    
        legend.key.size = unit(.4, "cm"),
        legend.text = element_text(size=6),
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank(),
        panel.grid.major.y = element_line(color = "gray90"),
        legend.position = "bottom",legend.margin=margin(c(1,1,1,1)) 
  )+
  guides(colour = guide_legend(nrow = 2))




# graph7 <- ggplot(subset(combined, (group %in% c("Care home")))) +
#   geom_line(aes(x = date, y = incidence_per_1000 , col = label)) +
#   geom_vline(xintercept = as.Date("2020-03-01"), col = "gray70",
#              linetype = "longdash") +
#   geom_vline(xintercept = as.Date("2020-11-01"), col = "gray70",
#              linetype = "longdash") +
#   geom_vline(xintercept = as.Date("2021-01-01"), col = "gray70",
#              linetype = "longdash") +
#   scale_color_manual(values =  pal24) +
#   scale_y_continuous(expand = c(0.3, 0)) +
#   ylab("") +
#   xlab("") +
#   theme_bw() +
#   theme(text = element_text(size=10),
#         strip.background = element_blank(), 
#         strip.text = element_text(hjust = 0),
#         axis.title.y = element_text(size = 8),
#         axis.text.x = element_text(angle = 45, hjust = 1),
#         legend.title = element_blank(),
#         panel.grid.major.x = element_blank(),
#         panel.grid.minor.x = element_blank(),
#         panel.grid.major.y = element_line(color = "gray90"),
#         legend.position = "bottom"
#   )+
#   guides(colour = guide_legend(ncol = 3))
# 
# 
# graph8 <- ggplot(subset(combined, (group %in% c("Sickle cell disease")))) +
#   geom_line(aes(x = date, y = incidence_per_1000 , col = label)) +
#   geom_vline(xintercept = as.Date("2020-03-01"), col = "gray70",
#              linetype = "longdash") +
#   geom_vline(xintercept = as.Date("2020-11-01"), col = "gray70",
#              linetype = "longdash") +
#   geom_vline(xintercept = as.Date("2021-01-01"), col = "gray70",
#              linetype = "longdash") +
#   scale_color_manual(values =  pal24) +
#   scale_y_continuous(expand = c(0.3, 0)) +
#   ylab("People prescribed an opioid per\n1000 registered patients") +
#   xlab("") +
#   theme_bw() +
#   theme(text = element_text(size=10),
#         strip.background = element_blank(), 
#         strip.text = element_text(hjust = 0),
#         axis.title.y = element_text(size = 8),
#         axis.text.x = element_text(angle = 45, hjust = 1),
#         legend.title = element_blank(),
#         panel.grid.major.x = element_blank(),
#         panel.grid.minor.x = element_blank(),
#         panel.grid.major.y = element_line(color = "gray90"),
#         legend.position = "bottom"
#   )+
#   guides(colour = guide_legend(ncol = 3))




png("combined_new.png", res = 300, units = "in", width = 6.8, height = 8)

ggarrange(graph1, graph2, graph3, graph5, graph4, ncol = 2, nrow = 3, 
          widths = c(1.1,1), heights = c(1,1,1.05),labels = "auto", label.y =1.02, label.x = .0 )

dev.off()

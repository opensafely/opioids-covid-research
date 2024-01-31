#######################################################
# This script creates plot of overall population
#######################################################

# For running locally only #
# setwd("C:/Users/aschaffer/OneDrive - Nexus365/Documents/GitHub/opioids-covid-research")
# getwd()


library('tidyverse')
library('here')
library('reshape2')
library('fs')
library('ggplot2')
library('PNWColors')


## Create directories
dir_create(here::here("output", "released_outputs", "final"), showWarnings = FALSE, recurse = TRUE)


# Read in data
pop <-  read_csv(here::here("output", "released_outputs", "final", "ts_overall_its.csv")) %>%
  dplyr::select(c("pop_total_round", "pop_naive_round", "month")) %>%
  reshape2::melt(id = "month")

pop$variable <- factor(pop$variable, levels = c("pop_total_round", "pop_naive_round"),
                       labels = c("Total", "Opioid-naive"))


# Plot
png(here::here("output", "released_outputs", "final", "suppfigure1.png"), res = 300, 
    units = "in", height = 2.5, width =5.2)

ggplot(pop, aes(x =month)) + 
  geom_line(aes(y = value, col = variable), linewidth = .8) +
  geom_vline(aes(xintercept = as.Date("2020-03-01")), linetype = "longdash", col = "black") +
  geom_vline(aes(xintercept = as.Date("2021-03-01")), linetype = "longdash", col = "black") +
  scale_y_continuous(expand = c(.4,0)) +
  scale_color_manual(values = pnw_palette("Bay", 2, "discrete")) +
  xlab("") + ylab("No. registered adult patients")+
  theme_bw() + 
  theme(text = element_text(size = 10), strip.background = element_blank(),
        strip.text = element_blank(),legend.title = element_blank(),
        legend.position = "right",
        panel.grid.minor.x = element_blank(),
        panel.grid.minor.y= element_blank(),
        panel.grid.major.x = element_blank(),
        panel.grid.major.y =element_line(color = "gray90"),
        axis.title.y = element_text(size = 8),
        axis.text.x = element_text(angle = 45, hjust = 1)) +
  guides(color=guide_legend(nrow=2, byrow=TRUE))

dev.off()
####################################################################
# This script:
#   - estimates negative binomial / poisson models
#   for overall opioid prescribing (prevalent, new, high dose, parenteral);
#   - plots predicted and observed value
# among people without cancer (senstivity analysis)
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
library(MASS)
library(lmtest)
library(PNWColors)
library(sandwich)
library(ggpubr)
library(patchwork)

## Create directories
dir_create(here::here("output", "released_outputs", "final" , "graphs"), showWarnings = FALSE, recurse = TRUE)


## Custom functions
source(here("analysis", "lib", "custom_functions.R"))


######################################
#### Without cancer only ################
######################################

#### Overall prescribing ####

df.data1 <- read_csv(here::here("output", "released_outputs", "final", "ts_overall_nocancer_its.csv")) %>%
  mutate(opioid = opioid_any_round, pop = pop_total_round)

# Base model
mod1 <- glm.nb(opioid ~ time +  step + step2 + slope + slope2 + 
                 as.factor(month_dummy) + offset(log(pop)), df.data1, link = "log")
summary(mod1)

# Compare with model including Mar/Apr/May dummies
mod2 <- glm.nb(opioid ~ time +  step + step2 + slope + slope2 + mar20 + apr20 + may20 +
                 as.factor(month_dummy) + offset(log(pop)), df.data1, link = "log")
summary(mod2)

AIC(mod1)
AIC(mod2)
lrtest(mod1, mod2)

## Check autocorrelation of residuals
Box.test(mod2$residuals, type = 'Ljung-Box')

# Extract coefficients, calculated Newey-West adjusted 95%CIs
coef_noca_prev <- coef(mod2)
write.csv(coef_noca_prev,  
          file = here::here("output", "released_outputs", "final", "ts_coef_nocancer_prev.csv"),
          row.names = TRUE)

# Calculate predicted values (for graphs)
pred_noca_prev <- pred.val(mod2, df.data1, pop_total_round, "Prevalence", "Overall", rate_opioid_any_round) 


#### Overall incidence ####

df.data1 <-  read_csv(here::here("output", "released_outputs", "final", "ts_overall_nocancer_its.csv")) %>%
  mutate(opioid = opioid_new_round, pop = pop_naive_round)

# Base model
mod1 <- glm.nb(opioid ~ time +  step + step2 + slope + slope2 + 
                 as.factor(month_dummy) + offset(log(pop)), df.data1, link = "log")
summary(mod1)

# Compare with model including Mar/Apr/May dummies
mod2 <- glm.nb(opioid ~ time +  step + step2 + slope + slope2 + mar20 + apr20 + may20 +
                 as.factor(month_dummy) + offset(log(pop)), df.data1, link = "log")
summary(mod2)

AIC(mod1)
AIC(mod2)
lrtest(mod1, mod2)

## Check autocorrelation of residuals
Box.test(mod1$residuals, type = 'Ljung-Box')

# Extract coefficients, calculated Newey-West adjusted 95%CIs
coef_noca_new <- coef(mod1)
write.csv(coef_noca_new,  
          file = here::here("output", "released_outputs", "final", "ts_coef_nocancer_new.csv"),
          row.names = TRUE)

# Calculate predicted values (for graphs)
pred_noca_new <- pred.val(mod1, df.data1, pop_naive_round, "Incidence", "Overall", rate_opioid_new_round)


#### OVerall high dose prescribing ####

df.data1 <-  read_csv(here::here("output", "released_outputs", "final", "ts_overall_nocancer_its.csv")) %>%
  mutate(opioid = hi_opioid_any_round, pop = pop_total_round)

# Base model
mod1 <- glm.nb(opioid ~ time +  step + step2 + slope + slope2 + 
                 as.factor(month_dummy) + offset(log(pop)), df.data1, link = "log")
summary(mod1)

# Compare with model including Mar/Apr/May dummies
mod2 <- glm.nb(opioid ~ time +  step + step2 + slope + slope2 + mar20 + apr20 + may20 +
                 as.factor(month_dummy) + offset(log(pop)), df.data1, link = "log")
summary(mod2)

AIC(mod1)
AIC(mod2)
lrtest(mod1, mod2)

## Check autocorrelation of residuals
Box.test(mod1$residuals, type = 'Ljung-Box')

# Extract coefficients, calculated Newey-West adjusted 95%CIs
coef_noca_hi <- coef(mod1)

write.csv(coef_noca_hi,  
          file = here::here("output", "released_outputs", "final", "ts_coef_nocancer_hi.csv"),
          row.names = TRUE)

# Calculate predicted values (for graphs)
pred_noca_hi <- pred.val(mod1, df.data1, pop_total_round, "High dose prevalence", "Overall", rate_hi_opioid_round)



##################################

# Combine all predicted values together 

pred_noca_all <- rbind(pred_noca_prev, pred_noca_new, pred_noca_hi)

pred_noca_all$outcome <- factor(pred_noca_all$outcome, 
                           levels = c("Prevalence", "High dose prevalence", "Incidence"),
                           labels =c("Any opioid prescribing", 
                                     "High dose long-acting opioid prescribing",
                                     "New opioid prescribing"))

write.csv(pred_noca_all, here::here("output", "released_outputs", "final", "ts_predicted_nocancer.csv"),
          row.names = FALSE)



##############################################
#### Plot
##############################################
 
 
a <- ggplot(subset(pred_noca_all, outcome == "Any opioid prescribing"), aes(x =month)) + 
   geom_point(aes( y = obs), col = "#00496f", fill = "#00496f", alpha=.3) +
   geom_ribbon(aes(ymin = pred_lci, ymax = pred_uci), alpha=.5, fill = "gray90")+
   geom_line(aes(y = pred), col = "#00496f",linewidth = .8) +
   geom_vline(aes(xintercept = as.Date("2020-03-01")), linetype = "longdash", col = "black") +
   geom_vline(aes(xintercept = as.Date("2021-03-01")), linetype = "longdash", col = "black") +
   scale_y_continuous(expand = c(.4,0)) +
   xlab("") + ylab("No. people per 1000\nadult patients")+
   facet_wrap(~ outcome) + 
   theme_bw() + 
   theme(text = element_text(size = 10), strip.background = element_blank(),
         strip.text = element_text(hjust = 0),legend.title = element_blank(),
         legend.position = "none",
         panel.grid.minor.x = element_blank(),
         panel.grid.minor.y= element_blank(),
         panel.grid.major.x = element_blank(),
         panel.grid.major.y =element_line(color = "gray90"),
         axis.title.y = element_text(size = 8),axis.title.x = element_blank(),
         axis.text.x = element_text(angle = 45, hjust = 1)) 
 
b <- ggplot(subset(pred_noca_all, outcome == "High dose long-acting opioid prescribing"), aes(x =month)) + 
   geom_point(aes( y = obs), col = "#0f85a0", fill = "#0f85a0", alpha=.3) +
   geom_ribbon(aes(ymin = pred_lci, ymax = pred_uci), alpha=.5, fill = "gray90")+
   geom_line(aes(y = pred), col = "#0f85a0",linewidth = .8) +
   geom_vline(aes(xintercept = as.Date("2020-03-01")), linetype = "longdash", col = "black") +
   geom_vline(aes(xintercept = as.Date("2021-03-01")), linetype = "longdash", col = "black") +
   
   scale_y_continuous(expand = c(.4,0)) +
   scale_fill_manual(values = pnw_palette("Bay", 4), guide = "none")+
   scale_color_manual(values = pnw_palette("Bay", 4, "discrete")) +
   xlab("") + ylab("No. people per 1000\nadult patients")+
   theme_bw() + 
   facet_wrap(~ outcome) + 
   theme(text = element_text(size = 10), strip.background = element_blank(),
         strip.text = element_text(hjust = 0),legend.title = element_blank(),
         legend.position = "none",
         panel.grid.minor.x = element_blank(),
         panel.grid.minor.y= element_blank(),
         panel.grid.major.x = element_blank(),
         panel.grid.major.y =element_line(color = "gray90"),
         axis.title.y = element_text(size = 8),axis.title.x = element_blank(),
         axis.text.x = element_text(angle = 45, hjust = 1)) 
 
c <- ggplot(subset(pred_noca_all, outcome == "New opioid prescribing"), aes(x =month)) + 
   geom_point(aes( y = obs), col = "#edd746", fill = "#edd746", alpha=.3) +
   geom_ribbon(aes(ymin = pred_lci, ymax = pred_uci), alpha=.5, fill = "gray90")+
   geom_line(aes(y = pred), col = "#edd746",linewidth = .8) +
   geom_vline(aes(xintercept = as.Date("2020-03-01")), linetype = "longdash", col = "black") +
   geom_vline(aes(xintercept = as.Date("2021-03-01")), linetype = "longdash", col = "black") +
   
   scale_y_continuous(expand = c(.4,0)) +
   scale_fill_manual(values = pnw_palette("Bay", 4), guide = "none")+
   scale_color_manual(values = pnw_palette("Bay", 4, "discrete")) +
   xlab("") + ylab("No. people per 1000\nadult opioid-naive patients")+
   facet_wrap(~ outcome) + 
   theme_bw() + 
   theme(text = element_text(size = 10), strip.background = element_blank(),
         strip.text = element_text(hjust = 0),legend.title = element_blank(),
         legend.position = "none",
         panel.grid.minor.x = element_blank(),
         panel.grid.minor.y= element_blank(),
         panel.grid.major.x = element_blank(),
         panel.grid.major.y =element_line(color = "gray90"),
         axis.title.y = element_text(size = 8),axis.title.x = element_blank(),
         axis.text.x = element_text(angle = 45, hjust = 1)) 
 

 
 
png(here::here("output", "released_outputs", "final", "suppfigure2.png"), height = 4, width =3.2,
    res = 300, units = "in")
 
 a /  c
 
 dev.off()
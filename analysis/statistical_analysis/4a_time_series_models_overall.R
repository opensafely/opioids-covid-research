#######################################################
# This script estimates negative binomial models
#   for overall opioid prescribing (prevalent, new, high dose, parenteral)
#######################################################

# For running locally only #
# setwd("C:/Users/aschaffer/OneDrive - Nexus365/Documents/GitHub/opioids-covid-research")
# getwd()


library('tidyverse')
library('here')
library('fs')
library('ggplot2')
library(MASS)
library(sandwich)
library(lmtest)
library(PNWColors)

library(patchwork)

## Create directories
dir_create(here::here("output", "released_outputs", "final" , "graphs"), showWarnings = FALSE, recurse = TRUE)
dir_create(here::here("output", "released_outputs", "final"), showWarnings = FALSE, recurse = TRUE)


## Custom functions
source(here("analysis", "lib", "custom_functions.R"))


######################################
#### Full population  ################
######################################

#### Overall prescribing ####

df.data1 <- read_csv(here::here("output", "released_outputs", "final", "ts_overall_its.csv")) %>%
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
coef_prev <- coef(mod2)
write.csv(coef_prev,  
          file = here::here("output", "released_outputs", "final", "ts_coef_prev.csv"),
          row.names = TRUE)

# Calculate predicted values (for graphs)
pred_prev <- pred.val(mod2, df.data1, pop_total_round, "Prevalence", "Overall", rate_opioid_any_round) 


#### Overall incidence ####

df.data1 <-  read_csv(here::here("output", "released_outputs", "final", "ts_overall_its.csv")) %>%
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
coef_new <- coef(mod1)
write.csv(coef_new,  
          file = here::here("output", "released_outputs", "final", "ts_coef_new.csv"),
          row.names = TRUE)

# Calculate predicted values (for graphs)
pred_new <- pred.val(mod1, df.data1, pop_naive_round, "Incidence", "Overall", rate_opioid_new_round)


#### OVerall high dose prescribing ####

df.data1 <-  read_csv(here::here("output", "released_outputs", "final", "ts_overall_its.csv")) %>%
  mutate(opioid = hi_opioid_any_round, 
         pop = pop_total_round)

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
coef_hi <- coef(mod1)

write.csv(coef_hi,  
          file = here::here("output", "released_outputs", "final", "ts_coef_hi.csv"),
          row.names = TRUE)

# Calculate predicted values (for graphs)
pred_hi <- pred.val(mod1, df.data1, pop_total_round, "High dose prevalence", "Overall", rate_hi_opioid_round)



#### Parenteral prescribing ####

df.data1 <- read_csv(here::here("output", "released_outputs", "final", "ts_type_its.csv")) %>%
  subset(measure == "Parenteral") %>%
  mutate(opioid = opioid_any_round, pop = pop_total_round)

# Base model
mod1 <- glm.nb(opioid ~ time +  step + step2 + slope + slope2 + 
                 as.factor(month_dummy) + offset(log(pop)), df.data1, link = "log")
summary(mod1)

# Compare with model including Mar/Apr/May dummies
mod2 <- glm.nb(opioid ~ time +  step + step2 + slope + slope2 + mar20 + apr20 +may20 +
                 as.factor(month_dummy) + offset(log(pop)), df.data1, link = "log")
summary(mod2)

AIC(mod1)
AIC(mod2)
lrtest(mod1, mod2)

## Check autocorrelation of residuals
Box.test(mod2$residuals, type = 'Ljung-Box')

# Extract coefficients, calculated Newey-West adjusted 95%CIs
coef_par <- coef(mod2)

write.csv(coef_par,  
          file = here::here("output", "released_outputs", "final", "ts_coef_parent.csv"),
          row.names = TRUE)

# Calculate predicted values (for graphs)
pred_par <- pred.val(mod2, df.data1, 
                     pop_total_round, "Parenteral prevalence", "Overall", rate_opioid_any_round)


##################################

# Combine all predicted values together 

pred_all <- rbind(pred_prev, pred_new, pred_hi, pred_par)

pred_all$outcome <- factor(pred_all$outcome, 
                       levels = c("Prevalence", "High dose prevalence", "Incidence", "Parenteral prevalence"),
                       labels =c("Any opioid prescribing", 
                                 "High dose long-acting opioid prescribing",
                                 "New opioid prescribing", 
                                 "Parenteral opioid prescribing"))

write.csv(pred_all, here::here("output", "released_outputs", "final", "ts_predicted_all.csv"),
          row.names = FALSE)



##############################################
#### Plot
##############################################


a <- ggplot(subset(pred_all, outcome == "Any opioid prescribing"), aes(x =month)) + 
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

b <- ggplot(subset(pred_all, outcome == "High dose long-acting opioid prescribing"), aes(x =month)) + 
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

c <- ggplot(subset(pred_all, outcome == "New opioid prescribing"), aes(x =month)) + 
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

d <- ggplot(subset(pred_all, outcome == "Parenteral opioid prescribing"), aes(x =month)) + 
  geom_point(aes( y = obs), col = "#dd4124", fill = "#dd4124", alpha=.3) +
  geom_ribbon(aes(ymin = pred_lci, ymax = pred_uci), alpha=.5, fill = "gray90")+
  geom_line(aes(y = pred), col = "#dd4124",linewidth = .8) +
  geom_vline(aes(xintercept = as.Date("2020-03-01")), linetype = "longdash", col = "black") +
  geom_vline(aes(xintercept = as.Date("2021-03-01")), linetype = "longdash", col = "black") +
  scale_y_continuous(expand = c(.4,0)) +
  scale_fill_manual(values = pnw_palette("Bay", 4), guide = "none")+
  scale_color_manual(values = pnw_palette("Bay", 4, "discrete")) +
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
        axis.title.y = element_text(size = 8), axis.title.x = element_blank(),
        axis.text.x = element_text(angle = 45, hjust = 1)) 




pdf(here::here("output", "released_outputs", "final", "figure1.pdf"), height = 4.25, width =6)

(a + b )/ (c + d)

dev.off()
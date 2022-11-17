#######################################################
#
# This script estimates negative binomial models
#   for overall opioid prescribing (prevalent, new, high dose)
#   and among people in care homes (prevalent, new, high dose)
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
library('TSA')
library('tseries')
library('forecast')
library('astsa')
library(MASS)
library(sandwich)
library(lmtest)
library(PNWColors)
library(ggpubr)

## Create directories
dir_create(here::here("output", "released_outputs"), showWarnings = FALSE, recurse = TRUE)
dir_create(here::here("output", "released_outputs", "graphs"), showWarnings = FALSE, recurse = TRUE)

## Read in data
combined <- read_csv(here::here("output", "released_outputs", "ts_combined_full.csv"),
                      col_types = cols(
                        group  = col_character(),
                        label = col_character(),
                        date = col_date(format="%Y-%m-%d")))

## Create variables to estimate change during
##    lockdown and recovery periods
data1 <- ts(subset(combined, group == "Total")$prevalence_per_1000, 
            start = c(2018,01,01), frequency = 12)


combined.its <- combined %>% arrange(group, label, date) %>%
  mutate(time = rep(1:51, 40),
         mar20 = ifelse(date == as.Date("2020-03-01"), 1, 0),
         apr20 = ifelse(date == as.Date("2020-04-01"), 1, 0),
         may20 = ifelse(date == as.Date("2020-05-01"), 1, 0),
         step = ifelse(date < as.Date("2020-03-01"), 0, 1),
         step2 = ifelse(date < as.Date("2021-04-01"), 0, 1),
         slope = ifelse(date < as.Date("2020-03-01"), 0, time-26),
         slope2 = ifelse(date < as.Date("2021-04-01"), 0, time-39), 
         month = as.factor(month(date))
        )

write.csv(combined.its, file = here::here("output", "released_outputs", "ts_combined_full.csv"),
                row.names = FALSE)

# Functions

coef <- function(mod){
  data.frame(est = exp(mod$coef), 
        exp(coefci(mod, vcov = NeweyWest(mod, lag = 2, prewhite = F)))) %>%
    rename(lci = `X2.5..`, uci = `X97.5..`) %>%
    mutate(est = round(est, 3), lci = round(lci, 3), 
           uci = round(uci, 3))
}

pred.val <- function(mod, group, pop, var, obs){
  pred <- predict(mod, se.fit = TRUE, interval = "confidence")
  pred2 <- data.frame(pred_n = exp(pred$fit), 
             lci_n = exp(pred$fit-1.96*pred$se.fit),
             uci_n = exp(pred$fit+1.96*pred$se.fit),
             subset(combined, group == group)) %>% 
  mutate(pred = pred_n/!!enquo(pop)*1000, 
         pred_lci = lci_n/ !!enquo(pop)*1000,
         pred_uci = uci_n/ !!enquo(pop) * 1000, 
         var = var) %>%
  rename(obs = !!enquo(obs))%>%
  dplyr::select(c(date, pred, obs, var, pred_lci, pred_uci, period))
 
  return(pred2) 
}

###################################################
#### Model for overall prescribing ################
###################################################


df.data1 <- subset(combined.its, group == "Total") %>%
  rename(opioid = any_opioid_prescribing,
                  pop = total_population)

# Base model
mod1 <- glm.nb(opioid ~ time +  step + step2 + slope + slope2 + 
             as.factor(month) + offset(log(pop)), df.data1, link = "log")
summary(mod1)

# Compare with model including Mar/Apr/May dummies
mod2 <- glm.nb(opioid ~ time +  step + step2 + slope + slope2 + mar20 + apr20 +may20 +
                  as.factor(month) + offset(log(pop)), df.data1, link = "log")
summary(mod2)
  
AIC(mod1)
AIC(mod2)
lrtest(mod1,mod2)

## Check autocorrelation of residuals
Box.test(mod2$residuals, type = 'Ljung-Box')

# Extract coefficients, calculated Newey-West adjusted 95%CIs
coef_prev <- coef(mod2)
write.csv(coef_prev,  
          file = here::here("output", "released_outputs", "ts_coef_any_prev.csv"),
          row.names = TRUE)

# Calculate predicted values (for graphs)
pred_prev <- pred.val(mod2, "Total", total_population, "Prevalence", prevalence_per_1000)



###################################################
#### Model for overall incidence ##################
###################################################


df.data1 <- subset(combined.its, group == "Total") %>%
  rename(opioid = new_opioid_prescribing,
         pop = opioid_naive)

# Base model
mod1 <- glm.nb(opioid ~ time +  step + step2 + slope + slope2 + 
                 as.factor(month) + offset(log(pop)), df.data1, link = "log")
summary(mod1)

# Compare with model including Mar/Apr/May dummies
mod2 <- glm.nb(opioid ~ time +  step + step2 + slope + slope2 + mar20 + apr20 +may20 +
                 as.factor(month) + offset(log(pop)), df.data1, link = "log")
summary(mod2)

AIC(mod1)
AIC(mod2)
lrtest(mod1,mod2)

## Check autocorrelation of residuals
Box.test(mod1$residuals, type = 'Ljung-Box')

# Extract coefficients, calculated Newey-West adjusted 95%CIs
coef_prev <- coef(mod1)

write.csv(coef_prev, 
          file = here::here("output", "released_outputs", "ts_coef_any_new.csv"),
          row.names = TRUE)

# Calculate predicted values (for graphs)
pred_new <- pred.val(mod1, "Total", opioid_naive, "Incidence", incidence_per_1000)


###################################################
#### High dose prevalence #########################
###################################################


df.data1 <- subset(combined.its, group == "Total") %>%
  rename(opioid = any_high_dose_opioid_prescribing,
         pop = total_population)

# Base model
mod1 <- glm.nb(opioid ~ time +  step + step2 + slope + slope2 + 
                 as.factor(month) + offset(log(pop)), df.data1, link = "log")
summary(mod1)

# Compare with model including Mar/Apr/May dummies
mod2 <- glm.nb(opioid ~ time +  step + step2 + slope + slope2 + mar20 + apr20 +may20 +
                 as.factor(month) + offset(log(pop)), df.data1, link = "log")
summary(mod2)

AIC(mod1)
AIC(mod2)
lrtest(mod1, mod2)

## Check autocorrelation of residuals
Box.test(mod1$residuals, type = 'Ljung-Box')

# Extract coefficients, calculated Newey-West adjusted 95%CIs
coef_prev <- coef(mod1)

write.csv(coef_prev,  
          file = here::here("output", "released_outputs", "ts_coef_hi_prev.csv"),
          row.names = TRUE)

# Calculate predicted values (for graphs)
pred_hi <- pred.val(mod1, "Total", total_population, "High dose prevalence", high_dose_prevalence_per_1000)


##################################

# Combine all predicted values together 

pred_all <- rbind(pred_prev, pred_new, pred_hi)

pred_all$var <- factor(pred_all$var, 
                       levels = c("Prevalence", "High dose prevalence","Incidence"),
                       labels =c("Any opioid prescribing", 
                                 "High dose/long-acting opioid prescribing",
                                 "New opioid prescribing"))




##############################
#
# Care homes 
#
##############################


###################################################
#### Model for overall prescribing ################
###################################################


df.data1 <- subset(combined.its, group == "Care home" & label == "Yes") %>%
  rename(opioid = any_opioid_prescribing,
         pop = total_population)

# Base model
mod1 <- glm.nb(opioid ~ time +  step + step2 + slope + slope2 + 
                 as.factor(month) + offset(log(pop)), df.data1, link = "log")
summary(mod1)

# Compare with model including Mar/Apr/May dummies
mod2 <- glm.nb(opioid ~ time +  step + step2 + slope + slope2 + mar20 + apr20 +may20 +
                 as.factor(month) + offset(log(pop)), df.data1, link = "log")
summary(mod2)

AIC(mod1)
AIC(mod2)
lrtest(mod1, mod2)

## Check autocorrelation of residuals
Box.test(mod2$residuals, type = 'Ljung-Box')

# Extract coefficients, calculated Newey-West adjusted 95%CIs
coef_prev <- coef(mod2)
write.csv(coef_prev,  
          file = here::here("output", "released_outputs", "ts_coef_any_prev.csv"),
          row.names = TRUE)

# Calculate predicted values (for graphs)
pred_prev <- pred.val(mod2, "Total", total_population, "Prevalence", prevalence_per_1000)



###################################################
#### Model for overall incidence ##################
###################################################


df.data1 <- subset(combined.its, group == "Care home" & label == "Yes") %>%
  rename(opioid = new_opioid_prescribing,
         pop = opioid_naive)


# Base model
mod1 <- glm.nb(opioid ~ time +  step + step2 + slope + slope2 + 
                 as.factor(month) + offset(log(pop)), df.data1, link = "log")
summary(mod1)

# Compare with model including Mar/Apr/May dummies
mod2 <- glm.nb(opioid ~ time +  step + step2 + slope + slope2 + mar20 + apr20 +may20 +
                 as.factor(month) + offset(log(pop)), df.data1, link = "log")
summary(mod2)

AIC(mod1)
AIC(mod2)
lrtest(mod1,mod2)

## Check autocorrelation of residuals
Box.test(mod1$residuals, type = 'Ljung-Box')

# Extract coefficients, calculated Newey-West adjusted 95%CIs
coef_prev <- coef(mod1)

write.csv(coef_prev, 
          file = here::here("output", "released_outputs", "ts_coef_any_new.csv"),
          row.names = TRUE)

# Calculate predicted values (for graphs)
pred_new <- pred.val(mod1, "Total", opioid_naive, "Incidence", incidence_per_1000)


###################################################
#### High dose prevalence #########################
###################################################


df.data1 <- subset(combined.its, group == "Care home" & label == "Yes") %>%
  rename(opioid = any_high_dose_opioid_prescribing,
         pop = total_population)

# Base model
mod1 <- glm.nb(opioid ~ time +  step + step2 + slope + slope2 + 
                 as.factor(month) + offset(log(pop)), df.data1, link = "log")
summary(mod1)

# Compare with model including Mar/Apr/May dummies
mod2 <- glm.nb(opioid ~ time +  step + step2 + slope + slope2 + mar20 + apr20 +may20 +
                 as.factor(month) + offset(log(pop)), df.data1, link = "log")
summary(mod2)

AIC(mod1)
AIC(mod2)
lrtest(mod1, mod2)

## Check autocorrelation of residuals
Box.test(mod1$residuals, type = 'Ljung-Box')

# Extract coefficients, calculated Newey-West adjusted 95%CIs
coef_prev <- coef(mod1)

write.csv(coef_prev,  
          file = here::here("output", "released_outputs", "ts_coef_hi_prev.csv"),
          row.names = TRUE)

# Calculate predicted values (for graphs)
pred_hi <- pred.val(mod1, "Total", total_population, "High dose prevalence", high_dose_prevalence_per_1000)


#########################################

# Combine all predicted values together 

pred_care <- rbind(pred_prev, pred_new, pred_hi)

pred_care$var <- factor(pred_care$var, 
                       levels = c("Prevalence", 
                                  "High dose prevalence",
                                  "Incidence"),
                       labels =c("Any opioid prescribing", 
                                 "High dose/long-acting opioid prescribing",
                                 "New opioid prescribing"))


##############################################
#### Plot overall and care homes together 
##############################################


full <- ggplot(pred_all, aes(x =date)) + 
  geom_point(aes( y = obs, col = var, fill = var), alpha=.3) +
  geom_ribbon(aes(ymin = pred_lci, ymax = pred_uci), alpha=.5, fill = "gray90")+
  geom_line(aes( y = pred, col = var), size = 1) +
  geom_vline(aes(xintercept = as.Date("2020-03-01")), linetype = "longdash", col = "black") +
  geom_vline(aes(xintercept = as.Date("2021-03-01")), linetype = "longdash", col = "black") +
  
  scale_y_continuous(expand = c(.4,0)) +
  scale_fill_manual(values = pnw_palette("Bay", 3), guide = "none")+
  scale_color_manual(values = pnw_palette("Bay", 3, "discrete")) +
  facet_wrap(~ var , nrow=1, scales = "free_y") +
  xlab("") + ylab("No. people per 1000\nregistered adult patients")+
  theme_bw() + 
  theme(text = element_text(size = 10),
        panel.grid.major.x = element_blank(), strip.background = element_blank(),
        strip.text = element_blank(),legend.title = element_blank(),
        panel.grid.minor.x = element_blank(),
        panel.grid.major.y =element_line(color = "gray90"),
        axis.title.y = element_text(size = 8),
        axis.text.x = element_text(angle = 45, hjust = 1))

care <- ggplot(pred_care, aes(x =date)) + 
  geom_point(aes( y = obs, col = var, fill = var), alpha=.3) +
  geom_ribbon(aes(ymin = pred_lci, ymax = pred_uci), alpha=.5, fill = "gray90")+
  geom_line(aes( y = pred, col = var), size = 1) +
  
  geom_vline(aes(xintercept = as.Date("2020-03-01")), linetype = "longdash", col = "black") +
  geom_vline(aes(xintercept = as.Date("2021-03-01")), linetype = "longdash", col = "black") +
  scale_y_continuous(expand = c(.4,0)) +
  scale_fill_manual(values = pnw_palette("Bay", 3), guide = "none")+
  scale_color_manual(values = pnw_palette("Bay", 3, "discrete")) +
  facet_wrap(~ var , nrow=1, scales = "free_y") +
  xlab("") + ylab("No. people per 1000 registered\nadult patients in care homes")+
  theme_bw() + 
  theme(text = element_text(size = 10), strip.text=element_blank(),
        panel.grid.major.x = element_blank(), strip.background = element_blank(),
        panel.grid.minor.x = element_blank(), legend.title = element_blank(),
        panel.grid.major.y =element_line(color = "gray90"),
        axis.title.y = element_text(size = 8), 
        axis.text.x = element_text(angle = 45, hjust = 1))


png("figure1.png", res = 300, units = "in", height = 4.5, width = 8)

ggarrange(full, care, nrow = 2, labels = "auto", label.y = 1.15, common.legend = TRUE)

dev.off()

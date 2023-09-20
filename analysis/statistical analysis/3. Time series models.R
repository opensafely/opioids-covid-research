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
overall <- read_csv(here::here("output", "released_outputs", "ts_overall_rounded.csv"),
                      col_types = cols(month = col_date(format="%Y-%m-%d")))
demo <- read_csv(here::here("output", "released_outputs", "ts_demo_rounded.csv"),
                    col_types = cols(month = col_date(format="%Y-%m-%d")))
type <- read_csv(here::here("output", "released_outputs", "ts_type_rounded.csv"),
                    col_types = cols(month = col_date(format="%Y-%m-%d")))
carehome <- read_csv(here::here("output", "released_outputs", "ts_carehome_rounded.csv"),
                    col_types = cols(month = col_date(format="%Y-%m-%d")))

## Create ITS variables
its.vars <- overall %>%
            dplyr::select(month) %>%
            mutate(mar20 = ifelse(month == as.Date("2020-03-01"), 1, 0),
                    apr20 = ifelse(month == as.Date("2020-04-01"), 1, 0),
                    may20 = ifelse(month == as.Date("2020-05-01"), 1, 0),
                    step = ifelse(month < as.Date("2020-03-01"), 0, 1),
                    step2 = ifelse(month < as.Date("2021-04-01"), 0, 1),
                    month_dummy = as.factor(month(month)),
                    time = seq(1, by = 1, length.out = nrow(overall)),
                    slope = ifelse(as.Date(month, format="%Y-%m-%d") < as.Date("2020-03-01"), 0, 
                                  time - sum(step == 0)),
                    slope2 = ifelse(as.Date(month, format="%Y-%m-%d") < as.Date("2021-04-01"), 0, 
                                   time - sum(step2 == 0)))

## Merge ITS vars into datasets
overall.its <- overall %>% 
  arrange(month) %>% 
  merge(its.vars, by = "month")

write.csv(overall.its, file = here::here("output", "released_outputs", "ts_overall_its.csv"),
          row.names = FALSE)


demo.its <- demo %>%
  arrange(month) %>%
  merge(its.vars, by = "month")

write.csv(demo.its, file = here::here("output", "released_outputs", "ts_demo_its.csv"),
          row.names = FALSE)


type.its <- type %>%
  arrange(month) %>%
  merge(its.vars, by = "month")

write.csv(type.its, file = here::here("output", "released_outputs", "ts_type_its.csv"),
          row.names = FALSE)


carehome.its <- carehome %>%
  arrange(month) %>%
  merge(its.vars, by = "month")

write.csv(carehome.its, file = here::here("output", "released_outputs", "ts_carehome_its.csv"),
          row.names = FALSE)


#################
### Functions ###
#################

# Extracting coefficients and 95%CIs with standard errors 
#    adjusted for autocorrelation
coef <- function(mod){
  data.frame(est = exp(mod$coef), 
        exp(coefci(mod, vcov = NeweyWest(mod, lag = 2, prewhite = F)))) %>%
    rename(lci = `X2.5..`, uci = `X97.5..`) %>%
    mutate(est = round(est, 3), lci = round(lci, 3), 
           uci = round(uci, 3))
}

# Calculating predicted values
pred.val <- function(mod, data, pop, outcome, var, obs){
  
  pred <- predict(mod, se.fit = TRUE, interval = "confidence")
  pred2 <- data.frame(pred_n = exp(pred$fit), 
             lci_n = exp(pred$fit - 1.96 * pred$se.fit),
             uci_n = exp(pred$fit + 1.96 * pred$se.fit),
             data) %>% 
  mutate(pred = pred_n / !!enquo(pop) * 1000, 
         pred_lci = lci_n / !!enquo(pop) * 1000,
         pred_uci = uci_n / !!enquo(pop) * 1000, 
         outcome = outcome,
         var = var
         ) %>%
  rename(obs = !!enquo(obs)) %>%
  dplyr::select(c(month, pred, obs, outcome, var, pred_lci, pred_uci, period))
 
  return(pred2) 
}

######################################
#### Full population  ################
######################################

#### Overall prescribing ####

df.data1 <- overall.its %>%
  rename(opioid = opioid_any_round, pop = pop_total_round)

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
pred_prev <- pred.val(mod2, overall.its, pop_total_round, "Prevalence", "Overall", rate_opioid_any_round) 


#### Overall incidence ####

df.data1 <- overall.its %>%
  rename(opioid = opioid_new_round, pop = pop_naive_round)

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
pred_new <- pred.val(mod1, overall.its, pop_naive_round, "Incidence", "Overall", rate_opioid_new_round)


#### OVerall high dose prescribing ####

df.data1 <- overall.its %>%
  rename(opioid = hi_opioid_any_round, pop = pop_total_round)

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
pred_hi <- pred.val(mod1, overall.its, pop_total_round, "High dose prevalence", "Overall", rate_hi_opioid_any_round)


##################################

# Combine all predicted values together 

pred_all <- rbind(pred_prev, pred_new, pred_hi)

pred_all$outcome <- factor(pred_all$outcome, 
                       levels = c("Prevalence", "High dose prevalence","Incidence"),
                       labels =c("Any opioid prescribing", 
                                 "High dose/long-acting opioid prescribing",
                                 "New opioid prescribing"))

write.csv(pred_all, here::here("output", "released_outputs", "final", "ts_predicted_all.csv"),
          row.names = FALSE)



##############################
######## Care homes ##########
##############################

#### Overall prescribing ####

df.data1 <- carehome.its %>%
  rename(opioid = opioid_any_round,
         pop = pop_total_round)

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
coef_care_prev <- coef(mod2)
write.csv(coef_care_prev,  
          file = here::here("output", "released_outputs", "final", "ts_coef_carehome_prev.csv"),
          row.names = TRUE)

# Calculate predicted values (for graphs)
pred_care_prev <- pred.val(mod2, carehome.its, pop_total_round, "Prevalence", "Care home", rate_opioid_any_round)


#### Overall incidence ####

df.data1 <- carehome.its %>%
  rename(opioid = opioid_new_round,
         pop = pop_naive_round)

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
lrtest(mod1,mod2)

## Check autocorrelation of residuals
Box.test(mod2$residuals, type = 'Ljung-Box')

# Extract coefficients, calculated Newey-West adjusted 95%CIs
coef_care_new <- coef(mod2)

write.csv(coef_care_new, 
          file = here::here("output", "released_outputs", "final", "ts_coef_care_new.csv"),
          row.names = TRUE)

# Calculate predicted values (for graphs)
pred_care_new <- pred.val(mod2, carehome.its, pop_naive_round, "Incidence", "Care home", rate_opioid_new_round)


#### High dose prescribing ####

df.data1 <- carehome.its %>%
  rename(opioid = hi_opioid_any_round,
         pop = pop_naive_round)

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
Box.test(mod1$residuals, type = 'Ljung-Box')

# Extract coefficients, calculated Newey-West adjusted 95%CIs
coef_care_hi <- coef(mod1)

write.csv(coef_care_hi,  
          file = here::here("output", "released_outputs", "final", "ts_coef_carehome_hi.csv"),
          row.names = TRUE)

# Calculate predicted values (for graphs)
pred_care_hi <- pred.val(mod1, carehome.its, pop_total_round, "High dose prevalence", "Care home", rate_hi_opioid_any_round)


#########################################

# Combine all predicted values together 

pred_carehome <- rbind(pred_care_prev, pred_care_new, pred_care_hi)

pred_carehome$outcome <- factor(pred_carehome$outcome, 
                       levels = c("Prevalence", 
                                  "High dose prevalence",
                                  "Incidence"),
                       labels =c("Any opioid prescribing", 
                                 "High dose/long-acting opioid prescribing",
                                 "New opioid prescribing"))

write.csv(pred_carehome, here::here("output", "released_outputs", "final", "ts_predicted_carehome.csv"),
          row.names = FALSE)


##############################################
#### Plot overall and care homes together 
##############################################

full <- ggplot(pred_all, aes(x =month)) + 
  geom_point(aes( y = obs, col = outcome, fill = outcome), alpha=.3) +
  geom_ribbon(aes(ymin = pred_lci, ymax = pred_uci), alpha=.5, fill = "gray90")+
  geom_line(aes(y = pred, col = outcome), linewidth = 1) +
  geom_vline(aes(xintercept = as.Date("2020-03-01")), linetype = "longdash", col = "black") +
  geom_vline(aes(xintercept = as.Date("2021-03-01")), linetype = "longdash", col = "black") +
  
  scale_y_continuous(expand = c(.4,0)) +
  scale_fill_manual(values = pnw_palette("Bay", 3), guide = "none")+
  scale_color_manual(values = pnw_palette("Bay", 3, "discrete")) +
  facet_wrap(~ outcome , nrow=1, scales = "free_y") +
  xlab("") + ylab("No. people per 1000\nregistered adult patients")+
  theme_bw() + 
  theme(text = element_text(size = 10),
        panel.grid.major.x = element_blank(), strip.background = element_blank(),
        strip.text = element_blank(),legend.title = element_blank(),
        panel.grid.minor.x = element_blank(),
        panel.grid.major.y =element_line(color = "gray90"),
        axis.title.y = element_text(size = 8),
        axis.text.x = element_text(angle = 45, hjust = 1))

care <- ggplot(pred_carehome, aes(x =month)) + 
  geom_point(aes( y = obs, col = outcome, fill = outcome), alpha=.3) +
  geom_ribbon(aes(ymin = pred_lci, ymax = pred_uci), alpha=.5, fill = "gray90")+
  geom_line(aes( y = pred, col = outcome), size = 1) +
  
  geom_vline(aes(xintercept = as.Date("2020-03-01")), linetype = "longdash", col = "black") +
  geom_vline(aes(xintercept = as.Date("2021-03-01")), linetype = "longdash", col = "black") +
  scale_y_continuous(expand = c(.4,0)) +
  scale_fill_manual(values = pnw_palette("Bay", 3), guide = "none")+
  scale_color_manual(values = pnw_palette("Bay", 3, "discrete")) +
  facet_wrap(~ outcome , nrow=1, scales = "free_y") +
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

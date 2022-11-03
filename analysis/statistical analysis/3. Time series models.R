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
library('TSA')
library('tseries')
library('forecast')
library('astsa')
library(MASS)
library(sandwich)
library(lmtest)

## Create directories
dir_create(here::here("output", "released_outputs"), showWarnings = FALSE, recurse = TRUE)
dir_create(here::here("output", "released_outputs", "graphs"), showWarnings = FALSE, recurse = TRUE)


# Read in data
combined <- read_csv(here::here("output", "released_outputs", "ts_combined_full.csv"),
                      col_types = cols(
                        group  = col_character(),
                        label = col_character(),
                        date = col_date(format="%Y-%m-%d")))

# ITS variables
data1 <- ts(subset(combined, group == "Total")$prevalence_per_1000, start = c(2018,01,01), frequency = 12)

time <- seq(1,length(data1))
step <- append(rep(0,26),rep(1,25))
slope <- append(rep(0,26),seq(1,25))
slope2 <- append(rep(0,39),seq(1,12))
step2 <- append(rep(0,39), rep(1,12))
month <- seasonaldummy(data1) 
month2 <- season(data1)

mar20 <- append(append(rep(0,26),1),rep(0,24))
nov20 <- append(append(rep(0,34),1),rep(0,16))
jan21 <- append(append(rep(0,36),1),rep(0,14))
apr20 <- append(append(rep(0,27),1),rep(0,23))



# Overall prescribing ##################

data1 <- ts(subset(combined, group == "Total")$prevalence_per_1000, start = c(2018,01,01), frequency = 12)
df.data1 <- cbind(opioid = subset(combined, group == "Total")$any_opioid_prescribing,
                  pop = subset(combined, group == "Total")$total_population,
                  rate = subset(combined, group == "Total")$prevalence_per_1000,
                  time, step, step2, slope, slope2, month ,month = month2, mar20) %>% as.data.frame()

#mod1 <- lm(data1 ~ time + step + step2 + slope + month + mar20)
#Box.test(mod1$residuals, type = "Ljung-Box", lag = 12)

mod1 <- glm.nb(opioid ~ time + mar20 + step + step2 + slope + slope2 +
             as.factor(month) +
                offset(log(pop)), df.data1, link = "log")

coef <- cbind(est = exp(mod1$coef), exp(coefci(mod1,vcov=NeweyWest(mod1,lag = 2,prewhite = FALSE))))

pred <- predict(mod1, newdata= data.frame(month = "2", time, step , step2 , slope,
                                      slope2, mar20, pop = df.data1$pop), se.fit = TRUE)

pred_prev <- 
  data.frame(pred_n = exp(pred$fit), lci_n = exp(pred$fit-1.96*pred$se.fit),
             uci_n = exp(pred$fit+1.96*pred$se.fit),
             subset(combined, group == "Total")) %>% 
  mutate(pred = pred_n/opioid_naive*1000, pred_lci = lci_n/opioid_naive*1000,
         pred_uci = uci_n/opioid_naive*1000, var = "Prevalence") %>%
  rename(obs = prevalence_per_1000)%>%
  dplyr::select(c(date, pred, obs, var, pred_lci, pred_uci, period))



# Overall incidence ##################

data1 <- ts(subset(combined, group == "Total")$incidence_per_1000, start = c(2018,01,01), frequency = 12)

df.data1 <- cbind(opioid = subset(combined, group == "Total")$new_opioid_prescribing,
                  pop = subset(combined, group == "Total")$opioid_naive,
                  rate = subset(combined, group == "Total")$incidence_per_1000,
                  time, step, step2, slope, slope2, month ,month = month2, mar20) %>% as.data.frame()

#mod1 <- lm(data1 ~ time + step + step2 + slope + month + mar20)
#Box.test(mod1$residuals, type = "Ljung-Box", lag = 12)

mod1 <- glm.nb(opioid ~ time + mar20 + step + step2 + slope + slope2 +
                 as.factor(month) +
                 offset(log(pop)), df.data1, link = "log")

coef <- cbind(est = exp(mod1$coef), exp(coefci(mod1,vcov=NeweyWest(mod1,lag = 2,prewhite = FALSE))))

pred <- predict(mod1, newdata= data.frame(month = "5", time, step , step2 , slope,
                                          slope2, mar20, pop = df.data1$pop), se.fit = TRUE, interval = "confidence")

pred_inc <- 
  data.frame(pred_n = exp(pred$fit), lci_n = exp(pred$fit-1.96*pred$se.fit),
             uci_n = exp(pred$fit+1.96*pred$se.fit),
             subset(combined, group == "Total")) %>% 
  mutate(pred = pred_n/opioid_naive*1000, pred_lci = lci_n/opioid_naive*1000,
         pred_uci = uci_n/opioid_naive*1000, var = "Incidence") %>%
  rename(obs = incidence_per_1000) %>%
  dplyr::select(c(date, pred, obs, var, pred_lci, pred_uci, period))





# High dose prevalence ##################

df.data1 <- cbind(opioid = subset(combined, group == "Total")$any_high_dose_opioid_prescribing,
                  pop = subset(combined, group == "Total")$total_population,
                  rate = subset(combined, group == "Total")$high_dose_prevalence_per_1000,
                  time, step, step2, slope, slope2, month , month = month2, mar20) %>% as.data.frame()

#mod1 <- lm(data1 ~ time + step + step2 + slope + month + mar20)
#Box.test(mod1$residuals, type = "Ljung-Box", lag = 12)

mod1 <- glm.nb(opioid ~ time + mar20 + step + step2 + slope + slope2 +
                 as.factor(month)+
                 offset(log(pop)), df.data1, link = "log")

coef <- cbind(est = exp(mod1$coef), exp(coefci(mod1,vcov=NeweyWest(mod1,lag = 2,prewhite = FALSE))))

pred <- predict(mod1, newdata= data.frame(month = "2", time, step , step2 , slope,
                                          slope2, mar20, pop = df.data1$pop), se.fit = TRUE, interval = "confidence")

pred_hi <- 
  data.frame(pred_n = exp(pred$fit), lci_n = exp(pred$fit-1.96*pred$se.fit),
             uci_n = exp(pred$fit+1.96*pred$se.fit),
             subset(combined, group == "Total")) %>% 
  mutate(pred = pred_n/opioid_naive*1000, pred_lci = lci_n/opioid_naive*1000,
         pred_uci = uci_n/opioid_naive*1000, var = "High dose prevalence") %>%
  rename(obs = high_dose_prevalence_per_1000) %>%
  dplyr::select(c(date, pred, obs, var, pred_lci, pred_uci, period))

#######

pred_all <- rbind(pred_prev, pred_inc, pred_hi)

pred_all$var <- factor(pred_all$var, levels = c("Prevalence", "High dose prevalence","Incidence"),
                       labels =c("Prevalence (any opioid)", "Prevalence (high dose/long-acting opioid)",
                                 "Incidence (any opioids"))

library(PNWColors)

ggplot(pred_all, aes(x =date)) + 
  geom_point(aes( y = obs, col = var, fill = var),alpha=.5) +
  geom_ribbon(aes(ymin = pred_lci, ymax = pred_uci), alpha=.3, fill = "gray90")+
  geom_line(aes( y = pred, col = var), size = 1) +
  geom_vline(aes(xintercept = as.Date("2020-03-01")), linetype = "longdash", col = "red") +
  geom_vline(aes(xintercept = as.Date("2020-11-01")), linetype = "longdash", col = "gray70") +
  geom_vline(aes(xintercept = as.Date("2021-01-01")), linetype = "longdash", col = "gray70") +
  geom_vline(aes(xintercept = as.Date("2021-03-01")), linetype = "longdash", col = "red") +
  scale_y_continuous(expand = c(.3,0)) +
  scale_fill_manual(values = pnw_palette("Bay", 3), guide = "none")+
  scale_color_manual(values = pnw_palette("Bay", 3), guide = "none") +
  facet_wrap(~ var , nrow=3, scales = "free_y") +
  xlab("") + ylab("People prescribed opioids per\n1000 registered patients")+
  theme_bw() + 
  theme(text = element_text(size = 10),
        panel.grid.major.x = element_blank(), strip.background = element_blank(),
        strip.text = element_text(hjust=0) ,
        panel.grid.minor.x = element_blank(),
        panel.grid.major.y =element_line(color = "gray90"),
        axis.title.y = element_text(size = 10),
        axis.text.x = element_text(angle = 45, hjust = 1))

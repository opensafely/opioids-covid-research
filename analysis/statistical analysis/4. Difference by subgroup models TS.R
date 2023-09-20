#######################################################
#
# This script estimates negative binomial models
#   for overall opioid prescribing and initiation
#   to determine differences in changes by subgroup
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
library(miceadds)
library(PNWColors)
library(MASS)
library(lmtest)
library(sandwich)
library(janitor)
library(fastDummies)
library(MASS)

## Create directories
dir_create(here::here("output", "released_outputs"), showWarnings = FALSE, recurse = TRUE)
dir_create(here::here("output", "released_outputs", "graphs"), showWarnings = FALSE, recurse = TRUE)
dir_create(here::here("output", "released_outputs", "graphs"), showWarnings = FALSE, recurse = TRUE)


##### Read in data #######
demo.its <- read_csv(here::here("output", "released_outputs", "ts_demo_its.csv"),
                      col_types = cols(month = col_date(format = "%Y-%m-%d"))) 


##############################################

# Function for prevalent prescribing model 
nb <- function(data, ref){
  
  data$cat <- relevel(as.factor(data$cat), ref = ref)
  
  # Prevalent prescribing
  mod.any <- glm.nb(opioid_any_round ~ time + step*cat + step2*cat + 
                      slope + slope2 + mar20 + apr20 + may20 +
                      as.factor(month_dummy) + offset(log(pop_total_round)), 
                    data = data, link = "log",
                    control = list(trace = TRUE, maxiter = 30, epsilon = 1))
  
  ci.any <- coefci(mod.any, vcov. = vcovPL(mod.any, cluster = data$cat)) %>% exp()
  coef.any <- mod.any$coefficients %>% exp()
  
  coef.any <- data.frame(ci.any, coef = coef.any, 
                         label = rownames(ci.any)) %>% 
    clean_names() %>% 
    subset(label %in% c("step", "step2")) %>%
    mutate(
      coef = as.numeric(coef), 
      x2_5 = as.numeric(x2_5), 
      x97_5 = as.numeric(x97_5),
      time = ifelse(label == "step", "Lockdown", "Recovery"),
      type = "Prevalent",
      label = ref)
  
  # New prescribing
  mod.new <- glm.nb(opioid_new_round ~ time + step*cat  + step2*cat + 
                      slope + slope2 + as.factor(month_dummy) + offset(log(pop_naive_round)), 
                    data = data, link = "log",
                    control = list(trace = TRUE, maxiter = 30, epsilon = 1))
  
  ci.new <- coefci(mod.new, vcov. = vcovPL(mod.new, cluster = data$cat)) %>% exp()
  coef.new <- mod.new$coefficients %>% exp()
  
  coef.new <- data.frame(ci.new, coef = coef.new, 
                         label = rownames(ci.new)) %>% 
    clean_names() %>% 
    subset(label %in% c("step", "step2")) %>%
    mutate(
      coef = as.numeric(coef), 
      x2_5 = as.numeric(x2_5), 
      x97_5 = as.numeric(x97_5),
      time = ifelse(label == "step", "Lockdown", "Recovery"),
      type = "Incident",
      label = ref)
  
  coef <- rbind(coef.any, coef.new)
  
  return(coef)

}

# Function for predicted values from prevalent prescribing model
pred.val <- function(data){

  # Any prescribing
  mod.any <- glm.nb(opioid_any_round ~ time + step*cat + step2*cat + 
                      slope + slope2 + mar20 + apr20 + may20 +
                      as.factor(month_dummy) + offset(log(pop_total_round)), 
                    data = data, link = "log",
                    control = list(trace = TRUE, maxiter = 30, epsilon = 1))
  
  pred.any <- predict(mod.any, se.fit = TRUE)
  
  pred.any <- 
    data.frame(pred_n = exp(pred.any$fit), 
               lci_n = exp(pred.any$fit - 1.96 * pred.any$se.fit),
               uci_n = exp(pred.any$fit + 1.96 * pred.any$se.fit), 
               data) %>% 
    mutate(pred = pred_n / pop_total_round * 1000, 
           pred_lci = lci_n / pop_total_round * 1000,
           pred_uci = uci_n / pop_total_round * 1000,
           type = "Prevalent") %>%
    rename(obs = rate_opioid_any_round) %>%
    dplyr::select(c(month, pred, obs, pred_lci, pred_uci,
                    type, period, var, cat))
  
  # New prescribing
  mod.new <- glm.nb(opioid_new_round ~ time + step*cat + step2*cat + 
                      slope + slope2 + mar20 + apr20 + may20 +
                      as.factor(month_dummy) + offset(log(pop_naive_round)), 
                      data = data, link = "log",
                      control = list(trace = TRUE, maxiter = 30, epsilon = 1))
  
  pred.new <- predict(mod.new, se.fit = TRUE)
  
  pred.new <- 
    data.frame(pred_n = exp(pred.new$fit), 
               lci_n = exp(pred.new$fit - 1.96 * pred.new$se.fit),
               uci_n = exp(pred.new$fit + 1.96 * pred.new$se.fit), 
               data) %>% 
    mutate(pred = pred_n / pop_naive_round * 1000, 
           pred_lci = lci_n / pop_naive_round * 1000,
           pred_uci = uci_n / pop_naive_round * 1000,
           type = "Incident") %>%
    rename(obs = rate_opioid_new_round) %>%
    dplyr::select(c(month, pred, obs, pred_lci, pred_uci, 
                    type, period, var, cat))
  
  pred <- rbind(pred.any, pred.new)
  
  return(pred)
}


####################################################

#### By age group ####

age <- subset(demo.its, var == "age") %>% 
  arrange(cat, month)

# Run NegBin models, extract coefficients and 
#    calculate predicted values
age_coef1 <- nb(data = age, ref = "18-29")  
age_coef2 <- nb(data = age, ref = "30-39") 
age_coef3 <- nb(data = age, ref = "40-49")  
age_coef4 <- nb(data = age, ref = "50-59")
age_coef5 <- nb(data = age, ref = "60-69") 
age_coef6 <- nb(data = age, ref = "70-79") 
age_coef7 <- nb(data = age, ref = "80-89") 
age_coef8 <- nb(data = age, ref = "90+")  

age_coef <- rbind(age_coef1, age_coef2, age_coef3, 
                  age_coef4, age_coef5, age_coef6, 
                  age_coef7, age_coef8) %>%
              mutate(var = "Age")

age_pred <- pred.val(age)


#### By IMD decile ####

imd <- subset(demo.its, var == "imd" & !(cat %in% c("Missing",NA))) %>% 
  arrange(cat, month)

# Run NegBin models, extract coefficients and 
#    calculate predicted values
imd_coef1 <- nb(data = imd, ref = "1 (most deprived)")  
imd_coef2 <- nb(data = imd, ref = "2")   
imd_coef3 <- nb(data = imd, ref = "3")    
imd_coef4 <- nb(data = imd, ref = "4")
imd_coef5 <- nb(data = imd, ref = "5")   
imd_coef6 <- nb(data = imd, ref = "6")   
imd_coef7 <- nb(data = imd, ref = "7")    
imd_coef8 <- nb(data = imd, ref = "8")  
imd_coef9 <- nb(data = imd, ref = "9")  
imd_coef10 <- nb(data = imd, ref = "10 (least deprived)")  

imd_coef <- rbind(imd_coef1, imd_coef2, imd_coef3, imd_coef4,
                  imd_coef5, imd_coef6, imd_coef7, imd_coef8,
                  imd_coef9, imd_coef10) %>%
                  mutate(var = "IMD decile")

imd_coef$label <- factor(imd_coef$label, 
                      levels=c("10 (least deprived)","9","8","7","6",
                               "5","4","3","2","1 (most deprived)"))

imd_pred <- pred.val(imd) 


#### By sex ####

sex <- subset(demo.its, var == "sex" & !(cat %in% c("Missing",NA))) %>% arrange(cat, month)

# Run NegBin models, extract coefficients and 
#    calculate predicted values
sex_coef1 <- nb(data = sex, ref = "female") 
sex_coef2 <- nb(data = sex, ref = "male")

sex_coef <- rbind(sex_coef1, sex_coef2) %>% mutate(var = "Sex")

sex_pred <- pred.val(sex) 


#### By ethnicity ####

eth <- subset(demo.its, var == "eth6" & !(cat %in% c("Missing",NA))) %>% arrange(cat,month)

# Run NegBin models, extract coefficients and 
#    calculate predicted values
eth_coef1 <- nb(data = eth, ref = "White")   
eth_coef2 <- nb(data = eth, ref = "Black")  
eth_coef3 <- nb(data = eth, ref = "South Asian")  
eth_coef4 <- nb(data = eth, ref = "Mixed")  
eth_coef5 <- nb(data = eth, ref = "Other")  
eth_coef6 <- nb(data = eth, ref = "Unknown")    
   
eth_coef <- rbind(eth_coef1, eth_coef2, 
                  eth_coef3, eth_coef4,
                  eth_coef5, eth_coef6) %>% 
            mutate(var = "Ethnicity")

eth_pred <- pred.val(eth) 


#### By region ####

region <- subset(demo.its, var == "region" & !(cat %in% c("Missing", NA))) %>% arrange(cat, month)

# Run NegBin models, extract coefficients and 
#    calculate predicted values
region_coef1 <- nb(data = region, ref = "East") 
region_coef2 <- nb(data = region, ref = "North East")
region_coef3 <- nb(data = region, ref = "North West")
region_coef4 <- nb(data = region, ref = "London") 
region_coef5 <- nb(data = region, ref = "Yorkshire and The Humber") 
region_coef6 <- nb(data = region, ref = "East Midlands")
region_coef7 <- nb(data = region, ref = "West Midlands") 
region_coef8 <- nb(data = region, ref = "South West")
region_coef9 <- nb(data = region, ref = "South East") 

region_coef <- rbind(region_coef1, region_coef2, region_coef3, 
                     region_coef4, region_coef5, region_coef6,
                     region_coef7, region_coef8, region_coef9) %>%
                mutate(var = "Region")

region_pred <- pred.val(region) 


#### Combine all coefficients

all.irr <- rbind(age_coef, sex_coef, imd_coef, region_coef, eth_coef)
write.csv(all.irr, here::here("output", "released_outputs", "final", "coefficients_bygroup.csv"),
          row.names = FALSE)

all.irr$time <- factor(all.irr$time, levels = c("Lockdown", "Recovery"),
                        labels = c("Lockdown period relative\nto pre-COVID-19",
                                   "Recovery period relative\nto lockdown period"))

all.irr$var <- factor(all.irr$var, levels = c("Age", "Sex", "IMD decile", "Region", "Ethnicity"))

all.irr$label <- factor(all.irr$label,
                         levels= c("90+", "80-89","70-79","60-69","50-59",
                                    "40-49","30-39","18-29","female","male",
                                    "1 (most deprived)","2","3","4","5","6","7","8","9","10 (least deprived)",
                                    "Yorkshire and The Humber","West Midlands","South West",
                                    "South East","North West","North East","London",
                                    "East Midlands","East","Unknown","Other","Mixed","Black",
                                    "South Asian","White"),
                         labels= c("90+ y", "80-89 y","70-79 y","60-69 y","50-59 y",
                                   "40-49 y","30-39 y","18-29 y","Female","Male",
                                   "1 most deprived","2","3","4","5","6","7","8","9","10 least deprived",
                                   "Yorkshire & The Humber","West Midlands","South West",
                                   "South East","North West","North East","London",
                                   "East Midlands","East","Unknown","Other","Mixed","Black/Black British",
                                   "Asian/Asian British","White"))

#### Combine all predicted values 

all.pred <- rbind(age_pred, sex_pred, imd_pred, region_pred, eth_pred)
write.csv(all.pred, here::here("output", "released_outputs", "final", "predicted_vals_bygroup.csv"),
          row.names = FALSE)



#### Figures with percent changes ####

png(here::here("output", "released_outputs", "graphs", "prev IRR pcent.png"), 
    res = 300, units = "in", width = 5, height = 7)

ggplot(data = subset(all.irr, type == "Prevalent"),
       aes(x = (coef-1)*100, y= label, group = time, col = time)) +
  geom_vline(aes(xintercept = 0), linetype = "longdash") +
  geom_point(position=position_dodge(width =1)) + 
  geom_errorbarh(aes( xmin=(x2_5-1)*100, xmax=(x97_5-1)*100),height=.1) +
  scale_x_continuous(lim = c(-25,20)) +
  xlab("Percentage change (95% CI)") + ylab(NULL) +
  scale_color_manual(values = pnw_palette("Bay", 2), guide = "none")+
  facet_grid(var ~time, scales = "free_y", space = "free",switch= "y")+
  theme_bw() +
  theme(text = element_text(size=10), strip.background = element_blank(), 
        strip.placement = "outside", axis.title.x = element_text(size=9),
        panel.grid.major.x =element_line(color = "gray90"), panel.grid.minor.y=element_blank(),
        panel.grid.minor.x = element_line(color = "gray90"))

dev.off()


png(here::here("output", "released_outputs", "graphs","New IRR pcent.png"), 
    res = 300, units = "in", width = 5, height = 7)

ggplot(data = subset(all.irr, type == "Incident"),
       aes(x = (coef-1)*100, y= label, group = time, col = time)) +
  geom_vline(aes(xintercept = 0), linetype = "longdash") +
  geom_point(position=position_dodge(width =1)) + 
  geom_errorbarh(aes( xmin=(x2_5-1)*100, xmax=(x97_5-1)*100), height=.1) +
  scale_x_continuous(lim = c(-25,40)) +
  xlab("Percentage change (95% CI)") + ylab(NULL) +
  scale_color_manual(values = pnw_palette("Bay", 2), guide = "none")+
  facet_grid(var ~ time, scales = "free_y", space = "free",switch= "y")+
  theme_bw() +
  theme(text = element_text(size=10), strip.background = element_blank(), strip.placement = "outside", 
        axis.title.x = element_text(size=9),
        panel.grid.major.x =element_line(color = "gray90"), panel.grid.minor.y=element_blank(),
        panel.grid.minor.x = element_line(color = "gray90"))

dev.off()



############################################################
# SENSTIVITY ANALYSIS  - excluding people in care homes 
############################################################


# Read in data
agecare <- read_csv(here::here("output", "released_outputs", "ts_agecare.csv"),
                    col_types = cols(
                      age_cat  = col_character(),
                      carehome = col_character(),
                      date = col_date(format="%Y-%m-%d"))) %>%
  rename(cat = age_cat, var = carehome) %>%
  mutate(period = ifelse(date <= as.Date("2020-03-01"), "Pre-COVID-19",
                         ifelse(date >= as.Date("2021-04-01"), "Recovery", "Lockdown")))

# Merge in ITS variables and subset to people outside care homes
no_care <- merge(agecare, 
                 dplyr::select(subset(demo.its, var == "age" & 
                                 cat %in% c("60-69 y", "70-79 y", "80-89 y", "90+ y")),
                        c(date, cat, time, slope, slope2, step, step2, month,
                          mar20, apr20, may20)),
                 by = c("date", "cat")) %>%
          subset(var == "No")

# Run negative binomial models
age_coef1 <- nb(data = no_care, ref = "70-79 y") 
age_coef2 <- nb(data = no_care, ref = "80-89 y")   
age_coef3 <- nb(data = no_care, ref = "90+ y")  

# Combined coefficients
age_coef_nocare <- rbind(age_coef1, age_coef2, age_coef3) %>% 
  mutate(var ="Not in care home")

# Combined with data from full population
age_coef_bycare <- rbind(age_coef, age_coef_nocare) %>% 
  subset(cat %in% c("70-79 y","80-89 y","90+ y")) %>%
  mutate(var = ifelse(var == "age", "Full population", var))

write.csv(age_coef_bycare, 
          here::here("output", "released_outputs", "coefficients_bycarehome.csv"),
          row.names = FALSE)

# Predicted values
age_pred_nocare <- pred.val(no_care) 

# Combined with full population
age_pred_bycare <- rbind(age_pred_nocare, age_pred) %>% 
  subset(cat %in% c("70-79 y","80-89 y","90+ y")) %>%
  mutate(var = ifelse(var == "age", "Full population", "Not in care home"))
  
write.csv(age_pred_bycare, 
          here::here("output", "released_outputs", "predicted_vals_bycarehome.csv"),
          row.names = FALSE)

################################


age_pred_bycare$time <- factor(age_pred_bycare$time, levels = c("Lockdown", "Recovery"),
                                 labels = c("Lockdown period relative\nto pre-COVID-19",
                                            "Recovery period relative\nto lockdown period"))

age_pred_bycare$cat <- factor(age_pred_bycare$cat, 
                                  levels= c("70-79 y", "80-89 y","90+ y"))


prev <- ggplot(data = subset(age_pred_bycare, type == "Prevalent"),
               aes(x = (coef-1)*100, y= var, group = time, col = var)) +
  geom_vline(aes(xintercept = 0), linetype = "longdash") +
  geom_point(position=position_dodge(width =1)) + 
  geom_errorbarh(aes( xmin=(x2_5-1)*100, xmax=(x97_5-1)*100),height=.1) +
  #  scale_x_log10() +
  scale_x_continuous(lim = c(-23,20)) +
  xlab("Percentage change (95% CI)") + ylab(NULL) +
  scale_color_manual(values = pnw_palette("Bay", 2), guide = "none")+
  facet_grid(cat ~time , scales = "free_y", space = "free",switch= "y")+
  theme_bw() +
  theme(text = element_text(size=10), strip.background = element_blank(), 
        strip.placement = "outside", axis.title.x = element_text(size=9),
        panel.grid.major.x =element_line(color = "gray90"), panel.grid.minor.y=element_blank(),
        panel.grid.minor.x = element_line(color = "gray90"),
        plot.title = element_text(size = 10, face = "bold", hjust=.5)) +
  ggtitle("Any prescribing")

new <- ggplot(data = subset(age_pred_bycare, type == "Incident"),
              aes(x = (coef-1)*100, y= var, group = time, col = var)) +
  geom_vline(aes(xintercept = 0), linetype = "longdash") +
  geom_point(position=position_dodge(width =1)) + 
  geom_errorbarh(aes( xmin=(x2_5-1)*100, xmax=(x97_5-1)*100),height=.1) +
  #  scale_x_log10() +
  scale_x_continuous(lim = c(-23,20)) +
  xlab("Percentage change (95% CI)") + ylab(NULL) +
  scale_color_manual(values = pnw_palette("Bay", 2), guide = "none")+
  facet_grid(cat ~time, scales = "free_y", space = "free",switch= "y")+
  theme_bw() +
  theme(text = element_text(size=10), strip.background = element_blank(), strip.placement = "outside", 
        axis.title.x = element_text(size=9), 
        axis.title.y = element_blank(),
        panel.grid.major.x =element_line(color = "gray90"), panel.grid.minor.y=element_blank(),
        panel.grid.minor.x = element_line(color = "gray90"),
        plot.title = element_text(size = 10, face = "bold", hjust = .5)) +
  ggtitle("New prescribing")


png(here::here("output", "released_outputs", "graphs","SuppFigureX.png"), 
    res = 300, units = "in", height = 3.5, width = 9)

prev + 
  new + 
  plot_layout(nrow = 1) 

dev.off()




###############################################





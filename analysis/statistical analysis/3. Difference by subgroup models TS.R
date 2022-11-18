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


##### Read in data #######
combined.its <- read_csv(here::here("output", "released_outputs", "ts_combined_full.csv"),
                      col_types = cols(
                        group  = col_character(),
                        label = col_character(),
                        date = col_date(format = "%Y-%m-%d"))) 


##############################################

# Function for prevalent prescribing model 
nb <- function(data, ref){
  
  data$label <- relevel(as.factor(data$label), ref = ref)
  
  # Prevalent prescribing
  mod.any <- glm.nb(any_opioid_prescribing ~ time + step*label + step2*label + 
                      slope + slope2 + mar20 + apr20 + may20 +
                      as.factor(month) + offset(log(total_population)), 
                    data = data, link = "log",
                    control = list(trace = TRUE, maxiter = 30, epsilon = 1))
  
  ci.any <- coefci(mod.any, vcov. = vcovPL(mod.any, cluster = data$label)) %>% exp()
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
  mod.new <- glm.nb(new_opioid_prescribing ~ time + step*label  + step2*label + 
                      slope + slope2 + as.factor(month) + offset(log(opioid_naive)), 
                    data = data, link = "log",
                    control = list(trace = TRUE, maxiter = 30, epsilon = 1))
  
  ci.new <- coefci(mod.new, vcov. = vcovPL(mod.new, cluster = data$label)) %>% exp()
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
  mod.any <- glm.nb(any_opioid_prescribing ~ time + step*label + step2*label + 
                      slope + slope2 + mar20 + apr20 + may20 +
                      as.factor(month) + offset(log(total_population)), 
                    data = data, link = "log",
                    control = list(trace = TRUE, maxiter = 30, epsilon = 1))
  
  pred.any <- predict(mod.any, se.fit = TRUE)
  
  pred.any <- 
    data.frame(pred_n = exp(pred.any$fit), 
               lci_n = exp(pred.any$fit - 1.96 * pred.any$se.fit),
               uci_n = exp(pred.any$fit + 1.96 * pred.any$se.fit), 
               data) %>% 
    mutate(pred = pred_n / total_population * 1000, 
           pred_lci = lci_n / total_population * 1000,
           pred_uci = uci_n / total_population * 1000,
           type = "Prevalent") %>%
    rename(obs = prevalence_per_1000) %>%
    dplyr::select(c(date, pred, obs, pred_lci, pred_uci,
                    type, period, group, label))
  
  # New prescribing
  mod.new <- glm.nb(new_opioid_prescribing ~ time + step*label + step2*label + 
                      slope + slope2 + mar20 + apr20 + may20 +
                      as.factor(month) + offset(log(opioid_naive)), 
                      data = data, link = "log",
                      control = list(trace = TRUE, maxiter = 30, epsilon = 1))
  
  pred.new <- predict(mod.new, se.fit = TRUE)
  
  pred.new <- 
    data.frame(pred_n = exp(pred.new$fit), 
               lci_n = exp(pred.new$fit - 1.96 * pred.new$se.fit),
               uci_n = exp(pred.new$fit + 1.96 * pred.new$se.fit), 
               data) %>% 
    mutate(pred = pred_n / opioid_naive * 1000, 
           pred_lci = lci_n / opioid_naive * 1000,
           pred_uci = uci_n / opioid_naive * 1000,
           type = "Incident") %>%
    rename(obs = incidence_per_1000) %>%
    dplyr::select(c(date, pred, obs, pred_lci, pred_uci, 
                    type, period, group, label))
  
  pred <- rbind(pred.any, pred.new)
  
  return(pred)
}


####################################################

#### By age group ####

age <- subset(combined.its, group == "Age" & !(label %in% c("Missing",NA))) %>% 
  arrange(label, date)

# Run NegBin models, extract coefficients and 
#    calculate predicted values
age_coef1 <- nb(data = age, ref = "18-29 y")  
age_coef2 <- nb(data = age, ref = "30-39 y") 
age_coef3 <- nb(data = age, ref = "40-49 y")  
age_coef4 <- nb(data = age, ref = "50-59 y")
age_coef5 <- nb(data = age, ref = "60-69 y") 
age_coef6 <- nb(data = age, ref = "70-79 y") 
age_coef7 <- nb(data = age, ref = "80-89 y") 
age_coef8 <- nb(data = age, ref = "90+ y")  

age_coef <- rbind(age_coef1, age_coef2, age_coef3, 
                  age_coef4, age_coef5, age_coef6, 
                  age_coef7, age_coef8) %>%
              mutate(group = "Age")

age_pred <- pred.val(age)


#### By IMD decile ####

imd <- subset(combined.its, group == "IMD decile" & !(label %in% c("Missing",NA))) %>% 
  arrange(label, date)

# Run NegBin models, extract coefficients and 
#    calculate predicted values
imd_coef1 <- nb(data = imd, ref = "1 most deprived")  
imd_coef2 <- nb(data = imd, ref = "2")   
imd_coef3 <- nb(data = imd, ref = "3")    
imd_coef4 <- nb(data = imd, ref = "4")
imd_coef5 <- nb(data = imd, ref = "5")   
imd_coef6 <- nb(data = imd, ref = "6")   
imd_coef7 <- nb(data = imd, ref = "7")    
imd_coef8 <- nb(data = imd, ref = "8")  
imd_coef9 <- nb(data = imd, ref = "9")  
imd_coef10 <- nb(data = imd, ref = "10 least deprived")  

imd_coef <- rbind(imd_coef1, imd_coef2, imd_coef3, imd_coef4,
                  imd_coef5, imd_coef6, imd_coef7, imd_coef8,
                  imd_coef9, imd_coef10) %>%
                  mutate(group = "IMD decile")

imd_coef$label <- factor(imd_coef$label, 
                      levels=c("10 least deprived","9","8","7","6",
                               "5","4","3","2","1 most deprived"))

imd_pred <- pred.val(imd) 


#### By sex ####

sex <- subset(combined.its, group == "Sex" & !(label %in% c("Missing",NA))) %>% arrange(label,date)

# Run NegBin models, extract coefficients and 
#    calculate predicted values
sex_coef1 <- nb(data = sex, ref = "Female") 
sex_coef2 <- nb(data = sex, ref = "Male")

sex_coef <- rbind(sex_coef1, sex_coef2) %>% mutate(group = "Sex")

sex_pred <- pred.val(sex) 


#### By ethnicity ####

eth <- subset(combined.its, group == "Ethnicity6" & !(label %in% c("Missing",NA))) %>% arrange(label,date)

# Run NegBin models, extract coefficients and 
#    calculate predicted values
eth_coef1 <- nb(data = eth, ref = "White")   
eth_coef2 <- nb(data = eth, ref = "Black or Black British")  
eth_coef3 <- nb(data = eth, ref = "Asian or Asian British")  
eth_coef4 <- nb(data = eth, ref = "Mixed")  
eth_coef5 <- nb(data = eth, ref = "Other")  
eth_coef6 <- nb(data = eth, ref = "Unknown")    
   
eth_coef <- rbind(eth_coef1, eth_coef2, 
                  eth_coef3, eth_coef4,
                  eth_coef5, eth_coef6) %>% 
            mutate(group = "Ethnicity")

eth_pred <- pred.val(eth) 


#### By region ####

region <- subset(combined.its, group == "Region" & !(label %in% c("Missing", NA))) %>% arrange(label, date)

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
                mutate(group = "Region")

region_pred <- pred.val(region) 


#### Combine all coefficients

all.irr <- rbind(age_coef, sex_coef, imd_coef, region_coef, eth_coef)
write.csv(all.irr, here::here("output", "released_outputs", "coefficients_bygroup.csv"),
          row.names = FALSE)

all.irr$time <- factor(all.irr$time, levels = c("Lockdown", "Recovery"),
                        labels = c("Lockdown period relative\nto pre-COVID-19",
                                   "Recovery period relative\nto lockdown period"))

all.irr$group <- factor(all.irr$group, levels = c("Age", "Sex", "IMD decile", "Region", "Ethnicity"),
                         labels = c("Age", "Sex", "IMD decile", "Region", "Ethnicity"))

all.irr$label <- factor(all.irr$label,
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

#### Combine all predicted values 

all.pred <- rbind(age_pred, sex_pred, imd_pred, region_pred, eth_pred)
write.csv(all.pred, here::here("output", "released_outputs", "predicted_vals_bygroup.csv"),
          row.names = FALSE)



#### Figures with percent changes ####

png(here::here("output", "released_outputs", "graphs","prev IRR pcent.png"), 
    res = 300, units = "in", width = 5, height = 7)

ggplot(data = subset(all.irr, type = "Prevalent"),
       aes(x = (coef-1)*100, y= label, group = time, col = time)) +
  geom_vline(aes(xintercept = 0), linetype = "longdash") +
  geom_point(position=position_dodge(width =1)) + 
  geom_errorbarh(aes( xmin=(x2_5-1)*100, xmax=(x97_5-1)*100),height=.1) +
  scale_x_continuous(lim = c(-25,20)) +
  xlab("Percentage change (95% CI)") + ylab(NULL) +
  scale_color_manual(values = pnw_palette("Bay", 2), guide = "none")+
  facet_grid(group ~time, scales = "free_y", space = "free",switch= "y")+
  theme_bw() +
  theme(text = element_text(size=10), strip.background = element_blank(), 
        strip.placement = "outside", axis.title.x = element_text(size=9),
        panel.grid.major.x =element_line(color = "gray90"), panel.grid.minor.y=element_blank(),
        panel.grid.minor.x = element_line(color = "gray90"))

dev.off()


png(here::here("output", "released_outputs", "graphs","New IRR pcent.png"), 
    res = 300, units = "in", width = 5, height = 7)

ggplot(data = subset(all.irr, type = "Incident"),
       aes(x = (coef-1)*100, y= label, group = time, col = time)) +
  geom_vline(aes(xintercept = 0), linetype = "longdash") +
  geom_point(position=position_dodge(width =1)) + 
  geom_errorbarh(aes( xmin=(x2_5-1)*100, xmax=(x97_5-1)*100),height=.1) +
  scale_x_continuous(lim = c(-25,20)) +
  xlab("Percentage change (95% CI)") + ylab(NULL) +
  scale_color_manual(values = pnw_palette("Bay", 2), guide = "none")+
  facet_grid(group ~ time, scales = "free_y", space = "free",switch= "y")+
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
  rename(label = age_cat, group = carehome) %>%
  mutate(period = ifelse(date <= as.Date("2020-03-01"), "Pre-COVID-19",
                         ifelse(date >= as.Date("2021-04-01"), "Recovery", "Lockdown")))

# Merge in ITS variables and subset to people outside care homes
no_care <- merge(agecare, 
                 dplyr::select(subset(combined.its, group == "Age" & 
                                 label %in% c("60-69 y", "70-79 y", "80-89 y", "90+ y")),
                        c(date, label, time, slope, slope2, step, step2, month,
                          mar20, apr20, may20)),
                 by = c("date", "label")) %>%
          subset(group == "No")

# Run negative binomial models
age_coef1 <- nb(data = no_care, ref = "70-79 y") 
age_coef2 <- nb(data = no_care, ref = "80-89 y")   
age_coef3 <- nb(data = no_care, ref = "90+ y")  

# Combined coefficients
age_coef_nocare <- rbind(age_coef1, age_coef2, age_coef3) %>% 
  mutate(group ="Not in care home")

# Combined with data from full population
age_coef_bycare <- rbind(age_coef, age_coef_nocare) %>% 
  subset(label %in% c("70-79 y","80-89 y","90+ y")) %>%
  mutate(group = ifelse(group == "Age", "Full population", group))

write.csv(age_coef_bycare, 
          here::here("output", "released_outputs", "coefficients_bycarehome.csv"),
          row.names = FALSE)

# Predicted values
age_pred_nocare <- pred.val(no_care) 

# Combined with full population
age_pred_bycare <- rbind(age_pred_nocare, age_pred) %>% 
  subset(label %in% c("70-79 y","80-89 y","90+ y")) %>%
  mutate(group = ifelse(group == "Age", "Full population", "Not in care home"))
  
write.csv(age_pred_bycare, 
          here::here("output", "released_outputs", "predicted_vals_bycarehome.csv"),
          row.names = FALSE)

################################


age_pred_bycare$time <- factor(age_pred_bycare$time, levels = c("Lockdown", "Recovery"),
                                 labels = c("Lockdown period relative\nto pre-COVID-19",
                                            "Recovery period relative\nto lockdown period"))

age_pred_bycare$label <- factor(age_pred_bycare$label, 
                                  levels= c("70-79 y", "80-89 y","90+ y"))


prev <- ggplot(data = subset(age_pred_bycare, type == "Prevalent"),
               aes(x = (coef-1)*100, y= group, group = time, col = group)) +
  geom_vline(aes(xintercept = 0), linetype = "longdash") +
  geom_point(position=position_dodge(width =1)) + 
  geom_errorbarh(aes( xmin=(x2_5-1)*100, xmax=(x97_5-1)*100),height=.1) +
  #  scale_x_log10() +
  scale_x_continuous(lim = c(-23,20)) +
  xlab("Percentage change (95% CI)") + ylab(NULL) +
  scale_color_manual(values = pnw_palette("Bay", 2), guide = "none")+
  facet_grid(label ~time , scales = "free_y", space = "free",switch= "y")+
  theme_bw() +
  theme(text = element_text(size=10), strip.background = element_blank(), 
        strip.placement = "outside", axis.title.x = element_text(size=9),
        panel.grid.major.x =element_line(color = "gray90"), panel.grid.minor.y=element_blank(),
        panel.grid.minor.x = element_line(color = "gray90"),
        plot.title = element_text(size = 10, face = "bold", hjust=.5)) +
  ggtitle("Any prescribing")

new <- ggplot(data = subset(age_pred_bycare, type == "Incident"),
              aes(x = (coef-1)*100, y= group, group = time, col = group)) +
  geom_vline(aes(xintercept = 0), linetype = "longdash") +
  geom_point(position=position_dodge(width =1)) + 
  geom_errorbarh(aes( xmin=(x2_5-1)*100, xmax=(x97_5-1)*100),height=.1) +
  #  scale_x_log10() +
  scale_x_continuous(lim = c(-23,20)) +
  xlab("Percentage change (95% CI)") + ylab(NULL) +
  scale_color_manual(values = pnw_palette("Bay", 2), guide = "none")+
  facet_grid(label ~time, scales = "free_y", space = "free",switch= "y")+
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





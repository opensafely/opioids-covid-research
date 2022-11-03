
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


# Read in data
combined <- read_csv(here::here("output", "released_outputs", "ts_combined_full.csv"),
                      col_types = cols(
                        group  = col_character(),
                        label = col_character(),
                        date = col_date(format="%Y-%m-%d"))) 

# Time variables
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

combined <- arrange(combined,group,label,date)

combined2 <- cbind(combined, time = rep(time,40), 
                   slope = rep(slope,40), slope2 = rep(slope2, 40),
                   step = rep(step,40), step2 = rep(step2, 40),
                   month = rep(month2, 40), mar20 = rep(mar20,40)) %>%
  mutate(step3 = ifelse(step==1 & step2==0,1,ifelse(step2==1,2,0)), 
         step3 = as.factor(step3))


##############################################


nb <- function(data, ref, y, denom){
  
  data$label <- relevel(as.factor(data$label), ref = ref)
  mod1 <- glm.nb(y ~ time + mar20 + step3*label  + slope + slope2 +
                   month + offset(log(denom)), data= data, link = "log")
  
  ci1 <- coefci(mod1, vcov = NeweyWest(mod1,lag=2,prewhite =FALSE)) %>% exp()
  coef1 <- mod1$coefficients  %>% exp()
  coef1 <- data.frame(ci1, coef = coef1, label = rownames(ci1)) %>% 
    clean_names() %>% subset(!str_detect(label, "Intercept|time|slope")) 
  
  coef <- coef1 %>%
    subset(str_detect(label, "label")) %>%
    mutate(
      period = ifelse(str_detect(label, "step31:"), "Lockdown",
                      ifelse(str_detect(label, "step32:"), "Recovery", "Pre-COVID")),
      label = ifelse(str_detect(label, "step31"), gsub("step31:label","",label),
                     ifelse(str_detect(label, "step32:"), gsub("step32:label", "", label),
                            gsub("label", "", label)))) %>%
    rbind(c(1.0, 1.0, 1.0, ref, "Pre-COVID"),
          c(1.0, 1.0, 1.0, ref, "Recovery"),
          c(1.0, 1.0, 1.0, ref, "Lockdown")) %>%
    mutate(
      coef = as.numeric(coef), 
      x2_5 = as.numeric(x2_5), 
      x97_5 = as.numeric(x97_5))
  
  return(coef)
}

#########################


imd <- subset(combined2, group == "IMD decile" & !(label %in% c("Missing",NA))) %>% arrange(label, date)

imd_coef_prev <- nb(data = imd, ref = "10 least deprived", 
                    y = imd$any_opioid_prescribing, denom = imd$total_population) %>% 
                  mutate(group = "IMD") 
imd_coef_new <- nb(data = imd, ref = "10 least deprived", 
                   y = imd$new_opioid_prescribing, denom = imd$opioid_naive) %>% 
                  mutate(group = "IMD") 

imd_coef_prev$label <- factor(imd_coef$label, 
                      levels=c("10 least deprived","9","8","7","6","5","4","3","2","1 most deprived"))
imd_coef_new$label <- factor(imd_coef$label, 
                              levels=c("10 least deprived","9","8","7","6","5","4","3","2","1 most deprived"))

#######################

age <- subset(combined2, group == "Age" & !(label %in% c("Missing",NA))) %>% arrange(label, date)

age_coef_prev <- nb(data = age, ref = "50-59 y", 
                    y = age$any_opioid_prescribing, denom = age$total_population) %>% 
                 mutate(group = "Age") 
age_coef_new <- nb(data = age, ref = "50-59 y", 
                   y = age$new_opioid_prescribing,  denom = age$opioid_naive) %>% 
                 mutate(group = "Age") 

#######################

sex <- subset(combined2, group == "Sex" & !(label %in% c("Missing",NA))) %>% arrange(label,date)

sex_coef_prev <- nb(data = sex, ref = "Male", 
                  y = sex$any_opioid_prescribing, denom = sex$total_population) %>% 
                  mutate(group = "Sex") 
sex_coef_new <- nb(data = sex, ref = "Male", 
                  y = sex$new_opioid_prescribing, denom = sex$opioid_naive) %>%
                  mutate(group = "Sex") 

#################################


ethnicity <- subset(combined2, group == "Ethnicity6" & !(label %in% c("Missing",NA))) %>% arrange(label,date)

eth_coef_prev <- nb(data = ethnicity, ref = "White", 
                    y = ethnicity$any_opioid_prescribing, denom = ethnicity$total_population) %>% 
                      mutate(group = "Ethnicity") 
eth_coef_new <- nb(data = ethnicity, ref = "White", 
                   y = ethnicity$new_opioid_prescribing, denom = ethnicity$opioid_naive) %>%
                    mutate(group = "Ethnicity") 


#################################


region <- subset(combined2, group == "Region" & !(label %in% c("Missing",NA))) %>% arrange(label, date)

region_coef_prev <- nb(data = region, ref = "East", 
                       y = region$any_opioid_prescribing, denom = region$total_population) %>% 
                        mutate(group = "Region") 
region_coef_new <- nb(data = region, ref = "East", 
                      y = region$new_opioid_prescribing, denom = region$opioid_naive) %>% 
                      mutate(group = "Region") 


#############################


all_prev <- rbind(age_coef_prev, sex_coef_prev, imd_coef_prev, region_coef_prev, eth_coef_prev)
rownames(all_prev) <- NULL

all_new <- rbind(age_coef_new, sex_coef_new, imd_coef_new, region_coef_new, eth_coef_new)
rownames(all_new) <- NULL

############################


all_prev$period <- factor(all_prev$period, levels = c("Pre-COVID", "Lockdown", "Recovery"),
                          labels = c("Pre-COVID-19", "Change during lockdown\nrelative to pre-COVID-19",
                                     "Change during recovery\nrelative to pre-COVID-19"))

all_prev$group <- factor(all_prev$group, levels = c("Age", "Sex", "IMD", "Region", "Ethnicity"),
                         labels = c("Age", "Sex", "IMD decile", "Region", "Ethnicity"))

all_prev$label <- factor(all_prev$label,
                         levels= c("90+ y", "80-89 y","70-79 y","60-69 y","50-59 y",
                                    "40-49 y","30-39 y","18-29 y","Female","Male",
                                    "1 most deprived","2","3","4","5","6","7","8","9","10 least deprived",
                                    "Yorkshire and The Humber","West Midlands","South West",
                                    "South East","North West","North East","London",
                                    "East Midlands","East","Unknown","Other","Mixed","Black or Black British",
                                    "Asian or Asian British","White"))

png("Prev IRR.png", res = 300, units = "in", width = 7, height = 7)
ggplot(data = all_prev,
       aes(x = coef, y= label, group = period, col = period)) +
  geom_vline(aes(xintercept = 1.0), linetype = "longdash") +
  geom_point(position=position_dodge(width =1)) + 
  geom_errorbarh(aes( xmin=x2_5, xmax=x97_5),height=.1) +
  scale_x_log10(lim= c(0.13,3), breaks=c(.5,1,2)) +
  xlab("Incidence rate ratio (IRR)") + ylab(NULL) +
  scale_color_manual(values = pnw_palette("Bay", 3), guide = "none")+
  facet_grid(group ~period, scales = "free_y", space = "free",switch= "y")+
  theme_bw() +
  theme(strip.background = element_blank(), strip.placement = "outside",
        panel.grid.major.x =element_line(color = "gray90"), panel.grid.minor.y=element_blank(),
        panel.grid.minor.x = element_line(color = "gray90"))

dev.off()


all_new$period <- factor(all_new$period, levels = c("Pre-COVID", "Lockdown", "Recovery"),
                         labels = c("Pre-COVID-19", "Change during lockdown\nrelative to pre-COVID-19",
                                    "Change during recovery\nrelative to pre-COVID-19"))

all_new$group <- factor(all_new$group, levels = c("Age", "Sex", "IMD", "Region", "Ethnicity"),
                         labels = c("Age", "Sex", "IMD decile", "Region", "Ethnicity"))

all_new$label <- factor(all_new$label,
                         levels= c("90+ y", "80-89 y","70-79 y","60-69 y","50-59 y",
                                   "40-49 y","30-39 y","18-29 y","Female","Male",
                                   "1 most deprived","2","3","4","5","6","7","8","9","10 least deprived",
                                   "Yorkshire and The Humber","West Midlands","South West",
                                   "South East","North West","North East","London",
                                   "East Midlands","East","Unknown","Other","Mixed","Black or Black British",
                                   "Asian or Asian British","White"))

png("New IRR.png", res = 300, units = "in", width = 7, height = 8)
ggplot(data = all_new,
       aes(x = coef, y= label, group = period, col = period)) +
  geom_vline(aes(xintercept = 1.0), linetype = "longdash") +
  geom_point(position=position_dodge(width =1)) + 
  geom_errorbarh(aes( xmin=x2_5, xmax=x97_5),height=.1) +
  scale_x_log10(lim= c(0.45,3), breaks=c(.5,1,2)) +
  xlab("Incidence rate ratio (IRR)") + ylab(NULL) +
  scale_color_manual(values = pnw_palette("Bay", 3), guide = "none")+
  facet_grid(group ~ period, scales = "free_y", space = "free",switch= "y")+
  theme_bw() +
  theme(strip.background = element_blank(), 
        strip.placement = "outside",
        panel.grid.major.x =element_line(color = "gray90"), 
        panel.grid.minor.y=element_blank(),
        panel.grid.minor.x = element_line(color = "gray90"))

dev.off()
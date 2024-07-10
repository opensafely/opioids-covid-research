#######################################################
# This script estimates negative binomial models
#   for overall opioid prescribing and initiation
#   to determine differences in changes by subgroup
#
# Author: Andrea Schaffer
#   Bennett Institute for Applied Data Science
#   University of Oxford, 2024
#######################################################


# For running locally only #
# setwd("C:/Users/aschaffer/OneDrive - Nexus365/Documents/GitHub/opioids-covid-research")
# getwd()


library('tidyverse')
library('here')
library('fs')
library('ggplot2')
library(PNWColors)
library(janitor)
library(MASS)
library(lmtest)
library(sandwich)
library(ggpubr)

## Create directories
dir_create(here::here("output", "released_outputs", "final"), showWarnings = FALSE, recurse = TRUE)


## Custom functions
source(here("analysis", "lib", "custom_functions.R"))


##### Read in data #######
demo.its <- read_csv(here::here("output", "released_outputs", "final", "ts_demo_its.csv"),
                      col_types = cols(month = col_date(format = "%Y-%m-%d"))) 


####################################################

#### By age group ####

age <- subset(demo.its, var == "age") %>% 
  arrange(cat, month)

# Run NegBin models, extract coefficients and 
#    calculate predicted values
age_coef1 <- nb.age(data = age, ref = "18-29")  
age_coef2 <- nb.age(data = age, ref = "30-39") 
age_coef3 <- nb.age(data = age, ref = "40-49")  
age_coef4 <- nb.age(data = age, ref = "50-59")
age_coef5 <- nb.age(data = age, ref = "60-69") 
age_coef6 <- nb.age(data = age, ref = "70-79") 
age_coef7 <- nb.age(data = age, ref = "80-89") 
age_coef8 <- nb.age(data = age, ref = "90+")  

age_coef <- rbind(age_coef1, age_coef2, age_coef3, 
                  age_coef4, age_coef5, age_coef6, 
                  age_coef7, age_coef8) %>%
              mutate(var = "Age")

age_pred <- pred.val.age(age)


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

imd_pred <- pred.val.cat(imd) 


#### By sex ####

sex <- subset(demo.its, var == "sex" & !(cat %in% c("Missing",NA))) %>% arrange(cat, month)

# Run NegBin models, extract coefficients and 
#    calculate predicted values
sex_coef1 <- nb(data = sex, ref = "female") 
sex_coef2 <- nb(data = sex, ref = "male")

sex_coef <- rbind(sex_coef1, sex_coef2) %>% mutate(var = "Sex")

sex_pred <- pred.val.cat(sex) 


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

eth_pred <- pred.val.cat(eth) 


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

region_pred <- pred.val.cat(region) 


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

fig3a <- ggplot(data = subset(all.irr, type == "Prevalent"),
       aes(x = (coef-1)*100, y= label, group = time, col = time)) +
  geom_vline(aes(xintercept = 0), linetype = "longdash") +
  geom_point(position=position_dodge(width =1)) + 
  geom_errorbarh(aes( xmin=(x2_5-1)*100, xmax=(x97_5-1)*100),height=.1) +
  scale_x_continuous(lim = c(-25,40)) +
  xlab("Percentage change (95% CI)") + ylab(NULL) +
  scale_color_manual(values = pnw_palette("Bay", 2), guide = "none")+
  facet_grid(var ~time, scales = "free_y", space = "free",switch= "y")+
  theme_bw() +
  theme(text = element_text(size=10), strip.background = element_blank(), 
        strip.placement = "outside", axis.title.x = element_text(size=9),
        panel.grid.major.x =element_line(color = "gray90"), 
        panel.grid.minor.y=element_blank(),
        panel.grid.major.y=element_blank(),
        panel.grid.minor.x = element_line(color = "gray90"))

fig3b <- ggplot(data = subset(all.irr, type == "Incident"),
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
        panel.grid.major.x =element_line(color = "gray90"), 
        panel.grid.minor.y=element_blank(),
        panel.grid.major.y=element_blank(),
        panel.grid.minor.x = element_line(color = "gray90"))

dev.off()



pdf(here::here("output", "released_outputs", "final", "figure3.pdf"), width = 10, height = 7)

ggarrange(fig3a, fig3b, labels = c("A","B"))

dev.off()




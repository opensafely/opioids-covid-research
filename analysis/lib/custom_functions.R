#########################################
# This script contains custom functions  
#########################################


# Factorise ----
fct_case_when <- function(...) {
  # uses dplyr::case_when but converts the output to a factor,
  # with factors ordered as they appear in the case_when's  ... argument
  args <- as.list(match.call())
  levels <- sapply(args[-1], function(f) f[[3]])  # extract RHS of formula
  levels <- levels[!is.na(levels)]
  factor(dplyr::case_when(...), levels=levels)
}

# Rounding and redaction
rounding <- function(vars) {
  case_when(vars > 10 ~ round(vars / 7) * 7)
}

# Extracting coefficients and 95%CIs with standard errors 
#    adjusted for autocorrelation
coef <- function(mod){
  data.frame(est = exp(mod$coef), 
             exp(coefci(mod, vcov = NeweyWest(mod, lag = 2, prewhite = F)))) %>%
    rename(lci = `X2.5..`, uci = `X97.5..`) %>%
    mutate(est = round(est, 5), 
           lci = round(lci, 5), 
           uci = round(uci, 5),
           pcent_est = round((est - 1) * 100, 2), 
           pcent_lci = round((lci - 1) * 100, 2),
           pcent_uci = round((uci - 1) * 100, 2))
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
                      slope + slope2 +  mar20 + apr20 + may20 +
                      as.factor(month_dummy) + offset(log(pop_naive_round)), 
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
pred.val.cat <- function(data){
  
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


# Function for prevalent prescribing model - FOR AGE ONLY
nb.age <- function(data, ref){
  
  data$cat <- relevel(as.factor(data$cat), ref = ref)
  
  # Prevalent prescribing
  mod.any <- glm.nb(opioid_any_round ~ time + step*cat + step2*cat + 
                      slope + slope2 + mar20*cat + apr20*cat + may20*cat +
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
                      slope + slope2 +  mar20*cat + apr20*cat + may20*cat +
                      as.factor(month_dummy) + offset(log(pop_naive_round)), 
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


# Function for predicted values from prevalent prescribing model - FOR AGE ONLY
pred.val.age <- function(data){
  
  # Any prescribing
  mod.any <- glm.nb(opioid_any_round ~ time + step*cat + step2*cat + 
                      slope + slope2 + mar20*cat + apr20*cat + may20*cat +
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
                      slope + slope2 + mar20*cat + apr20*cat + may20*cat +
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

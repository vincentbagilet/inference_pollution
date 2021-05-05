library(tidyverse) # for data manipulation and visualisation
library(modelr) # modeling within the tidyverse
library(retrodesign) # formulas for type-m and type-s errors
library(broom)
library(lubridate)
library(lmtest)
library(sandwich)
library(tictoc)
library(rlang)
library(readr)
library(fixest)
library(Formula)

draw_study_period <- function(data, n_days_study = 200) {
  dates <- data[["date"]]
  begin_study <- sample(seq.Date(min(dates), max(dates) - n_days_study, "day"), 1)
  
  data[["study_period"]] <-
    dplyr::between(dates, begin_study, begin_study + n_days_study)
  
  return(data)
}


draw_treated <- function(data, p_treat = 0.5, quasi_exp = "random_day") {
  
  if (quasi_exp == "random_days") {
    data[["treated"]] <- rbernoulli(length(data[["date"]]), p_treat)
  } else if (quasi_exp == "national") {
    num_date <- as.numeric(data[["date"]])
    data[["treated"]] <- (num_date >= quantile(num_date, 1 - p_treat))
  } else if (quasi_exp %in% c("GAM", "IV")) {
    # treated <- TRUE
    treated <- rbernoulli(length(data[["date"]]), p_treat)
    data[["treated"]] <- ifelse(treated, treated, NA) 
  } else if (quasi_exp == "local") {
    treated_cities <- unique(data[["city"]]) %>%
      sample(size = round(length(.) * min(p_treat * 2, 1)))
    data[["treated"]] <- (data[["city"]] %in% treated_cities &
                            data[["date"]] >= median(data[["date"]]))
  } else if (str_starts(quasi_exp, "alert")) {
    pollutant <- str_extract(quasi_exp, "(?<=_).+")
    threshold_pos <- rbeta(1, 20, 2) 
    data <- data %>%
      group_by(.data$city) %>%
      mutate(
        threshold = quantile(.data[[pollutant]], threshold_pos, names = FALSE),
        treated = (.data[[pollutant]] >= threshold),
        bw = cut_width(
          .data[[pollutant]],
          width = length(.) * 2 * p_treat,
          center = unique(threshold) #threshold center of an interval
        ),
        treated = ifelse(
          threshold > as.numeric(str_extract(bw, "([:digit:]|\\.|-)+(?=,)")) &
            threshold < as.numeric(str_extract(bw, "(?<=,)([:digit:]|\\.)+")), treated, NA)
      ) %>%
      select(-bw, -threshold) %>% 
      ungroup()
  } else if (quasi_exp == "rolling") {
    data <- data %>%
      group_by(.data$city) %>%
      mutate(
        treated = (.data$date > sample(
          seq.Date(
            min(.data$date) + (1 - 2*p_treat)*length(.data$date),
            max(.data$date), "day"
          ), 1))
      ) %>%
      ungroup() 
  } else if (quasi_exp == "national_short") {
    dates <- unique(data[["date"]])
    bw <- floor(min(p_treat, 0.5) * length(dates))
    
    date_start_treat <- sample(seq.Date(min(dates) + bw, max(dates) - bw, "day"), 1)
    
    # treated <- (data[["date"]] >= date_start_treat)
    # data[["treated"]] <- ifelse(
    #   data[["date"]] > date_start_treat + bw | data[["date"]] < date_start_treat - bw,
    #   NA, treated
    # )
    data <- data %>%
      mutate(
        treated = ifelse(
          .data[["date"]] > date_start_treat + bw |
            .data[["date"]] < date_start_treat - bw,
          NA, (.data[["date"]] >= date_start_treat))
      )
  }
  
  return(data)
  # data <- data %>% mutate(treated = treated)
  # return(data)
}


create_y1 <- function(data,
                      percent_effect_size = 0.5,
                      quasi_exp = "random_days") {
  
  if (str_starts(quasi_exp, ("random|national|local|alert|rolling"))) {
    data[["y1"]] <- data[["y0"]] + 
      rpois(length(data[["y0"]]), mean(data[["y0"]], na.rm = TRUE) * percent_effect_size / 100) %>%
      suppressWarnings() #warnings when is.na(dep_var) eg rpois(1, NA)
  } else if (quasi_exp == "GAM") {
    y1 <- data[["y0"]] 
  }
  return(data)
} 



estimate_model <- function(data, formula) {
  #get the different parameters from the formula
  fml <- Formula::as.Formula(formula)
  cluster <- formula(fml, lhs = 0, rhs = 3) %>% 
    suppressWarnings() #when no cluster provided, warning
  actual_fml <- formula(fml, rhs = -3)
  se <- ifelse(cluster == ~0, "hetero", "cluster")  
  
  #run the estimation
  est_results <- data %>% 
    feols(
      data = ., 
      fml = actual_fml, 
      cluster = cluster,
      se = se
    ) 
  
  #retrieve the useful info
  nobs <- length(est_results$residuals)
  
  est_results %>%
    broom::tidy(conf.int = TRUE) %>%
    filter(term =="treatedTRUE") %>%
    rename(p_value = p.value, se = std.error) %>%
    select(estimate, p_value, se) %>%
    mutate(n_obs = nobs)
} 


compute_simulation <- function(data,
                               n_days_study = 200,
                               p_treat = 0.5,
                               quasi_exp = "random_days",
                               percent_effect_size = 0.5,
                               formula = "deaths_all_causes ~ treated") {
  
  fml <- Formula::as.Formula(formula)
  dep_var <- paste(fml[[2]])
  
  sim_data <- data %>%
    draw_study_period(n_days_study) %>%
    filter(study_period) %>%
    select(-study_period) %>%
    rename(y0 = .data[[dep_var]]) %>%
    draw_treated(p_treat, quasi_exp) %>% 
    create_y1(percent_effect_size, quasi_exp) %>% 
    mutate(
      yobs = y1 * treated + y0 * (1 - treated)
      # yobs = y1*true_treated + y0*(1 - true_treated)
    ) %>%
    filter(!is.na(treated)) #not necessary bc dropped in lm()
  # filter(!is.na(true_treated)) #not necessary bc dropped in lm()
  
  #for the local intervention, we estimate a DID 
  #and thus need a post and a city_treated variable
  if (quasi_exp == "local") {
    sim_data <- sim_data %>%
      group_by(city) %>%
      mutate(city_treated = as.logical(max(treated))) %>%
      ungroup() %>%
      group_by(date) %>%
      mutate(post = as.logical(max(treated))) %>%
      ungroup()
    
    true_effect <- sim_data %>% 
      filter(post, city_treated) %>% 
      summarise(mean(y1 - y0, na.rm = TRUE)) %>% 
      as.numeric()
  } else if (str_starts(quasi_exp, "national")) {
    #for the nation intervention, we estimate an ITS 
    #and thus need a time index and time index
    sim_data <- sim_data %>%
      mutate(
        date_num = as.numeric(date),
        t = date_num - min(date_num),
        t_post = date_num - as.numeric(min(.data$date[treated == TRUE])),
        t_post = ifelse(t_post < 0, 0, t_post)
      )
    
    true_effect <- sim_data %>% 
      filter(t_post > 0) %>% 
      summarise(mean(y1 - y0, na.rm = TRUE)) %>% 
      as.numeric()
  } else {
    true_effect <- mean(sim_data$y1 - sim_data$y0, na.rm = TRUE)
  }
  
  sim_output <- sim_data %>%
    estimate_model(formula = update(fml, yobs ~ .)) %>%
    mutate(true_effect = true_effect)
  
  
  return(sim_output)
}

compute_simulation(total_data)

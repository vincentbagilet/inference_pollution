create_missing_length <- function(prop_missing, length_period) {
  draw <- rbinom(n(), 1, prob = prop_missing/length_period)*length_period
  out <- draw
  
  for (i in seq_along(draw)) {
    if(draw[i] > 0) {
      for (k in 1:draw[i]) {
          out[i + k - 1] <- draw[i]
      }
    }
  }
  
  missing <- (out > 0)
  
  return(missing[1:length(draw)])
}

#example
t <- data %>% 
  select(date, city, pollutant) %>% 
  group_by(city, pollutant) %>%
  mutate(r = create_missing_length(0.1, 4)) %>% 
  ungroup()

#copied/pasted from missingness_pattern_fr.Rmd
length_missing_data <- data %>% 
  mutate(row_id = row_number()) %>% 
  group_by(site, pollutant) %>%
  arrange(date) %>% 
  mutate(
    missing_period_id = ifelse(missing == TRUE & lag(missing) == FALSE, row_id, NA)
  ) %>%
  # filter(missing == TRUE) %>%
  fill(missing_period_id) %>% 
  ungroup() %>% 
  select(-row_id) %>% 
  arrange(missing_period_id) %>% 
  group_by(missing_period_id, pollutant) %>% 
  mutate(length_period_missing = n()) %>% 
  ungroup()

#define the table df_length_prop in the global environment
length_per_city_poll <- length_missing_data %>% 
  group_by(city, pollutant) %>% 
  count(length_period_missing) %>% 
  mutate(
    n = n/length_period_missing, 
    prop = n/sum(n)
  ) %>% 
  select(-n) %>% 
  nest() %>%
  rename(length_prop = data)

length_per_poll <- length_missing_data %>% 
  group_by(pollutant) %>% 
  count(length_period_missing) %>% 
  mutate(
    n = n/length_period_missing, 
    prop = n/sum(n)
  ) %>% 
  select(-n) %>% 
  nest() %>%
  rename(length_prop = data)
  

missing_diff_length <- function(prop_missing, df_prop_mult) {
  missing <- rep(0, n())
  df_prop <- df_prop_mult[[1]]
  
  for (i in 1:nrow(df_prop)){
    missing <- missing + create_missing_length(prop_missing*df_prop[[i, "prop"]], df_prop[[i, "length_period_missing"]])
  }
  out <- (missing > 0)
  return(out)
}


missing_per_city_poll <- data %>% 
  left_join(length_per_city_poll, by = c("city", "pollutant")) %>% 
  select(date, city, pollutant, length_prop) %>% 
  group_by(city, pollutant) %>% 
  mutate(missing_crea = missing_diff_length(0.1, length_prop)) %>% 
  select(-length_prop)

missing_per_poll <- data %>% 
  left_join(length_per_poll, by = "pollutant") %>% 
  select(date, pollutant, length_prop) %>% 
  group_by(pollutant) %>% 
  mutate(missing_crea = missing_diff_length(0.1, length_prop)) %>% 
  select(-length_prop)

#One observation per week
one_obs_per_week <- data %>% 
  group_by(city, pollutant, week = week(date)) %>% 
  slice_sample(n = 1) %>% 
  ungroup() %>% 
  select(-week) 

#With all covariates


library(tidyverse)
library(mediocrethemes)
library(fixest)

set_mediocre_all()

n_iter <- 1000
out <- tibble(
  term = rep("a", n_iter),
  estimate = rep(0, n_iter),
  std.error = rep(0, n_iter),
  statistic = rep(0, n_iter),
  p.value = rep(0, n_iter),
)

data_test <- total_data %>% 
  drop_na(deaths_all_causes, pm10, temperature)

n_obs <- 100
percent_effect_size <- 0.5
formula <- "log(y0) ~ pm10 + temperature | city"

for (i in seq_along(1:n_iter)) {
  dat <- data_test %>% 
    slice_sample(n = n_obs) %>% 
    rename(y0 = deaths_all_causes)
  
  fml <- Formula::as.Formula(formula)
  actual_fml <- formula(fml, rhs = -3)
  #run the estimation
  reg <- feols(data = dat, actual_fml)
  reg$coefficients[["pm10"]] <- percent_effect_size/100
  
  res <- reg$residuals
  dat <- dat %>% 
    mutate(
      y1 = exp(predict(reg, .)) + 
                 rnorm(res, mean(res), sd = sd(res))
      # y1 = round(y1)
    )
  mean(dat$y0)
  mean(dat$y1)
  
  reg_fake <- feols(data = dat, update(Formula::as.Formula(actual_fml), log(y1) ~ .))
  
  out[i,] <- reg_fake %>% 
    tidy() %>% 
    filter(term == "pm10") %>% 
    mutate(
      estimate = estimate*100, 
      std.error = 100*std.error
    )
}

# Design calculations
out %>% 
  filter(term == "pm10") %>% 
  rename(p_value = p.value) %>% 
  summarise(
    power = mean(p_value <= 0.05, na.rm = TRUE)*100, 
    type_m = mean(ifelse(p_value <= 0.05, abs(estimate/percent_effect_size), NA), na.rm = TRUE),
    type_s = sum(ifelse(p_value <= 0.05, sign(estimate) != sign(percent_effect_size), NA), na.rm = TRUE)/n()*100,
    mean_est = mean(estimate, na.rm = TRUE),
    .groups	= "drop"
  ) %>% 
  ungroup()

# Graph
out %>% 
  mutate(
    id = row_number(),
    significant = (p.value <= 0.05)
  ) %>% 
  ggplot() + 
  geom_point(aes(x = id, y = estimate, color = significant)) 
# geom_hline(aes(yintercept = 0.00772)) +
# ylim(c(-0.1, 0.1))









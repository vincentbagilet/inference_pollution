library(tidyverse)
library(mediocrethemes)

set_mediocre_all()

sim_evol_usual <- readRDS("~/Documents/Research/inference_pollution/R/Outputs/sim_evol_usual.RDS")
summary_evol_usual <- readRDS("~/Documents/Research/inference_pollution/R/Outputs/summary_evol_usual.RDS")

###################### Reduced form ############################

sim_evol_usual %>% 
  filter(id_method == "reduced_form") %>% 
  group_by(p_obs_treat, percent_effect_size, formula) %>% 
  summarise(n_obs = mean(n_obs)) %>% 
  mutate(n_treat = n_obs*p_obs_treat)

sim_evol_usual %>% 
  filter(id_method == "reduced_form") %>% 
  filter(p_obs_treat == 0.1, percent_effect_size == 11, str_starts(formula, "resp_total"))%>% 
  summarise(mean_se = mean(se), sd_est = sd(estimate - true_effect), mean_est = mean(estimate), mean_true_effect = mean(true_effect))

res_event_base

sim_evol_usual %>% 
  filter(id_method == "reduced_form") %>% 
  filter( percent_effect_size == 11, str_starts(formula, "resp_total")) %>%
  ggplot(aes(x = estimate)) + #, fill = (p_value <= 0.05))) + 
  geom_histogram(bins = 70) +
  facet_wrap(~ p_obs_treat)



sim_param_base_usual_reduced <- tibble(
  n_days = 2200,
  n_cities = 5,
  p_obs_treat = 0.004, #about 45/(2200*5),
  percent_effect_size = 11, 
  iv_strength = NA,
  formula = "resp_total ~ treated + temperature + temperature_squared | city + month^year + weekday"
)


sim_evol_large %>% 
  filter(id_method == "reduced_form") %>% 
  filter(n_cities == 40, n_days == 2500,
         percent_effect_size == 1, str_starts(formula, "death_total")) %>%
  ggplot(aes(x = estimate)) + #, fill = (p_value <= 0.05))) + 
  geom_histogram(bins = 70) +
  facet_wrap(~ p_obs_treat)

  
###################### IV ############################

sim_evol_usual %>% 
  filter(id_method == "IV") %>% 
  group_by(p_obs_treat, percent_effect_size, formula) 

sim_evol_usual %>% 
  filter(id_method == "IV") %>% 
  filter(p_obs_treat == 0.5, percent_effect_size == 1.5, str_starts(formula, "death_total"), iv_strength == 0.5) %>% 
  summarise(mean_se = mean(se), sd_est = sd(estimate), mean_est = mean(estimate), mean_true_effect = mean(true_effect))

sim_evol_usual %>% 
  filter(id_method == "IV") %>% 
  filter(p_obs_treat == 0.5, percent_effect_size == 1.5, str_starts(formula, "death_total"), iv_strength == 0.5) %>%
  ggplot(aes(x = estimate, fill = (p_value <= 0.05))) + 
  geom_histogram()

###################### RDD ############################

sim_evol_usual %>% 
  filter(id_method == "RDD") %>% 
  # filter(p_obs_treat == 0.012, percent_effect_size == 12, str_starts(formula, "death_total")) %>% 
  group_by(n_cities, n_days, p_obs_treat, percent_effect_size, formula) %>% 
  summarise(n_obs = mean(n_obs)) %>% 
  mutate(n_treat = n_cities*n_days*p_obs_treat)

sim_evol_usual %>% 
  filter(id_method == "RDD") %>% 
  filter(p_obs_treat == 0.012, percent_effect_size == 12, str_starts(formula, "death_total")) %>% 
  summarise(
    mean_se = mean(se, na.rm = TRUE), 
    sd_est = sd(estimate), 
    mean_est = mean(estimate), 
    mean_true_effect = mean(true_effect),
    median_est = median(estimate)
  )


sim_evol_usual %>% 
  filter(id_method == "RDD") %>% 
  filter(p_obs_treat == 0.012, percent_effect_size == 12, str_starts(formula, "death_total")) %>% 
  ggplot(aes(x = estimate, fill = (p_value <= 0.05))) + 
  geom_histogram(bins = 100)



sim_evol_usual %>% 
  filter(id_method == "RDD") %>%
  select(n_days:formula) %>% 
  unique() %>% 
  view


######################### SIMS #############


sim_param_evol_usual <- prepare_sim_param(
  sim_param_unique_usual_reduced %>% filter(p_obs_treat == 0.1)
  , n_iter = 5000) %>% 
  filter(id_method == "reduced_form") 

sim_evol_usual_test <- run_all_sim(nmmaps_data, sim_param_evol_usual_reduced, save_every = 10000, "sim_evol_usual_test")


sim_evol_usual %>% 
  filter(id_method == "reduced_form") %>% 
  filter(percent_effect_size == 11, str_starts(formula, "resp_total")) %>%
  ggplot(aes(x = estimate/true_effect, fill = (p_value <= 0.05))) + 
  geom_histogram(bins = 70) +
  facet_wrap(~ p_obs_treat)


sim_evol_usual %>% 
  filter(id_method == "reduced_form") %>% 
  filter(percent_effect_size == 11, str_starts(formula, "resp_total")) %>% 
  summarise(
    mean_se = mean(se), 
    sd_est = sd(estimate - true_effect), 
    mean_est = mean(estimate), 
    mean_true_effect = mean(true_effect)
  )



rpois(10000, 2*0.004) %>% qplot()



sim_evol_usual %>% 
  inner_join(sim_param_base_usual_reduced) %>%
  summarise(
    mean_se = mean(se), 
    sd_est = sd(estimate - true_effect), 
    mean_est = mean(estimate), 
    mean_true_effect = mean(true_effect)
  )

sim_evol_usual %>% 
  inner_join(sim_param_base_usual_RDD) %>%
  summarise(
    mean_se = mean(se), 
    sd_est = sd(estimate - true_effect), 
    mean_est = mean(estimate), 
    mean_true_effect = mean(true_effect)
  )


sim_evol_usual %>% 
  filter(iv_strength == 0.5, str_starts(formula, "death_total")) %>%
  summarise(
    mean_se = mean(se), 
    sd_est = sd(estimate - true_effect), 
    mean_est = mean(estimate), 
    mean_true_effect = mean(true_effect)
  )














#packages and set cores
library(tidyverse)
library(broom)
library(furrr)

future::plan(multisession, workers = availableCores() - 1)

#set baseline parameters
baseline_param <- tibble(
  N = 1000,
  mu_x = 1.2, 
  sigma_x = 0.9,
  sigma_u = 4,
  alpha = 0.5,
  beta = 0.3,
  div = 1
)

#function to generate data
generate_data <- function(N,
                          mu_x,
                          sigma_x,
                          sigma_u, 
                          alpha,
                          beta,
                          div) {
  
  data <- tibble(id = 1:N) %>%
    mutate(
      # x = rnorm(N, mu_x, sigma_x),
      x = rbernoulli(N),
      u = rnorm(N, 0, sigma_u),
      y = alpha + beta*x + u,
      y = floor(y/div)
    )
}

#function to run the estimation
run_estim <- function(data) {
  lm(data = data, y ~ x) %>%
    .$residuals %>% 
    sd() %>% 
    as_tibble()
}

#function to compute a simulation
compute_sim <- function(...) {
  generate_data(...) %>% 
    run_estim() %>% 
    cbind(as_tibble(list(...))) #add parameters used for generation
}

#replicate the process
#set the number of iterations and parameters to vary
n_iter <- 1000
vect_div <- c(1, 20)
#define the complete set of parameters
param <- baseline_param %>% 
  crossing(rep_id = 1:n_iter)  %>% 
  select(-div) %>% 
  crossing(div = vect_div) %>% 
  select(-rep_id) 

result_sim <- future_pmap_dfr(param, compute_sim,
                              .options = furrr_options(seed = TRUE))

result_sim <- result_sim %>% as_tibble()

result_sim %>% 
  summarise(power = mean(p.value <= 0.05))

result_sim %>% 
  mutate(
    comp_estimate = ifelse(div == 20, estimate*10, estimate),
    comp_estimate_sign = ifelse(p.value <= 0.05, abs(comp_estimate), NA)
  ) %>% 
  ggplot() +
  geom_histogram(aes(x = comp_estimate, fill = (p.value <= 0.05)), bins = 70) +
  geom_vline(aes(xintercept = mean(comp_estimate)), color = "white") +
  geom_vline(aes(xintercept = mean(comp_estimate_sign, na.rm = TRUE))) +
  facet_wrap(~ div)
  
result_sim %>% 
  group_by(div) %>% 
  summarise(power = mean(p.value <= 0.05))
  
  
  
  
  
  
  
  



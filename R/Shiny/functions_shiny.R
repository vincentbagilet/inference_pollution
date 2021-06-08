library(shiny)
library(tidyverse) 
library(mediocrethemes)
library(shinythemes)
library(shinyWidgets)
library(ggridges)
library(here)

set_mediocre_all()

summary_evol_small <- readRDS(here("R", "Outputs", "summary_evol_small.RDS")) 
summary_evol_large <- readRDS(here("R", "Outputs", "summary_evol_large.RDS")) 
summary_evol_usual <- readRDS(here("R", "Outputs", "summary_evol_usual.RDS")) 

sim_evol_small <- readRDS(here("R", "Outputs", "sim_evol_small.RDS")) 
sim_evol_large <- readRDS(here("R", "Outputs", "sim_evol_large.RDS")) 
sim_evol_usual <- readRDS(here("R", "Outputs", "sim_evol_usual.RDS")) 

case_studies_data <- readRDS(here("R", "Outputs", "case_studies_data.RDS"))

summary_decomp <- readRDS(here("R", "Outputs", "summary_decomp.RDS")) 

get_baseline_param <- function(df) {
  all_var <- c(
    "quasi_exp", 
    "n_days", 
    "n_cities", 
    "p_obs_treat", 
    "percent_effect_size", 
    "id_method",
    "iv_strength",
    "formula",
    "outcome"
  )
  
  #Get baseline values
  baseline_param <- df %>% 
    filter(outcome == "resp_total") %>% 
    select(quasi_exp, n_days, n_cities, p_obs_treat, percent_effect_size, id_method, iv_strength) %>% 
    distinct() %>% 
    # mutate(n_cities = max(n_cities)) %>% #when considering "evol_small"
    inner_join(
      df,
      by = all_var[!(all_var %in% c("formula", "outcome"))]
    ) %>% 
    filter(outcome == "death_total") %>% 
    select(all_var) %>% 
    distinct()
  
  return(baseline_param)
}


graph_evol_by_exp <- function(df, var_param = "n_days", stat = "power") {
  
  var_param_name <- str_replace_all(var_param, "_", " ") 
  stat_name <- str_replace_all(stat, "_", " ") 
  all_var <- c(
    "quasi_exp", 
    "n_days", 
    "n_cities", 
    "p_obs_treat", 
    "percent_effect_size", 
    "id_method",
    "iv_strength",
    "outcome"
  )
  
  df_filtered <-  get_baseline_param(df) %>% 
    select(-var_param) %>% 
    inner_join(df, by = all_var[all_var != var_param]) %>% 
    group_by(id_method) %>% #when the varying parameter pr stat is not available with some methods (eg iv_strength)
    filter(!is.na(.data[[var_param]])) %>% 
    filter(!is.na(.data[[stat]])) %>% 
    ungroup() 
  
  #graph itself
  graph <- df_filtered %>% 
    mutate(
      id_method = str_replace_all(id_method, "_", " ")
    ) %>% 
    ggplot(aes(x = .data[[var_param]], y = .data[[stat]])) + #, color = .data[[id_method]] + 
    geom_point() +
    geom_line(linetype = "dashed", size = 0.1) +
    facet_wrap(~ id_method, scales = "free_x") +
    ylim(c(0, ifelse(stat == "power", 100, NA))) +
    labs(
      title = paste(
        "Evolution of",
        str_to_title(stat_name), 
        "with", 
        var_param_name
      ),
      subtitle = "Comparison across quasi-experiments and identification methods",
      x = var_param_name,
      y = str_to_title(stat_name)
    ) 
  # theme(legend.position = "none")
  
  return(graph)
} 

check_distrib_estimate <- function(df) {

  #only consider baseline values
  df_baseline <- df %>% 
    filter(str_detect(formula, "resp_total")) %>% 
    select(quasi_exp, n_days, n_cities, p_obs_treat, percent_effect_size, id_method, iv_strength) %>% 
    distinct() %>% 
    inner_join(
      df,
      by = c("quasi_exp", "n_days", "n_cities", "p_obs_treat", "percent_effect_size", "id_method", "iv_strength")
    ) %>% 
    filter(str_detect(formula, "death_total"))

  graph <- df_baseline %>%
    ggplot() +
    geom_density(aes(x = true_effect - estimate)) +
    facet_wrap(~ id_method, scales = "free") + 
    geom_vline(aes(xintercept = 0)) +
    labs(
      title = "Distribution of estimates by identification method",
      subtitle = "Comparison to the true effect",
      x = "Difference between true effect and estimate"
    ) 
    
  return(graph)
}

table_stats <- function(df, var_param = "n_days", stat = "power", method = "DID") {
  all_var <- c(
    "quasi_exp", 
    "n_days", 
    "n_cities", 
    "p_obs_treat", 
    "percent_effect_size", 
    "id_method",
    "iv_strength",
    "outcome"
  )
  
  tab_out <-  get_baseline_param(df) %>% 
    select(-var_param) %>% 
    inner_join(df, by = all_var[all_var != var_param]) %>% 
    select(stat, var_param, id_method, all_var) %>% 
    filter(id_method == method) %>% 
    arrange(var_param) %>% 
    rename_with(~ str_to_title(str_replace_all(.x, "_", " "))) 
  
  return(tab_out)
}

graph_decomp <- function(df_decomp, var_decomp, stat) {
  df <-  df_decomp %>% 
    filter(decomp_var == var_decomp)
  
  x_var <- ifelse(var_decomp == "n_obs", "n_cities", "p_obs_treat")
  decreasing_x_var <- ifelse(var_decomp == "n_obs", "number of days", "number of observations")
  
  graph <- df %>% 
    mutate(
      n_treat = as.factor(round(n_days*n_cities*p_obs_treat/100)*100), 
      n_obs = as.factor(round(n_days*n_cities/100)*100)
    ) %>% 
    ggplot() + 
    geom_point(aes(x = .data[[x_var]], y = .data[[stat]], color = .data[[var_decomp]])) +
    geom_line(aes(x = .data[[x_var]], y = .data[[stat]], color = .data[[var_decomp]])) +
    facet_wrap(~ id_method, scales = "free_x") +
    labs(
      title = paste("Analysis of possible decoupling of", str_replace_all(var_decomp, "_", " ")),
      subtitle = str_c("Representation of iso-", var_decomp),
      y = str_to_title(str_replace_all(stat, "_", " ")),
      x = paste(str_to_title(x_var), "(and decreasing", decreasing_x_var, ")"),
      color = str_to_title(str_replace_all(var_decomp, "_", " "))
    ) 
  
  return(graph)
}

graph_ridge <- function(df, var_param = "n_days", stat = "estimate") {
  all_var <- c(
    "quasi_exp", 
    "n_days", 
    "n_cities", 
    "p_obs_treat", 
    "percent_effect_size", 
    "id_method",
    "iv_strength"
  )
  
  #only consider baseline values
  df_filtered <-  df %>% 
    mutate(outcome = str_extract(formula, "^[^\\s~]+(?=\\s?~)")) %>% 
    get_baseline_param() %>% 
    select(-var_param) %>% 
    inner_join(df, by = c(all_var[all_var != var_param], "formula")) %>% 
    group_by(id_method) %>% #when the varying parameter pr stat is not available with some methods (eg iv_strength)
    filter(!is.na(.data[[var_param]])) %>% 
    # filter(!is.na(.data[[stat]])) %>% 
    ungroup() %>% 
    filter(outcome == "death_total")
  
  graph <- df_filtered %>%
    ggplot() +
    geom_density_ridges(aes(x = .data[["estimate"]], y = as.factor(.data[[var_param]]))) +
    facet_wrap(~ id_method, scales = "free")

  return(graph)
}

select_df_size <- function(chr_size, summary = FALSE) {
  if (summary == FALSE) {
    df <- case_when(
      chr_size == "large_df" ~ "sim_evol_large", 
      chr_size == "small_df" ~ "sim_evol_small",
      chr_size == "case_study_df" ~ "sim_evol_usual")
  } else {
    df <- case_when(
      chr_size == "large_df" ~ "summary_evol_large", 
      chr_size == "small_df" ~ "summary_evol_small",
      chr_size == "case_study_df" ~ "summary_evol_usual")
  }
 
  return(get(df))
} 



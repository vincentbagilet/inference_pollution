get_baseline_param <- function(df) {
  all_var <- c(
    "quasi_exp", 
    "n_days", 
    "n_cities", 
    "p_obs_treat", 
    "percent_effect_size", 
    "id_method",
    "iv_intensity",
    "formula"
  )
  
  #Get baseline values
  baseline_param <- df %>% 
    filter(str_detect(formula, "resp_total")) %>% 
    select(quasi_exp, n_days, n_cities, p_obs_treat, percent_effect_size, id_method, iv_intensity) %>% 
    distinct() %>% 
    inner_join(
      df,
      by = all_var[all_var != "formula"]
    ) %>% 
    filter(str_detect(formula, "death_total")) %>% 
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
    "iv_intensity",
    "formula"
  )
  
  df_filtered <-  get_baseline_param(df) %>% 
    select(-var_param) %>% 
    inner_join(df, by = all_var[all_var != var_param])
  
  #graph itself
  graph <- df_filtered %>% 
    mutate(
      id_method = str_replace_all(id_method, "_", " ")
    ) %>% 
    ggplot(aes(x = .data[[var_param]], y = .data[[stat]])) + #, color = .data[[id_method]] + 
    geom_point() +
    geom_line(linetype = "dashed", size = 0.1) +
    facet_wrap(~ id_method) +
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
    select(quasi_exp, n_days, n_cities, p_obs_treat, percent_effect_size, id_method, iv_intensity) %>% 
    distinct() %>% 
    inner_join(
      df,
      by = c("quasi_exp", "n_days", "n_cities", "p_obs_treat", "percent_effect_size", "id_method", "iv_intensity")
    ) %>% 
    filter(str_detect(formula, "death_total"))
  
  data_true_effects <- df_baseline %>%
    group_by(id_method) %>%
    summarize(mean_true_effect = mean(true_effect))

  graph <- df_baseline %>%
    ggplot() +
    geom_density(aes(x = estimate)) +
    facet_wrap(~ id_method, scales = "free") + 
    geom_vline(data = data_true_effects, aes(xintercept = mean_true_effect)) +
    labs(
      title = "Distribution of estimates by identification method",
      subtitle = "Comparison to the true effect",
      caption = "The vertical line represents the true effect"
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
    "iv_intensity",
    "formula"
  )
  
  tab_out <-  get_baseline_param(df) %>% 
    select(-var_param) %>% 
    inner_join(df, by = all_var[all_var != var_param]) %>% 
    select(stat, all_var) %>% 
    filter(id_method == method) %>% 
    rename_with(~ str_to_title(str_replace_all(.x, "_", " ")))
  
  return(tab_out)
}

graph_decomp <- function(df_decomp, var_decomp, stat) {
  df <-  df_decomp %>% 
    filter(decomp_var == var_decomp)
  
  x_var <- ifelse(var_decomp == "n_obs", "n_cities", "p_obs_treat")
  
  graph <- df %>% 
    mutate(
      n_treat = as.factor(round(n_days*n_cities*p_obs_treat/100)*100), 
      n_obs = as.factor(round(n_days*n_cities/100)*100)
    ) %>% 
    ggplot() + 
    geom_point(aes(x = .data[[x_var]], y = .data[[stat]], color = .data[[var_decomp]])) +
    geom_line(aes(x = .data[[x_var]], y = .data[[stat]], color = .data[[var_decomp]])) +
    facet_wrap(~ id_method, scales = "free_x")
  
  return(graph)
}





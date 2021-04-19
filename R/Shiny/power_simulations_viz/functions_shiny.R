sim_param_base <- readRDS("data/sim_param_base.RDS")

graph_evol_by_exp <- function(df, var_param = "n_days_study", stat = "power") {
  
  var_param_name <- str_replace_all(var_param, "_", " ")
  stat_name <- str_replace_all(stat, "_", " ")
  
  #considering baseline values
  df_filtered <- df %>% 
    filter(str_detect(formula, "temperature")) #to only consider the model with all covariates
  
  if (var_param != "p_treat") {
    df_filtered <- df_filtered %>% 
      filter(p_treat == sim_param_base[["p_treat"]])
  } 
  if (!(var_param %in% c("n_days_study", "average_n_obs"))) {
    df_filtered <- df_filtered %>% 
      filter(n_days_study == sim_param_base[["n_days_study"]])
  } 
  if (var_param != "percent_effect_size") {
    df_filtered <- df_filtered %>% 
      filter(percent_effect_size == sim_param_base[["percent_effect_size"]])
  }
  
  #graph itself
  graph <- df_filtered %>% 
    mutate(
      quasi_exp = str_to_sentence(str_replace_all(quasi_exp, "_", " "))
    ) %>% 
    ggplot(aes(x = .data[[var_param]], y = .data[[stat]])) + #, color = .data[[quasi_exp]] + 
    geom_point() +
    geom_line(linetype = "dashed", size = 0.1) +
    facet_wrap(~ quasi_exp) +
    ylim(c(0, ifelse(stat == "power", 100, NA))) +
    labs(
      title = paste(
        str_to_title(stat_name), ifelse(stat == "power", "increases", "decreases"),
        "with", var_param_name
      ),
      subtitle = "Comparison across quasi-experiments",
      x = var_param_name,
      y = str_to_title(stat_name)
    ) 
  # theme(legend.position = "none")
  
  return(graph)
} 
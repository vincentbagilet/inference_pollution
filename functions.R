#Functions that are used in several scripts
summarise_sim <- function(data, varying_params, true_effect) {
  data %>%
    mutate(signif = (p_value <= 0.05)) |>  
    group_by(across({{ varying_params }})) |>
    summarise(
      power = mean(signif, na.rm = TRUE)*100, 
      type_m = mean(ifelse(signif, abs(estimate/unique({{ true_effect }})), NA), na.rm = TRUE),
      # exag_ratio = mean(ifelse(signif, estimate/{{ true_effect }}, NA), na.rm = TRUE),
      bias_all = mean(estimate/{{ true_effect }}, na.rm = TRUE),
      bias_all_median = median(estimate/{{ true_effect }}, na.rm = TRUE),
      median_snr = median(abs(estimate/se), na.rm = TRUE),
      .groups	= "drop"
    ) |>  
    ungroup() 
} 

summary_power <- function(data, lint_names = FALSE) {
  summary_power <- data |>
    summarise(
      median_exagg = median(type_m),
      `3rd_quartile_exagg` = quantile(type_m, 0.75),
      prop_larger_2 = mean(type_m > 2)*100,
      median_power = median(power),
      `3rd_quartile_power` = quantile(power, 0.75)
    ) |> 
    round(1)
  
  if (lint_names) {
    summary_power <- summary_power |>
      rename(`Prop Exagg Larger Than 2 (%)` = prop_larger_2) |> 
      rename_with(\(x) str_to_title(str_replace_all(x, "_", " ")))
  }
  
  return(summary_power)
}
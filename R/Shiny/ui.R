fluidPage(theme = shinytheme("flatly"),
          
          chooseSliderSkin("Flat", color = "#182029"),
          
          titlePanel("Power visualisations"),
          
          # Sidebar with a slider input for number of bins 
          sidebarLayout(
              sidebarPanel(
                  conditionalPanel(
                      condition = "input.tabselected < '4'",
                      radioButtons(inputId = "df_size",
                                   label = "Dataset size:",
                                   choices = c(
                                       "Large" = "large_df", 
                                       "Small" = "small_df")),
                  ),
                  conditionalPanel(
                      condition = "input.tabselected < '3'",
                      selectInput(inputId = "var_param",
                                  label = "Varying parameter:",
                                  choices = c(
                                      "Number of days in the study" = "n_days", 
                                      "Effect size" = "percent_effect_size", 
                                      "Proportion of treated units" = "p_obs_treat",
                                      "Outcome" = "outcome",
                                      "IV intensity" = "iv_intensity")),
                  ), 
                  conditionalPanel(
                      condition = "input.tabselected != '3' && input.tabselected != '1'",
                      selectInput(inputId = "stat",
                                  label = "Statistics:",
                                  choices = c(
                                      "Power" = "power", 
                                      "Type M" = "type_m", 
                                      "Type S" = "type_s",
                                      "Coverage rate (significant)" = "coverage_rate",
                                      "Coverage rate (all)" = "coverage_rate_all",
                                      "Signal to noise ratio" = "mean_signal_to_noise",
                                      "Average F-stat" = "mean_f_stat")),
                  ),
                  conditionalPanel(
                      condition = "input.tabselected == '2'",
                      selectInput(inputId = "method",
                                  label = "Identification method:",
                                  choices = c("RCT", "RDD", "OLS", "IV")),
                  ),
                  conditionalPanel(
                      condition = "input.tabselected == '4'",
                      radioButtons(inputId = "var_decomp",
                                   label = "Decomposition of:",
                                   choices = c(
                                       "Number of observations" = "n_obs",
                                       "Number of treated" = "n_treat")),
                  ),
              ),
              
              # Show a plot of the generated distribution
              mainPanel(
                  tabsetPanel(
                      tabPanel(
                          value = 0,
                          "Relation statistics/parameters",
                          plotOutput("evol_by_exp"),
                          h3("Values of non-varying parameters"),
                          tableOutput("table_baseline_param"),
                      ),
                      tabPanel(
                          value = 1,
                          "Ridge plot",
                          plotOutput("ridge_plot"),
                      ),
                      tabPanel(
                          value = 2,
                          "Table statistics",
                          tableOutput("table_by_exp"),
                      ),
                      tabPanel(
                          value = 3,
                          "Checks",
                          plotOutput("check_plot"),
                      ),
                      tabPanel(
                          value = 4,
                          "Decomposition",
                          plotOutput("decomp_plot"),
                      ),
                      
                      id = "tabselected"
                  )
              )
          )
)

library(shiny)
library(tidyverse) 
library(mediocrethemes)
library(shinythemes)
library(shinyWidgets)

set_mediocre_all()

summary_simulations <- readRDS("./data/summary_simulations.RDS")
all_simulations <- readRDS("./data/all_simulations.RDS")
# sim_param_base <- readRDS("data/sim_param_base.RDS")
source("./functions_shiny.R")

#### UI ------------------

ui <- fluidPage(theme = shinytheme("flatly"),
                
    chooseSliderSkin("Flat", color = "#182029"),

    titlePanel("Power visualisations"),

    # Sidebar with a slider input for number of bins 
    sidebarLayout(
        sidebarPanel(
            conditionalPanel(
                condition = "input.tabselected < '2'",
                selectInput(inputId = "var_param",
                            label = "Choose a varying parameter:",
                            choices = c(
                                "Number of days in the study" = "n_days", 
                                "Number of cities in the study" = "n_cities",  
                                "Effect size" = "percent_effect_size", 
                                "Proportion of treated units" = "p_obs_treat")),
                
                selectInput(inputId = "stat",
                            label = "Choose a statistics:",
                            choices = c(
                                "Power" = "power", 
                                "Type M" = "type_m", 
                                "Type S" = "type_s",
                                "MSE" = "mse", 
                                "Mean of the estimates" = "mean_estimate",
                                "Normalised biased" = "nomalized_bias",
                                "Estimate to true ratio" = "estimate_true_ratio", 
                                "Average F-stat" = "mean_f_stat")),
            ),
            conditionalPanel(
                condition = "input.tabselected == '1' || input.tabselected == '2'",
                selectInput(inputId = "method",
                            label = "Choose an identification method:",
                            choices = c("DID", "RCT", "RDD", "OLS", "IV_0.5", "IV_0.1")),
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
                    "Table statistics",
                    tableOutput("table_by_exp"),
                ),
                tabPanel(
                    value = 2,
                    "Checks",
                    plotOutput("check_plot"),
                ),
                id = "tabselected"
            )
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) {

    output$evol_by_exp <- renderPlot({
        graph_evol_by_exp(summary_simulations, input$var_param, input$stat)
    })
    
    output$check_plot <- renderPlot({
        check_distrib_estimate(all_simulations)
    })
    
    output$table_by_exp <- renderTable({
        table_stats(summary_simulations, input$var_param, input$stat, input$method)
    })
    
    output$table_baseline_param <- renderTable({
        get_baseline_param(summary_simulations) %>% 
            select(-input$var_param) %>% 
            distinct() %>% 
            rename_with(~ str_to_title(str_replace_all(.x, "_", " ")))
    })
}

# Run the application 
shinyApp(ui = ui, server = server)

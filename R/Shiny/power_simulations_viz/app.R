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
                condition = "input.tabselected == '0'",
                selectInput(inputId = "var_param",
                            label = "Choose a variable:",
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

        # Show a plot of the generated distribution
        mainPanel(
            tabsetPanel(
                tabPanel(
                    value = 0,
                    "Relation statistics/parameters",
                    plotOutput("evol_by_exp"),
                ),
                tabPanel(
                    value = 1,
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
}

# Run the application 
shinyApp(ui = ui, server = server)

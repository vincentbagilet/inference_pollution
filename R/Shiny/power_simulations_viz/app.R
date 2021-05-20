library(shiny)
library(tidyverse) 
library(mediocrethemes)
library(shinythemes)
library(shinyWidgets)

set_mediocre_all()

summary_simulations <- readRDS("data/summary_simulations.RDS")
# sim_param_base <- readRDS("data/sim_param_base.RDS")
source("./functions_shiny.R")

#### UI ------------------

ui <- fluidPage(theme = shinytheme("flatly"),
                
    chooseSliderSkin("Flat", color = "#182029"),

    titlePanel("Power visualisations"),

    # Sidebar with a slider input for number of bins 
    sidebarLayout(
        sidebarPanel(
            selectInput(inputId = "var_param",
                        label = "Choose a variable:",
                        choices = c(
                            "Number of days in the study" = "n_days", 
                            "Number of cities in the study" = "n_cities", 
                            "Number of observations" = "average_n_obs", 
                            "Effect size" = "percent_effect_size", 
                            "Proportion of treated units" = "p_treat")),
            
            selectInput(inputId = "stat",
                        label = "Choose a statistics:",
                        choices = c(
                            "Power" = "power", 
                            "Type M" = "type_m", 
                            "Type S" = "type_s")),
        ),

        # Show a plot of the generated distribution
        mainPanel(
           plotOutput("design_plot")
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) {

    output$design_plot <- renderPlot({
        graph_evol_by_exp(summary_simulations, input$var_param, input$stat)
    })
}

# Run the application 
shinyApp(ui = ui, server = server)

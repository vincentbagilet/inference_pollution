library(shiny)
library(tidyverse) 
library(mediocrethemes)
library(shinythemes)
library(shinyWidgets)
library(ggridges)

set_mediocre_all()

summary_evol <- readRDS(here("R", "Outputs", "summary_evol.RDS")) 
sim_evol <- readRDS(here("R", "Outputs", "sim_evol.RDS")) 
summary_decomp_ptreat <- readRDS(here("R", "Outputs", "summary_decomp.RDS")) 

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
                condition = "input.tabselected < '4'",
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
                condition = "input.tabselected == '3'",
                selectInput(inputId = "var_decomp",
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
                    "Decomposition",
                    plotOutput("decomp_plot"),
                ),
                tabPanel(
                    value = 4,
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
        graph_evol_by_exp(summary_evol, input$var_param, input$stat)
    })
    
    output$check_plot <- renderPlot({
        check_distrib_estimate(sim_evol)
    })
    
    output$table_by_exp <- renderTable({
        table_stats(summary_evol, input$var_param, input$stat, input$method)
    })
    
    output$table_baseline_param <- renderTable({
        get_baseline_param(summary_evol) %>% 
            select(-input$var_param) %>% 
            distinct() %>% 
            select(id_method, everything()) %>% 
            rename_with(~ str_to_title(str_replace_all(.x, "_", " "))) 
    })
    
    output$decomp_plot <- renderPlot({
        graph_decomp(summary_decomp, input$var_decomp, input$stat)
    })
    
    output$ridge_plot <- renderPlot({
        graph_ridge(sim_evol,  input$var_param, input$stat)
    })
}

# Run the application 
shinyApp(ui = ui, server = server)

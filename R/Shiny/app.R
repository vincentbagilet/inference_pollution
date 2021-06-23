#to publish online
dir.create('~/.fonts')
file.copy("www/Lato.ttf", "~/.fonts")
system('fc-cache -f ~/.fonts')

source("functions_shiny.R")

#in local
# source(here::here("R/Shiny/functions_shiny.R"))

#### UI ------------------

ui <- fluidPage(theme = shinytheme("flatly"),
                
    chooseSliderSkin("Flat", color = "#182029"),

    titlePanel("Power visualisations"),

    # Sidebar with a slider input for number of bins 
    sidebarLayout(
        sidebarPanel(
            conditionalPanel(
                condition = "input.tabselected < '4'",
                radioButtons(inputId = "df_size",
                             label = "Dataset:",
                             choices = c(
                                 "Large data set" = "large_df", 
                                 "Small data set" = "small_df",
                                 "Case studies" = "case_study_df")),
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
                                "IV strength" = "iv_strength")),
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
                            choices = c("Reduced form" = "reduced_form", "RDD", "OLS", "IV")),
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

# Define server logic required to draw a histogram
server <- function(input, output) {

    output$evol_by_exp <- renderPlot({
        graph_evol_by_exp(select_df_size(input$df_size, summary = TRUE), input$var_param, input$stat)
    })
    
    output$check_plot <- renderPlot({
        check_distrib_estimate(select_df_size(input$df_size, summary = FALSE))
    })
    
    output$table_by_exp <- renderTable({
        table_stats(select_df_size(input$df_size, summary = TRUE), input$var_param, input$stat, input$method)
    })
    
    output$table_baseline_param <- renderTable({
        get_baseline_param(select_df_size(input$df_size, summary = TRUE)) %>% 
            select(-input$var_param) %>% 
            distinct() %>% 
            select(id_method, everything()) %>% 
            rename_with(~ str_to_title(str_replace_all(.x, "_", " "))) 
    })
    
    output$decomp_plot <- renderPlot({
        graph_decomp(summary_decomp, input$var_decomp, input$stat)
    })
    
    output$ridge_plot <- renderPlot({
        graph_ridge(select_df_size(input$df_size, summary = FALSE),  input$var_param, input$stat)
    })
}

# Run the application 
shinyApp(ui = ui, server = server)

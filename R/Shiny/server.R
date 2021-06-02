function(input, output) {

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

#-----------------------------------------------

# SCRIPT FOR CUSTOM GGPLOT2 GRAPHICS THEME

#-----------------------------------------------

custom_theme <- hrbrthemes::theme_ipsum_rc() + theme(
    # titles parameters
    plot.title = element_text(size=30, face = "bold"),
    plot.subtitle=element_text(size=16),
    # axis titles parameters
    axis.title.x = element_text(size=24, margin = margin(t = 20, r = 0, b = 0, l =0)),
    axis.title.y = element_text(size=24, margin = margin(t = 0, r = 20, b = 0, l = 0)),
    # axis texts
    axis.text.x = element_text(size=18),
    axis.text.y = element_text(size=18),
    # facet texts
    strip.text.x = element_text(size=24, face = "bold"),
    strip.text.y = element_text(size=24, face = "bold"),
    # legend parameters
    legend.position="bottom",
    legend.title = element_text(size=24, face = "bold"),
    legend.text = element_text(size=24),
    plot.margin = margin(1, 1, 1, 1, "cm"))


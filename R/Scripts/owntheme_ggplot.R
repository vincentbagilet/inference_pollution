library("tidyverse")
library("viridis")
library("wesanderson")

green <- c(base = "#2D6A48", light = "#D9F8D1", background = "#E7F5E7", dark = "#1C4221")
color <- c(base = "#283845", light = "#4A6982", background = "#F5F6F4", dark = "#1D2834")

own_pal <- c("#F94144", "#F86335", "#F68425", "#F9AF37", "#F9C74F", "#C5C35E", "#90BE6D", "#43AA8B", "4D908E", "#577590")

light_green <- "#E7F5E7"
color_base <- "#2D6A48"



mpg %>% 
  # filter(fl != "e", fl != "r", fl != "c") %>%
  ggplot(aes(x = cty, y = displ, fill = manufacturer)) +
  geom_col() +
  # geom_point() +
  # geom_smooth() +
  # geom_density() +
  theme_mediocre() +
  scale_mediocre_d() +
  # scale_fill_distiller(low = color[["light"]], high = color[["dark"]])
  # scale_fill_viridis_d() +
  # scale_fill_brewer(palette = "Spectral") +
  labs(title = "A very nice title", subtitle = "A desapointing subtitle")

  
  ggplot(data = ggplot2::mpg, aes(x = cty, y = displ)) +
    geom_col() +
    theme_mediocre() +
    scale_mediocre_d() +
    labs(title = "A very nice title", subtitle = "A desapointing subtitle")
  

#---------------------------------------------------------------------------------

# SCRIPT: CLEANING WEATHER DATA

#---------------------------------------------------------------------------------

# attach libraries
library(tidyverse)
library(data.table)
library(lubridate)

# load data
weather_data <- data.table::fread("C:/Users/Leo/Dropbox/phd_thesis/project_air_pollution_lockdown/1.data/1.raw_data/2.weather/weather_data.txt", dec = ",")

# select relevant variables and rename them
weather_data <- weather_data %>%
  select(POSTE:GLOT) %>%
  rename("city" = "POSTE",
         "date" = "DATE",
         "rainfall_height" = "RR",
         "rainfall_duration" = "DRR",
         "temperature_minimum" = "TN",
         "temperature_maximum" = "TX",
         "temperature_average" = "TM",
         "sea_level_pressure" = "PMERM",
         "wind_speed_average_10_meters" = "FFM",
         "wind_speed_maximum_instantaneous" = "FXI",
         "wind_direction_maximum_instantaneous" = "DXI",
         "wind_speed_maximum_over_10_minutes" = "FXY",
         "wind_direction_maximum_over_10_minutes" = "DXY",
         "humidity_average" = "UM",
         "insolation_duration" = "INST",
         "global_radiation" = "GLOT")

# convert date variable in date format
weather_data <- weather_data %>%
  mutate(date = lubridate::ymd(date))

# rename city
weather_data <- weather_data %>%
  mutate(city = recode(city, 
                       "6088001" = "Nice", "13054001" = "Marseille", "31069001" = "Toulouse",
                       "44020001" = "Nantes", "69029001" = "Lyon", "75114001" = "Paris"))
# save the data
saveRDS(weather_data,"C:/Users/Leo/Dropbox/phd_thesis/project_air_pollution_lockdown/1.data/2.cleaned_data/weather_data.RDS")














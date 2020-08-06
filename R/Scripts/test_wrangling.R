library(tidyverse)
library(europollution)
library(lubridate)

load("/Users/vincentbagilet/Dropbox/project_air_pollution_lockdown/1.data/1.raw_data/1.air_pollution/data_downloaded.Rda")

data_wrangled <- data_downloaded %>%
  ep_wrangle()

data_wrangled %>%
  # head(8000) %>%
  group_by(station_id, pollutant) %>%
  summarise(
    min_date = min(datetime_begin),
    max_date = max(datetime_begin),
    nb_dates = n()
  ) %>%
  view()


data_wrangled %>%
  group_by(station_id, pollutant) %>%
  summarise(
    min_date = min(datetime_begin),
    max_date = max(datetime_begin),
    n = n()
  ) %>%
  view()

#No missing data before station opening
data_wrangled %>%
  head(100000) %>%
  mutate(
    date = ymd_hms(datetime_begin)
  ) %>%
  group_by(station_id, pollutant) %>%
  complete(date = ymd_hms(seq(min(date), max(date), by = 'hour'))) %>% 
  fill(country_iso, sampling_point) %>%
  ungroup() %>% 
  view()

#Missing data before station opening and after closing
data_wrangled %>%
  head(100000) %>%
  mutate(
    date = ymd_hms(datetime_begin),
    min_date = min(min_date, na.rm = TRUE),
    max_date = max(max_date, na.rm = TRUE)
  ) %>%
  group_by(station_id, pollutant) %>%
  complete(date = ymd_hms(seq(min_date, max_date, by = 'hour'))) %>% 
  fill(country_iso, sampling_point) %>%
  ungroup() %>% 
  view()

%>%
  complete(station_id = station_id, pollutant = pollutant) %>%
  fill(country_iso, sampling_point) %>%
  ungroup() %>%
  arrange(station_id, pollutant, date) %>%
  filter(averaging_time > 3600 | lead(averaging_time, 2) > 3600 | lag(averaging_time, 2) > 3600 | lead(averaging_time) > 3600 | lag(averaging_time) > 3600| lead(averaging_time, 3) > 3600 | lag(averaging_time, 3) > 3600) %>%
  view()


data_wrangled %>%
  group_by(station_id, pollutant) %>%
  mutate(
    min_date = min(datetime_begin),
    max_date = max(datetime_begin)
  )

  # arrange(station_id, pollutant, datetime_begin) %>%
  complete(station_id, pollutant, datetime_begin) %>%
  arrange(station_id, pollutant, datetime_begin) %>%
  group_by(station_id, pollutant) %>%
  mutate(
    min_date = min(min_date, na.rm = TRUE),
    max_date = max(max_date, na.rm = TRUE)
  ) %>%
  ungroup() %>%
  filter(datetime_begin >= min_date & datetime_begin <= max_date)
  # fill(country_iso, station_id, sampling_point, pollutant)


  # group_by(sampling_point, pollutant)

  data_wrangled %>%
    head(100000) %>%
    ep_complete_dates() %>% 
    view()
  
    

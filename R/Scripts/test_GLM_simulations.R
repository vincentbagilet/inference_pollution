reg <- feglm(data = nmmaps_data, fml = resp_total ~ co)

reg$coefficients[["co"]] <- 10/100

dat <- nmmaps_data %>% 
  mutate(resp_total = predict(reg, nmmaps_data))

new_reg <- feols(data = dat, fml = resp_total ~ co)

new_reg$coefficients[["co"]]/mean(dat$resp_total)





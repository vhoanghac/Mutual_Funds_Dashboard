library(tidyverse)
library(timetk)
library(purrr)

# CSV paths:
paths <- fs::dir_ls("data")

# Get file names:
datanames <-  gsub("\\.csv$","", list.files(path = "data", pattern = "\\.csv$")) %>% 
  tolower()

# Import multiple csv to a list:
list <- paths %>% 
  map(function(path){
    read_csv(path)
  })

# Convert to monthly data:
list_converted <- list %>% 
  set_names(datanames) %>% 
  
  lapply(function(x){
    
    x %>%
      
      # First day of each month in the dataset
      summarise_by_time(.date_var = date,
                        .by       = "month",
                        price     = first(price),
                        .type     = "floor") %>% 
      
      # Calculate monthly returns
      tq_transmute(select     = price,
                   mutate_fun = periodReturn,
                   period     = "monthly",
                   col_rename = "returns") 
  })

# Convert from list to tibble. Full data.
data <- lapply(names(list_converted), function(x) cbind(list_converted[[x]], x)) %>% 
  bind_rows() %>%
  as.tibble() %>% 
  rename("symbol" = x)

# Export
write_csv(data, "data_tidied/full_data.csv")

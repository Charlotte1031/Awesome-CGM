# This is the script for processing Shah 2019 data into the common format. 
# Author: Charlotte Xu
# Date: Sep.30 

# Load the necessary library
library(dplyr)
library(tidyverse)
library(haven)
library(readr)

T1DE_CGM <- read_csv("Pre-Processing/Shah2019/NonDiabDeviceCGM.csv") # CGM_reading: PtID = T1DE$id, DeviceTm = T1DE$time, Value = T1DE$gl
T1DE_screening <- read_csv("Pre-Processing/Shah2019/NonDiabScreening.csv") # PtID = T1DE$id,  Gender = NDChild$sex
T1DE_Patient<- read_csv("Pre-Processing/Shah2019/NonDiabPtRoster.csv") #AgeAsOfEnrollDt = T1DE$age

# Merging acquired variable information
T1DE <- T1DE_CGM %>%
  left_join(T1DE_screening, by = "PtID") %>%  # PtID corresponds to "id"
  left_join(T1DE_Patient, by = "PtID")        # joining by PtID and id

# To blind the exact study start date, we mask the outputs by only using the n-th dates. 
# For this purpose, we generate pseudo start dates, starting from January 1, 2017.
pseudo_start_date <- as.Date("2017-01-01")

# Prepare the T1DE_combined dataset by generating pseudo start dates and transforming variables
T1DE_combined <- T1DE %>%
  # Calculate the actual device date by adding the days from enrollment to the pseudo start date
  mutate(DeviceDate = pseudo_start_date + days(DeviceDtDaysFromEnroll),
         # Combine DeviceDate and DeviceTm to create a DateTime column
         DateTime = as.POSIXct(paste(DeviceDate, DeviceTm), format = "%Y-%m-%d %H:%M:%S")) %>%
  # Select relevant columns and rename them for consistency
  select(id = PtID, time = DateTime, gl = Value, sex = Gender, age = AgeAsOfEnrollDt) %>%
  # Ensure the time is correctly formatted as POSIXct
  mutate(time = as.POSIXct(time, format = "%Y-%m-%d %H:%M:%S"),
         # Label the dataset for reference
         dataset = "shah2019",
         # Set type to 0 as placeholder (e.g., non-diabetic or unspecified)
         type = 0,
         # Set insulin modality to NA as we don't have this information
         insulinModality = NA,
         # Set the device type to "Dexcom G6" for all subjects
         device = "Dexcom G6") %>%
  # Generate unique pseudo IDs for each participant by adding 9000 to group IDs
  group_by(id) %>%
  mutate(pseudoID = cur_group_id() + 9000) %>%
  # Ungroup the dataset after creating pseudoID
  ungroup() %>%
  # Select the final columns for the output dataset with renamed IDs and relevant fields
  select(id = pseudoID, time, gl, age, sex, insulinModality, type, device, dataset)

# Save the final dataset to a CSV file
write.csv(T1DE_combined, file = "csv_data/Shah2019.csv", row.names = FALSE)
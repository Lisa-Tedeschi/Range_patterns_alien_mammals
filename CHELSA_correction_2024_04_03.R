########################################
############# CLIMATIC DATA ############
########################################

# Started on 11.12.2022
# modified on 03.04.2024
# by LT
# for the paper "Patterns and drivers of range filling of alien mammals in Europe"

# this is a script to adjust scale and offset of CHELSA bioclimatic variables 

# Setting up the R environment
rm(list=ls())
setwd("E:/PhD/2nd_Chapter/Sensitivity_analysis")
getwd()

pacman::p_load(terra, tidyverse)



# - # - # - # - # - # - # - # - # - # - # 
#                                       #
#                                       #
#           1. CLIMATE DATA             #
#                                       #
#                                       #
# - # - # - # - # - # - # - # - # - # - # 



## 2.1 Load and stack original (1x1km) Chelsa bioclimatic variables

chelsa_1km <- terra::rast(paste0("./Data/Original/Chelsa/Original_1km/", list.files("./Data/Original/Chelsa/Original_1km")))

# check the names - NB they are NOT in the order bio1-bio2-bio3-etc
names(chelsa_1km)
summary(chelsa_1km[[2]]) # the 2nd layer is bio10 and has a min value of -38.45

# short the names
short_names <- c(paste0("bio", c(1, 10:19,2:9), "_1km"))
names(chelsa_1km) <- short_names
names(chelsa_1km) 
summary(chelsa_1km[[2]]) 

# reorder the layers
ordered_names <- c(paste0("bio",1:19,"_1km"))
chelsa_1km <- chelsa_1km[[ordered_names]]
names(chelsa_1km)
summary(chelsa_1km[[10]])



## 2.2 Adjust the Chelsa variables if needed 

# depending on the versions of the GIS used, data may need to be adjusted 
summary(chelsa_1km[[1]]) 

# this is bio1, the mean annual temperature: it should range between -53 and +34
# if it doesn't, the scale and offset has to be set manually for the variables
# This can be done by first multiplying the raster values with the ‘scale’ value and then adding the ‘offset’ value

offset <- c(-273.15,0,0,0,-273.15,-273.15,0,rep(-273.15,4),rep(0,8)) # this is in order bio1:bio19

i = 1
chelsa_updated_1km <- c()

for(layer in names(chelsa_1km)){
  
  new_layer <- (chelsa_1km[[i]] * 0.1) + (offset[i])
  chelsa_updated_1km <- c(chelsa_updated_1km, new_layer)
  
  i = i + 1
  
}

chelsa_updated_1km

filenames <- c(paste0("./Data/Processed/Chelsa/Updated_1km/", names(chelsa_updated_1km), ".tif"))

i = i 
for(layer in names(chelsa_updated_1km)){
  
  terra::writeRaster(x = chelsa_updated_1km, filename = filenames, bylayer = T, overwrite = T)
  i = i + 1
  
}

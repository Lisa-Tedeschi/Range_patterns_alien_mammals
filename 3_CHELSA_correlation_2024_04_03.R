########################################
############# CLIMATIC DATA ############
########################################

# Started on 11.12.2022
# modified on 03.04.2024
# by LT
# for the paper "Patterns and drivers of range filling of alien mammals in Europe"

# this is a script to check for correlation of CHELSA bioclimatic variables 
# and to crop CHELSA to the world landmass

# Setting up the R environment
rm(list=ls())
setwd("E:/PhD/2nd_Chapter/Sensitivity_analysis")
getwd()

pacman::p_load(terra, tidyverse, sdmpredictors)



# - # - # - # - # - # - # - # - # - # - # 
#                                       #
#                                       #
#            1. CORRELATION             #
#                                       #
#                                       #
# - # - # - # - # - # - # - # - # - # - # 



## 1.1 Load and stack the aggregated (10x10 km) Chelsa bioclim rasters

# load the raster stack of aggregated Chelsa bioclimated 
chelsa_10km <- raster::stack(paste0("./Data/Processed/Chelsa/Aggregated_10km/", list.files("./Data/Processed/Chelsa/Aggregated_10km")))

# check the names - NB they are NOT in the order bio1-bio2-bio3-etc
names(chelsa_10km)
summary(chelsa_10km[[2]]) # the 2nd layer is bio10 and has a min value of -38.45

# short the names
short_names <- c(paste0("bio", c(1, 10:19,2:9), "_10km"))
names(chelsa_10km) <- short_names
names(chelsa_10km) 
summary(chelsa_10km[[2]]) 

# reorder the layers
ordered_names <- c(paste0("bio",1:19,"_10km"))
chelsa_10km <- chelsa_10km[[ordered_names]]
names(chelsa_10km)
summary(chelsa_10km[[10]])



## 1.2 Check for collinearity between the variables

chelsa_corr_matrix <- pearson_correlation_matrix(chelsa_10km)
chelsa_corr_matrix
write.table(chelsa_corr_matrix, "./Data/Processed/Chelsa/chelsa_corr_matrix_10km.csv")



# - # - # - # - # - # - # - # - # - # - # - # - # 
#                                               #
#                                               #
#         2. CROP CHELSA TO THE WORLD           #
#                                               #
#                                               #
# - # - # - # - # - # - # - # - # - # - # - # - # 

world <- terra::vect("./Data/Original/world.shp")
chelsa_10km <- terra::rast(chelsa_10km)
world <- terra::rasterize(world, chelsa_10km[[1]])
crs(world) <- "EPSG:4326"

for(l in names(chelsa_10km)){
  
  chelsa_10km_l <- chelsa_10km[[l]] * world
  terra::writeRaster(chelsa_10km_l, paste0("./Data/Processed/Chelsa/Aggregated_10km_crop/",l,".tif"), overwrite = T)
  
}

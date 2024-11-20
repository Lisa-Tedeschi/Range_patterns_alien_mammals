############################################################
################# SDMs PROBABILITY SURFACE #################
############################################################

# Started on 08.03.2023
# modified on 03.04.2024
# for the paper "Patterns and drivers of range filling of alien mammals in Europe"

# this is a script to create a "biasfile" that accounts for different efforts in sampling
# to sample SDM Pseudo-absences using a target-group approach

# Setting up the R environment
rm(list = ls())
setwd("E:/PhD/2nd_Chapter/Sensitivity_analysis")
getwd()

pacman::p_load(tidyverse, raster, terra)



# - # - # - # - # - # - # - # - # - # - # 
#                                       #
#                                       #
#            1. LOAD THE DATA           #
#                                       #
#                                       #
# - # - # - # - # - # - # - # - # - # - # 



## 1. Create the biasfile
biasfile_pedruzzi <- terra::rast("./Data/Processed/biasfile.tif") # from Pedruzzi et al. 2022

chelsa_10km <- terra::rast(paste0("./Data/Processed/Chelsa/Aggregated_10km_crop/", list.files("./Data/Processed/Chelsa/Aggregated_10km_crop")))
names(chelsa_10km)
ordered_names <- c(paste0("bio",1:19,"_10km"))
chelsa_10km <- chelsa_10km[[ordered_names]]
names(chelsa_10km)

# as Pedruzzi et al. 2022 raster is in mollweide and the resolution is different, i will just create an empty raster with extent, res, and crs I need, and then reproject mine 
r <- rast(ext(chelsa_10km[[1]]), resolution = res(chelsa_10km[[1]]), crs = crs((chelsa_10km[[1]])))
r[,] <- 1

biasfile <- project(biasfile_pedruzzi, r)
plot(biasfile)



## 1.2 Add the "belts"

# the biasfile from meyer et al (and thus the one from Pedruzzi) is missing the northern and southern parts of the Poles (Arctic and Antarctic)
# but we have species occurring there, so we need those areas, even if with a low probability of sampling PAs
# mask CHELSA bioclimatic variables with the biasfile to obtain the belt

belt <- terra::mask(chelsa_10km[[1]],
                    biasfile,
                    inverse = T)

# it has the values from bio1, but I will need to have 0s
plot(belt)
summary(belt)

# replace all cells that are NOT NA with a 0
belt[which(!is.na(values(belt)))] <- 0

#plot(belt)
summary(belt)

plot(biasfile)
plot(belt, col = "red", add = T)

# now I can merge both
biasfile <- terra::merge(biasfile, belt)
plot(biasfile)
summary(biasfile)

writeRaster(biasfile, "./Data/Processed/biasfile_new.tif")




###############################################################
################# SAVE THE BINARY PROJECTIONS #################
###############################################################

# Started on 14.12.2023
# modified on 03.04.2024
# for the paper "Patterns and drivers of range filling of alien mammals in Europe"

# this is a script to load the ensemble models' projections and create a raster (.tif) 
# with climatically suitable cells as 1 and climatically unsuitable as 0 
# created within Biomod using TSS as a threshold
# and crop and reproject to Europe

# Setting up the R environment
rm(list = ls())
setwd("E:/PhD/2nd_Chapter/Sensitivity_analysis")
getwd()

pacman::p_load(tidyverse, terra)



# - # - # - # - # - # - # - # - # - # 
#                                   #
#                                   #
#          1. PREPARE DATA          #
#                                   #
#                                   #
# - # - # - # - # - # - # - # - # - # 

list_eu <- read.table("./Data/Processed/List_eu_neozoa.txt", sep = ";", fileEncoding = "UTF-8-BOM")
colnames(list_eu)[1] <- "Binomial"
list_eu <- subset(list_eu, !Binomial == "Capra_aegagrus")
list_eu <- subset(list_eu, !Binomial == "Desmana_moschata")
list_eu <- subset(list_eu, !Binomial == "Lama_glama")
list_eu <- subset(list_eu, !Binomial == "Ovis_orientalis")
row.names(list_eu) <- NULL
list_eu



## 1.1 Load EU WG84 
EU <- terra::vect("./Data/Original/EU_3035.shp")

# load chelsa variables
chelsa_10km <- rast(paste0("./Data/Processed/Chelsa/Aggregated_10km_crop/", list.files("./Data/Processed/Chelsa/Aggregated_10km_crop")))
ordered_names <- c(paste0("bio",1:19,"_10km"))
chelsa_10km <- chelsa_10km[[ordered_names]]
names(chelsa_10km)

# reproject EU.shp
EU_WGS84 <- terra::project(EU, "epsg:4326")

# Define a Bounding box:  xmin: -31.26575 ymin: 32.39748 xmax: 69.07032 ymax: 81.85737
xmin <- -31.26575 
ymin <- 32.39748 
xmax <- 69.07032 
ymax <- 81.85737

# Create an empty raster with EU extent, WGS84 crs, and chelsa resolution
r <- rast(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, 
          crs = "EPSG:4326", 
          resolution = res(chelsa_10km[[1]]))

# rasterize
EU_WGS84 <- terra::rasterize(EU_WGS84, r)



## 1.2 Load EU 3035
EU_3035 <- terra::rast("./Data/Original/EU_3035.tif")
EU_3035 # NB resolution is 30x30 km

xmin = ext(EU_3035)[1]
xmax = ext(EU_3035)[2]
ymin = ext(EU_3035)[3]
ymax = ext(EU_3035)[4]

# change resolution of EU_3035
r_eu <- rast(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, 
          crs = "EPSG:3035", 
          resolution = c(10000, 10000)) # NB resolution is in METRES
r_eu

EU_3035_resampled <- terra::resample(EU_3035, r_eu, method = "near") 
EU_3035_resampled



# - # - # - # - # - # - # - # - # - # - # - # - # - # - # - #
#                                                           #
#                                                           #
#          2. LOAD EU SHP AND MODEL BINARY OUTPUTS          #
#                                                           #
#                                                           #
# - # - # - # - # - # - # - # - # - # - # - # - # - # - # - #



## 2.1 Load binary outputs for each species, crop to EU, and save

# define looping variable
output <- "problayer"

bin_stack <- list() 
bin_stack_crop <- list()
bin_stack_eu <- list()

i = 1

for(sp in sub("_", "", list_eu$Binomial)){
    
    if(file.exists(paste0("../SDM/Server_outputs_", output ,"/", sub("_", "", sp), 
                          "/proj_CurrentEM/proj_CurrentEM_", sub("_", "", sp), "_ensemble_TSSbin.grd")) == T){
    
    # load the ensembled binary projections (only the weighted mean one, which is the 2nd layer)
    bin_stack[[i]] <- rast(paste0("../SDM/Server_outputs_", output ,"/", sub("_", "", sp), 
                                  "/proj_CurrentEM/proj_CurrentEM_", sub("_", "", sp), "_ensemble_TSSbin.grd"))[[2]]
    
    # reproject to 4326
    bin_stack[[i]] <- terra::project(bin_stack[[i]], "epsg:4326")
    
    # crop to EU
    bin_stack_crop[[i]] <- crop(bin_stack[[i]][[1]], EU_WGS84)
         
    # resample to EU
    bin_stack_crop[[i]] <- terra::resample(bin_stack_crop[[i]], EU_WGS84, method = "near") 
    
    # mask to EU
    bin_stack_crop[[i]] <- mask(bin_stack_crop[[i]], EU_WGS84)
    
    # rename
    names(bin_stack_crop)[[i]] <- sp
    
    # save as tif
    terra::writeRaster(bin_stack_crop[[i]], paste0("./SDM/SDM_problayer_binaries_WGS84_2023_12_14/", sp, ".tif"), overwrite = T)
    
    # reproject to EU
    bin_stack_eu[[i]] <- terra::project(bin_stack_crop[[i]], "epsg:3035", method = "near")
    # NB resolution is 6x6 km and NOT 10x10km! Need to resample 
    
    # resample to EU
    bin_stack_eu[[i]] <- terra::resample(bin_stack_eu[[i]], r_eu, method = "near") 
    
    # save it 
    terra::writeRaster(bin_stack_eu[[i]], paste0("./SDM/SDM_problayer_binaries_3035_2023_12_14/", sp, ".tif"), overwrite = T)
    
  }
  
  i = i + 1 
  
}


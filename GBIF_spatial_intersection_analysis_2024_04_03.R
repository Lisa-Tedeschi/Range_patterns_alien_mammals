#####################################################################
################### SPATIAL INTERSECTION ANALYSIS ###################
#####################################################################

# Started on 20.01.2023
# modified on 03.04.2024
# by LT (with improvements of AS)
# for the paper "Patterns and drivers of range filling of alien mammals in Europe"

# this is a script to remove the extreme 1% of GBIF points

# Setting up the R environment
rm(list=ls())
setwd("E:/PhD/2nd_Chapter/Sensitivity_analysis")
getwd()

pacman::p_load(tidyverse, spThin)



# - # - # - # - # - # - # - # - # - # - # - # - # - # 
#                                                   #
#                                                   #
#               1. IMPORT THE DISTANCES             #
#                                                   #
#                                                   #
# - # - # - # - # - # - # - # - # - # - # - # - # - # 

# from the spatial intersection analysis run in GRASS GIS
# I obtained each species' .csv with distances inside a subfolder



## 1.1. Load distances of points from ANY polygons 
# there is also information if the reference polygon is native (nothing in the column "areacat") or alien (there will be the common name of the species in the column "areacat") 

list_eu <- read.table("./Data/Processed/List_eu_neozoa.txt", sep = ";", fileEncoding = "UTF-8-BOM")
colnames(list_eu)[1] <- "Binomial"
list_eu <- subset(list_eu, !Binomial == "Capra_aegagrus")
list_eu <- subset(list_eu, !Binomial == "Desmana_moschata")
list_eu <- subset(list_eu, !Binomial == "Lama_glama")
list_eu <- subset(list_eu, !Binomial == "Ovis_orientalis")
row.names(list_eu) <- NULL
list_eu

filenames <- paste0(sub(" ", "_",list_eu$Binomial),".csv")
filefolders <- paste0("./Data/Processed/Distances/", str_sub(filenames,end = -5))

all_dist <- lapply(paste0(filefolders, "/", filenames), 
                             function(sp){read.csv(sp, h = T, sep = ",", fileEncoding = "UTF-8-BOM")}) 

summary(all_dist)
length(all_dist)
head(all_dist[[1]])
tail(all_dist[[1]])
names(all_dist) <- str_sub(filenames, end = -5)
summary(all_dist)



## 1.2. Clean the data
# update the values of each dataframe (column dist and darea) dividing for 1000, because those are still m and i want km

copy_all_dist <- all_dist # copy the list, just in case 

all_dist <- lapply(all_dist, function(df) mutate(df,dist = dist/1000, darea = darea/1000))
head(all_dist[[1]])

all_dist <- (bind_rows(all_dist, .id = "species_ne")) 
nrow(all_dist) # 258985 points for neozoa

# this (all_dist) is the final dataframe that has, for each GBIF point: 
# its distance from the nearest polygon border, either IUCN or DAMA (dist)
# if the point is inside a polygon, either IUCN or DAMA (darea == 0)

# to know how many points are inside the polygons and how many are outside
nrow(all_dist[all_dist$darea==0,]) # number of points inside any polygon: 229301 for neozoa
(nrow(all_dist[all_dist$darea==0,]) * 100) / nrow(all_dist) # 88.5% of points inside any of the polygons 



# - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # 
#                                                           #
#                                                           #
#               2. SELECT A DISTANCE THRESHOLD              #
#                                                           #
#                                                           #
# - # - # - # - # - # - # - # - # - # - # - # - # - # - # - #



## 2.1. Select a threshold to remove the points too far from the polygons

# now I can select a threshold and remove all rows with dist_IUCN & dist_DAMA > threshold ! darea_IUCN == 0 & darea_DAMA == 0, 
# first find the threshold below which 99% of the points are 

nrow(all_dist) 

range(all_dist$dist)
summary(all_dist$dist)

th <- quantile(all_dist$dist, probs = 0.99)

rows_above_th <- all_dist[(all_dist$dist > th),] 

nrow(rows_above_th) # 2590

# exclude the points above the distance threshold that are inside the range polygons
rows_above_th <- rows_above_th[!(rows_above_th$darea==0),] 

all_dist <- dplyr::setdiff(all_dist, rows_above_th)

nrow(all_dist) # 256395

# to see the % of points that are inside the ranges (either IUCN or DAMA)
(sum(all_dist$darea==0) * 100) / sum(nrow(all_dist)) # 89.4% 

write.csv(all_dist,"./Data/Processed/all_dist_neozoa.csv", row.names = F)



# - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # 
#                                                           #
#                                                           #
#                3. THIN AND EXPLORE THE DATA               #
#                                                           #
#                                                           #
# - # - # - # - # - # - # - # - # - # - # - # - # - # - # - #



## 3.1 Thin

all_dist <- read.csv("./Data/Processed/all_dist_neozoa.csv", sep = ",", h = T)
head(all_dist)

for(sp in unique(all_dist$species_ne)){
  
  # Save the updated occurrences (aggregated and without the extreme 1%)
  saveRDS(all_dist[all_dist$species_ne == sp,], paste0("./occ_data/", sp, ".RDS"))
  
  # subset 
  sp_data <- all_dist[all_dist$species_ne == sp,]
  
  spThin::thin(loc.data = sp_data,
               lat.col = "latY_round",
               long.col = "lonX_round",
               spec.col = "species_ne",
               thin.par = 50,       # dist in km that you want records to be separated
               reps = 5,            # how many files
               write.files = T,
               write.log.file = T,
               out.dir = paste0("./Data/Processed/occ_data/Thinned/Thinned_occ_50km/", sp, "/"),
               verbose = T)
  
  remove(sp_data)
  
}



## 3.2 Obtain the shapefiles of thinned occurrences

for(sp in list_eu$Binomial){
  
  df <- read.csv(paste0("./Data/Processed/occ_data/Thinned/Thinned_occ_50km/", sub(" ", "_", sp), "/thinned_data_thin1.csv"), sep = ",", h = T)
  
  spdf <- SpatialPointsDataFrame(coords = df[,c("lonX_round","latY_round")], # NB: FIRST lon and then lat!!!
                                 data = df,
                                 proj4string = CRS(as.character("+proj=longlat +datum=WGS84 +no_defs")))
  
  # save it as a .shp
  shapefile(spdf, paste0("./Data/Processed/occ_data/Thinned/Thinned_occ_50km_shapefiles/", sub(" ", "_", sp), ".shp"), overwrite = T)
  
}



## 3.3 Load the thinned data 
# then re-run the GRASS GIS script (with the thinned points instead of the aggregated ones) 
# to get updated info on how many thinned points are inside the polygons

filenames <- paste0(sub(" ", "_",list_eu$Binomial),".csv")
filefolders <- paste0("./Data/Processed/Distances/Distances_thinned_1981_2022_categories/", str_sub(filenames,end = -5))

all_dist <- lapply(paste0(filefolders, "/", filenames), 
                   function(sp){read.csv(sp, h = T, sep = ",", fileEncoding = "UTF-8-BOM")}) 

summary(all_dist)
length(all_dist)
head(all_dist[[1]])
tail(all_dist[[1]])
names(all_dist) <- str_sub(filenames, end = -5)
summary(all_dist)

copy_all_dist <- all_dist # copy the list, just in case 



## 3.4 Update distance in km

all_dist <- lapply(all_dist, function(df) mutate(df,dist = dist/1000, darea = darea/1000))
head(all_dist[[1]])

all_dist <- (bind_rows(all_dist, .id = "species_ne")) 
nrow(all_dist) # 26677

write.csv(all_dist[,c("species_ne", "lonX_round", "latY_round", "dist", "darea", "areacat")], 
          "./Data/Processed/all_dist_neozoa_final.csv", row.names = F)



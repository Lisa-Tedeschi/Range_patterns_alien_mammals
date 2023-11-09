##################################################################
#################### THINNING GBIF OCCURRENCES ###################
##################################################################

# Started on 23.01.2023
# by LT (with improvements of AS)

############## USEFUL MATERIAL ##############

### M: https://griffithdan.github.io/pages/outreach/SDM-Workshop-OSU-FALL2017.pdf
### M: https://data-blog.gbif.org/post/gbif-filtering-guide/
### M: https://data-blog.gbif.org/post/downloading-long-species-lists-on-gbif/

# check C:/SDM/Notes.R to interpret BIOMOD inputs

#############################################

# Setting up the R environment
rm(list=ls())
setwd("D:/PhD/2nd chapter - Range filling patterns")
getwd()
load("./GBIF.Rdata")

library(pacman)
pacman::p_load(gridExtra, scales, corrplot, sdmpredictors, usdm, terra, rgdal, rgbif, readr, sf, maps, maptools, biomod2, dismo, colorRamps, dplyr, CoordinateCleaner, ggplot2, rgeos, spThin, stringr, viridis, hrbrthemes, forcats, tidyverse, cowplot)



# - # - # - # - # - # - # - # - # - # - # 
#                                       #
#                                       #
#          1. THINNING THE DATA         #
#                                       #
#                                       #
# - # - # - # - # - # - # - # - # - # - # 


# from the server 
setwd("/home/lisa/R")

library(spThin)

all_dist <- read.csv("./all_dist.csv",sep=",",h=T)
head(all_dist)

for(sp in unique(all_dist$species_ne)){

  # Save the updated occurrences (wich )aggregated and without the extreme 1%)
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
               out.dir = paste0("./occ_data/Thinned_occ_50km/", sp, "/"),
               verbose = T)
  
  remove(sp_data)
  
}




# for Vulpes vulpes

setwd("/home/lisa/R")

library(spThin)

all_dist <- read.csv("../all_dist.csv",sep=",",h=T)
head(all_dist)
sp = "Vulpes_vulpes"
#dir.create(paste0(getwd(),"/Thinned_occ_50km/", sp, "/"))

#for(sp in unique(all_dist$species_ne)){
  #sp = "Vulpes_vulpes"
  # Save the updated occurrences (wich )aggregated and without the extreme 1%)
  saveRDS(all_dist[all_dist$species_ne == sp,], paste0(sp, ".RDS"))
  
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
               out.dir = paste0("./Thinned_occ_50km/", sp, "/"),
               verbose = T)
  
  remove(sp_data)
  
#}


# - # - # - # - # - # - # - # - # - # - # 
#                                       #
#                                       #
#          2. PLOT THINNED DATA         #
#                                       #
#                                       #
# - # - # - # - # - # - # - # - # - # - # 



## 1. Load native ranges

# list all IUCN files and delete the extension
IUCN_names <- str_sub(list.files(path = "./IUCN/EU_mammals_filtered", pattern = ".gpkg"), start = 10, end = -6)

# Note the nomenclature: Lama glama in Phylacine is Lama guanicoe in IUCN, Ovis gmelini (IUCN) is Ovis orientalis (Phylacine)
IUCN_names[IUCN_names=="Lama guanicoe"] <- "Lama glama"
IUCN_names[IUCN_names=="Ovis gmelini"] <- "Ovis orientalis"



## 2. Load alien ranges

# # list all DAMA files and delete the extension
DAMA_names <- str_sub(list.files(path = "./DAMA/DAMA_complete", pattern = ".shp"), end = -5)

#retain only species included in list_eu
DAMA_names <- DAMA_names[DAMA_names %in% list_eu$Binomial]



## 3. Load the thinned data for each species and plot them against the ranges 

# load the countries
countries <- rnaturalearthdata::countries50 %>%
  st_as_sf() %>%
  filter(admin != "Antarctica")

for(sp in list_eu$Binomial){
  
  # load native range
  IUCN_range <- st_read(paste0("./IUCN/EU_mammals_filtered/binomial_",sp,".gpkg")) %>%
    st_as_sf()
  
  # load alien range
  DAMA_range <- st_read(paste0("./DAMA/DAMA_complete/",sp,".shp")) %>%
    st_as_sf()
  
  # get the occurrences for species sp thinned at 10km
  # occ_sp_10km <- read.csv(paste0("./spThin/Thinned_occ_10km/",str_replace(sp, " ", "_"), "/thinned_data_thin1.csv"), h = T, sep = ",")
  
  # get the occurrences for species sp thinned at 50km
  occ_sp_50km <- read.csv(paste0("./spThin/Thinned_occ_50km/", sub(" ", "_", sp), "/thinned_data_thin1.csv"), h = T, sep = ",")
  
  # transform occurrences to sf
  # occ_sf_10km <- occ_sp_10km %>%
  #   st_as_sf(.,
  #            coords = c("lonX_round", "latY_round"),
  #            crs = 4326)
  
  occ_sf_50km <- occ_sp_50km %>%
    st_as_sf(.,
             coords = c("lonX_round", "latY_round"),
             crs = 4326)
  
  # plot 10km
  # occ_plot <- ggplot() +
  #   
  #   # countries of the world
  #   geom_sf(data = countries, fill = "grey90", col = "grey70")  +
  #   
  #   #IUCN native range
  #   geom_sf(data = IUCN_range, col = "#74D055FF", fill = "#74D055FF", alpha = 0.3, show.legend = F) +
  #   
  #   # DAMA alien range
  #   geom_sf(data = DAMA_range, col = "#481568FF", fill = "#481568FF", alpha = 0.3, show.legend = F) +
  #   
  #   # add the occurrences
  #   geom_sf(data = occ_sf_10km,
  #           alpha = 0.3,    
  #           pch = 16) +
  #   
  #   # add a colour gradient to your points
  #   scale_colour_gradientn(colours = viridis::magma(10),
  #                          breaks = seq(0, 50000, by = 5000),
  #                          limits = c(0, 50000),
  #                          labels = as.character(seq(0, 50000, by = 5000)),
  #                          na.value = "grey50") +
  #   
  #   # add the bounding box based on your occurrences.
  #   coord_sf(xlim = st_bbox(occ_sf_10km)[c(1,3)], # min & max of x values
  #            ylim = st_bbox(occ_sf_10km)[c(2,4)]) + # min & max of y values
  #   #lims_method = "geometry_bbox") + 
  #   
  #   labs(title = paste(sp, "thin 10km n =", nrow(occ_sf_10km))) + theme_void()
  # 
  # ggsave(paste0("./maps/range_occ_thin_maps/thin_10km/", sp, ".jpg"),
  #        dpi = 250, width = 10, height = 8)
  # 
  # remove(occ_plot)
  
  # plot 50km
  occ_plot <- ggplot() +
    
    # countries of the world
    geom_sf(data = countries, fill = "grey90", col = "grey70")  +
    
    #IUCN native range
    geom_sf(data = IUCN_range, col = "#74D055FF", fill = "#74D055FF", alpha = 0.3, show.legend = F) +
    
    # DAMA alien range
    geom_sf(data = DAMA_range, col = "#481568FF", fill = "#481568FF", alpha = 0.3, show.legend = F) +
    
    # add the occurrences
    geom_sf(data = occ_sf_50km,
            alpha = 0.3,    
            pch = 16) +
    
    # add a colour gradient to your points
    scale_colour_gradientn(colours = viridis::magma(10),
                           breaks = seq(0, 50000, by = 5000),
                           limits = c(0, 50000),
                           labels = as.character(seq(0, 50000, by = 5000)),
                           na.value = "grey50") +
    
    # add the bounding box based on your occurrences.
    coord_sf(xlim = st_bbox(occ_sf_50km)[c(1,3)], # min & max of x values
             ylim = st_bbox(occ_sf_50km)[c(2,4)]) + # min & max of y values
    #lims_method = "geometry_bbox") + 
    
    labs(title = paste(sp, "thin 50km n =", nrow(occ_sf_50km))) + theme_void()
  
  ggsave(paste0("./maps/range_occ_thin_maps/thin_50km/", sp, ".jpg"),
         dpi = 250, width = 12, height = 10)
    
    
  }

















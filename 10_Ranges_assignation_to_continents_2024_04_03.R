##############################################################################
################# ASSIGN A CONTINENT REGION TO EACH SPECIES ##################
##############################################################################

# Started on 07.03.2023
# modified on 03.04.2024
# for the paper "Patterns and drivers of range filling of alien mammals in Europe"

# this is a script to assign a continent region to each species
# based on where its native/alien range polygons occur
# and crop CHELSA bioclimatic variables based on that 

# Setting up the R environment
rm(list = ls())
setwd("E:/PhD/2nd_Chapter/Sensitivity_analysis")
getwd()

pacman::p_load(tidyverse, stringr, sf, rnaturalearthdata, terra)



# - # - # - # - # - # - # - # - # - # - # 
#                                       #
#                                       #
#            1. LOAD THE DATA           #
#                                       #
#                                       #
# - # - # - # - # - # - # - # - # - # - # 

list_eu <- read.table("./Data/Processed/List_eu_neozoa.txt", sep = ";", fileEncoding = "UTF-8-BOM")
colnames(list_eu)[1] <- "Binomial"
list_eu <- subset(list_eu, !Binomial == "Capra_aegagrus")
list_eu <- subset(list_eu, !Binomial == "Desmana_moschata")
list_eu <- subset(list_eu, !Binomial == "Lama_glama")
list_eu <- subset(list_eu, !Binomial == "Ovis_orientalis")
row.names(list_eu) <- NULL
list_eu



## 1.1 Native ranges

# list all IUCN files and delete the extension
IUCN_names <- str_sub(list.files(path = "./Data/Processed/IUCN/EU_mammals_filtered", pattern = ".gpkg"), start = 10, end = -6)

# Note the nomenclature: Lama glama in Phylacine is Lama guanicoe in IUCN, Ovis gmelini (IUCN) is Ovis orientalis (Phylacine)
IUCN_names[IUCN_names=="Lama guanicoe"] <- "Lama glama"
IUCN_names[IUCN_names=="Ovis gmelini"] <- "Ovis orientalis"

# check if in IUCN_names there are all the species of list_eu and of gbif_occ_clean$species_new (the new names)
all(list_eu[1:nrow(list_eu),] %in% sub(" ", "_", IUCN_names)) # it returns TRUE so every species is there



## 1.2 Alien ranges

# list all DAMA files and delete the extension
DAMA_names <- str_sub(list.files(path = "./Data/Processed/DAMA/", pattern = ".shp"), end = -5)

# check if in DAMA_names there are all the species of list_eu and of gbif_occ_clean$species_new (the new names)
all(list_eu[1:nrow(list_eu),] %in% sub(" ", "_", DAMA_names)) # it returns TRUE so every species is there



## 1.3 Countries and continents

# Switch off spherical geometry, because although coordinates are longitude/latitude, st_intersection assumes that they are planar
sf_use_s2(FALSE)

# Load countries
countries <- countries50 %>%
  st_as_sf() 

# Subset continents 
continents <- list()

i = 1

for(c in unique(countries$continent)){
  
  cont <- countries[countries$continent == c,]
  continents[[i]] <- cont
  names(continents)[[i]] <- sub(" ", "_", c)
  
  i = i + 1
  
}

names(continents)[[7]] <- "Seven_seas"

# Save both vector and raster files
for(n in names(continents)){
  
  st_write(continents[[n]], paste0("./Data/Processed/Continents/Shp/", n, ".gpkg"))
  
  cont <- terra::rasterize(continents[[n]], chelsa_10km[[1]])
  crs(cont) <- "EPSG:4326"
  
  writeRaster(cont, paste0("./Data/Processed/Continents/Raster/", n, ".tif"))

}



# - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # 
#                                                                   #
#                                                                   #
#            2. ASSIGN A CONTINENT TO EACH RANGE POLYGON            #
#                                                                   #
#                                                                   #
# - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # 



## 2.1 Create two empty dataframes where to store the information

IUCN_poly <- data.frame("Species" = list_eu$Binomial,
                   "North_America" = 0,
                   "Asia" = 0,
                   "Africa" = 0,
                   "Europe" = 0,
                   "South_America" = 0,
                   "Oceania" = 0,
                   "Antarctica" = 0,
                   "Seven_seas" = 0)

DAMA_poly <- data.frame("Species" = list_eu$Binomial,
                        "North_America" = 0,
                        "Asia" = 0,
                        "Africa" = 0,
                        "Europe" = 0,
                        "South_America" = 0,
                        "Oceania" = 0,
                        "Antarctica" = 0,
                        "Seven_seas" = 0)

## NB Continents should be in the same order
summary(continents)
continents <- continents[c("North_America",
                    "Asia",
                    "Africa",
                    "Europe",
                    "South_America",
                    "Oceania", 
                    "Antarctica", 
                    "Seven_seas")]
summary(continents)



## 2.2 Loop 

for(sp in list_eu$Binomial){
      
      # load native range
      IUCN_range <- st_read(paste0("./Data/Processed/IUCN/EU_mammals_filtered/binomial_", sub("_", " ", sp),".gpkg")) %>%
        st_as_sf()
      
      # load alien range
      DAMA_range <- st_read(paste0("./Data/Processed/DAMA/", sub("_", " ", sp),".shp")) %>%
        st_as_sf()
      
      for(i in 1:length(continents)){
        
        # Subset native polygons inside i-th continent
        iucn <- st_intersection(IUCN_range, continents[[i]])
        
        # If there is a match, assign a 1 in the corresponding column 
        if(nrow(iucn) > 0){
          
          IUCN_poly[IUCN_poly$Species == sp, i + 1] <- 1
          
          }
        
        # Subset alien polygons inside i-th continent
        dama <- st_intersection(DAMA_range, continents[[i]])
        
        # If there is a match, assign a 1 in the corresponding column 
        if(nrow(dama) > 0){
          
          DAMA_poly[DAMA_poly$Species == sp, i + 1] <- 1
          
        }
        
      }
}

# check if every species has a 1 under Europe in DAMA_poly

# Collate the names 
IUCN_poly$Species <- sub(" ", "", IUCN_poly$Species)
DAMA_poly$Species <- sub(" ", "", DAMA_poly$Species)

# Save csv
write.csv(IUCN_poly,"./Data/Processed/IUCN_ranges_in_continents.csv", row.names = F)
write.csv(DAMA_poly,"./Data/Processed/DAMA_ranges_in_continents.csv", row.names = F)



# - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # 
#                                                                   #
#                                                                   #
#            3. CROP CHELSA VARIABLES BASED ON CONTINENTS           #
#                                                                   #
#                                                                   #
# - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # 

chelsa_10km <- terra::rast(paste0("./Data/Processed/Chelsa/Aggregated_10km_crop/", list.files("./Data/Processed/Chelsa/Aggregated_10km_crop")))
names(chelsa_10km)
ordered_names <- c(paste0("bio",1:19,"_10km"))
chelsa_10km <- chelsa_10km[[ordered_names]]
names(chelsa_10km)

for(i in 1:length(continents)){
  
  # Rasterize the vector of the i-th continent
  cont <- terra::rasterize(continents[[i]], chelsa_10km[[1]])
  crs(cont) <- "EPSG:4326"
  
  # Create suitable directory where to save the cropped raster for the i-th continent
  dir.create(paste0("./Data/Processed/Chelsa/Aggregated_10km_continent/",names(continents)[[i]]))
  
  for(l in names(chelsa_10km)){
    
    # Retain only chelsa values inside the i-th continent
    chelsa_10km_l <- chelsa_10km[[l]] * cont
    
    # Save the new raster 
    terra::writeRaster(chelsa_10km_l, paste0("./Data/Processed/Chelsa/Aggregated_10km_continent/",names(continents)[[i]], "/", l,".tif"), overwrite = T)
    
  }
  
}




















#######################################################################
#################### OBSERVED ALIEN RANGES - NEOZOA ###################
#######################################################################

# Started on 05.04.2023
# modified on 04.04.2024
# for the paper "Patterns and drivers of range filling of alien mammals in Europe"

# Setting up the R environment
rm(list = ls())
setwd("E:/PhD/2nd_Chapter/Sensitivity_analysis")
getwd()



# - # - # - # - # - # - # - # - # - # - # - # - # - # 
#                                                   #
#                                                   #
#          1. DELETE DAMA POLYGONS < 1492           #
#                                                   #
#                                                   #
# - # - # - # - # - # - # - # - # - # - # - # - # - #

list_eu <- read.table("./Data/Processed/List_eu_neozoa.txt", sep = ";", fileEncoding = "UTF-8-BOM")
colnames(list_eu)[1] <- "Binomial"
list_eu <- subset(list_eu, !Binomial == "Capra_aegagrus")
list_eu <- subset(list_eu, !Binomial == "Desmana_moschata")
list_eu <- subset(list_eu, !Binomial == "Lama_glama")
list_eu <- subset(list_eu, !Binomial == "Ovis_orientalis")
row.names(list_eu) <- NULL
list_eu

dama_ranges <- list()

i = 1

for(sp in list_eu$Binomial){
  
  # load sp alien range
  sp_shp <- terra::vect(paste0("./Data/Processed/DAMA/", sub("_", " ", sp), ".shp"))
  
  # update names
  names(sp_shp) <- c("ID", "Taxa", "Family", "Binomial", "CommonName", "Landmass", "Date", "Pathway", "Method", "Inv_Stage", "A_Realms", "N_Realms", "References", "Notes", "AREA", "layer", "path")
  
  # store the shp in the list
  dama_ranges[[i]] <- sp_shp
  
  # filter by year and NA
  dama_ranges[[i]] <- dama_ranges[[i]][!is.na(dama_ranges[[i]]$Date),]
  dama_ranges[[i]] <- dama_ranges[[i]][!(dama_ranges[[i]]$Date <= 1492),]
  
  # assign name
  names(dama_ranges)[i] <- sp
  
  # save file
  writeVector(dama_ranges[[i]], filename = paste0("./Data/Processed/DAMA_EU_neozoa/", sub(" ", "_", sp), ".gpkg"), overwrite = T)
  
  i = i +1 
  
}

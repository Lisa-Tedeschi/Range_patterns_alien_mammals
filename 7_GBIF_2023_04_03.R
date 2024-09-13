#############################################
#################### GBIF ###################
#############################################

# Started on 11.11.2022
# modified on 03.04.2024
# by LT (with improvements of AS)
# for the paper "Patterns and drivers of range filling of alien mammals in Europe"

# this is a script to download, clean, filter, explore GBIF data
# and save them grouped by different decades  

# Setting up the R environment
rm(list=ls())
setwd("E:/PhD/2nd_Chapter/Sensitivity_analysis")
getwd()

pacman::p_load(tidyverse, terra, raster, rgbif, CoordinateCleaner)



# - # - # - # - # - # - # - # - # - # - # 
#                                       #
#                                       #
#     1. ASSEMBLE AND ORGANIZE DATA     #
#                                       #
#                                       #
# - # - # - # - # - # - # - # - # - # - # 



## 1.1 Load the list of species
list_eu <- read.csv("./Data/Processed/List_eu.csv", sep = ";", h = T, fileEncoding = "UTF-8-BOM")



## 1.2 Download data from GBIF

###### get the data - in you already have downloaded the data, skip this ######

# Get taxa keys to speed up the search 
gbif_taxon_keys <- (unique(name_backbone_checklist(list_eu)$usageKey))

# The important part here is to use rgbif::occ_download with pred_in and to fill in my gbif credentials
#user <- ""
#email <- ""
#pwd <- ""

# Put the download into the GBIF query
# !!very important here to use pred_in!!
#gbif_download_key <- occ_download(
 # pred_in("taxonKey", gbif_taxon_keys),
  #pred("hasCoordinate", TRUE),
  #pred("hasGeospatialIssue", FALSE),
  #format = "SIMPLE_CSV",
  #user = user, pwd = pwd, email = email
#)

# check the status of the query (running/succeded) 
# gbif_download_metadata <- occ_download_wait(gbif_download_key) 

# returns info on the download and also the DOI and how to cite it
# gbif_download_key 

######

# After it finishes, download your occurrences from GBIF into your PC (with occ_download_get)
# and load them into R (with occ_download_import)

gbif_occurrences <- occ_download_get('0195686-220831081235567') %>% # if the query has been running in this R session, it can be used gbif_download_key instead of the key itself
  occ_download_import() # this loads the data into R

# remove redundant/unnecessary columns
colnames(gbif_occurrences)
object.size(gbif_occurrences)

gbif_occurrences <- gbif_occurrences %>% 
  dplyr::select(gbifID, taxonKey, speciesKey, datasetKey, 
         species,scientificName, verbatimScientificName,
         occurrenceStatus,basisOfRecord, year, 
         decimalLatitude, decimalLongitude, coordinateUncertaintyInMeters, coordinatePrecision )

object.size(gbif_occurrences) 

##########



# - # - # - # - # - # - # - # - # 
#                               #
#                               #
#      2. DATA EXPLORATION      #
#                               #
#                               #
# - # - # - # - # - # - # - # - # 



# 2.1 Explore the df

all(unique(gbif_occurrences$species) %in% list_eu[1:nrow(list_eu),]) # check if there are all the species

# if it returns FALSE, there are species in list_eu not present in gbif_occurrences
# it may be due to an inconsistency of taxonomy
# check which species they are

list_eu$Binomial[!list_eu$Binomial %in% unique(gbif_occurrences$species)] 

# I need to replace the names in the "species" column with the ones I need, using the taxonKey as an identifyier 
# because both C. canadensis and C. elaphus have C. elaphus under "species", so the only way to distinguish them is with the key 

# so I pair the names with the key
keys <- c("Capra aegagrus"  = 4409366,
          "Cervus canadensis" = 8600904,
          "Eutamias sibiricus" = 10602587,
          "Herpestes auropunctatus" = 2434282,
          "Neovison vison" = 2433652,
          "Ovis orientalis" = 2441112) 

# create a new column where I will store the new name
gbif_occurrences$species_new <- gbif_occurrences$species

# and put the new name in the new column based on the matching key 
for(k in 1:length(keys)){
  gbif_occurrences[gbif_occurrences$taxonKey == keys[k],]$species_new <- names(keys)[k]
}

length(which(gbif_occurrences$species != gbif_occurrences$species_new)) # changed 85,943 names 
length(unique(gbif_occurrences$species_new)) # check if they are still 71 species
all(unique(gbif_occurrences$species_new) %in% list_eu[1:nrow(list_eu),])



# - # - # - # - # - # - # - # - # - # - # - #
#                                           #
#                                           #
#       3. DATA CLEANING AND PLOTTING       #
#                                           #
#                                           #
# - # - # - # - # - # - # - # - # - # - # - #



## 3.1 Create a clean dataset for each timespan 

years <- c("1950_2022","1981_2010","1981_2017","1981_2022")
dataset_names <- character(0)
i = 1

for(y in years){

  a <- paste0("gbif_occ_clean_", y)

  dataset_names <- append(dataset_names, a)

  b <- gbif_occurrences %>%
    # all the colnames lowercase
    setNames(tolower(names(.))) %>%
    # remove the duplicates
    distinct(decimallongitude,decimallatitude,specieskey,datasetkey, .keep_all = TRUE) %>%
    # only present occurrences
    filter(occurrencestatus  == "PRESENT") %>%
    # no fossils or living specimens:
    filter(basisofrecord != "FOSSIL_SPECIMEN") %>%
    filter(basisofrecord != "LIVING_SPECIMEN") %>%
    filter(year >= as.integer(str_sub(y, end = - 6)) | is.na(year)) %>%
    filter(year <= as.integer(str_sub(y, start = 6))) %>%
    filter(coordinateprecision < 0.01| is.na(coordinateprecision)) %>%
    # remove points with a coordinate uncertainty > 10km
    filter(coordinateuncertaintyinmeters < 10000) %>%
    filter(!coordinateuncertaintyinmeters %in% 9999) %>%
    filter(!decimallatitude == 0 | !decimallongitude == 0) %>%
    # remove country centroids within 2km
    cc_cen(lon = "decimallongitude",
           lat = "decimallatitude",
           buffer = 2000) %>%
    # remove capitals centroids within 2km
    cc_cap(lon = "decimallongitude",
           lat = "decimallatitude",
           buffer = 2000) %>%
    # remove zoo and herbaria within 2km
    cc_inst(lon = "decimallongitude",
            lat = "decimallatitude",
            buffer = 2000) %>%
    # remove from ocean
    cc_sea(lon = "decimallongitude",
           lat = "decimallatitude")

  print(nrow(b))

  # save clean data
  write.csv(b, paste0("./Data/Processed/occ_data/gbif_occ_clean_", y,".csv"))

  # assign correct name to the cleaned data set
  assign(dataset_names[i], b)
  remove(b)

  i = i + 1

}

# this loop creates those 4 dataframes:
# gbif_occ_clean_1950_2022
# gbif_occ_clean_1981_2010
# gbif_occ_clean_1981_2017
# gbif_occ_clean_1981_2022

# remove raw data
remove(gbif_occurrences)



## 3.2 Save each species' occurrences in a dataset and plot it

# load the countries
countries <- rnaturalearthdata::countries50 %>%
  st_as_sf() %>%
  filter(admin != "Antarctica")

# create a dataset for each species, save it, and save the plot
# first store all the datasets in a list
gbif_occ_clean_list <- list(gbif_occ_clean_1950_2022,
                            gbif_occ_clean_1981_2010,
                            gbif_occ_clean_1981_2017,
                            gbif_occ_clean_1981_2022)
# this is a list with 4 dataframes, each one of them refers to a different timespan of occurrences 

years <- c("1950_2022","1981_2010","1981_2017","1981_2022")

# NB for this loop, pay attention to indexing correctly years and gbif_occ_clean_list with the [i]
for(i in 1:length(years)){
  
  lapply(gbif_occ_clean_list[i], function(df){

    for(x in unique(df$species_new)){

        # get all records of your species x
        dat_clean <- df %>%
          filter(species_new == x)

        # save the data
        saveRDS(dat_clean, paste0("./Data/Processed/occ_data/Original/occ_data_clean_", years[i], "/", x, ".RDS"))
    
    }
    }
  )
}



# - # - # - # - # - # - # - # - # - # - # - #
#                                           #
#                                           #
#             4. DATA AGGREGATION           #
#                                           #
#                                           #
# - # - # - # - # - # - # - # - # - # - # - #



## 4.1 Load CHELSA aggregated bioclimatic variables

chelsa_10km <- terra::rast(paste0("./Data/Processed/Chelsa/Aggregated_10km/", list.files("./Data/Processed/Chelsa/Aggregated_10km")))
names(chelsa_10km) <- c("bio1",paste0("bio",10:19),paste0("bio",2:9))
ordered_names <- c(paste0("bio",1:19))
chelsa_10km <- chelsa_10km[[ordered_names]]
summary(chelsa_10km)



## 4.2 Aggregate GBIF cleaned data to the desired resolution (10 x 10 km, which is 0.1°)

# gbif_occ_clean_list contains 4 dataframes that refer to the different time spans:
# gbif_occ_clean_1950_2022
# gbif_occ_clean_1981_2010
# gbif_occ_clean_1981_2017
# gbif_occ_clean_1981_2022

# set the desired extent and resolution
myExpl <- chelsa_10km[[1]]
summary(myExpl)
resolution <- res(myExpl)[1]
ex <- ext(myExpl)

gbif_occ_clean_aggregated <- lapply(gbif_occ_clean_list, function(df) {
  
  # for each dataframe (gbif_occ_clean_1950_2022, gbif_occ_clean_1981_2010, etc) in the list gbif_occ_clean_list
  # do:
  
  # center the point coordinates in the center of the cell
  df$lonX_round <- round((df$decimallongitude - ex[1])/resolution) * resolution + resolution / 2 + ex[1]
  df$latY_round <- round((df$decimallatitude - ex[3])/resolution) * resolution + resolution / 2 + ex[3]
  
  # create a column of 1 (as those are all presences)
  df$occ <- 1
  
  # reorder the df by species' name 
  df <- df[order(df$species_new),]
  
  # create an empty list where to store the result 
  aggr_list <- list()
  i = 1 
  
  # for each species present in each dataframe 
  for(sp in unique(df$species_new)){
    
    # save species' names
    sp_names <- unique(df$species_new)
    
    # create dataframe for each species 
    df_sp <- df[df$species_new==sp,] 
    
    # aggregate species points to the centre of the cell  
    df_sp_aggregated <- aggregate(df_sp$occ,
                                  by = list(lonX_round = df_sp$lonX_round, latY_round = df_sp$latY_round),
                                  FUN = sum)
    
    # create a new column with species name 
    df_sp_aggregated$species_new <- rep(sp, nrow(df_sp_aggregated))
    
    # store the result in the list
    aggr_list[[i]] <- df_sp_aggregated
    
    # rename the df in the list according to the species name
    names(aggr_list)[[i]] <- sp_names[i]
    
    i = i + 1
    
  }
  
  return(aggr_list)
  
})

# I obtain a list with 4 lists, each of them refers to a timespan and contains a dataframe for each species with the rounded coordinates and the species' name
names(gbif_occ_clean_aggregated) <- c("gbif_occ_clean_1950_2022", "gbif_occ_clean_1981_2010", 
                                      "gbif_occ_clean_1981_2017", "gbif_occ_clean_1981_2022")

sort(sapply(gbif_occ_clean_aggregated[[1]], function (df) nrow(df)))
sort(sapply(gbif_occ_clean_aggregated[[2]], function (df) nrow(df)))
sort(sapply(gbif_occ_clean_aggregated[[3]], function (df) nrow(df)))
sort(sapply(gbif_occ_clean_aggregated[[4]], function (df) nrow(df)))




# - # - # - # - # - # - # - # - # - # - # - # 
#                                           #
#                                           #
#       5. SAVE SPECIES' OCCURRENCES        #
#                                           #
#                                           #
# - # - # - # - # - # - # - # - # - # - # - # 



## 5.1 Save each aggregated species' occurrences in a dataset

# create a dataset for each species, save it, and save the plot
# first store all the datasets in a list
# in gbif_occ_clean_aggregated I have
# gbif_occ_clean_1950_2022,
# gbif_occ_clean_1981_2010,
# gbif_occ_clean_1981_2017,
# gbif_occ_clean_1981_2022

years <- c("1950_2022","1981_2010","1981_2017","1981_2022")

for(i in 1:length(years)){
  
  lapply(gbif_occ_clean_aggregated[[i]], function(df){
    
    # save the data
    saveRDS(df, paste0("./Data/Processed/occ_data/Aggregated/occ_data_clean_aggregated_", y, "/", unique(df$species_new), ".RDS"))

    }
  )
}



## 5.2 Save each aggregated species' occurrences in a .gpkg

for(sp in list_eu$Binomial){
  
  a <- readRDS(paste0("./Data/Processed/occ_data/Original/occ_data_clean_1981_2022/", sp, ".RDS"))
  a <- vect(as.data.frame(a), geom = c("decimallongitude", "decimallatitude"), crs = "epsg:4326")
  writeVector(a, paste0("./Data/Processed/occ_data/Original_shp/", sub(" ", "_", sp), ".gpkg"))
  
  b <- readRDS(paste0("./Data/Processed/occ_data/Aggregated/occ_data_clean_aggregated_1981_2022/", sp, ".RDS"))
  b <- vect(as.data.frame(b), geom = c("lonX_round", "latY_round"), crs = "epsg:4326")
  writeVector(b, paste0("./Data/Processed/occ_data/Aggregated_shp/", sub(" ", "_", sp), ".gpkg"))
  
}


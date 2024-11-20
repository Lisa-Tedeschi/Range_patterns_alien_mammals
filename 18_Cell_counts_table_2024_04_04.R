###############################################################
######################## CELL COUNTS ##########################
###############################################################

# started on 20.07.2022 
# modified on 06.04.2023, 24.11.2023, 14.12.2023, and 04.04.2024
# for the paper "Patterns and drivers of range filling of alien mammals in Europe"

# this is a script to take the .csv output of r.stats of range filling, unfilling, and overfilling rasters from GRASS for each species 
# calculate range filling ratios
# and merge it in one table

# Setting up the R environment
rm(list = ls())
setwd("E:/PhD/2nd_Chapter/Sensitivity_analysis")
getwd()

library(tidyverse)



# - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # 
#                                                                                   #
#                                                                                   #
#      1. CREATE A TABLE WITH THE NUMBER OF CELLS FOR EACH FILLING PATTERN          #
#                                                                                   #
#                                                                                   #
# - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # - #

list_eu <- read.table("./Data/Processed/List_eu_neozoa.txt", sep = ";", h = F, fileEncoding = "UTF-8-BOM")
colnames(list_eu)[1] <- "Binomial"

# delete species 
list_eu <- subset(list_eu, !Binomial == "Capra_aegagrus")
list_eu <- subset(list_eu, !Binomial == "Desmana_moschata")
list_eu <- subset(list_eu, !Binomial == "Lama_glama")
list_eu <- subset(list_eu, !Binomial == "Ovis_orientalis")
row.names(list_eu) <- NULL
list_eu



# 4 different combinations:
# median dispersal distance and generation length ("Disp_gen")
# median dispersal distance and age at first reproduction ("Disp_age")
# maximum dispersal distance and generation length ("MaxDisp_gen")
# maximum  dispersal distance and age at first reproduction ("MaxDisp_age")

scenarios <- c("Disp_gen", "Disp_age", "MaxDisp_gen", "MaxDisp_age")
filling_pattern <- c("Range_filling","Range_unfilling","Range_overfilling")

# loop through the scenarios
for(scen in scenarios){
  
# loop through the filling patterns
for(fil in filling_pattern){
  
# load all the .csv
filenames <- list.files(paste0("./Outputs/Filling_patterns/", scen, "/", fil), full.names = F, pattern = ".csv")  
filenames

# NB this doesn't work if a .csv is empty
all_data <- lapply(filenames, function(i){
  
  read.csv((paste0("./Outputs/Filling_patterns/", scen, "/", fil, "/", i)), h = F, sep = ",")

  }) 

all_data

# rename data frames and column names
names(all_data) <- str_sub(filenames, end = -9)
all_data
colnames <- c("cell_type","V2","n_cells")
all_data <- lapply(all_data, setNames, colnames)
all_data

# remove second column
all_data <- lapply(all_data, function(sp){ 
  
  sp["V2"] <- NULL;
  
  sp
  
  })

all_data

# create an empty dataframe with the list of species and the columns of interest
mydf_1 <- list_eu %>% 
  mutate(cell_type = "0",
         n_cells = 0) %>% 
  dplyr::select(cell_type, n_cells, Binomial)

# add a column called Binomial with the species name to each df in all_data
all_data <- Map(cbind, all_data, Binomial = names(all_data))

# create the final table 
cell_counts <- all_data %>% 
  bind_rows() %>% 
  bind_rows(mydf_1) %>% 
  pivot_wider(names_from = cell_type, values_from = n_cells, values_fill = 0) %>% 
  dplyr::select(-`0`)

# delete species 
cell_counts <- subset(cell_counts, !Binomial == "Capra_aegagrus")
cell_counts <- subset(cell_counts, !Binomial == "Desmana_moschata")
cell_counts <- subset(cell_counts, !Binomial == "Lama_glama")
cell_counts <- subset(cell_counts, !Binomial == "Ovis_orientalis")
row.names(cell_counts) <- NULL
#cell_counts

write.csv(cell_counts, paste0("./Outputs/Filling_patterns/", scen, "/", fil, "_", scen, "_cell_counts.csv"), row.names = F) 

}
}




# - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # 
#                                                                                   #
#                                                                                   #
#       2. CREATE A TABLE WITH THE NUMBER OF CELLS FOR OAR, PAR, AND POAR           #
#                                                                                   #
#                                                                                   #
# - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # - #

scenarios <- c("Disp_gen", "Disp_age", "MaxDisp_gen", "MaxDisp_age")
range <- c("OAR","PAR","POAR")

for(scen in scenarios){
  
for(r in range){
  
  # load all the .csv
  
  if(r == "PAR"){
    
    filenames <- list.files(paste0("./Outputs/Filling_patterns/", scen, "/", r, "_3035/PAR_suit"), full.names = F, pattern = ".csv")  
    
  }else if(r == "OAR"){
    
    filenames <- list.files(paste0("./Outputs/", r, "_3035/OAR_3035"), full.names = F, pattern = ".csv")  
    
  }else{
    
    filenames <- list.files(paste0("./Outputs/Filling_patterns/", scen, "/", r, "_3035"), full.names = F, pattern = ".csv")  
    
  }
  
  #filenames
  
  # NB this doesn't work if a .csv is empty
  all_data <- lapply(filenames, function(i){
    
    if(r == "PAR"){
      
      read.csv((paste0("./Outputs/Filling_patterns/", scen, "/", r, "_3035/PAR_suit/", i)), h = F, sep = ",")
      
    }else if(r == "OAR"){
    
      read.csv((paste0("./Outputs/", r, "_3035/OAR_3035", i)), h = F, sep = ",")
    
    }else{
      
      read.csv((paste0("./Outputs/Filling_patterns/", scen, "/", r, "_3035/", i)), h = F, sep = ",")
      
    }
  }) 
  
  all_data
  
  # rename data frames and column names
  if(r == "POAR"){
    
    names(all_data) <- str_sub(filenames, end = -10)
    
  }else if(r == "OAR"){
    
    names(all_data) <- str_sub(filenames, end = -9)
    
  }else if(r == "PAR"){
    
    names(all_data) <- str_sub(filenames, end = -14)
    
  }
  
  all_data
  colnames <- c("cell_type","V2","n_cells")
  all_data <- lapply(all_data, setNames, colnames)
  all_data
  
  # remove second column
  all_data <- lapply(all_data, function(sp){ 
    
    sp["V2"] <- NULL;
    
    sp
    
  })
  
  all_data
  
  # add a column called Binomial with the species name to each df in all_data
  all_data <- Map(cbind, all_data, Binomial = names(all_data))
  
  # create an empty dataframe with the list of species and the columns of interest
  mydf_1 <- list_eu %>% 
    mutate(cell_type = "0",
           n_cells = 0) %>% 
    dplyr::select(cell_type, n_cells, Binomial)
  
  # create the final table 
  cell_counts <- all_data %>% 
    bind_rows() %>% 
    bind_rows(mydf_1) %>% 
    pivot_wider(names_from = cell_type, values_from = n_cells, values_fill = 0) %>% 
    dplyr::select(-`0`)
  
  #View(cell_counts)
  
  # delete species 
  cell_counts <- subset(cell_counts, !Binomial == "Capra_aegagrus")
  cell_counts <- subset(cell_counts, !Binomial == "Desmana_moschata")
  cell_counts <- subset(cell_counts, !Binomial == "Lama_glama")
  cell_counts <- subset(cell_counts, !Binomial == "Ovis_orientalis")
  row.names(cell_counts) <- NULL
  #cell_counts
  
  write.csv(cell_counts, paste0("./Outputs/Filling_patterns/", scen, "/", r, "_", scen, "_cell_counts.csv"), row.names = F) 
  
}
}
  


# - # - # - # - # - # - # - # - # - # - # - # - # - # 
#                                                   #
#                                                   #
#         3. CREATE A TABLE WITH THE RATIOS         #
#                                                   #
#                                                   #
# - # - # - # - # - # - # - # - # - # - # - # - # - # 



## 3.1 Load the data
list_eu <- read.table("./Data/Processed/List_eu_neozoa.txt", sep = ";", h = F, fileEncoding = "UTF-8-BOM")
colnames(list_eu)[1] <- "Binomial"

# delete species 
list_eu <- subset(list_eu, !Binomial == "Capra_aegagrus")
list_eu <- subset(list_eu, !Binomial == "Desmana_moschata")
list_eu <- subset(list_eu, !Binomial == "Lama_glama")
list_eu <- subset(list_eu, !Binomial == "Ovis_orientalis")
row.names(list_eu) <- NULL
list_eu

# define overall directory
gen_dir <- "E:/PhD/2nd_Chapter/Sensitivity_analysis/Outputs/Filling_patterns"

scenarios <- c("Disp_gen", "Disp_age", "MaxDisp_gen", "MaxDisp_age")

for(scen in scenarios){
  
OAR <- read.csv(paste0(gen_dir, "/", scen, "/", "OAR_", scen, "_cell_counts.csv"), h = T, sep = ",")
colnames(OAR)[2] <- "OAR"
OAR[3] <- NULL
head(OAR)

PAR <- read.csv(paste0(gen_dir, "/", scen, "/", "PAR_", scen, "_cell_counts.csv"), h = T, sep = ",")
colnames(PAR)[2] <- "PAR"
PAR[3] <- NULL
head(PAR)

POAR <- read.csv(paste0(gen_dir, "/", scen, "/", "POAR_", scen, "_cell_counts.csv"), h = T, sep = ",")
colnames(POAR)[2] <- "POAR"
POAR[3] <- NULL
head(POAR)

fil <- read.csv(paste0(gen_dir, "/", scen, "/", "Range_filling_", scen, "_cell_counts.csv"), h = T, sep = ",")
colnames(fil)[2] <- "range_filling"
fil[3] <- NULL
head(fil)

unf <- read.csv(paste0(gen_dir, "/", scen, "/", "Range_unfilling_", scen, "_cell_counts.csv"), h = T, sep = ",")
colnames(unf)[2] <- "range_unfilling"
unf[3] <- NULL
head(unf)

ove <- read.csv(paste0(gen_dir, "/", scen, "/", "Range_overfilling_", scen, "_cell_counts.csv"), h = T, sep = ",")
colnames(ove)[2] <- "range_overfilling"
ove[3] <- NULL
head(ove)

# merge

mydf <- 
  bind_rows(OAR) %>%
  bind_rows(PAR) %>%
  bind_rows(POAR) %>%
  bind_rows(fil) %>%
  bind_rows(unf) %>%
  bind_rows(ove) %>%
  mutate("ranges" = c(rep("OAR", 46),
                    rep("PAR", 46),
                    rep("POAR", 46),
                    rep("range_filling", 46),
                    rep("range_unfilling", 46),
                    rep("range_overfilling", 46))) %>%
  pivot_wider(names_from = ranges, 
              values_from = c("OAR", "PAR", "POAR","range_filling","range_unfilling","range_overfilling"), 
              values_fill = 0) %>%
  dplyr::select(Binomial, OAR_OAR, PAR_PAR, POAR_POAR, range_filling_range_filling, range_unfilling_range_unfilling, range_overfilling_range_overfilling)

mydf
colnames(mydf) <- c("Binomial","OAR","PAR","POAR","range_filling","range_unfilling","range_overfilling")
mydf

# add proportions and ratios

mydf$Proportion_range_filling <- mydf$range_filling / mydf$POAR
mydf$Proportion_range_overfilling <- mydf$range_overfilling / mydf$POAR
mydf$Proportion_range_unfilling <- mydf$range_unfilling / mydf$POAR

mydf$Filling_ratio_range_filling <- (mydf$range_filling / mydf$POAR) * 100
mydf$Filling_ratio_range_overfilling <- (mydf$range_overfilling / mydf$POAR) * 100
mydf$Filling_ratio_range_unfilling <- (mydf$range_unfilling / mydf$POAR) * 100

mydf

mydf <- mydf[, c("Binomial", "OAR","PAR","POAR","range_filling","range_overfilling","range_unfilling",
                 "Proportion_range_filling","Proportion_range_overfilling","Proportion_range_unfilling",
                 "Filling_ratio_range_filling","Filling_ratio_range_overfilling","Filling_ratio_range_unfilling")]

names(mydf)[5] <- "Range_filling"
names(mydf)[6] <- "Range_overfilling"
names(mydf)[7] <- "Range_unfilling"

mydf

write.csv(mydf, paste0("./Outputs/Filling_patterns/", scen, "_cell_counts_all.csv"), row.names = F) 

}
















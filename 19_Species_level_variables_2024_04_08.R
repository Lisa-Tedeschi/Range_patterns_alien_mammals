##########################################################################
################# SPECIES-LEVEL EXPLANATORY VARIABLES ###################
##########################################################################

# Started on 11.05.2023 
# modified on 14.12.2023 (to use the new ranges obtained using the binary maps of biomod), and 08.04.2024
# for the paper "Patterns and drivers of range filling of alien mammals in Europe"

# this is a script to collate the information such as species' traits (generation length, age at first reproduction, dispersal), 
# time since introduction, and pathways

# Setting up the R environment
rm(list = ls())
setwd("E:/PhD/2nd_Chapter/Sensitivity_analysis")
getwd()

library(tidyverse)



# - # - # - # - # - # - # - # - # - # - # 
#                                       #
#                                       #
#            1. LOAD THE DATA           #
#                                       #
#                                       #
# - # - # - # - # - # - # - # - # - # - # 



## 1.1 Load the list of neozoa species
list_eu <- read.table("./Data/Processed/List_eu_neozoa.txt", sep = ";", h = F, fileEncoding = "UTF-8-BOM")
colnames(list_eu)[1] <- "Binomial"

# delete species 
list_eu <- subset(list_eu, !Binomial == "Capra_aegagrus")
list_eu <- subset(list_eu, !Binomial == "Desmana_moschata")
list_eu <- subset(list_eu, !Binomial == "Lama_glama")
list_eu <- subset(list_eu, !Binomial == "Ovis_orientalis")
row.names(list_eu) <- NULL
list_eu



## 1.2 Load species' traits from COMBINE 
# contains also max dispersal (calculated from Santini et al. 2013)
my_traits <- read.csv("./Data/Processed/traits.csv", sep = ",", h = T, fileEncoding = "UTF-8-BOM")
head(my_traits)
nrow(my_traits)



## 1.3 Load alien polygons with pathways of introductions (from DAMA)
path_eu <- read.csv("./Data/Processed/DAMA_european_species_EU.csv",sep = ",", h = T)
head(path_eu)
nrow(path_eu)

# retain only study species
path_eu <- path_eu[path_eu$x_ScientificName %in% sub("_", " ", list_eu$Binomial),]
head(path_eu)
nrow(path_eu)



## 1.4 Load cell counts and filling ratios for all scenarios

scenarios <- c("Disp_gen", "Disp_age", "MaxDisp_gen", "MaxDisp_age")

for(scen in scenarios){
  
  # create name 
  name <- paste0(scen, "_cell_counts")
  
  # load data
  a <- read.csv(paste0("./Outputs/Filling_patterns/", scen, "_cell_counts_all.csv"), h = T, sep = ",")
  
  # assign name
  assign(name, a)
  
}

rm(a)
rm(name)



# - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # 
#                                                               #
#                                                               #
#         2. ADD SPECIES-LEVEL INFORMATION TO A TABLE           #
#                                                               #
#                                                               #
# - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # - #



## 2.1 Create an empty table with pathways

sp_tbl <- data.frame(Binomial = list_eu$Binomial,
                     "Biological_Control" = 0, 
                     "Conservation" = 0, 
                     "Farming" = 0, 
                     "Fauna_Improvement" = 0, 
                     "Fur_Farming" = 0, 
                     "Hunting" = 0, 
                     "Ornamental_Purposes" = 0, 
                     "Pet" = 0, 
                     "Research" = 0, 
                     "Stowaway" = 0, 
                     "Wild_Fur" = 0, 
                     "Zoo" = 0)

sp_tbl



## 2.2 Add COMBINE traits
my_traits$phylacine_binomial <- sub(" ", "_", my_traits$phylacine_binomial)
colnames(my_traits)[2] <- "Binomial"

sp_tbl <- left_join(sp_tbl, my_traits)
head(sp_tbl)
sp_tbl <- sp_tbl %>% relocate(order)
head(sp_tbl)



## 2.3 Add single pathways 

for(sp in list_eu$Binomial){
  
  # subset pathways for species sp
  p <- path_eu[path_eu$x_ScientificName == sub("_", " ", sp),]
  #p
  
  i = 1
  
  for(path in colnames(sp_tbl)[3:14]){
    
    # Assign a 1 if the pathway is present
    sp_tbl[sp_tbl$Binomial == sp, i + 2] <- ifelse( (path %in% p$x_Pathway) | (path %in% p$X) | (path %in% p$X.1), 1, 0 )
    
    i = i + 1 
    
  }
  
}

sp_tbl



## 2.4 Add total number of pathways

for(i in 1:nrow(sp_tbl)){
  
  sp_tbl$Pathways_tot[i] <- sum(sp_tbl[i, c("Biological_Control", "Conservation", "Farming", "Fauna_Improvement", "Fur_Farming", "Hunting","Ornamental_Purposes", 
                                            "Pet","Research", "Stowaway", "Wild_Fur", "Zoo")])
  
}

sp_tbl
sp_tbl <- sp_tbl %>% relocate(Pathways_tot, .after = Zoo)



## 2.4 Add residence time from the colonization pressure database
# NB: the database of colonization pressure has different dates of introduction compared to DAMA
# to construct the PARs, I used the residence time calculated from the colonization pressure database

cp_est <- read.csv("./Data/Processed/CP_EU_neozoa.csv", h = T, sep = ",")

# delete species 
cp_est <- subset(cp_est, !Binomial == "Capra aegagrus")
cp_est <- subset(cp_est, !Binomial == "Desmana moschata")
cp_est <- subset(cp_est, !Binomial == "Lama glama")
cp_est <- subset(cp_est, !Binomial == "Ovis orientalis")
row.names(cp_est) <- NULL
cp_est
length(unique(cp_est$Binomial))

dates <- c()

for(sp in list_eu$Binomial){
  
  sp_df <- cp_est[cp_est$Binomial == sub("_", " ", sp), ]
  date <- min(na.omit(unique(sp_df$Date)))
  dates <- append(date, dates)
  
}

length(dates)
dates <- rev(dates) # needs to be reversed because at the end there's the first species

# convert to days
sp_tbl$Residence_time_d <- (2017 - dates) * 365
sp_tbl



## 2.6 Add the native range recalculated 
# NB it is not in sq km but in number of 10x10 cells (like the range filling patterns)

# create empty column
sp_tbl$Native_range <- 0

for(sp in list_eu$Binomial){
  
  # load csv
  sp_df <- read.csv(paste0("./Data/Processed/IUCN/EU_mammals_filtered/", sp, ".csv"), sep = ",", h = F)
  
  # update table
  sp_tbl[sp_tbl$Binomial == sp,]$Native_range <- as.integer(sp_df[sp_df$V2 == "Value 1",]$V3)
  
}

sp_tbl



## 2.7 Add points of successful introduction
# load table with number of successful and unsuccessful points
temp <- read.csv("./Data/Processed/Species_table.csv")
temp <- subset(temp, !Binomial == "Lama_glama")
nrow(temp[temp$Binomial %in% sp_tbl$Binomial,])

sp_tbl$Points_succ_intro <- 0

for(sp in temp$Binomial){
  
  sp_tbl[sp_tbl$Binomial == sp,]$Points_succ_intro <- as.integer(temp[temp$Binomial == sp,]$Successful_introduction)
  
}

sp_tbl



## 2.9 Add cell counts

scenarios <- c("Disp_gen", "Disp_age", "MaxDisp_gen", "MaxDisp_age")

for(scen in scenarios){
  
  # create name 
  name <- paste0(scen, "_sp_tbl")
  
  # subset dataframe
  a <- bind_cols(sp_tbl,
               get(paste0(scen, "_cell_counts"))[,c(2:13)])
  
  # assign name 
  assign(name, a)
  
}

rm(a)
rm(name)



# - # - # - # - # - # - # - # - # - # - # 
#                                       #
#                                       #
#            3. REORDER TABLE           #
#                                       #
#                                       #
# - # - # - # - # - # - # - # - # - # - # 



## 3.1 Dispersal + generation length 

Disp_gen_sp_tbl <- Disp_gen_sp_tbl[,c("order", "Binomial", 
                    "OAR", "PAR", "POAR", "Range_filling", "Range_overfilling", "Range_unfilling",
                    "Filling_ratio_range_filling", "Filling_ratio_range_overfilling", "Filling_ratio_range_unfilling", 
                    "Biological_Control", "Conservation", "Farming", "Fauna_Improvement", "Fur_Farming", "Hunting", "Ornamental_Purposes", "Pet", "Research", "Stowaway", "Wild_Fur", "Zoo", 
                    "adult_mass_kg", "generation_length_y", "age_first_reproduction_y", "dispersal_km", "max_dispersal_km",
                    "Residence_time_d", "Pathways_tot", "Native_range", "Points_succ_intro")]

head(Disp_gen_sp_tbl)

write.csv(Disp_gen_sp_tbl, "./Outputs/Disp_gen_species_level_variables.csv", row.names = F)
write.csv(as.data.frame(t(Disp_gen_sp_tbl)), "./Outputs/Disp_gen_species_level_variables_transposed.csv")



## 3.2 Dispersal + age at first reproduction 

Disp_age_sp_tbl <- Disp_age_sp_tbl[,c("order", "Binomial", 
                                      "OAR", "PAR", "POAR", "Range_filling", "Range_overfilling", "Range_unfilling",
                                      "Filling_ratio_range_filling", "Filling_ratio_range_overfilling", "Filling_ratio_range_unfilling", 
                                      "Biological_Control", "Conservation", "Farming", "Fauna_Improvement", "Fur_Farming", "Hunting", "Ornamental_Purposes", "Pet", "Research", "Stowaway", "Wild_Fur", "Zoo", 
                                      "adult_mass_kg", "generation_length_y", "age_first_reproduction_y", "dispersal_km", "max_dispersal_km",
                                      "Residence_time_d", "Pathways_tot", "Native_range", "Points_succ_intro")]

Disp_age_sp_tbl

write.csv(Disp_age_sp_tbl, "./Outputs/Disp_age_species_level_variables.csv", row.names = F)
write.csv(as.data.frame(t(Disp_age_sp_tbl)), "./Outputs/Disp_age_species_level_variables_transposed.csv")



## 3.3 Maximum dispersal + generation length 

MaxDisp_gen_sp_tbl <- MaxDisp_gen_sp_tbl[,c("order", "Binomial", 
                                      "OAR", "PAR", "POAR", "Range_filling", "Range_overfilling", "Range_unfilling",
                                      "Filling_ratio_range_filling", "Filling_ratio_range_overfilling", "Filling_ratio_range_unfilling", 
                                      "Biological_Control", "Conservation", "Farming", "Fauna_Improvement", "Fur_Farming", "Hunting", "Ornamental_Purposes", "Pet", "Research", "Stowaway", "Wild_Fur", "Zoo", 
                                      "adult_mass_kg", "generation_length_y", "age_first_reproduction_y", "dispersal_km", "max_dispersal_km",
                                      "Residence_time_d", "Pathways_tot", "Native_range", "Points_succ_intro")]

head(MaxDisp_gen_sp_tbl)

write.csv(MaxDisp_gen_sp_tbl, "./Outputs/MaxDisp_gen_species_level_variables.csv", row.names = F)
write.csv(as.data.frame(t(MaxDisp_gen_sp_tbl)), "./Outputs/MaxDisp_gen_species_level_variables_transposed.csv")



## 3.4 Maximum dispersal + age at first reproduction 

MaxDisp_age_sp_tbl <- MaxDisp_age_sp_tbl[,c("order", "Binomial", 
                                      "OAR", "PAR", "POAR", "Range_filling", "Range_overfilling", "Range_unfilling",
                                      "Filling_ratio_range_filling", "Filling_ratio_range_overfilling", "Filling_ratio_range_unfilling", 
                                      "Biological_Control", "Conservation", "Farming", "Fauna_Improvement", "Fur_Farming", "Hunting", "Ornamental_Purposes", "Pet", "Research", "Stowaway", "Wild_Fur", "Zoo", 
                                      "adult_mass_kg", "generation_length_y", "age_first_reproduction_y", "dispersal_km", "max_dispersal_km",
                                      "Residence_time_d", "Pathways_tot", "Native_range", "Points_succ_intro")]

MaxDisp_age_sp_tbl

write.csv(MaxDisp_age_sp_tbl, "./Outputs/MaxDisp_age_species_level_variables.csv", row.names = F)
write.csv(as.data.frame(t(MaxDisp_age_sp_tbl)), "./Outputs/MaxDisp_age_species_level_variables_transposed.csv")



# - # - # - # - # - # - # - # - # - # - # 
#                                       #
#                                       #
#     4. EXPLORE SPECIES-LEVEL DATA     #
#                                       #
#                                       #
# - # - # - # - # - # - # - # - # - # - # 



## 4.1 Load data

scenarios <- c("Disp_gen", "Disp_age", "MaxDisp_gen", "MaxDisp_age")

for(scen in scenarios){
  
  # create name 
  name <- paste0(scen, "_sp_tbl")
  
  # load data
  a <- read.csv(paste0("./Outputs/", scen, "_species_level_variables.csv"), h = T, sep = ",")
  
  # assign name
  assign(name, a)
  
}



## 4.2 Explore MaxDisp_gen scenario

summary(MaxDisp_gen_sp_tbl$OAR)
summary(MaxDisp_gen_sp_tbl$PAR)
summary(MaxDisp_gen_sp_tbl$Range_filling)
summary(MaxDisp_gen_sp_tbl$Range_overfilling)
summary(MaxDisp_gen_sp_tbl$Range_unfilling)
summary(MaxDisp_gen_sp_tbl$Filling_ratio_range_filling)
summary(MaxDisp_gen_sp_tbl$Filling_ratio_range_overfilling)
summary(MaxDisp_gen_sp_tbl$Filling_ratio_range_unfilling)

summary(as.factor(MaxDisp_gen_sp_tbl$order)) # cetartiodactyla, rodentia, and carnivora are the most common orders
nrow(MaxDisp_gen_sp_tbl[MaxDisp_gen_sp_tbl$Pathways_tot == 1,]) # 24 species were introduced via only one pathway
tmp <- MaxDisp_gen_sp_tbl[,c("Biological_Control", "Conservation", "Farming", "Fauna_Improvement", "Fur_Farming", "Hunting", "Ornamental_Purposes", "Pet", "Research", "Stowaway", "Wild_Fur", "Zoo")]

summary(tmp) # we see that hunting has the highest mean, meaning it's the more common pathway
sum(tmp$Hunting) # 26 species were introduced via hunting



## Range filling
MaxDisp_gen_sp_tbl[order(MaxDisp_gen_sp_tbl$Range_filling, decreasing = T),][,c(1:11)] # N_vison is the species with higher range filling

MaxDisp_gen_sp_tbl[order(MaxDisp_gen_sp_tbl$Filling_ratio_range_filling, decreasing = T),][,c(1:11)] 
# Muntiacus_reevesi, Neovison_vison, and Sylvilagus_floridanus are the species with higher range filling in proportion

nrow(MaxDisp_gen_sp_tbl[MaxDisp_gen_sp_tbl$Filling_ratio_range_filling > 90,])
# no species have a filling % > 90% 

nrow(MaxDisp_gen_sp_tbl[MaxDisp_gen_sp_tbl$Filling_ratio_range_filling > 50,])
# 5 species (10.9% of the total study species) have a filling % > 50% 

nrow(MaxDisp_gen_sp_tbl[MaxDisp_gen_sp_tbl$Filling_ratio_range_filling > 10,])
# 25 species (54.3% of the total study species) have a range filling % > 10% 



## Range overfilling
MaxDisp_gen_sp_tbl[order(MaxDisp_gen_sp_tbl$Range_overfilling, decreasing = T),][,c(1:11)] # O_zibethicus highest range overfilling

MaxDisp_gen_sp_tbl[order(MaxDisp_gen_sp_tbl$Filling_ratio_range_overfilling, decreasing = T),][,c(1:11)] 
# Micromys_minutus, Dama_dama, and Ondatra_zibethicus are the species with higher range overfilling in proportion

nrow(MaxDisp_gen_sp_tbl[MaxDisp_gen_sp_tbl$Filling_ratio_range_overfilling > 90,])
# 1 species (2.2% of the total study species) (Micromys_minutus) has a range overfilling % > 90% 

nrow(MaxDisp_gen_sp_tbl[MaxDisp_gen_sp_tbl$Filling_ratio_range_overfilling > 50,])
# 13 species (28.3% of the total study species) have a range overfilling % > 50% 

nrow(MaxDisp_gen_sp_tbl[MaxDisp_gen_sp_tbl$Filling_ratio_range_overfilling > 10,])
# 31 species (67.4% of the total study species) have a range overfilling % > 10% 



## Range unfilling
MaxDisp_gen_sp_tbl[order(MaxDisp_gen_sp_tbl$Range_unfilling, decreasing = T),][,c(1:11)] # C_nippon higher range unfilling

MaxDisp_gen_sp_tbl[order(MaxDisp_gen_sp_tbl$Filling_ratio_range_unfilling, decreasing = T),][,c(1:11)] # C_canadensis is the species with higher range unfilling in proportion

nrow(MaxDisp_gen_sp_tbl[MaxDisp_gen_sp_tbl$Filling_ratio_range_unfilling > 90,])
# 4 species (8.7% of the total study species) (Capra_ibex, Cervus_canadensis, Marmota_bobak, Rupicapra_rupicapra) have a range unfilling % > 90% 

nrow(MaxDisp_gen_sp_tbl[MaxDisp_gen_sp_tbl$Filling_ratio_range_unfilling > 50,])
# 14 species (30.4% of the total study species) have a range unfilling % > 50% 

nrow(MaxDisp_gen_sp_tbl[MaxDisp_gen_sp_tbl$Filling_ratio_range_unfilling > 10,])
# 25 species (54.3% of the total study species) have a range unfilling % > 10% 







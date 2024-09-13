########################################################################################
################# SPECIES-LEVEL EXPLANATORY VARIABLES AT POLYGON LEVEL #################
########################################################################################

# Started on 07.08.2023 by LT
# modified on 14.12.2023 (to use the new ranges obtained using the binary maps of biomod) and 08.04.2024
# by LT 
# for the paper "Patterns and drivers of range filling of alien mammals in Europe"

# this is a script to collate the information such as species' traits (generation length, age at first reproduction, dispersal), 
# time since introduction, and pathways
# and socio-economic factors average values at polygon level

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



## 1.2 Load species explanatory variables table

scenarios <- c("Disp_gen", "Disp_age", "MaxDisp_gen", "MaxDisp_age")

# create empty list
sp_tbl_list <- list()

sp_tbl_list <- lapply(scenarios, function(scen){
  
  read.csv(paste0("./Outputs/", scen, "_species_level_variables.csv"), sep = ",", h = T, fileEncoding = "UTF-8-BOM")
  
})

names(sp_tbl_list) <- scenarios

str(sp_tbl_list)



# - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # - #  
#                                                                       #
#                                                                       #
#            2. ADD THE SOCIO-ECONOMIC VARIABLES POLYGON STATS          #
#                                                                       #
#                                                                       #
# - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # 



## 2.1 Create lists where to store data

# create patterns vector to loop through
patterns <- c("Range_filling","Range_unfilling","Range_overfilling")

scenariosList <- list()

# create empty final list for scenarios
for(i in seq_along(scenarios)){
  
  scenariosList[[i]] <- list()
  
  for(j in seq_along(patterns)){
    
    scenariosList[[i]][[j]] <- list()
    
  }
  
}

scenariosList 



## 2.2 Load data

k = 1

# loop through scenarios
for(scen in scenarios){
  
  j = 1
  
  # create empty list for filling patterns
  patternsList <- list()
  
  # loop through pattern
  for(p in patterns){
  
    # assign fil, exp, or unf to a dummy variable
    if(p == "Range_filling"){pat <- "fil"}else if(p == "Range_overfilling"){pat <- "ove"}else{pat <- "unf"}

    i = 1
  
    # loop through species list
    for(sp in list_eu$Binomial){
    
      # load sp df with polygon number of cells for the filling pattern "p" for the species "sp"
      sp_cell <- read.csv(paste0("./Outputs/Filling_patterns/", scen, "/Variables/Variables_stats/Polygons_cells_no/", p, "/", sp, "_", pat, ".csv"), h = T, sep = ",")
    
      # load sp df with values of the socio-economic factors for the filling pattern "p" for the species "sp"
      sp_df <- read.csv(paste0("./Outputs/Filling_patterns/", scen, "/Variables/Variables_stats/Polygons/", p, "/", sp, "_", pat, ".csv"), h = T, sep = ",")
      
      # if statement to perform the action only if there are data
      if(nrow(sp_df) > 0 & nrow(sp_cell) > 0){
      
        # remove unnecessary columns from every dataframe
        sp_cell <- sp_cell[,c("cells_number")]
        sp_df <- sp_df[,c("PopdensityAvg_3035_average","landuseHAvg_3035_average", "infrastructuresAvg_3035_average")] 
      
        # create new df for filling pattern "p" for species "sp" with as many rows as species' polygons   
        sp_p <- sp_tbl_list[[scen]][rep(i, nrow(sp_df)),]
      
        # merge everything in one df 
        a <- sp_p %>% 
          bind_cols(sp_df) %>%
          # update number of cells for filling pattern "p" for each polygon
          # here I use the syntax from the glue package when naming parameters when using :=. Here the {} in the name grab the value by evaluating the expression inside
          mutate( "{p}" := sp_cell)
      
        # store in the list
        patternsList[[i]] <- a
      
        i = i + 1
      
        } else if(nrow(sp_df) <= 0){
      
        # if there is no filling pattern. print a warning and include an empty row 
        print(paste0("WARNING: no ", p, " found for ", sp, " in ", scen))
        patternsList[[i]] <- data.frame()
      
        i = i + 1
      
      }
    
      # patternsList is a list with all the polygon-level variables for pattern "p", each one in a separate dataframe for each species
      # now I want to merge them in a single df and put it in a list for the scenario "scen" 
      
    }
  
    # merge all the dataframes for pattern "p" of the list in a dataframe and store in the final list
    scenariosList[[k]][[j]] <- bind_rows(patternsList)
    
    j = j + 1
  
  }
  
  names(scenariosList[[k]]) <- paste0(scen, "_", patterns)
  
  k = k + 1
  
}

names(scenariosList) <- scenarios

str(scenariosList)



## 2.1 Explore MaxDisp_gen scenario

length(unique(scenariosList$MaxDisp_gen$MaxDisp_gen_Range_filling$Binomial)) # 41 species
length(unique(scenariosList$MaxDisp_gen$MaxDisp_gen_Range_overfilling$Binomial)) # 43 species
length(unique(scenariosList$MaxDisp_gen$MaxDisp_gen_Range_unfilling$Binomial)) # 33 species

nrow(scenariosList$MaxDisp_gen$MaxDisp_gen_Range_filling) # 474
nrow(scenariosList$MaxDisp_gen$MaxDisp_gen_Range_overfilling) # 1197
nrow(scenariosList$MaxDisp_gen$MaxDisp_gen_Range_unfilling) # 1061

summary(scenariosList$MaxDisp_gen$MaxDisp_gen_Range_filling) 
# median PAR: 21065
# median POAR: 26595
# median range filling: 3 (range 1-27736)

summary(scenariosList$MaxDisp_gen$MaxDisp_gen_Range_overfilling) 
# median range overfilling: 3 (range 1-65029)

summary(scenariosList$MaxDisp_gen$MaxDisp_gen_Range_unfilling) 
# median range overfilling: 2 (range 1-13572)



# - # - # - # - # - # - # - # - # - # - # - # - # - # 
#                                                   #
#                                                   #
#         4. UPDATE FILLING RATIOS PER POLYGON      #
#                                                   #
#                                                   #
# - # - # - # - # - # - # - # - # - # - # - # - # - #



## 4.1 Update values

# the values are at species-level, but I need them at a polygon level

# make a copy 
scenariosList_copy <- scenariosList
head(scenariosList$MaxDisp_gen$MaxDisp_gen_Range_filling)

for(scen in scenarios){
  
  for(p in patterns){
    
    # subset list
    df <- scenariosList[scen][[1]][[paste0(scen, "_", p)]]
    
    # calculate filling ratio for pattern "p" in scenario "scen"
    
    a <- ( (df[,p] / df[,"POAR"]) * 100 )
    # create indexing name 
    
    name <- paste0("Filling_ratio_", tolower(p))
    
    # update values 
    df[,name] <- a
    
    scenariosList[scen][[1]][[paste0(scen, "_", p)]] <- df 
    
  }
  
}

head(scenariosList$MaxDisp_gen$MaxDisp_gen_Range_filling)



## 4.2 Save outputs

for(scen in scenarios){
  
  for(p in patterns){
    
    # subset list
    df <- scenariosList[scen][[1]][[paste0(scen, "_", p)]]
    
    write.csv(df, paste0("./Outputs/Filling_patterns/", scen, "/", p, "_", scen, "_polygons.csv"), row.names = F)
    
  }
  
}




# - # - # - # - # - # - # - # - # - # - # - # - # - # 
#                                                   #
#                                                   #
#        5. EXPLORE FILLING RATIOS PER POLYGON      #
#                                                   #
#                                                   #
# - # - # - # - # - # - # - # - # - # - # - # - # - #



## 5.1 Create empty final list for all the data from different scenarios

scenarios <- c("Disp_gen", "Disp_age", "MaxDisp_gen", "MaxDisp_age")
patterns <- c("Range_filling","Range_unfilling","Range_overfilling")

filling_ratios <- list()

for(i in seq_along(scenarios)){
  
  filling_ratios[[i]] <- list()
  
  for(j in seq_along(patterns)){
    
    filling_ratios[[i]][[j]] <- list()
    
  }
  
}

filling_ratios



## 5.2 Rename list

filling_ratios
names(filling_ratios) <- scenarios

for(scen in scenarios){
  
  names(filling_ratios[[scen]]) <- patterns
  
}

filling_ratios



## 5.3 Upload data

for(scen in scenarios){
  
  for(p in patterns){
   
    # create name 
    file <- paste0("./Outputs/Filling_patterns/", scen, "/", p, "_", scen, "_polygons.csv") 
    
    # load data
    df <- read.csv(file, h = T, sep = ",", fileEncoding = "UTF-8-BOM")
    
    # upload data to list
    filling_ratios[[scen]][[p]] <- df
    
  }
  
}

filling_ratios



## 5.4 Explore
fil <- filling_ratios[["MaxDisp_gen"]][["Range_filling"]]
ove <- filling_ratios[["MaxDisp_gen"]][["Range_overfilling"]]
unf <- filling_ratios[["MaxDisp_gen"]][["Range_unfilling"]]

summary(fil)
summary(ove)
summary(unf)


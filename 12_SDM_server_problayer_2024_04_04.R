########################################
################# SDMs #################
########################################

# Started on 01.03.2023
# modified on 04.04.2024
# for the paper "Patterns and drivers of range filling of alien mammals in Europe"

# this is a script to perform Species Distribution Models (SDMs) on the server 



# - # - # - # - # - # - # - # - # - # - # 
#                                       #
#                                       #
#            1. USEFUL INFO             #
#                                       #
#                                       #
# - # - # - # - # - # - # - # - # - # - # 

### Remember to set the wd to /SDM
### NB on the server biomod2 3.3-7.1 is installed, so some things have changed
### Remember that the species name looks like Ammotraguslervia

# /Chelsa/Aggregated_10km_crop contains the 19 bioclimatic predictors cropped to the world (i.e., without the sea)
# /Chelsa/Aggregated_10km_continent contains 8 folders with the continents (North America, Europe, etc), each one contains the 19 bioclimatic predictors cropped to the world (i.e., without the sea)
# /occ_data/Aggregated/occ_data_clean_aggregated_1981_2022 contains the occurrences cleaned, filtered, aggregated at 10 x 10 km (NOT thinned) that are needed for species with < 100 presences
# /Biomod_data contains the THINNED presences (at 50 x 50 km)

args = commandArgs(trailingOnly = TRUE)
sp <- args[1]

library(pacman)
pacman::p_load(tidyverse, devtools, gridExtra, scales, corrplot, sdmpredictors, usdm, terra, readr, sf, maps, biomod2, dismo, colorRamps, CoordinateCleaner, stringr, hrbrthemes, forcats, cowplot)

setwd("/home/biodiversity/SDM_problayer")



# - # - # - # - # - # - # - # - # - # - # 
#                                       #
#                                       #
#           2. BIOMOD INPUT             #
#                                       #
#                                       #
# - # - # - # - # - # - # - # - # - # - # 

# This function rearranges the input data to make sure they can be used within biomod2
# The function allows to select pseudo-absences or background data in the case that true absences data are not available, or to add pseudo-absence data to an existing set of absence
# the argument resp.name is used for all file and folder naming of biomod


## 2.1 Names and data needed

cont_names <- c("Africa", "Antarctica", "Asia", "Europe", "North_America", "Oceania", "Seven_seas", "South_America")
IUCN_poly <- read.csv("../grass/Sensitivity_analysis/Data/Processed/IUCN_ranges_in_continents.csv", sep = ",", h = T) 
DAMA_poly <- read.csv("../grass/Sensitivity_analysis/Data/Processed/DAMA_ranges_in_continents.csv", sep = ",", h = T) 
biasfile <- stack("../grass/Sensitivity_analysis/Data/Processed/biasfile_new.tif")



## 2.2 Species occurrences

# load the thinned data for the species sp
myDf <- read.csv(paste0("../grass/Sensitivity_analysis/Data/Processed/occ_data/Thinned/Biomod_data_thin/", sp, ".csv"), h = T, sep = ",")

print(paste("Number of presences:", nrow(myDf)))

# the presences data for the species (must be a numeric! 0/1 or 1 vector)
myResp <- rep(1, nrow(myDf)) # a vector of presences (1) 

# the XY coordinates of species data (must be a 2 columns dataframe or matrix)
myRespCoord <- myDf[c("lonX_round", "latY_round")]

#x11()
#plot(biasfile)
#points(myRespCoord, col="blue",pch=16)



## 2.3 The predictors

# here i need some workarounds
# first I create an empty raster with extent and resolution as chelsa bioclimatic variables (rasterStack)
chelsa_10km <- stack(paste0("../grass/Sensitivity_analysis/Data/Processed/Chelsa/Aggregated_10km_crop/", list.files("../grass/Sensitivity_analysis/Data/Processed/Chelsa/Aggregated_10km_crop")))
ordered_names <- c(paste0("bio",1:19,"_10km"))
chelsa_10km <- chelsa_10km[[ordered_names]]

r <- raster(extent(chelsa_10km[[1]]), resolution = res(chelsa_10km[[1]]))

# then I stack how many empty rasters as there are bioclimatic variables (in this case, 6)
chelsa_stack <- addLayer(r,r,r,r,r,r)

# Assign crs
crs(chelsa_stack) <- crs("EPSG:4326")

chelsa_cont12 <- chelsa_stack

# then for each continent  
for(cont in cont_names){

  # if the species sp has a 1 in the column corresponding to the cont (e.g., Africa) for native ranges
  if(IUCN_poly[IUCN_poly$Species == sp, cont] == 1){
    
    # stack the bioclimatic variables cropped to the continent 
    chelsa_cont1 <- stack(paste0("../grass/Sensitivity_analysis/Data/Processed/Chelsa/Aggregated_10km_continent/", cont, "/", 
                                 c("bio1_10km.tif","bio3_10km.tif","bio4_10km.tif","bio15_10km.tif","bio16_10km.tif","bio17_10km.tif")))
    
  }
  
  # if the species sp has a 1 in the column corresponding to the cont (e.g., Africa) for alien ranges
  if(DAMA_poly[DAMA_poly$Species == sp, cont] == 1){
    
    # stack the bioclimatic variables cropped to the continent 
    chelsa_cont2 <- stack(paste0("../grass/Sensitivity_analysis/Data/Processed/Chelsa/Aggregated_10km_continent/", cont, "/", 
                                 c("bio1_10km.tif","bio3_10km.tif","bio4_10km.tif","bio15_10km.tif","bio16_10km.tif","bio17_10km.tif")))
  
  }
  
  # if both exist, merge native bioclim with alien bioclim  
  if(exists("chelsa_cont1") & exists("chelsa_cont2")){
    
    chelsa_cont12 <- stack(merge(chelsa_cont1, chelsa_cont2))
    
  } else if(exists("chelsa_cont1")){
    
    chelsa_cont12 <- stack(chelsa_cont1)
      
  } else if(exists("chelsa_cont2")){
    
    chelsa_cont12 <- stack(chelsa_cont2)
    
  }
  
  # and then merge them with the previous ones (e.g., merge bio1 from both native and alien from Africa with bio1 from Europe)
  chelsa_stack <- stack(merge(chelsa_stack, chelsa_cont12))
  
}

# rasterStack of myPred
myPred <- chelsa_stack
names(myPred) <- c("bio1_10km", "bio3_10km", "bio4_10km", "bio15_10km", "bio16_10km", "bio17_10km")

print(paste("My predictors names:", names(myPred)))

rm(chelsa_cont1)
rm(chelsa_cont2)
rm(chelsa_cont12)
rm(chelsa_stack)



## 2.4 Probability layer 

# mask biasfile
biasfile_masked <- biasfile * (myPred[[1]]/myPred[[1]])

# add a small value to 0
biasfile_masked <- biasfile_masked + 1

# Load native and alien ranges
range <- terra::vect(paste0("../SDM_continent/Range_shp/", sp, ".gpkg"))
# same files that are in paste0("../Sensitivity_analysis/Data/Processed/Range_shp/", sp, ".gpkg") but the species name is without _ 

# Rasterize assigning the extent and CRS of Chelsa
range <- rasterize(range, terra::rast(chelsa_10km[[1]]))
crs(range) <- "EPSG:4326"

# Remove ranges 
# range is the raster of native and alien ranges
biasfile_masked_norange <- terra::mask(terra::rast(biasfile_masked), range, inverse = T)

# Remove unnecessary files
rm(r)
rm(range)
rm(biasfile_masked)

#x11()
#plot(biasfile_masked_norange)
#points(myRespCoord, col="blue",pch=16)



## 2.5 Selecting PAs number
if(length(myResp) >= 100){
  
  PAs_number <- length(myResp)
  
} else if(length(myResp) < 100){
  
  PAs_number <- 100
  
}



## 2.6 Format the data
myBiomodData <- BIOMOD_FormatingData(resp.name = sp,
                                     resp.var = myResp, # vector of presences
                                     expl.var = myPred, # rasterStack containing my predictors for the continents where the ranges (native and alien) are, WITHOUT the areas occupied by the ranges  
                                     #dir.name = "./Models",
                                     resp.xy = myRespCoord, # 2 column df with coordinates of resp.var
                                     PA.nb.rep = 5, # This should be set to 0 only if absence data are available (no pseudo-absence will be extracted)
                                     PA.nb.absences = PAs_number, # same as the presences 
                                     PA.strategy = "random",
                                     na.rm = T)

myBiomodData

paste("Number of modeled presences:", summary(as.factor(myBiomodData@data.species))[1])

write.csv(data.frame(Species = sp,
                     Presences = summary(as.factor(myBiomodData@data.species))[1]),
          paste0("./Presences/", sp, ".csv"),
          row.names = F)


#myBiomodData_old <- myBiomodData

pres <- myBiomodData@coord[1:as.integer(summary(as.factor(myBiomodData@data.species))[1]),]
pas <- myBiomodData@coord[as.integer(summary(as.factor(myBiomodData@data.species))[1])+1:nrow(myBiomodData@coord),]

x11()
plot(biasfile_masked_norange)
points(pres, col="blue",pch=16)
points(pas, col="red",pch=16)
plot(stack(myPred)[[1]])


## 2.7 Replace PAs randomly draw by biomod with PAs drawn based on a probability layer
# PAY ATTENTION If you need PA or PA.table (based on your biomod version), spatSample or sampleRandom

for(i in 1:5){ # 5 is the PA.nb.rep
  
  j <- i + 1
  
  if(j > 5){j <- 1}
  
  # first sample PAs_number of PAs from the biasfile and retain the coordinates
  new_coords <- terra::spatSample(x = biasfile_masked_norange, 
                                   size = PAs_number,
                                   method = "weight",
                                   na.rm = T,
                                   as.df = T,
                                   xy = T)[,1:2]
  
  # then replace the original PAs coordinates with the sampled ones
  myBiomodData@coord[myBiomodData@PA.table[,i] == T &
                       myBiomodData@PA.table[,j] == F ,] <- new_coords
  
  # myBiomodData@coord[myBiomodData@PA[,i] == T &
  #                          myBiomodData@PA[,j] == F ,] <- new_coords
  
  # then replace the original values of the environmental variables with those in correspondence of the newly sampled PAs 
  myBiomodData@data.env.var[myBiomodData@PA.table[,i] == T &
                                  myBiomodData@PA.table[,j] == F ,] <-
    as.data.frame(raster::extract(myPred, new_coords))
  
  # myBiomodData@data.env.var[myBiomodData@PA[,i] == T &
  #                             myBiomodData@PA[,j] == F ,] <-
  #   as.data.frame(raster::extract(myPred, new_coords))
  
} 

print(paste0("Check if there are NAs in the coordinates: ", sum(is.na(myBiomodData@coord))))
print(paste0("Check if there are NAs in the environmental values: ", sum(is.na(myBiomodData@data.env.var))))


# Remove unnecessary files
rm(biasfile_masked_norange)



# - # - # - # - # - # - # - # - # - # - # 
#                                       #
#                                       #
#               3. MODEL                #
#                                       #
#                                       #
# - # - # - # - # - # - # - # - # - # - # 



## 3.1 Model selection

# define a vector of models 
modelSet <- c("GLM", "GBM", "ANN", "FDA", "MARS",  "RF")

myBiomodOption <- BIOMOD_ModelingOptions()



## 3.2 Model calibration

myBiomodModelOut <- BIOMOD_Modeling(data = myBiomodData,
                                    models = modelSet, 
                                    models.options = myBiomodOption,
                                    NbRunEval = 3, # i can split the original dataset into two subsets, one to calibrate the models, and another one to evaluate them. NBRunEval provides the possibility to repeat this process (calibration and evaluation) N times (NbRunEval times)
                                    DataSplit = 80, # 80% to build the models and evaluate on the 20%
                                    VarImport = 3,
                                    models.eval.meth = c("KAPPA", "TSS", "ROC"),
                                    rescal.all.models = T,
                                    do.full.models = FALSE)

myBiomodModelOut



# - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # - #
#                                                               #
#                                                               #
#           4. MODEL EVALUATION AND RESPONSE CURVES             #
#                                                               #
#                                                               #
# - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # - #



## 4.1 Get model evaluation and variable importance 

dir.create(paste0("./Statistics/", sp))

evaluation <- get_evaluations(myBiomodModelOut) 

write.table(evaluation, paste0("./Statistics/", sp, "/evaluation.csv"),
            dec = ".", 
            row.names = TRUE,
            col.names = TRUE,
            quote = FALSE,
            sep = ";")

# get variable importance 
variable_imp <- get_variables_importance(myBiomodModelOut)

write.table(variable_imp, paste0("./Statistics/", sp, "/variable_imp.csv"),
            dec = ".", 
            row.names = TRUE,
            col.names = TRUE,
            quote = FALSE,
            sep = ";")



## 4.2 Plot evaluation scores & variables importance

dir.create(paste0("./Plots/", sp))

# Plots of mean evaluation scores (and their standard deviation) of models
pic_path <- paste0("./Plots/", sp, "/", sp, "_ModelEval.jpeg")
jpeg(pic_path, units = "in", width = 15, height = 15, res = 300)
models_scores_graph(obj = myBiomodModelOut, 
                    metrics = c("ROC","TSS"),
                    by = "models")
dev.off()


# Plots of mean evaluation scores (and their standard deviation) of models grouped by run
pic_path <- paste0("./Plots/", sp, "/", sp, "_ModelEvalRun.jpeg")
jpeg(pic_path, units = "in", width = 15, height = 15, res = 300)
models_scores_graph(obj = myBiomodModelOut, 
                    metrics = c("ROC","TSS"),
                    by = "cv_run")
dev.off()


# Plots of mean evaluation scores (and their standard deviation) of models grouped by data_set
pic_path <- paste0("./Plots/", sp, "/", sp, "_ModelEvalData.jpeg")
jpeg(pic_path, units = "in", width = 15, height = 15, res = 300)
models_scores_graph(obj = myBiomodModelOut, 
                    metrics = c("ROC","TSS"),
                    by = "data_set")
dev.off()



# - # - # - # - # - # - # - # - # - #
#                                   #
#                                   #
#             5. PROJECT            #
#                                   #
#                                   #
# - # - # - # - # - # - # - # - # - #



## 5.1 Plot single models projections 

# reload chelsa variables to use as new predictors (otherwise it will predict only on the continents) 
myNewPred <- chelsa_10km[[c(1,3,4,15:17)]]

myBiomodProj <- BIOMOD_Projection(modeling.output = myBiomodModelOut,
                                  proj.name = "Current",
                                  new.env = myNewPred,
                                  selected.models = "all", 
                                  binary.meth = c("TSS"), # a vector of a subset of models evaluation method computed before # it uses the cutoff values of before to optimise KAPPA, TSS, and ROC # if i used KAPPA, TSS and ROC I can subset a binary.meth from one of this 3
                                  filtered.meth = c("TSS"),
                                  build.clamping.mask = F)

# load and stack the raster (with each run of each model) based on the binary projection for the TSS - values 0-1
current_binary_TSSproj <- raster::stack(paste0("./", sp, "/proj_Current/proj_Current_", sp, "_TSSbin.grd"))



# - # - # - # - # - # - # - # - # - # - # - # - #
#                                               #
#                                               #
#             6. ENSEMBLE MODELING              #
#                                               #
#                                               #
# - # - # - # - # - # - # - # - # - # - # - # - #



## 6.1 Ensemble modeling
# the ensemble models should include prob.mean.weight using TSS as evaluation metric

myBiomodEM <- BIOMOD_EnsembleModeling(modeling.output = myBiomodModelOut,
                                      chosen.models = "all",
                                      em.by = "all",
                                      eval.metric = c("TSS"), # evaluation metric names to be used together with metric.select.thresh to exclude single models based on their evaluation scores
                                      eval.metric.quality.threshold = c(0.70), # numeric values corresponding to the minimum scores (one for each metric.select) below which single models will be excluded from the ensemble model building
                                      models.eval.meth = c("TSS"), # same as in BIOMOD_Modeling()
                                      VarImport = 3,
                                      prob.mean.weight = T) # build the mean of all the probabilities



## 6.2 Ensemble modeling evaluation  
# get all models evaluation 
evaluation_em <- get_evaluations(myBiomodEM)

write.table(evaluation_em, paste0("./Statistics/", sp, "/evaluation_em.csv"),
            dec = ".", 
            row.names = TRUE,
            col.names = TRUE,
            quote = FALSE,
            sep = ";")



## 6.3 Plot ensemble models projection

# combine all the single model projections of the current climatic conditions to an ensemble model

myBiomodEMProj <- BIOMOD_EnsembleForecasting(EM.output = myBiomodEM,
                                             projection.output = myBiomodProj,
                                             proj.name = "CurrentEM",
                                             selected.models = "all",
                                             #metric.binary = c("KAPPA", "TSS", "ROC"), # a vector of a subset of models evaluation method computed before # it uses the cutoff values of before to optimise KAPPA, TSS, and ROC # if i used KAPPA, TSS and ROC I can subset a binary.meth from one of this 3
                                             binary.meth = c("TSS"),
                                             filtered.meth = c("TSS"))


# plot the ensembled models for the current climate
pic_path <- paste0("./Plots/", sp, "/", sp, "_projection_em.jpeg")
jpeg(pic_path, units = "in", width = 25, height = 25, res = 300)
plot(myBiomodEMProj)
dev.off()


# load and stack the raster (with the ensemble model) based on the binary projection for the TSS
current_binary_TSSEMproj <- raster::stack(paste0("./", sp, "/proj_CurrentEM/proj_CurrentEM_",  sp, "_ensemble_TSSbin.grd"))

pic_path <- paste0("./Plots/", sp, "/", sp, "_binary_TSSEMproj.jpeg")
jpeg(pic_path, units = "in", width = 25, height = 25, res = 300)
plot(current_binary_TSSEMproj)
dev.off()



# remove unnecessary files
files_unused <- paste0(getwd(), "/", sp, "/proj_Current/proj_Current_", sp, c(".gri",".grd","_TSSbin.grd","_TSSbin.gri","_TSSfilt.grd","_TSSfilt.gri"))
file.remove(files_unused)

directory_unused <- paste0(getwd(), "/", sp, "/proj_CurrentEM/individual_projections")
unlink(directory_unused, recursive = TRUE)

removeTmpFiles(h = 36)

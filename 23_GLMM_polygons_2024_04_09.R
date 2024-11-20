#####################################################
################# GLMM FOR NEOBIOTA #################
#####################################################

# Started on 08.08.2023
# modified on 09.04.2024
# for the paper "Patterns and drivers of range filling of alien mammals in Europe"

# this is a script to perform a glmm to see if the filling patterns are influenced by the introduction history (pathways of introduction, native range size...)
# and socio-economic factors (human population density, land-use (i.e., crop, pasture, urban, and rangeland), infrastructures (i.e., roads and railways))
# at a polygon level

# Setting up the R environment
rm(list = ls())
setwd("E:/PhD/2nd_Chapter/sensitivity_analysis")
getwd()

pacman::p_load(stats, DHARMa, glmmTMB, ggeffects, sjPlot, performance, tidyverse)



# - # - # - # - # - # - # - # - # - # - # 
#                                       #
#                                       #
#            1. LOAD THE DATA           #
#                                       #
#                                       #
# - # - # - # - # - # - # - # - # - # - # 



## 1.1 Create empty final list for all the data from different scenarios

scenarios <- c("Disp_gen", "Disp_age", "MaxDisp_gen", "MaxDisp_age")
patterns <- c("Range_filling","Range_unfilling","Range_overfilling")

sp_tbl_list <- list()

for(i in seq_along(scenarios)){
  
  sp_tbl_list[[i]] <- list()
  
  for(j in seq_along(patterns)){
    
    sp_tbl_list[[i]][[j]] <- list()
    
  }
  
}



## 1.2 Rename list
sp_tbl_list
names(sp_tbl_list) <- scenarios

for(scen in scenarios){
  
  names(sp_tbl_list[[scen]]) <- patterns
  
}

sp_tbl_list



## 1.3 Upload data

for(scen in scenarios){
  
  for(p in patterns){
    
    # create file name
    file <- paste0("./Outputs/Filling_patterns/", scen, "/", p, "_", scen, "_polygons.csv")
    
    # load data
    df <- read.csv(file, sep = ",", h = T, fileEncoding = "UTF-8-BOM")
    
    # upload data to list
    sp_tbl_list[[scen]][[p]] <- df 
    
  }
}

sp_tbl_list




## 1.1 Check for spearman correlation between covariates

for(scen in scenarios){
  
  for(p in patterns){
    
    # calculate correlation
    a <- cor(sp_tbl_list[[scen]][[p]][,c("Pathways_tot", "Native_range", "PopdensityAvg_3035_average", "landuseHAvg_3035_average", "infrastructuresAvg_3035_average")],
             method = "spearman", use = "pairwise.complete.obs")
    
    # save output
    write.csv(a, paste0("./Outputs/Filling_patterns/", scen, "/spear_cor_", tolower(p), "_", scen, "_polygons.csv"))
    
  }
}

# nothing is correlated (threshold |0.7|)



# - # - # - # - # - # - # - # - # - # - # - # - # - # 
#                                                   #
#                                                   #
#            2. ADJUST DATA FOR MODELING            #
#                                                   #
#                                                   #
# - # - # - # - # - # - # - # - # - # - # - # - # - # 

sp_tbl_list_copy <- sp_tbl_list



## 2.1 Change to factors

class(sp_tbl_list[[scen]][[p]]$Binomial)
class(sp_tbl_list[[scen]][[p]]$order)

for(scen in scenarios){
  
  for(p in patterns){
    
    sp_tbl_list[[scen]][[p]]$Binomial <- as.factor(sp_tbl_list[[scen]][[p]]$Binomial)
    sp_tbl_list[[scen]][[p]]$order <- as.factor(sp_tbl_list[[scen]][[p]]$order)
    
  }
}

class(sp_tbl_list[[scen]][[p]]$Binomial)
class(sp_tbl_list[[scen]][[p]]$order)



## 2.2 Scaling the continuous predictors 

head(sp_tbl_list[[scen]][[p]])

for(scen in scenarios){
  
  for(p in patterns){
    
    sp_tbl_list[[scen]][[p]] <- sp_tbl_list[[scen]][[p]] %>%
      mutate_at(c("Native_range", 
                  "Points_succ_intro", 
                  "landuseHAvg_3035_average", 
                  "infrastructuresAvg_3035_average"),
                scale)  %>%
      mutate(PopdensityAvg_3035_average = scale(log(PopdensityAvg_3035_average + 0.1)))
    
  }
}

head(sp_tbl_list[[scen]][[p]])



# - # - # - # - # - # - # - # - # - # - # - # 
#                                           #
#                                           # 
#     3. GLMMs ON THE FILLING PATTERNS      #
#                                           #
#                                           #
# - # - # - # - # - # - # - # - # - # - # - #



## 3.1 Create empty final list for model outputs

scenarios <- c("Disp_gen", "Disp_age", "MaxDisp_gen", "MaxDisp_age")
patterns <- c("Range_filling","Range_unfilling","Range_overfilling")

model_outputs <- list()

for(i in seq_along(scenarios)){
  
  model_outputs[[i]] <- list()
  
  for(j in seq_along(patterns)){
    
    model_outputs[[i]][[j]] <- list()
    
  }
  
}

model_outputs



## 3.2 Rename list
names(model_outputs) <- scenarios

for(scen in scenarios){
  
  names(model_outputs[[scen]]) <- patterns
  
}

model_outputs



## 3.3 GLMMs

for(scen in scenarios){
  
  for(p in patterns){
    
    model_outputs[[scen]][[p]] <- glmmTMB(get(p) ~ Pathways_tot + Native_range + 
                                        PopdensityAvg_3035_average  + landuseHAvg_3035_average + infrastructuresAvg_3035_average + 
                                        offset(log(POAR)) + (landuseHAvg_3035_average | Binomial),
                                        #control = glmmTMBControl(optimizer = optim, optArgs = list(method = "BFGS")),
                                        #control = glmmTMBControl(optCtrl = list(iter.max = 1e3, eval.max = 1e3)),
                                        control = glmmTMBControl(optimizer = optim, optArgs = list(method = "L-BFGS-B")), 
                                        data = sp_tbl_list[[scen]][[p]],
                                        family = nbinom2)
    
  }
  
}

model_outputs



## 3.4 Explore model outputs for MaxDisp_gen scenario 
scen <- "MaxDisp_gen"
f <- "Range_filling"
o <- "Range_overfilling"
u <- "Range_unfilling"

summary(model_outputs[[scen]][[f]])
summary(model_outputs[[scen]][[o]])
summary(model_outputs[[scen]][[u]])

# A significant ratio > 1 indicates overdispersion, a significant ratio < 1 underdispersion
testDispersion(model_outputs[[scen]][[f]]) # 0.048
testDispersion(model_outputs[[scen]][[o]]) # 0.408
testDispersion(model_outputs[[scen]][[u]]) # 0.016

# If the dispersion ratio is close to one, a Poisson model fits well to the data. Dispersion ratios larger than one indicate overdispersion, 
# thus a negative binomial model or similar might fit better to the data. Dispersion ratios much smaller than one indicate underdispersion. 
# A p-value < .05 indicates either overdispersion or underdispersion (the first being more common)
# NB from check_overdispersion help page:
# Using this approach would be inaccurate for zero-inflated or negative binomial mixed models (fitted with glmmTMB), 
# in such cases, the overdispersion test is based on simulate_residuals() (which is identical to check_overdispersion(simulate_residuals(model))).

check_overdispersion(model_outputs[[scen]][[f]]) # 0.048 under-dispersion
check_overdispersion(model_outputs[[scen]][[o]]) # 0.408
check_overdispersion(model_outputs[[scen]][[u]]) # 0.016 under-dispersion

check_collinearity(model_outputs[[scen]][[f]]) # low
check_collinearity(model_outputs[[scen]][[o]]) # low
check_collinearity(model_outputs[[scen]][[u]]) # low

check_model(model_outputs[[scen]][[f]])
check_model(model_outputs[[scen]][[o]])
check_model(model_outputs[[scen]][[u]])

testUniformity(model_outputs[[scen]][[f]]) # p-value < 0.000002, outlier test = 0.6
testUniformity(model_outputs[[scen]][[o]]) # p-value < 0.000002, outlier test = 0.0067
testUniformity(model_outputs[[scen]][[u]]) # p-value < 0.000002, outlier test = 0.0219

testOutliers(model_outputs[[scen]][[f]]) # 0.46
testOutliers(model_outputs[[scen]][[o]]) # 0.0067
testOutliers(model_outputs[[scen]][[u]]) # 0.0219

# The marginal R2 considers only the variance of the fixed effects (without the random effects), 
# while the conditional R2 takes both the fixed and random effects into account (i.e., the total model)
r2(model_outputs[[scen]][[f]]) # not reliable
r2(model_outputs[[scen]][[o]]) # not reliable
r2(model_outputs[[scen]][[u]]) # not reliable

################# OVER-/UNDER-DISPERSION #################
# OVERDISPERSION: If I get more residuals around 0 and 1 (the curve does not follow the diagonal and the points are grouped around 0 and 1), 
# it means that more residuals are in the tail of distribution 
# than would be expected under the fitted model = overdispersion
# UNDERDISPERSION: If I get too many residuals around 0.5 (the curve does not follow the diagonal and the points are grouped around the middle of the diagonal 
# and they may cross the diagonal), it means that I am not getting as many residuals 
# as I would expect in the tail of the distribution than expected from the fitted model = underdispersion

# from DHARMA vignette:
# If you see this pattern, note that a common reason for underdispersion is overfitting, 
# i.e. your model is too complex. Other possible explanations to check for include zero-inflation 
# (best to check by comparing to a ZIP model, but see also DHARMa::testZeroInflation), 
# non-independence of the data (e.g. temporal autocorrelation, check via DHARMa:: testTemporalAutocorrelation) 
# that your predictors can use to overfit, or that your data-generating process is simply not a Poisson process.
# From a technical side, underdispersion is not as concerning as over dispersion, 
# as it will usually bias p-values to the conservative side, but if your goal is to get a good power, 
# you may want to consider a simpler model. If that is not helping, you can move to 
# a distribution for underdispersed count data (e.g. Conway-Maxwell-Poisson, generalized Poisson).
#################

simulationOutput <- simulateResiduals(fittedModel = model_outputs[[scen]][[f]], plot = F)
plot(simulationOutput) # not the best residuals
simulationOutput <- simulateResiduals(fittedModel = model_outputs[[scen]][[o]], plot = F)
plot(simulationOutput) # not the best residuals
simulationOutput <- simulateResiduals(fittedModel = model_outputs[[scen]][[u]], plot = F)
plot(simulationOutput) # not the best residuals

#!/bin/bash

######################################################
############ CLIMATICALLY SUITABLE PARs ##############
######################################################

# created on 24.11.2023 
# modified on 04.04.2024 
# by LT
# for the paper "Patterns and drivers of range filling of alien mammals in Europe"

# this is a GRASS GIS script to import the predicted alien ranges (PAR) 
# created with different combinations of dispersal (median and max) and reproduction (generation length and age at first reproduction)
# for a list of species 
# then rasterize the vectors at a resolution of 10 x 10 km 
# adding a column in the attribute table with the species binomial name to make the heatmaps
# save all the vectors and the new rasters 
# load the binary projections from SDM
# and remove the climatically unsuitable parts

# the binary projections (in SDM_problayer_binaries_3035_2023_12_14 folder) 
# are the global binary outputs from the SDMs binarized directly into biomod2
# reprojected to Europe, cropped, saved as .tif

# as for the removal of the climatically unsuitable parts,
# if cells in the $sp binary projection raster equal 1, create a MASK and write a value of 1 in the new map, else write null values
# in this way, there will be "holes" (null values) in the binary rasters 
# and then I can save the new raster ($sp_PAR_suit) without the cells that in the binary raster where 0 
# (that were not saved in the new raster because they were assigned a null value)



# - # - # - # - # - # - # - # - # - # - # - # - # - # - # - #
#													        #
#                                                           #
#       1. LOAD BINARY PREDICTIONS AND CREATE PAR_SUIT      #
#                                                           #
#													        #
# - # - # - # - # - # - # - # - # - # - # - # - # - # - # - #

#grass /home/biodiversity/tedeschil/grass/3035/PERMANENT
#g.mapset mapset=PERMANENT location=3035
wd=/home/biodiversity/tedeschil/grass/Sensitivity_analysis



## 1.1 GDAL

echo "===================== SET REGION =======" 
g.region -p raster=EU_3035 res=10000 # REMEMBER you are in LAEA3035 and the resolution is METERS

while read scen;
do
	while read sp;
	do
	echo "===================== IMPORT $sp PAR VECTORS ======="
	v.in.ogr --o input=$wd'/'$scen'/PAR_3035/PAR/'$sp'.gpkg' output=$sp'_PAR' 
	echo "===================== CLEAN $sp_PAR VECTOR ======="
	v.clean -c --o input=$sp'_PAR' output=$sp'_PAR_clean' tool=snap threshold=1e-13
	echo "===================== ADD AND UPDATE COLUMN IN THE ATTRIBUTE TABLE ======="
	v.db.addcolumn map=$sp'_PAR_clean' layer=1 columns='Binomial VARCHAR' --o
	v.db.update map=$sp'_PAR_clean' layer=1 column=Binomial value=$sp
	echo "===================== SAVE $sp_PAR VECTOR ======="
	v.out.ogr --o input=$sp'_PAR_clean' output=$wd'/'$scen'/PAR_3035/PAR/'$sp'_cleaned.gpkg' format=GPKG output_layer=$sp
	echo "===================== STARTING $sp_PAR RASTERIZATION ======="
	gdal_rasterize -at -tr 10000 10000 -burn 1 -l $sp -a_nodata 0.0 -ot Float32 -of GTiff $wd'/'$scen'/PAR_3035/PAR/'$sp'_cleaned.gpkg' $wd'/'$scen'/PAR_3035/PAR/'$sp'.tif' 
	echo "===================== LOAD $sp_PAR RASTER AND BINARY PROJECTIONS OF SUITABLE HABITAT======="
	r.in.gdal input=$wd'/'$scen'/PAR_3035/PAR/'$sp'.tif' output=$sp'_PAR' --o
	r.in.gdal --o input=$wd'/Data/SDM_problayer_binaries_3035/'$sp'.tif' output=$sp'_bin'
	echo "===================== CREATE A MASK =======" 
	r.mapcalc --o "MASK = if(${sp}_bin == 1,1,null())" 
	echo "===================== CREATE A RASTER FOR $sp WITHOUT THE ENVIRONMENTALLY UNSUITABLE CELLS ======="
	r.mapcalc --o "${sp}_PAR_suit = ${sp}_PAR"
	echo "===================== SAVE $sp_PAR_suit RASTER =======" 
	r.out.gdal --o input=$sp'_PAR_suit' output=$wd'/'$scen'/PAR_3035/PAR_suit/'$sp'_PAR_suit.tif' format=GTiff
	echo "===================== VECTORIZE =======" 
	r.to.vect --o input=$sp'_PAR_suit' output=$sp'_PAR_suit' type=area
	echo "===================== ADD AND UPDATE COLUMN IN THE ATTRIBUTE TABLE ======="
	v.db.addcolumn map=$sp'_PAR_suit' layer=1 columns='Binomial VARCHAR' --o
	v.db.update map=$sp'_PAR_suit' layer=1 column=Binomial value=$sp
	echo "===================== SAVE VECTOR ======="
	v.out.ogr --o input=$sp'_PAR_suit' output=$wd'/'$scen'/PAR_3035/PAR_suit/'$sp'_PAR_suit.gpkg' format=GPKG
	echo "===================== REMOVE UNNECESSARY FILES FOR $sp =======" 
	g.remove -f type=vector name=$sp'_PAR',$sp'_PAR_clean',$sp'_PAR_suit'
	g.remove -f type=raster name=$sp'_PAR',$sp'_bin',$sp'_PAR_suit'
	r.mask -r
	echo "===================== DONE $sp_PAR RASTERIZATION =======" 
	done < /home/biodiversity/tedeschil/grass/List_eu_neozoa.txt # species list 
done < /home/biodiversity/tedeschil/grass/Sensitivity_analysis/scenarios.txt # txt file with the different combinations: 
# median dispersal distance and generation length ("Disp_gen")
# median dispersal distance and age at first reproduction ("Disp_age")
# maximum dispersal distance and generation length ("MaxDisp_gen")
# maximum  dispersal distance and age at first reproduction ("MaxDisp_age")
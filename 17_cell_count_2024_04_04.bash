#########################################################
############ CALCULATE THE NUMBER OF CELLS ##############
#########################################################

# created on 16.07.2022 by LT
# modified on 06.04.2023, 14.12.2023, and 04.04.2024 
# by LT
# for the paper "Patterns and drivers of range filling of alien mammals in Europe"

# this is a GRASS GIS script to count cells of PAR, OAR, POAR, range filling, unfilling, and overfilling
# at species and polygon levels
# and to create POARs
# all of this based on the ranges created with the biomod binary outputs 
# for different combinations of dispersal (median and max) and reproduction (generation length and age at first reproduction)



# - # - # - # - # - # - # - # - # - # - # - # - # - # - # - #
#                                                           #
#                                                           #
#          1. RANGE FILLING PATTERNS NUMBER OF CELLS        #
#                                                           #
#                                                           #
# - # - # - # - # - # - # - # - # - # - # - # - # - # - # - #

#grass /home/biodiversity/tedeschil/grass/3035/PERMANENT
#g.mapset mapset=PERMANENT location=3035
wd=/home/biodiversity/tedeschil/grass/Sensitivity_analysis



## 1. Load the rasters and calculate the cell count (-c) with labels (-l)

echo "===================== SET REGION ======="
g.region -p raster=EU_3035 res=10000 

while read scen;
do
	while read sp;	
	do
	echo "===================== LOAD $sp'_fil', $sp'_unf', $sp'_ove' =======" 
	r.in.gdal --o input=$wd'/'$scen'/Range_filling/'$sp'_fil.tif' output=$sp'_fil'
	r.in.gdal --o input=$wd'/'$scen'/Range_unfilling/'$sp'_unf.tif' output=$sp'_unf'
	r.in.gdal --o input=$wd'/'$scen'/Range_overfilling/'$sp'_ove.tif' output=$sp'_ove'
	echo "===================== CALCULATE STATISTIC AND SAVE IT AS A .CSV ======="
	r.stats --o -l -c input=$sp'_fil' output=$wd'/'$scen'/Range_filling/'$sp'_fil.csv' sep=,
	r.stats --o -l -c input=$sp'_unf' output=$wd'/'$scen'/Range_unfilling/'$sp'_unf.csv' sep=,
	r.stats --o -l -c input=$sp'_ove' output=$wd'/'$scen'/Range_overfilling/'$sp'_ove.csv' sep=,
	echo "===================== REMOVE FILES ======="
	g.remove -f type=raster name=$sp'_fil',$sp'_unf',$sp'_ove'
	echo "===================== DONE $sp STATISTICS =======" 
	done < /home/biodiversity/tedeschil/grass/List_eu_neozoa.txt # species list 
done < /home/biodiversity/tedeschil/grass/Sensitivity_analysis/scenarios.txt # txt file with the different combinations: 
# median dispersal distance and generation length ("Disp_gen")
# median dispersal distance and age at first reproduction ("Disp_age")
# maximum dispersal distance and generation length ("MaxDisp_gen")
# maximum  dispersal distance and age at first reproduction ("MaxDisp_age")



# - # - # - # - # - # - # - # - # - # - # - # - # - # 
#                                                   #
#                                                   #
#          2. OAR, PAR, POAR NUMBER OF CELLS        #
#                                                   #
#                                                   #
# - # - # - # - # - # - # - # - # - # - # - # - # - # 



## 2. Calculate cell count for OAR, PAR, and POAR (PAR + OAR; without counting the same cell twice and creating a new raster)

echo "===================== SET REGION ======="
g.region -p raster=EU_3035 res=10000 

while read scen;
do
	while read sp;
	do
	echo "===================== LOAD $sp'_OAR' AND $sp'_PAR' =======" 
	r.in.gdal --o input=$wd'/Data/Processed/OAR_3035/'$sp'.tif' output=$sp'_OAR'
	r.in.gdal --o input=$wd'/'$scen'/PAR_3035/PAR/'$sp'.tif' output=$sp'_PAR'
	r.in.gdal --o input=$wd'/'$scen'/PAR_3035/PAR_suit/'$sp'_PAR_suit.tif' output=$sp'_PAR_suit'
	echo "===================== CREATE A NEW MAP WITH BOTH OAR AND PAR ======="
	r.patch --o input=$sp'_OAR',$sp'_PAR_suit' output=$sp'_POAR' # as Predicted Observed Alien Range 
	echo "===================== SAVE THE NEW RASTER ======="	
	r.out.gdal --o input=$sp'_POAR' output=$wd'/'$scen'/POAR_3035/'$sp'_POAR.tif' format=GTiff
	echo "===================== VECTORIZE $sp POAR AND SAVE THE NEW VECTOR ======="
	r.to.vect --o input=$sp'_POAR' output=$sp'_POAR' type=area
	v.db.addcolumn map=$sp'_POAR' layer=1 columns='Binomial VARCHAR' --o
	v.db.update map=$sp'_POAR' layer=1 column=Binomial value=$sp
	v.out.ogr --o input=$sp'_POAR' output=$wd'/'$scen'/POAR_3035/'$sp'_POAR.gpkg' format=GPKG
	echo "===================== CALCULATE STATISTIC AND SAVE IT AS A .CSV ======="
	r.stats --o -l -c input=$sp'_OAR' output=$wd'/Data/Processed/OAR_3035/'$sp'_OAR.csv' sep=,
	r.stats --o -l -c input=$sp'_PAR' output=$wd'/'$scen'/PAR_3035/PAR/'$sp'_PAR.csv' sep=,
	r.stats --o -l -c input=$sp'_PAR_suit' output=$wd'/'$scen'/PAR_3035/PAR_suit/'$sp'_PAR_suit.csv' sep=,
	r.stats --o -l -c input=$sp'_POAR' output=$wd'/'$scen'/POAR_3035/'$sp'_POAR.csv' sep=,
	echo "===================== REMOVE FILES ======="
	g.remove -f type=raster name=$sp'_OAR',$sp'_PAR',$sp'_PAR_suit',$sp'_POAR'
	echo "===================== DONE $sp STATISTICS =======" 
	done < /home/biodiversity/tedeschil/grass/List_eu_neozoa.txt # species list 
done < /home/biodiversity/tedeschil/grass/Sensitivity_analysis/scenarios.txt



# - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # 
#                                                               #
#                                                               #
#       3. RANGE FILLING PATTERNS POLYGONS NUMBER OF CELLS      #
#                                                               #
#                                                               #
# - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # - # 

## v.rast.stats calculates univariate statistics from a raster map based on a vector map and uploads statistics to new attribute columns.
## The output layer attribute table will have as many fields as the unique values of the raster layer that intersects the polygon(s)



## 3.1 Load species' polygons and count the number of cells

echo "===================== SET REGION ======="
g.region -p raster=EU_3035 res=10000 

while read scen;
do
	while read sp;
	do
	echo "===================== LOAD $sp PARs, OARs, POARs, AND RANGE FILLING PATTERNS (VECTOR) FOR $scen ======="
	v.in.ogr --o input=$wd'/Data/Processed/OAR_3035/'$sp'_cleaned.gpkg' output=$sp'_OAR'
	v.in.ogr --o input=$wd'/'$scen'/PAR_3035/PAR_suit/'$sp'_PAR_suit.gpkg' output=$sp'_PAR_suit'
	v.in.ogr --o input=$wd'/'$scen'/POAR_3035/'$sp'_POAR.gpkg' output=$sp'_POAR'
	v.in.ogr --o input=$wd'/'$scen'/Range_filling/'$sp'_fil.gpkg' output=$sp'_fil'
	v.in.ogr --o input=$wd'/'$scen'/Range_overfilling/'$sp'_ove.gpkg' output=$sp'_ove'
	v.in.ogr --o input=$wd'/'$scen'/Range_unfilling/'$sp'_unf.gpkg' output=$sp'_unf'
	echo "===================== LOAD $sp PARs, OARs, POARs, AND RANGE FILLING PATTERN (RASTER) FOR $scen ======="
	r.in.gdal --o input=$wd'/Data/Processed/OAR_3035/'$sp'.tif' output=$sp'_OAR'
	r.in.gdal --o input=$wd'/'$scen'/PAR_3035/PAR_suit/'$sp'_PAR_suit.tif' output=$sp'_PAR_suit'
	r.in.gdal --o input=$wd'/'$scen'/POAR_3035/'$sp'_POAR.tif' output=$sp'_POAR'
	r.in.gdal --o input=$wd'/'$scen'/Range_filling/'$sp'_fil.tif' output=$sp'_fil'
	r.in.gdal --o input=$wd'/'$scen'/Range_overfilling/'$sp'_ove.tif' output=$sp'_ove'
	r.in.gdal --o input=$wd'/'$scen'/Range_unfilling/'$sp'_unf.tif' output=$sp'_unf'
	echo "===================== CALCULATE $sp CELL NUMBER FOR $scen ======="
	v.rast.stats -c -d map=$sp'_OAR' raster=$sp'_OAR' column_prefix=cells method=number
	v.rast.stats -c -d map=$sp'_PAR_suit' raster=$sp'_PAR_suit' column_prefix=cells method=number
	v.rast.stats -c -d map=$sp'_POAR' raster=$sp'_POAR' column_prefix=cells method=number
	v.rast.stats -c -d map=$sp'_fil' raster=$sp'_fil' column_prefix=cells method=number
	v.rast.stats -c -d map=$sp'_ove' raster=$sp'_ove' column_prefix=cells method=number
	v.rast.stats -c -d map=$sp'_unf' raster=$sp'_unf' column_prefix=cells method=number
	echo "===================== EXPORT $sp ATTRIBUTE TABLE FOR $scen ======="
	db.out.ogr --o input=$sp'_OAR' output=$wd'/'$scen'/Variables/Variables_stats/Polygons_cells_no/OAR_3035/'$sp'_OAR.csv' format=CSV
	db.out.ogr --o input=$sp'_PAR_suit' output=$wd'/'$scen'/Variables/Variables_stats/Polygons_cells_no/PAR_3035/PAR_suit/'$sp'_PAR_suit.csv' format=CSV
	db.out.ogr --o input=$sp'_POAR' output=$wd'/'$scen'/Variables/Variables_stats/Polygons_cells_no/POAR_3035/'$sp'_POAR.csv' format=CSV
	db.out.ogr --o input=$sp'_fil' output=$wd'/'$scen'/Variables/Variables_stats/Polygons_cells_no/Range_filling/'$sp'_fil.csv' format=CSV
	db.out.ogr --o input=$sp'_ove' output=$wd'/'$scen'/Variables/Variables_stats/Polygons_cells_no/Range_overfilling/'$sp'_ove.csv' format=CSV
	db.out.ogr --o input=$sp'_unf' output=$wd'/'$scen'/Variables/Variables_stats/Polygons_cells_no/Range_unfilling/'$sp'_unf.csv' format=CSV
	echo "===================== CLEAN $sp ======="
	g.remove -f type=raster,vector pattern=$sp i=EU_3035
	done < /home/biodiversity/tedeschil/grass/List_eu_neozoa.txt # species list 
done < /home/biodiversity/tedeschil/grass/Sensitivity_analysis/scenarios.txt

# to check if the column has been added
db.columns table=Ammotragus_lervia_ove



## 3.2. Clean

g.remove -f type=raster,vector pattern=* i=EU_3035

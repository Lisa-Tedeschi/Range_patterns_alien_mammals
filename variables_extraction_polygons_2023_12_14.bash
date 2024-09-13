#################################################################
############# VARIABLES EXTRACTION AT A POLYGON LEVEL ###########
#################################################################

# started on 14.12.2023
# modified on 08.04.2024 
# by LT
# for the paper "Patterns and drivers of range filling of alien mammals in Europe"

# this is a GRASS script to obtain the average value of the socio-economic factors across range filing patterns rasters
# divided by polygons
# because each range filling patterns polygon has a unique ID under the FID and cat fields
# all of this based on the ranges created with the biomod binary outputs 
# for different combinations of dispersal (median and max) and reproduction (generation length and age at first reproduction)


#grass /home/biodiversity/tedeschil/grass/3035/PERMANENT
#g.mapset mapset=PERMANENT location=3035
wd=/home/biodiversity/tedeschil/grass/Sensitivity_analysis


# - # - # - # - # - # - # - # - # - # - # - # - # 
#                                               #
#                                               #
#                1. LOAD THE DATA               #
#                                               #
#                                               #
# - # - # - # - # - # - # - # - # - # - # - # - #


## 1.1 Load filling patterns polygons and socio-economic factors  

echo "===================== SET REGION ======="
g.region -p raster=EU_3035 res=10000 

while read var;
do
echo "===================== LOAD $var ======="
r.in.gdal --o input=$wd'/Data/Processed/Variables/'$var'_3035.tif' output=$var'_3035'
done < /home/biodiversity/tedeschil/grass/Sensitivity_analysis/Data/Processed/Variables/variables_final.txt # variables list 

while read scen;
do
	while read sp;
	do
	echo "===================== LOAD $sp RANGE FILLING PATTERN FOR $scen ======="
	v.in.ogr --o input=$wd'/'$scen'/Range_filling/'$sp'_fil.gpkg' output=$sp'_'$scen'_fil'
	v.in.ogr --o input=$wd'/'$scen'/Range_overfilling/'$sp'_ove.gpkg' output=$sp'_'$scen'_ove'
	v.in.ogr --o input=$wd'/'$scen'/Range_unfilling/'$sp'_unf.gpkg' output=$sp'_'$scen'_unf'
	done < /home/biodiversity/tedeschil/grass/List_eu_neozoa.txt # species list 
done < /home/biodiversity/tedeschil/grass/Sensitivity_analysis/scenarios.txt # txt file with the different combinations: 
# median dispersal distance and generation length ("Disp_gen")
# median dispersal distance and age at first reproduction ("Disp_age")
# maximum dispersal distance and generation length ("MaxDisp_gen")
# maximum  dispersal distance and age at first reproduction ("MaxDisp_age")



# - # - # - # - # - # - # - # - # - # - # - # - # 
#                                               #
#                                               #
#            2. EXTRACT THE VALUES              #
#                                               #
#                                               #
# - # - # - # - # - # - # - # - # - # - # - # - #


## 2.1 Extract value of var for each polygon 

# for each scenario 
while read scen;
do 
	# read the species
	while read sp;
	do
		# read the socio-economic factor and calculate its average value across the polygons
		# NB this adds, to the attribute table of each $sp filling pattern, a column called $var'_3035'
		# but it's always on the same attribute table, this is why I export the tables outside the while read var loop
		while read var;
		do
		echo "===================== EXTRACT $sp VALUE FOR $var IN $scen ======="
		v.rast.stats -c map=$sp'_'$scen'_fil' raster=$var'_3035' column_prefix=$var'_3035' method=average
		v.rast.stats -c map=$sp'_'$scen'_ove' raster=$var'_3035' column_prefix=$var'_3035' method=average
		v.rast.stats -c map=$sp'_'$scen'_unf' raster=$var'_3035' column_prefix=$var'_3035' method=average
		done < /home/biodiversity/tedeschil/grass/Sensitivity_analysis/Data/Processed/Variables/variables_final.txt # variables list 
  
	echo "===================== EXPORT $sp ATTRIBUTE TABLE ======="
	db.out.ogr --o input=$sp'_'$scen'_fil' output=$wd'/'$scen'/Variables/Variables_stats/Polygons/Range_filling/'$sp'_fil.csv' format=CSV
	db.out.ogr --o input=$sp'_'$scen'_ove' output=$wd'/'$scen'/Variables/Variables_stats/Polygons/Range_overfilling/'$sp'_ove.csv' format=CSV
	db.out.ogr --o input=$sp'_'$scen'_unf' output=$wd'/'$scen'/Variables/Variables_stats/Polygons/Range_unfilling/'$sp'_unf.csv' format=CSV
	done < /home/biodiversity/tedeschil/grass/List_eu_neozoa.txt # species list 

done < /home/biodiversity/tedeschil/grass/Sensitivity_analysis/scenarios.txt 

## 2.2 Clean

g.remove -f type=raster,vector pattern=* i=EU_3035










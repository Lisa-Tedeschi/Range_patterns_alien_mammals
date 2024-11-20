####################################################
########## AGGREGATE A BIOCLIMATIC RASTER ##########
####################################################

# Started on 25.01.2023
# modified on 03.04.2024
# for the paper "Patterns and drivers of range filling of alien mammals in Europe"

# This is a script to aggregate an (updated) Chelsa raster from a finer to coarser resolution in GRASS GIS

#grass /home/biodiversity/grass/3035/PERMANENT
#g.mapset mapset=PERMANENT location=3035
wd=/home/biodiversity/grass/Sensitivity_analysis

for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19
do
echo "===================== IMPORT CHELSA BIOCLIMATIC VARIABLE bio$i =======" 
r.in.gdal --o input=$wd'/Data/Processed/Chelsa/Updated_1km/CHELSA_bio'$i'_1981.2010_V.2.1.tif' output='bio'$i # note the point in 1981.2010, as R didn't save the - 
echo "===================== SET NEW RESOLUTION ======="
g.region -p res=0.1 raster='bio'$i
echo "===================== AGGREGATE CHELSA bio$i TO NEW RESOLUTION ======="
r.resamp.stats --o -w input='bio'$i output='bio'$i'_10km'
echo "===================== SAVE NEW AGGREGATED bio$i_10km ======="
r.out.gdal --o input='bio'$i'_10km' output=$wd'/Data/Processed/Chelsa/Aggregated_10km/CHELSA_bio'$i'_1981-2010_V.2.1_10km.tif'
echo "===================== REMOVE RASTERS ======="
g.remove -f type=raster pattern=bio*
done 

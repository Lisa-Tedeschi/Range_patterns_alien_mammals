####################################################
############# ROADS, RAILWAYS VARIABLES ###########
###################################################

# started on 20.06.2023
# modified on 04.05.2024
# for the paper "Patterns and drivers of range filling of alien mammals in Europe"

# this is a loop to load the variables Roads and Railways
# extracted from Williams et al 2020 ()
# crop and reproject them to Europe 

#grass /home/biodiversity/grass/3035/PERMANENT
#grass /home/biodiversity/grass/4326/PERMANENT 
#g.mapset mapset=PERMANENT location=3035
wd=/home/biodiversity/grass/Sensitivity_analysis/Data



# - # - # - # - # - # - # - # - # - # - # - # - # 
#                                               #
#                                               #
#                1. LOAD THE DATA               #
#                                               #
#                                               #
# - # - # - # - # - # - # - # - # - # - # - # - #

# to check for the projection of a raster map before importing, use gdalinfo /path/file.tif

gdalinfo $wd'/Original/Variables/HumanFootprint/roads_hfp.tif'
gdalinfo $wd'/Original/Variables/HumanFootprint/railways_hfp.tif'
# CRS is Mollweide, resolution is 1000x1000



## 1.1 Reproject to WGS84, and load

gdalwarp -overwrite -t_srs EPSG:4326 -tr 0.1 0.1 $wd'/Original/Variables/HumanFootprint/roads_hfp.tif' $wd'/Processed/Variables/roads_WGS84.tif'
gdalwarp -overwrite -t_srs EPSG:4326 -tr 0.1 0.1 $wd'/Original/Variables/HumanFootprint/railways_hfp.tif' $wd'/Processed/Variables/railways_WGS84.tif'

# load 

grass /home/biodiversity/tedeschil/grass/4326/PERMANENT 

g.region -p res=0.1

r.in.gdal --o input=$wd'/Processed/Variables/roads_WGS84.tif' output=roads_WGS84
r.in.gdal --o input=$wd'/Processed/Variables/railways_WGS84.tif' output=railways_WGS84

# N.B.: after reprojection to LAEA3035, come back here and DELETE these rasters!!!

g.remove -f type=raster pattern=ro*,ra*,nav*



####################### RUN IN Europe3035 LOCATION 

## 1.2 Reproject to LAEA 3035

g.mapset mapset=PERMANENT location=3035
g.region -p raster=EU_3035 res=10000 # NB resolution is 10 x 10 km 

while read var;
do
echo "===================== CREATE A MASK OF EU, CROP AND REPROJECT VARIABLE $var TO LAEA3035, AND SAVE THE NEW RASTER ======="
r.mask --o raster=EU_3035
r.proj --o location=4326 mapset=PERMANENT input=$var'_WGS84' output=$var'_3035'
r.out.gdal --o input=$var'_3035' output=$wd'/Processed/Variables/'$var'Avg_3035.tif'
echo "===================== REMOVE MASK AND RASTER ======="
r.mask -r
#g.remove -f type=raster name=$var'_3035'
done < $wd'/Processed/Variables/HumanFootprint/roads_railways_waterways_names.txt' # txt file with roads,railways

# all this works but not for railways
# what doesn't work is the cropping to europe using the mask, nor in GRASS neither in QGIS GRASS with r.mask.rast

# the gdalwarp reprojection from WGS84 to 3035 "cuts" the file off (it looks like a band), but the one from Mollweide to 3035 works 

gdalwarp -overwrite -t_srs EPSG:3035 -tr 10000 10000 $wd'/Processed/Variables/railways_hfp.tif' $wd'/Processed/Variables/railways_3035.tif' 
gdalwarp -overwrite -t_srs EPSG:3035 -tr 10000 10000 -of GTiff -cutline $wd'/EU_3035.shp' -crop_to_cutline $wd'/Processed/Variables/railways_3035.tif' $wd'/Processed/Variables/railwaysAvg_3035_crop.tif'







#############################################
########## LAND-USE HYDE VARIABLES ##########
#############################################

# started on 06.07.2023
# modified on 04.05.2024
# for the paper "Patterns and drivers of range filling of alien mammals in Europe"

# this is a loop to load the land use variables from HYDE, crop and reproject them to Europe

#grass /home/biodiversity/grass/3035/PERMANENT
#grass /home/biodiversity/grass/4326/PERMANENT 
#g.mapset mapset=PERMANENT location=3035
wd=/home/biodiversity/grass/Sensitivity_analysis/Data

# in HYDE dataset  
# uopp = urban area, in km2/gridcell
# crop = cropland area, in km2/gridcell
# gras = pasture area, in km2/gridcell



# - # - # - # - # - # - # - # - # - # 
#                                   #
#                                   #
#             1. LAND-USE           #
#                                   #
#                                   #
# - # - # - # - # - # - # - # - # - # 



## 1.1 Check info for land-use rasters for 1980-2005

# first check the projection 

gdalinfo $wd/Original/Variables/HYDE/hyde31_final/crop1980AD.asc
# resolution is 1 km x 1 km (30", 0.01*) - NB Need to be resampled!



## 1.2 Load land-use raster 1980-2005 in WGS84 and resample to 10 x 10 km 

####################### RUN IN WGS84

g.mapset mapset=PERMANENT location=4326
g.region -p res=0.1 

for y in 1980 1990 2000 2005
do
echo "===================== RESAMPLE LAND USE DATA FOR $y AT 10 X 10 KM AND LOAD ======="
gdalwarp -t_srs EPSG:4326 -tr 0.1 0.1 $wd'/Original/Variables/HYDE/hyde31_final/uopp_'$y'AD.asc' $wd'/Processed/Variables/uopp'$y'.tif' -overwrite
gdalwarp -t_srs EPSG:4326 -tr 0.1 0.1 $wd'/Original/Variables/HYDE/hyde31_final/gras'$y'AD.asc' $wd'/Processed/Variables/gras'$y'.tif' -overwrite
gdalwarp -t_srs EPSG:4326 -tr 0.1 0.1 $wd'/Original/Variables/HYDE/hyde31_final/crop'$y'AD.asc' $wd'/Processed/Variables/crop'$y'.tif' -overwrite
r.in.gdal --o input=$wd'/Processed/Variables/uopp'$y'.tif' output='uopp'$y
r.in.gdal --o input=$wd'/Processed/Variables/gras'$y'.tif' output='gras'$y
r.in.gdal --o input=$wd'/Processed/Variables/crop'$y'.tif' output='crop'$y
done

# N.B.: after reprojection to LAEA3035, come back here and DELETE these rasters!!!

g.remove -f type=raster pattern=* i=world

####################### RUN IN 3035 

g.mapset mapset=PERMANENT location=3035
g.region -p raster=EU_3035 res=10000 # NB resolution is 10 x 10 km 

for y in 1980 1990 2000 2005;
do
echo "===================== CREATE A MASK OF EU, CROP AND REPROJECT LAND-USE $y TO LAEA3035, AND SAVE THE NEW RASTER ======="
r.mask --o raster=EU_3035
r.proj --o location=4326 mapset=PERMANENT input='uopp'$y output='uopp'$y'_3035'
r.proj --o location=4326 mapset=PERMANENT input='gras'$y output='gras'$y'_3035'
r.proj --o location=4326 mapset=PERMANENT input='crop'$y output='crop'$y'_3035'
r.out.gdal --o input='uopp'$y'_3035' output=$wd'/Processed/Variables/uopp'$y'_3035.tif'
r.out.gdal --o input='gras'$y'_3035' output=$wd'/Processed/Variables/gras'$y'_3035.tif'
r.out.gdal --o input='crop'$y'_3035' output=$wd'/Processed/Variables/crop'$y'_3035.tif'
echo "===================== REMOVE MASK ======="
r.mask -r
done



## 1.3 Create a new unique land-use raster with the average of the years

g.region -p raster=EU_3035 res=10000 

# if not loaded, load with
for y in 1980 1990 2000 2005;
do
r.in.gdal --o input=$wd'/Processed/Variables/uopp'$y'_3035.tif' output='uopp'$y'_3035'
r.in.gdal --o input=$wd'/Processed/Variables/gras'$y'_3035.tif' output='gras'$y'_3035'
r.in.gdal --o input=$wd'/Processed/Variables/crop'$y'_3035.tif' output='crop'$y'_3035'
done

# average the rasters in Europe
r.series input=`g.list type=raster pattern=uopp* mapset=. separator=,` output=uoppAvg_3035 method=average --o
r.series input=`g.list type=raster pattern=gras* mapset=. separator=,` output=grasAvg_3035 method=average --o
r.series input=`g.list type=raster pattern=crop* mapset=. separator=,` output=cropAvg_3035 method=average --o
r.out.gdal --o input=uoppAvg_3035 output=$wd'/Processed/Variables/uoppAvg_3035.tif'
r.out.gdal --o input=grasAvg_3035 output=$wd'/Processed/Variables/grasAvg_3035.tif'
r.out.gdal --o input=cropAvg_3035 output=$wd'/Processed/Variables/cropHAvg_3035.tif' # the H is for HYDE and is to distinguish from the other crop 

# sum the rasters
r.series --o input=grasAvg_3035,cropHAvg_3035,uoppAvg_3035 output=landuseHAvg_3035 method=sum
r.out.gdal --o input=landuseHAvg_3035 output=$wd'/Processed/Variables/landuseHAvg_3035.tif'

g.remove -f type=raster pattern=* i=EU_3035



## 1.4 Recrop the file 

gdalwarp -overwrite -t_srs EPSG:3035 -tr 10000 10000 -of GTiff -cutline $wd'/EU_3035.shp' -crop_to_cutline $wd'/Processed/Variables/landuseHAvg_3035.tif' $wd'/Processed/Variables/landuseHAvg_3035_crop.tif'



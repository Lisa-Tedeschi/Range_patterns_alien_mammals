###############################################
########## POPULATION HYDE VARIABLES ##########
################################################

# started on 23.06.2023
# modified on 04.05.2024
# for the paper "Patterns and drivers of range filling of alien mammals in Europe"

# this is a loop to load the HYDE variables Population density, crop and reproject to Europe

#grass /home/biodiversity/grass/3035/PERMANENT
#grass /home/biodiversity/grass/4326/PERMANENT 
#g.mapset mapset=PERMANENT location=3035
wd=/home/biodiversity/grass/Sensitivity_analysis/Data

# in HYDE dataset  
# popc = population counts, in inhabitants/gridcell
# popd = population density, in inhabitants/km2 per gridcell. Calculated with gridarea.asc
# rurc = rural population counts, in inh/gridcell
# urbc = urban population counts, in inh/gridcell
# uopp = urban area, in km2/gridcell



# - # - # - # - # - # - # - # - # - # - # - # - # 
#                                               #
#                                               #
#            1. POPULATION DENSITY              #
#                                               #
#                                               #
# - # - # - # - # - # - # - # - # - # - # - # - #



## 1.1 Check info for Population density rasters for 1980-2015

# first check the projection 

gdalinfo $wd'/Original/Variables/HYDE/Human_population_HYDE/Density/popd_1980AD.asc'
# resolution is 1 km x 1 km (30", 0.01°) - NB Need to be resampled!



## 1.2 Load population density raster 1980-2005 in WGS84 and resample to 10 x 10 km 

####################### RUN IN WGS84

g.mapset mapset=PERMANENT location=4326
g.region -p res=0.1

for y in 1980 1990 2000 2005
do
echo "===================== RESAMPLE POPULATION DENSITY DATA FOR $y AT 10 X 10 KM AND LOAD ======="
gdalwarp -t_srs EPSG:4326 -tr 0.1 0.1 $wd'/Original/Variables/HYDE/Human_population_HYDE/Density/popd_'$y'AD.asc' $wd'/Processed/Variables/Popdensity'$y'.tif' -overwrite
g.region -p res=0.1 
r.in.gdal --o input=$wd'/Processed/Variables/Popdensity'$y'.tif' output='Popdensity'$y
done

# N.B.: after reprojection to LAEA3035, come back here and DELETE these rasters!!!

g.remove -f type=raster pattern=Popdensity*

####################### RUN IN 3035 

g.mapset mapset=PERMANENT location=3035
g.region -p raster=EU_3035 res=10000 # NB resolution is 10 x 10 km 

for y in 1980 1990 2000 2005;
do
echo "===================== CREATE A MASK OF EU, CROP AND REPROJECT POPULATION DENSITY $y TO LAEA3035, AND SAVE THE NEW RASTER ======="
r.mask --o raster=EU_3035
r.proj --o location=4326 mapset=PERMANENT input='Popdensity'$y output='Popdensity'$y'_3035'
r.out.gdal --o input='Popdensity'$y'_3035' output=$wd'/Processed/Variables/Popdensity'$y'_3035.tif'
echo "===================== REMOVE MASK AND RASTER ======="
r.mask -r
done



## 1.3. Create a new unique population density raster with the average of the years

g.region -p raster=EU_3035 res=10000 

r.series input=`g.list type=raster pattern=Popdensity* mapset=. separator=,` output=PopdensityAvg_3035 method=average --o
r.out.gdal --o input=PopdensityAvg_3035 output=$wd'/Processed/Variables/PopdensityAvg_3035.tif'
g.remove -f type=raster pattern=Popdensity* i=PopdensityAvg_3035 



## 1.4 Recrop the file 

# the file look strangely cropped to EU

gdalwarp -overwrite -t_srs EPSG:3035 -tr 10000 10000 -of GTiff -cutline $wd'/EU_3035.shp' -crop_to_cutline $wd'/Processed/Variables/PopdensityAvg_3035.tif' $wd'/Processed/Variables/PopdensityAvg_3035_crop.tif'

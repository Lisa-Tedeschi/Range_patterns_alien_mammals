############################################################################
########## CALCULATING DISTANCE OF A POINT TO THE NEAREST POLYGON ##########
############################################################################

# Started on 21.12.2022
# modified on 03.04.2024 by LT
# by LT, based on Appendix S1 of Ficetola et al. 2015 (https://onlinelibrary.wiley.com/action/downloadSupplement?doi=10.1111%2Fjbi.12206&file=jbi12206-sup-0001-AppendixS1-corrected.txt)
# for the paper "Patterns and drivers of range filling of alien mammals in Europe" 

#% DESCRIPTION: GRASS script to calculate the distance of points in shapefiles
#% (e.g., species presence localities) from the edge of a polygon shapefiles
#% (e.g., species range). It also provides information on whether the points
#% are inside or outside the polygons.

#% DETAILS
#% Presence points are shapefile in GRASS.
#% For each species, the point shapefile is named [speciesname_p]
#% Species ranges are polygon shapefiles in GRASS.
#% For each species, the range shapefile is named [speciesname]
#% All shapefiles are in the same mapset [mapsetname];
#% the mapset should be in decimal degrees, wgs84.
#% An additional text file [list.txt] is the list of names of all species
#% for which the analysis will be performed
#%
#% THE STEPS OF THE SCRIPT
#% 
#% 1) For each species, the script creates a table that is named [speciesname].
#%    The table includes two empty columns (dist, outside)
#% 2) In the column dist, the script writes the distance of a point from the
#%    edge of the range
#% 3) In the column outside, a cell has value zero if the point is inside
#%    the range.
#% 4) The table is then exported as a file named [speciesname].csv
#############################################################################

# Lama glama and Ovis gmelini are named differently in IUCN, DAMA and GBIF 
# IUCN has Lama glama, Ovis orientalis
# DAMA has Lama guanicoe, Ovis gmelini 
# GBIF has Lama glama, Ovis orientalis 
# rename them accordingly before running the script 

# v.distance finds the nearest element in vector map 'to' for elements in vector map 'from'
# upload=dist adds the minimum distance to nearest feature
# in the column "dist", the distance of the point from the nearest polygon border is indicated
# in lat-long locations (as this), v.distance gives distances (dist) in meters (not degrees!), calculated as geodesic distances on a sphere
# irrespectively if the point is inside or outside the polygon (this is why you can have a 0 in "darea" but an integer in "dist" - it means the point is inside the polygon, and it says how far it is from the border)
# in the column "outside", somthing else is indicated
# in the column "darea", if there is a 0, the point is inside the polygon
# otherwise, the value should be the same as in the column "dist"

# NB: the DAMA .shp need to be adjusted to be read in GRASS (i.e., change "Order" column name, and so on) 

#grass /home/biodiversity/tedeschil/grass/4326/PERMANENT 
#g.mapset mapset=PERMANENT location=4326
wd=/home/biodiversity/tedeschil/grass/Sensitivity_analysis


## Spatial intersection analysis for a single set of polygons containing both IUCN and DAMA, with the addition of the category of the polygon

# little trick: it will write the species' common name into areacat column if the point is closer to dama, otherwise (empty) it will be closer to iucn 

echo "===================== SET REGION =======" 
g.region -p res=0.1 vector=world

while read sp;
do
echo "===================== LOAD RANGE FOR $sp =======" 
v.in.ogr -r input=$wd'/Data/Processed/Range_shp/'$sp'.gpkg' output=$sp --o 
echo "===================== CLEAN RANGE FOR $sp =======" 
v.clean -c --o input=$sp output=$sp'_clean' tool=snap threshold=1e-13
echo "===================== LOAD OCCURRENCE POINTS FOR $sp =======" 
v.in.ogr -r input=$wd'/Data/Processed/occ_data/Aggregated_shp/'$sp'.gpkg' output=$sp'_1981_2022_p' --o 
j=$sp'_1981_2022_p'
echo "===================== ADD COLUMNS IN THE ATTRIBUTE TABLE FOR $sp ======="  
v.db.addcolumn map=$j layer=1 columns='dist INT,darea INT,areacat VARCHAR(250)' --o
echo "===================== CALCULATE DISTANCE FROM POINTS TO RANGE POLYGONS FOR $sp AND REPORT IF EACH OCCURRENCE IS INSIDE THE POLYGON =======" 
v.distance --o from=$j to=$sp'_clean' from_layer=1 to_type=boundary,area upload=dist,dist column=dist,darea
echo "===================== WRITE POLYGON ID INTO AREACAT COLUMN =======" 
v.distance --o from=$j to=$sp'_clean' upload=to_attr column=areacat to_column=x_CommonName
echo "===================== EXPORT ATTRIBUTE TABLE FOR $sp =======" 
# NB: if there is already a $sp folder in /Distances/IUCN/, it will not work (not even with --o)
db.out.ogr --o --verbose input=$j output=$wd'/Data/Processed/Distances/Distances_aggregated_1981_2022_categories/'$sp format=CSV 
echo "===================== REMOVE FILES =======" 
g.remove -f type=vector pattern=$sp*
done < /home/biodiversity/tedeschil/grass/Sensitivity_analysis/Data/Processed/List_eu.txt

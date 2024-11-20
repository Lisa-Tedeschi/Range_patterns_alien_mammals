############################################
############ FILLING PATTERNS ##############
############################################

# created on 08.03.2023
# modified on 04.04.2024 
# for the paper "Patterns and drivers of range filling of alien mammals in Europe"

# this is a GRASS GIS script to create rasters of:
# range filling (areas occupied both in the observed and potential alien ranges)
# range overfilling (areas occupied only in the observed alien ranges)
# range unfilling (areas occupied only in the potential alien ranges)
# and vectorize them 
# for different combinations of dispersal (median and max) and reproduction (generation length and age at first reproduction)

#grass /home/biodiversity/grass/3035/PERMANENT
#g.mapset mapset=PERMANENT location=3035
wd=/home/biodiversity/grass/Sensitivity_analysis



# - # - # - # - # - # - # - # - # - # - # 
#                                       #
#                                       #
#           1. RANGE FILLING            #
#                                       #
#                                       #
# - # - # - # - # - # - # - # - # - # - # 

echo "===================== SET REGION =======" 
g.region -p raster=EU_3035 res=10000 

while read scen;
do
	while read sp;
	do
	echo "===================== LOAD $sp_PAR_suit RASTER =======" 
	r.in.gdal --o input=$wd'/'$scen'/PAR_3035/PAR_suit/'$sp'_PAR_suit.tif' output=$sp'_PAR_suit'
	echo "===================== MASK ======="
	r.mask --o raster=$sp'_PAR_suit'
	echo "===================== LOAD $sp OAR RASTER =======" 
	r.in.gdal --o input=$wd'/Data/Processed/OAR_3035/'$sp'.tif' output=$sp'_OAR'
	echo "===================== SAVE OVERLAPPING RASTER ======="
	r.out.gdal --o input=$sp'_OAR' output=$wd'/'$scen'/Range_filling/'$sp'_fil.tif' format=GTiff
	echo "===================== REMOVE FILES ======="
	r.mask -r
	g.remove -f type=raster name=$sp'_PAR_suit',$sp'_OAR'
	done < /home/biodiversity/grass/List_eu_neozoa.txt # species list 
done < /home/biodiversity/grass/Sensitivity_analysis/scenarios.txt # txt file with the different combinations: 
# median dispersal distance and generation length ("Disp_gen")
# median dispersal distance and age at first reproduction ("Disp_age")
# maximum dispersal distance and generation length ("MaxDisp_gen")
# maximum  dispersal distance and age at first reproduction ("MaxDisp_age")



# - # - # - # - # - # - # - # - # - # - # 
#                                       #
#                                       #
#         2. RANGE OVERFILLING          #
#                                       #
#                                       #
# - # - # - # - # - # - # - # - # - # - # 

echo "===================== SET REGION =======" 
g.region -p raster=EU_3035 res=10000 

while read scen;
do
	while read sp;
	do
	echo "===================== LOAD $sp_PAR_suit RASTER =======" 
	r.in.gdal --o input=$wd'/'$scen'/PAR_3035/PAR_suit/'$sp'_PAR_suit.tif' output=$sp'_PAR_suit'
	echo "===================== LOAD $sp OAR RASTER =======" 
	r.in.gdal --o input=$wd'/Data/Processed/OAR_3035/'$sp'.tif' output=$sp'_OAR'
	echo "===================== OBTAIN $sp REVERSE MASK - PAR_suit CELLS ARE ZERO ======="
	r.mask --o -i raster=$sp'_PAR_suit' 
	echo "===================== CLIP THE MASK ON EU ======="
	r.mapcalc --o "${sp}_mask = EU_3035"
	echo "===================== CLIP $sp_OAR TO $sp_PAR_suit USING THE MASK =======" 
	r.mask --o raster=$sp'_mask'
	r.mapcalc --o "${sp}_ove = ${sp}_OAR"
	echo "===================== SAVE $sp_ove RASTER ======="
	r.out.gdal --o input=$sp'_OAR' output=$wd'/'$scen'/Range_overfilling/'$sp'_ove.tif' format=GTiff
	echo "===================== REMOVE MASK AND $sp_PAR_suit =======" 
	r.mask -r
	g.remove -f type=raster name=$sp'_PAR_suit',$sp'_OAR',$sp'_ove',$sp'_mask'
	done < /home/biodiversity/grass/List_eu_neozoa.txt
done < /home/biodiversity/grass/Sensitivity_analysis/scenarios.txt



# - # - # - # - # - # - # - # - # - # - # 
#                                       #
#                                       #
#          3. RANGE UNFILLING           #
#                                       #
#                                       #
# - # - # - # - # - # - # - # - # - # - # 

echo "===================== SET REGION =======" 
g.region -p raster=EU_3035 res=10000 

while read scen;
do
	while read sp;
	do
	echo "===================== LOAD $sp_PAR_suit RASTER =======" 
	r.in.gdal --o input=$wd'/'$scen'/PAR_3035/PAR_suit/'$sp'_PAR_suit.tif' output=$sp'_PAR_suit'
	echo "===================== LOAD $sp OAR RASTER =======" 
	r.in.gdal --o input=$wd'/Data/Processed/OAR_3035/'$sp'.tif' output=$sp'_OAR'
	echo "===================== OBTAIN $sp REVERSE MASK - OAR CELLS ARE ZERO ======="
	r.mask --o -i raster=$sp'_OAR' 
	echo "===================== CLIP THE MASK ON EU ======="
	r.mapcalc --o "${sp}_mask = EU_3035"
	echo "===================== CLIP $sp_PAR_suit TO $sp_OAR USING THE MASK =======" 
	r.mask --o raster=$sp'_mask'
	r.mapcalc --o "${sp}_unf = ${sp}_PAR_suit"
	echo "===================== SAVE $sp_unf RASTER ======="
	r.out.gdal --o input=$sp'_unf' output=$wd'/'$scen'/Range_unfilling/'$sp'_unf.tif' format=GTiff
	echo "===================== REMOVE MASK AND $sp_PAR_suit =======" 
	r.mask -r
	g.remove -f type=raster name=$sp'_PAR_suit',$sp'_OAR',$sp'_unf',$sp'_mask'
	done < /home/biodiversity/grass/List_eu_neozoa.txt
done < /home/biodiversity/grass/Sensitivity_analysis/scenarios.txt



# - # - # - # - # - # - # - # - # - # - # 
#                                       #
#                                       #
#           4. VECTORIZATION            #
#                                       #
#                                       #
# - # - # - # - # - # - # - # - # - # - #

echo "===================== SET REGION ======="
g.region -p raster=EU_3035 res=10000 

while read scen;
do
	while read sp;
	do
	echo "===================== LOAD $sp_fil, $sp_unf, $sp_ove =======" 
	r.in.gdal --o input=$wd'/'$scen'/Range_filling/'$sp'_fil.tif' output=$sp'_fil'
	r.in.gdal --o input=$wd'/'$scen'/Range_unfilling/'$sp'_unf.tif' output=$sp'_unf'
	r.in.gdal --o input=$wd'/'$scen'/Range_overfilling/'$sp'_ove.tif' output=$sp'_ove'	
	echo "===================== VECTORIZE =======" 
	r.to.vect --o input=$sp'_fil' output=$sp'_fil' type=area
	r.to.vect --o input=$sp'_unf' output=$sp'_unf' type=area
	r.to.vect --o input=$sp'_ove' output=$sp'_ove' type=area
	echo "===================== ADD AND UPDATE COLUMN IN THE ATTRIBUTE TABLE ======="
	v.db.addcolumn map=$sp'_fil' layer=1 columns='Binomial VARCHAR' --o
	v.db.update map=$sp'_fil' layer=1 column=Binomial value=$sp
	v.db.addcolumn map=$sp'_unf' layer=1 columns='Binomial VARCHAR' --o
	v.db.update map=$sp'_unf' layer=1 column=Binomial value=$sp
	v.db.addcolumn map=$sp'_ove' layer=1 columns='Binomial VARCHAR' --o
	v.db.update map=$sp'_ove' layer=1 column=Binomial value=$sp
	echo "===================== SAVE VECTOR ======="
	v.out.ogr --o input=$sp'_fil' output=$wd'/'$scen'/Range_filling/'$sp'_fil.gpkg' format=GPKG
	v.out.ogr --o input=$sp'_unf' output=$wd'/'$scen'/Range_unfilling/'$sp'_unf.gpkg' format=GPKG
	v.out.ogr --o input=$sp'_ove' output=$wd'/'$scen'/Range_overfilling/'$sp'_ove.gpkg' format=GPKG
	echo "===================== REMOVE FILES ======="
	g.remove -f type=vector,raster name=$sp'_fil',$sp'_unf',$sp'_ove'
	done < /home/biodiversity/grass/List_eu_neozoa.txt
done < /home/biodiversity/grass/Sensitivity_analysis/scenarios.txt




 


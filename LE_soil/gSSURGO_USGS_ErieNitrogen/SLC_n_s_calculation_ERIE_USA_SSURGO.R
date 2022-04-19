
# DOWNLOAD REQUIRED LIBRARIES AND LOAD THEM XXXXXXXXXXXXXXXXXXXXXXX
library(foreign)
library(rgdal)
library(sf)
library(readxl)
library(ggplot2)
library(writexl)
library(ggplot2)
library(tidyverse)
library(raster)

#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

# SET ANY DIRECTORIES XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
SourceDir = "C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/LE_soil/gSSURGO_USGS_ErieNitrogen"
OutputDir = "C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/LE_soil/gSSURGO_USGS_ErieNitrogen/Outputs"

RawInput_IN = "C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/LE_soil/gSSURGO_USGS_ErieNitrogen/wss_gsmsoil_IN_[2016-10-13]/spatial"
RawInput_MI = "C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/LE_soil/gSSURGO_USGS_ErieNitrogen/wss_gsmsoil_MI_[2016-10-13]/spatial"
RawInput_NY = "C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/LE_soil/gSSURGO_USGS_ErieNitrogen/wss_gsmsoil_NY_[2016-10-13]/spatial"
RawInput_OH = "C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/LE_soil/gSSURGO_USGS_ErieNitrogen/wss_gsmsoil_OH_[2016-10-13]/spatial"
RawInput_PA = "C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/LE_soil/gSSURGO_USGS_ErieNitrogen/wss_gsmsoil_PA_[2016-10-13]/spatial"
RawSoilTable = "C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/LE_soil/gSSURGO_USGS_ErieNitrogen/Layer"
  
WshdShapefileDir = "C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/LE_Watershed_shapefiles/LE_ELEMENT_N/Reformatted"
WholeWshdShapefileFir = "C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/Shapefile"

#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

# LOAD IN THE SOIL POLYGONES

# each polygon will have it's soil mukey identified and then we'll 
# use the USGS data which has averaged characteristics for each mukey over the soil layers 

setwd(RawInput_IN)
SOIL_poly_IN = st_read('gsmsoilmu_a_in.shp')
head(SOIL_poly_IN)
setwd(RawInput_MI)
SOIL_poly_MI = st_read('gsmsoilmu_a_mi.shp')
head(SOIL_poly_MI)
setwd(RawInput_NY)
SOIL_poly_NY = st_read('gsmsoilmu_a_ny.shp')
head(SOIL_poly_NY)
setwd(RawInput_OH)
SOIL_poly_OH = st_read('gsmsoilmu_a_oh.shp')
head(SOIL_poly_OH)
setwd(RawInput_PA)
SOIL_poly_PA = st_read('gsmsoilmu_a_pa.shp')
head(SOIL_poly_PA)


# merge all state data together for lake erie 
SOIL_poly = rbind(SOIL_poly_IN,SOIL_poly_MI)
SOIL_poly = rbind(SOIL_poly,SOIL_poly_NY)
SOIL_poly = rbind(SOIL_poly,SOIL_poly_OH)
SOIL_poly = rbind(SOIL_poly,SOIL_poly_PA)

#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

# USING THE LAYER TABLE, EXTRACT EACH POLYGON'S SOIL data

#The Layer Table describes each of the individual soil and 
#landscape features which comprise the polygon

# The soil characteristics in the LAYER  table are are area- and depth-weighted average values for available water capacity (AVG_AWC), bulk density (AVG_BD), saturated 
# hydraulic conductivity (AVG_KSAT), vertical saturated hydraulic conductivity (AVG_KV), soil erodibility factor (AVG_KFACT), porosity (AVG_POR), field 
# capacity (AVG_FC), the soil fraction passing a number 4 sieve (AVG_NO4), the soil fraction passing a number 10 sieve (AVG_NO10), the soil fraction passing a 
# number 200 sieve (AVG_NO200), and organic matter (AVG_OM).

setwd(RawSoilTable)
SOIL_layer = read.dbf("Layer.dbf")
SOIL_layer[SOIL_layer==-9999]=NA

#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

# SET UP WATERSHEDS THAT WE WANT TO EXTRACT INFO FOR 

setwd(WshdShapefileDir)
NAME=list.files(pattern=".shp$")
NAME=NAME[grepl('USA',NAME)]
NAME = NAME[2:length(NAME)] #omit LE_USA
NAME=substr(NAME,5,nchar(NAME)-4)

# Pre-allocate space for average soil parameter values for the watershed 
SOIL_subbas_avg = data.frame(NAME)
SOIL_subbas_avg$OM = NA # ORGANIC MATERIAL 
SOIL_subbas_avg$n = NA # SOIL POROSITY
SOIL_subbas_avg$BD = NA # BULK DENSITY 
SOIL_subbas_avg$THETA = NA # WATER RETENTION AT 33KP
SOIL_subbas_avg$s = NA # SOIL WATER CONTENT
SOIL_subbas_avg$KSAT = NA #	SATURATED HYDRAULIC CONDUCTIVITY

#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
# FOR EACH WATERSHED, CLIP THE SOIL POLYGON AND PREPARE FOR DATA EXTRACTION 

for (k in 1:length(NAME)){ # this can be changed to iterate eventually 
  NAME_k = NAME[k]
  
  setwd(WshdShapefileDir)
  WSHD = st_read(paste0('USA_',NAME_k,'.shp'))
  
  # set same CRS
  SOIL_poly = st_transform(SOIL_poly,st_crs(WSHD))
  
  # clip soil polygons to watershed 
  SOIL_subbas_clip = st_intersection(st_buffer(SOIL_poly,0),st_buffer(WSHD,0))
  SOIL_subbas = subset(SOIL_subbas_clip,select = c(MUKEY,geometry))
  # calculate area 
  SOIL_subbas$AREA = st_area(SOIL_subbas) 
  
  #assign different values to each polygon based on layer table
  
  # for each polygon
  for (i in 1:nrow(SOIL_subbas)) {
    idx = match(as.numeric(str_sub(SOIL_subbas$MUKEY[i],2,6)),SOIL_layer$mukey)
    SOIL_subbas$BD[i]=as.numeric(SOIL_layer$AVG_BD[idx])
    SOIL_subbas$THETA[i]=as.numeric(SOIL_layer$AVG_FC[idx])/100
    SOIL_subbas$OM[i]=as.numeric(SOIL_layer$AVG_OM[idx])
  
  
  ############## BRINGING EVERYTHING TOGETHER FOR EACH POLYGON (i) ########################
  
  SOIL_subbas$n[i] = 1- SOIL_subbas$BD[i]/2.65
  SOIL_subbas$THETA[i] = SOIL_subbas$THETA[i]
  SOIL_subbas$s[i] = SOIL_subbas$THETA[i]/SOIL_subbas$n[i]
  
  }
  
  # AFTER THE ABOVE, WE SHOULD HAVE params FOR ALL THE SOIL POLYGONS IN OUR WATERSHED 
  # we should weight them and average over the entire basin (k) <- might be running for multiple basins 
  
  #Station ID
  SOIL_subbas_avg$subbas_ID[k] = NAME_k
  
  #Watershed Area 
  TOTAREA = sum(SOIL_subbas$AREA)   
  
  #Watershed Organic Carbon 
  SOIL_subbas_avg$OM[k] = sum(SOIL_subbas$OM*(SOIL_subbas$AREA/TOTAREA),na.rm = TRUE)
  
  #Watershed  soil bulk density (BD)
  SOIL_subbas_avg$BD[k] = sum(SOIL_subbas$BD*(SOIL_subbas$AREA/TOTAREA),na.rm = TRUE)
  
  #Watershed Soil porosity (n)
  SOIL_subbas_avg$n[k] = sum(SOIL_subbas$n*(SOIL_subbas$AREA/TOTAREA),na.rm = TRUE)
  
  # Watersged soil water retention at 33 kPa  
  SOIL_subbas_avg$THETA[k] = sum(SOIL_subbas$THETA*(SOIL_subbas$AREA/TOTAREA),na.rm = TRUE)
  
  #Watershed Field Capacity a.k.a. average soil moisture
  SOIL_subbas_avg$s[k] = sum(SOIL_subbas$s*(SOIL_subbas$AREA/TOTAREA),na.rm = TRUE)
  
  
  setwd(OutputDir)
}

write_csv(SOIL_subbas_avg,paste0("SOIL_parameters_watershedsUSA",".csv"))


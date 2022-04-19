# this script should take in Lamisa's shapefiles for watersheds 
# around lake erie and make sure they are processed and all have the 
# attributes I need. This includes areas, as well as Q station names 

# Load required libraries 
library(sf)
library(raster)
library(rgdal)
library(dplyr)
library(qdapRegex)

# Note Directories that will be called 
SourceDir = "C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/LE_Watershed_shapefiles/LE_ELEMENT_N/Reformatted/"
LamisaShapefilesDir = "C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/LE_Watershed_shapefiles/LE_ELEMENT_N/FinalWS_shapefiles_Lamisa/"
 
  
# Get a list of all basins we need 
setwd(LamisaShapefilesDir)
StationFiles = list.files(pattern = "\\.shp$")

#get rid of one station L has that I do not 
StationFiles = StationFiles[!grepl('04000100102',StationFiles)]

#separate out US Stations 
usaStationsFiles = StationFiles[grepl('SITE_NO',StationFiles)]
usaStations= substr(usaStationsFiles,20,27) # just grab the ID from file name

canStationsFiles = StationFiles[!grepl('SITE_NO',StationFiles)]
canStations = as.character(ex_between(canStationsFiles,".","."))



#now clean up shapefiles, all should have same naming format, all should have same attributes 
setwd(SourceDir)

#CANADA 
for (i in 1:length(canStations)){
  
  #read in each watershed shapefile ------------
  thisSHP = shapefile(paste0(LamisaShapefilesDir,canStationsFiles[i]))
  # Reproject to 5070 to that we can get set resolution in meters. << is this necessary?
  crsSHAPE = '+proj=aea +lat_0=23 +lon_0=-96 +lat_1=29.5 +lat_2=45.5 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs'
  thisSHP = spTransform(thisSHP, crsSHAPE)
  
  # add in area and gauge ID as attributes 
  thisSHP_area = raster::area(thisSHP) # in m^2
  thisSHP_area = thisSHP_area*0.0001 # in ha  
  thisSHP_gaugeName = canStations[i]
  
  thisSHP$AREA_ha=thisSHP_area
  thisSHP$GaugeID = thisSHP_gaugeName
  
  #write new shapefile
  newName = paste0('CAN_',canStations[i])
  writeOGR(thisSHP,dsn=".",layer=newName,driver = "ESRI Shapefile",overwrite_layer = TRUE)
  
}


#USA 
for (i in 1:length(usaStations)){
  
  #read in each watershed shapefile ------------
  thisSHP = shapefile(paste0(LamisaShapefilesDir,usaStationsFiles[i]))
  # Reproject to 5070 to that we can get set resolution in meters. << is this necessary?
  crsSHAPE = '+proj=aea +lat_0=23 +lon_0=-96 +lat_1=29.5 +lat_2=45.5 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs'
  thisSHP = spTransform(thisSHP, crsSHAPE)
  
  # add in area and gauge ID as attributes 
  thisSHP_area = raster::area(thisSHP) # in m^2
  thisSHP_area = thisSHP_area*0.0001 # in ha  
  thisSHP_gaugeName = usaStations[i]
  
  thisSHP$AREA_ha=thisSHP_area
  thisSHP$GaugeID = thisSHP_gaugeName
  
  #write new shapefile
  newName = paste0('USA_',usaStations[i])
  writeOGR(thisSHP,dsn=".",layer=newName,driver = "ESRI Shapefile",overwrite_layer = TRUE)
  
}
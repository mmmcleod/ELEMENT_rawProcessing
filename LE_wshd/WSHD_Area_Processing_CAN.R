# This script creates the WSHD.mat file required for the ELEMeNT model 
# It needs the shapefile of the subwatershed(s) being considered as well 
# as the shapefile of the counties 

library(sf)
library(raster)
library(rgdal)
library(dplyr)
library(rgeos)
library(sp)

# Directories ----------------------------------------------------------------------------------
#----------------------------------------------------------------------------------
SourceDir = "C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/LE_wshd/"
CountySHPDir = "C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/Shapefile"
WatershedSHPDir = "C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/LE_Watershed_shapefiles/LE_ELEMENT_N/Reformatted"
setwd(SourceDir)

# Load in shapefiles ----------------------------------------------------------------------------------
#----------------------------------------------------------------------------------

# Get a list of all basins we are considering
setwd(WatershedSHPDir)
StationsFiles = list.files(pattern = "\\.shp$")
StationsFiles=StationsFiles[grepl('CAN',StationsFiles)] #only take canada for now 
Stations= substr(StationsFiles,5,15) # just grab the ID from file name

# Load in the county boundaries for Lake Erie 
setwd(CountySHPDir)
CountySHP = st_read('LE_CA.shp')
#remove a weird extra attribute 
CountySHP=CountySHP[!is.na(CountySHP$CDUID),]
# Reproject to 5070 to that we can get set resolution in meters. << is this necessary?
crsSHAPE = '+proj=aea +lat_0=23 +lon_0=-96 +lat_1=29.5 +lat_2=45.5 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs'
CountySHP = st_transform(CountySHP, crsSHAPE)

# Edit County shapefiles to have proper IDs ----------------------------------------------------------------------------------
#----------------------------------------------------------------------------------

# the Canadian counties have the wrong ID's - switch them to element IDs 
ElementCANCountyIDs = rep(NA, length(CountySHP$CDNAME))
ElementCANCountyIDs[CountySHP$CDNAME=='Dufferin']='22000'
ElementCANCountyIDs[CountySHP$CDNAME=='Wellington']='23000'
ElementCANCountyIDs[CountySHP$CDNAME=='Halton']='24000'
ElementCANCountyIDs[CountySHP$CDNAME=='Hamilton']='25000'
ElementCANCountyIDs[CountySHP$CDNAME=='Haldimand']='28005'
ElementCANCountyIDs[CountySHP$CDNAME=='Norfolk']='28030'
ElementCANCountyIDs[CountySHP$CDNAME=='Brant']='29000'
ElementCANCountyIDs[CountySHP$CDNAME=='Waterloo']='30000'
ElementCANCountyIDs[CountySHP$CDNAME=='Perth']='31000'
ElementCANCountyIDs[CountySHP$CDNAME=='Oxford']='32000'
ElementCANCountyIDs[CountySHP$CDNAME=='Elgin']='34000'
ElementCANCountyIDs[CountySHP$CDNAME=='Chatham-Kent']='36000'
ElementCANCountyIDs[CountySHP$CDNAME=='Essex']='37000'
ElementCANCountyIDs[CountySHP$CDNAME=='Lambton']='38000'
ElementCANCountyIDs[CountySHP$CDNAME=='Middlesex']='39000'
ElementCANCountyIDs[CountySHP$CDNAME=='Huron']='40000'
ElementCANCountyIDs[CountySHP$CDNAME=='Grey']='42000'

# Assign a new attribute 
CountySHP$CountyID = ElementCANCountyIDs

# Get the area for all the counties (not yet clipped to a watershed) ----------------------------------------------------------------------------------
#----------------------------------------------------------------------------------

#get areas of counties 
# we can't use this shapefile directly since it has been clipped to lake erie 
# we rather can use the areas from lamisa's WSHD.mat file for the whole ERIE 
setwd("C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/LE_landuse/LU_watershed_scale/RF Processing/Input_Meghan_July21_used_for_LU/")
Orig_WSHD_table = read.csv('wshd_admin_inputs_WSHD_mat_CAN.csv')
countyAreas = Orig_WSHD_table$AREA_admin

#re-order to match the order of counties in the shapefile 
newOrd = match(CountySHP$CountyID,Orig_WSHD_table$ID)
countyAreas = countyAreas[newOrd]

CountySHP$area=countyAreas

countiesList = CountySHP$CountyID
areasList = CountySHP$area
nameList = CountySHP$CDNAME

#create a data frame with the data we have so far 
output = data.frame(countiesList,nameList,areasList)

# Find the clipped areas for each of the canadian subwatersheds considered ----------------------------------------------------------------------------------
#----------------------------------------------------------------------------------

#iterate through all the basins we are considering 
setwd(WatershedSHPDir)

for (i in 1:length(StationsFiles)){
  thisStationName = Stations[i]
  thisStationShape = st_read(StationsFiles[i])
  #project  to match other shapefiles 
  thisStationShape = st_transform(thisStationShape, crsSHAPE)
  #clip counties with current station's watershed and get new county areas
  countyClipped = st_intersection(CountySHP,thisStationShape)#gIntersection(thisStationShape,CountySHP)
  countyClipped$area_clipped = st_area(countyClipped)
  
  #now fill in the table for current station watershed with clipped area 
  
  #make a new column 
  output[thisStationName]=rep(0,length(countiesList))
  
  # go through the counties that are in the current basin, grab those counties clipped areas and populate the table
  for (j in 1:length(countyClipped$CDNAME)){
    thisCounty=countyClipped$CDNAME[j]
    thisclippedArea = countyClipped$area_clipped[j]
    idx = output$nameList==thisCounty
    output[idx,thisStationName]=thisclippedArea
  }
}

# now all the counties should have their areas done. 

# write to a folder 

setwd(SourceDir)
write.csv(output,'countyAreas_andclipped_for_WSHD.csv')




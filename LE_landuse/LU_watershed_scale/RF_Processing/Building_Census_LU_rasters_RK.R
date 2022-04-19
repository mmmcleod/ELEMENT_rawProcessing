
# This script accepts ELEMeNT census data and using this data, creates 2 raster bricks
# of the same extent, where each layer represents a year. One raster brick contains 
# percent crop and the other, percent pasture

library(naniar)
library(raster)
library(rgdal)
library(DBI)
library(sf)
library(readxl)
library(ncdf4)



'###############################################################'
# UPLOADING REQUIRED DATA 
# - census data (.mat files that were converted to excel)
# - county data (shapefiles for US and CAN with county boundaries )
'###############################################################'

## UPLOADING MATLAB FILES CONTAINING CENSUS CROP AND AREA INFORMATION 
setwd("C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/LE_landuse/LU_watershed_scale/RF Processing")
can_crops = read.csv("Input_Meghan_July21_used_for_LU/crop_area_CROP_mat_CAN.csv") # crop and pasture areas in hectares
can_county_area = read.csv("Input_Meghan_July21_used_for_LU/wshd_admin_inputs_WSHD_mat_CAN.csv") # county areas in m^2
usa_crops = read.csv("Input_Meghan_July21_used_for_LU/crop_area_CROP_mat_USA.csv") # crop and pasture areas in hectares
usa_county_area = read.csv("Input_Meghan_July21_used_for_LU/wshd_admin_inputs_WSHD_mat_USA.csv") # county areas in m^2
usa_past = read.csv('Input_Meghan_July21_used_for_LU/crop_area_PAST_mat_USA.csv')
  
  
#upload the global LU (just so we project the same way)
global_LU_NC = 'glcrop_1700-2007_0.5.nc'
global_LU_NC.stack = stack(global_LU_NC)

## UPLOAD CENSUS BOUNDARIES FOR CAN AND USA 
setwd("C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/Shapefile/")
ONT_shape = shapefile('LE_CA.shp')
ONT_shape <- spTransform(ONT_shape, proj4string(global_LU_NC.stack)) 
#ONT_shape = shift(ONT_shape,360)
USA_shape = shapefile('LE_USA.shp')
USA_shape <- spTransform(USA_shape, proj4string(global_LU_NC.stack)) 
#USA_shape = shift(USA_shape,360)

setwd("C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/LE_landuse/LU_watershed_scale/RF Processing")


#combine the 2 shape files into one 

#properly name the CAN counties first
ONT_shape$CDNAME[ONT_shape$CDNAME=="Waterloo"]=30000;ONT_shape$CDNAME[ONT_shape$CDNAME=="Lambton"]=38000;ONT_shape$CDNAME[ONT_shape$CDNAME=="Dufferin"]=22000;ONT_shape$CDNAME[ONT_shape$CDNAME=="Chatham-Kent"]=36000;ONT_shape$CDNAME[ONT_shape$CDNAME=="Essex"]=37000
ONT_shape$CDNAME[ONT_shape$CDNAME=="Haldimand"]=28005;ONT_shape$CDNAME[ONT_shape$CDNAME=="Norfolk"]=28030;ONT_shape$CDNAME[ONT_shape$CDNAME=="Elgin"]=34000;ONT_shape$CDNAME[ONT_shape$CDNAME=="Huron"]=40000;ONT_shape$CDNAME[ONT_shape$CDNAME=="Oxford"]=32000;ONT_shape$CDNAME[ONT_shape$CDNAME=="Perth"]=31000
ONT_shape$CDNAME[ONT_shape$CDNAME=="Wellington"]=23000;ONT_shape$CDNAME[ONT_shape$CDNAME=="Halton"]=24000 ;ONT_shape$CDNAME[ONT_shape$CDNAME=="Grey"]=42000 ;ONT_shape$CDNAME[ONT_shape$CDNAME=="Hamilton"]=25000;ONT_shape$CDNAME[ONT_shape$CDNAME=="Middlesex"]=39000;ONT_shape$CDNAME[ONT_shape$CDNAME=="Brant"]=29000
ONT_shape$ID = as.numeric(ONT_shape$CDNAME)

ONT_shape$ID = ONT_shape$CDNAME; ONT_shape=ONT_shape[c(28)] # only include ID
USA_shape$ID = USA_shape$GEOID; USA_shape=USA_shape[c(20)] # only include ID


ERIE_shape = bind(ONT_shape,USA_shape)


'###############################################################'
# COLLATING DATA FROM USA AND CAN ELEMENT INPUTS 
# CREATING TABLES WITH TOTAL AREA, CROP AREA, PAST AREA 
'###############################################################'


# dimensions of both USA and CAN data sets
numrowsUSA=length(usa_crops[,1])
numcolsUSA = length(usa_crops[1,])
numrowsCAN=length(can_crops[,1])
numcolsCAN  = length(can_crops[1,])

#convert county area from m^2 to ha (since crop areas are ha)
usa_county_area_ha = usa_county_area; usa_county_area_ha[,4]=usa_county_area[,4]*.0001
can_county_area_ha = can_county_area; can_county_area_ha[,4]=can_county_area[,4]*.0001


# start to build a county x year matrix for both countries 
yearsUSA = sort(na.omit(unique(usa_crops[,1])))
countiesUSA = colnames(usa_crops)[2:numcolsUSA];  countiesUSA = as.numeric(substring(countiesUSA, 2)) #turn to numeric 'x22000' to 22000 for example 
yearsCAN = sort(na.omit(unique(can_crops[,3])))
countiesCAN = can_crops[1,4:numcolsCAN]

# build total county area matrix (total area for each county over the years - each year we assume same area)
'_______________________________________________________________________________'
totalcountyAreaCAN=matrix(,nrow=length(yearsCAN),ncol=length(countiesCAN))
totalcountyAreaUSA=matrix(,nrow=length(yearsUSA),ncol=length(countiesUSA))

for (i in 1:length(yearsUSA)){
  totalcountyAreaUSA[i,]= t(usa_county_area_ha[,4])
}
for (i in 1:length(yearsCAN)){
  totalcountyAreaCAN[i,]= t(can_county_area_ha[,4])
}


# set up crop and pasture area for each county 
'_______________________________________________________________________________'
totalCropUSA = matrix(,nrow=length(yearsUSA),ncol=length(countiesUSA))
totalPastureUSA = matrix(,nrow=length(yearsUSA),ncol=length(countiesUSA))
totalCropCAN = matrix(,nrow=length(yearsCAN),ncol=length(countiesCAN))
totalPastureCAN = matrix(,nrow=length(yearsCAN),ncol=length(countiesCAN))

#USA
for (i in 1:length(yearsUSA)){
  thisyear = yearsUSA[i]
  
  #extract the year we want for each LU type
  thisyearPastMatrix = usa_past[(usa_past[,1]==thisyear),] #extract this year and only pasture area types
  thisyearCropMatrix = usa_crops[(usa_crops[,1]==thisyear),] #extract this year and only crop area types
  
  #sum together all areas for that year for each county 
  
  for (j in 1:length(countiesUSA)){
    thiscountyTotalCrop = sum(thisyearCropMatrix[,j+1],na.rm=TRUE) # doesn't really do anything here since one value per year 
    thiscountyTotalPast = sum(thisyearPastMatrix[,j+1],na.rm=TRUE)
    
    totalCropUSA[i,j]=thiscountyTotalCrop
    totalPastureUSA[i,j]=thiscountyTotalPast
  }
}


#CAN 

for (i in 1:length(yearsCAN)){
  thisyear = yearsCAN[i]
  
  #extract the year we want for each LU type
  thisyearPastMatrix = can_crops[(can_crops[,3]==thisyear)&(can_crops[,1]==2001|can_crops[,1]==2002),] #extract this year and only pasture area types
  thisyearCropMatrix = can_crops[(can_crops[,3]==thisyear)&(can_crops[,1]!=2001&can_crops[,1]!=2002),] #extract this year and only crop area types
  
  #sum together all areas for that year for each county 
  
  for (j in 1:length(countiesCAN)){
    thiscountyTotalCrop = sum(thisyearCropMatrix[,j+3],na.rm=TRUE)
    thiscountyTotalPast = sum(thisyearPastMatrix[,j+3],na.rm=TRUE)
    
    totalCropCAN[i,j]=thiscountyTotalCrop
    totalPastureCAN[i,j]=thiscountyTotalPast
  }
}


#now divide each counties/year's crop and past are with total area 
'_______________________________________________________________________________'
#USA
percentCrop_USA = totalCropUSA/totalcountyAreaUSA
percentPasture_USA = totalPastureUSA/totalcountyAreaUSA

USA_countycrop=data.frame(yearsUSA,percentCrop_USA)
names(USA_countycrop)=c("YEAR",countiesUSA)

USA_countypast=data.frame(yearsUSA,percentPasture_USA)
names(USA_countypast)=c("YEAR",countiesUSA)
#CAN 
percentCrop_CAN = totalCropCAN/totalcountyAreaCAN
percentPasture_CAN = totalPastureCAN/totalcountyAreaCAN

CAN_countycrop=data.frame(yearsCAN,percentCrop_CAN)
names(CAN_countycrop)=c("YEAR",countiesCAN)

CAN_countypast=data.frame(yearsCAN,percentPasture_CAN)
names(CAN_countypast)=c("YEAR",countiesCAN)


#interpolate for CAN to get yearly like USA -----------------------------------------------------------

CAN_countycrop_old = CAN_countycrop
CAN_countypast_old = CAN_countypast

#extend years to match length of USA
CAN_countycrop=data.frame(yearsUSA,matrix(data=NA,nrow=length(yearsUSA),ncol=length(countiesCAN)))
names(CAN_countycrop)=c("YEAR",countiesCAN)
CAN_countypast=data.frame(yearsUSA,matrix(data=NA,nrow=length(yearsUSA),ncol=length(countiesCAN)))
names(CAN_countypast)=c("YEAR",countiesCAN)


# fill in years to match USA
CAN_countycrop$YEAR=USA_countycrop$YEAR 
CAN_countypast$YEAR=USA_countypast$YEAR 


#fill in the data we have
for (i in 1:length(yearsCAN)){ 
  thisYear = CAN_countycrop_old$YEAR[i]
  CAN_countycrop[CAN_countycrop$YEAR==thisYear,]=CAN_countycrop_old[i,]
  CAN_countypast[CAN_countypast$YEAR==thisYear,]=CAN_countypast_old[i,]
}


# now fill in using approx 
for (i in 1:length(countiesCAN)){
  CAN_countycrop[,i+1]=approx(CAN_countycrop[,i+1],n=length(yearsUSA))$y
  CAN_countypast[,i+1]=approx(CAN_countypast[,i+1],n=length(yearsUSA))$y
}

#put them together in one table
countyCROP = cbind(CAN_countycrop,USA_countycrop[,2:66])
countyPAST = cbind(CAN_countypast,USA_countypast[,2:66])

'###############################################################'
# NOW MAP ALL OF THESE TABLES ONTO A SHAPEFILE WHICH WE 
# WILL TURN INTO A RASTER 
'###############################################################'

countyMap = ERIE_shape
r = raster(ncol=100, nrow=100)
extent(r)=extent(countyMap)
countyMap$idNUM = as.numeric(countyMap$ID)
countyMapRaster = rasterize(countyMap,r,"idNUM")

countyMapBrick= brick(countyMapRaster)

for (i in 2:length(yearsUSA)){
  countyMapBrick=addLayer(countyMapBrick,countyMapRaster)
}


#now we have a raster of countyIDs for all of ERIE 


# map each year's percent crop and percent pasture onto the county raster 
'-------------------------------------------------'

counties = c(countiesCAN,countiesUSA)
years = yearsUSA

crop_brick = brick()
past_brick = brick()

# FOR THIS MAYBE MERGE THE TWO TABLES WE MADE UP THERE TOGETHER 

for (i in 1:length(years))
{
  thislayerCrop = countyMapRaster
  thislayerPast = countyMapRaster
  
  for (j in 1:length(counties))
  {
    
    thisCounty = as.numeric(counties[[j]])
    
      thislayerCrop[thislayerCrop==thisCounty]=countyCROP[i,j+1]
      thislayerPast[thislayerPast==thisCounty]=countyPAST[i,j+1]
    }
  
  crop_brick=addLayer(crop_brick,thislayerCrop)
  past_brick=addLayer(past_brick,thislayerPast)
}

crop_brick
past_brick



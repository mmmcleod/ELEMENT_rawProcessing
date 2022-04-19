# Bring in libraries 
library(raster)
library(rgdal)
library(DBI)
library(sf)
library(readxl)
library(ncdf4)

######################### PULL IN AND REFORMAT DATA #########################
setwd("C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/LE_surplus/ELEMENT_Input_formatting/Deposition/Global Gridded")

# Pull in Shapefiles 
folder = 'DATA/'
shapefileCAN = shapefile(paste0(folder,'LE_ON_counties.shp'))
shapefileUSA = shapefile(paste0(folder,'LE_USA_counties.shp'))
shapefileGrand = shapefile("C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/LE_Watershed_shapefiles/LE_ELEMENT_N/Reformatted/CAN_16018409202_.shp")
# Set a proper projection (needs to be uniform )
PROJCRS = "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"

#reproject 
shapefileGrand = spTransform(shapefileGrand,PROJCRS)
shapefileUSA = spTransform(shapefileUSA,PROJCRS)
shapefileCAN = spTransform(shapefileCAN,PROJCRS)

# I believe the dep raster is shifted, so we might have to shift over 
shapefileGrand=shift(shapefileGrand,360)
shapefileUSA=shift(shapefileUSA,360)
shapefileCAN=shift(shapefileCAN,360)

# Pull in Gridded Deposition Data 
filenameDryNOY = paste0(folder,'ann_drynoy_ncdf4.nc')
filenameWetNOY = paste0(folder,'ann_wetnoy_ncdf4.nc')
filenameDryNHX = paste0(folder,'ann_drynhx_ncdf4.nc')
filenameWetNHX = paste0(folder,'ann_wetnhx_ncdf4.nc')

DryNOY.stack = stack(filenameDryNOY)
WetNOY.stack = stack(filenameWetNOY)
DryNHX.stack = stack(filenameDryNHX)
WetNHX.stack = stack(filenameWetNHX)

years = 1850:2014 #(according to kim's code) <- each stack layer is one of these years 

#Change Units of raster stacks (convert to kg/ha) <- this comes from kim's code 
convert = (10^4)*60*60*24*365

# Reproject 
crs(DryNHX.stack) = crs(shapefileGrand)
crs(DryNOY.stack) = crs(shapefileGrand)
crs(WetNOY.stack) = crs(shapefileGrand)
crs(WetNHX.stack) = crs(shapefileGrand)

layerNums = nlayers(WetNOY.stack)

##########################################################################

############## Preliminary Visualization #########################
#Plot just one year of a raster stack 
level = 22 #(year 1871 )
# add all the deposition components together 
year22totalDep = raster(DryNOY.stack,level)*convert+
  raster(WetNOY.stack,level)*convert+
  raster(DryNHX.stack,level)*convert+
  raster(WetNOY.stack,level)*convert

# plot shapefile on top of this year's deposition 
plot(year22totalDep)

plot(crop(year22totalDep,extent(225, 300, 0, 60)))
plot(shapefileGrand,add=TRUE)

plot(crop(year22totalDep,extent(277, 281, 42, 45)))
plot(shapefileGrand,add=TRUE)


# extract deposition VALUE for this year in the shapefile 
test = extract(year22totalDep,shapefileGrand,weights=TRUE, small=TRUE,fun=mean)

# ^^ this extract function is quite neat, if the polynomial is a multi-poly 
# such as a shapefile of counties, it will extract the mean values as a vector 
# where each value is a value for a county .. at this point I am clipping 
# to mono-polygons (watershed shapefiles) so will not use this feature here
##########################################################################

######################### Extract DEP timeseries for WSHD  #########################

DepTimeSeries = rep(NA,layerNums) # set up a vector for shapefile's deposition 

# for each year, add all the deposition rasters together and extract mean value for shapefile
for (i in 1:layerNums){
  level=i
  thisYearDep = raster(DryNOY.stack,level)*convert+
    raster(WetNOY.stack,level)*convert+
    raster(DryNHX.stack,level)*convert+
    raster(WetNOY.stack,level)*convert
  thisYearWSHDDep = extract(thisYearDep,shapefileGrand,weights=TRUE, small=TRUE,fun=mean)
  DepTimeSeries[i]=thisYearWSHDDep # store in vector 
}

plot(years,DepTimeSeries) # plot for sanity check 

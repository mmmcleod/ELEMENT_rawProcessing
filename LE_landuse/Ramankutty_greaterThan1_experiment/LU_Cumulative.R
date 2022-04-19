rm(list=ls()) # clear the enviornment

# Load in neccesary packages 
library(raster)
library(rgdal)
library(sf)
library(readxl)
library(writexl)

# this is where the project will be extacting info from & where this script should be saved 
#setwd("C:/fill in WD")
setwd("~/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/LU processing")

#ramenkutty's data is in netcdf form, we can extract each year as a raster (one raster per year)

# look at the fist layver in the net cdf (test)
LU_rast1 = raster('glcrop_1700-2007_0.5.nc', level = 100)
LU_rast2 = raster('glpast_1700-2007_0.5.nc', level = 100)

# plot for sanity check 
plot(LU_rast1)
plot(LU_rast2)

# upload the stack as a whole

# Upload the entire crop dataset from Ramankutty 
cropNC = 'glcrop_1700-2007_0.5.nc'
cropNC.s = stack(cropNC)
# Upload the entire pasture dataset from Ramankutty 
pastNC = 'glpast_1700-2007_0.5.nc'
pastNC.s = stack(pastNC)


## UPLOADING THE SHAPEFILE OF COUNTIES TO CLIP THIS DATA TO (one LU trend for each county)
'###############################################################'

# START WITH USA SIDE ##################################################

# go to shapefile folder
setwd('shapefiles_counties/')
# grab USA shapefiles 
US_county_shape = st_read('US_County_Byrnesetal.shp')
#transform shapefile projection to that of the LU netcdf data 
US_county_shape=st_transform(US_county_shape,as.character(crs(LU_rast1))) # set CRS the same

# leave the shapefile folder
setwd("..")

# split the county multipolygon in to several smaller polygons 
test = st_cast(US_county_shape,'POLYGON')

# ## CLIPPING EACH CROP LAYER TO EACH COUNTY 
# 
ncounties = dim(US_county_shape)[1]
nYears = nlayers(cropNC.s)
allcountiescrop = matrix(, nrow = nYears, ncol = ncounties)

for (k in 1:ncounties){
  clipped_cropNC = stack()
  meanVals = c()
for (i in 1:nYears){
  level = i
  # creating a new clipped raster stack
  
  #Grab this years raster
  thisYearLU_tot = raster(cropNC.s, level)
  
  #Grab this years raster cut to the total extent 
  thisYearLU_WS = crop(thisYearLU_tot, extent(US_county_shape[k,])) # crop the raster file to the shape file extent 
  data = na.omit(values(thisYearLU_WS))
  thisMean = mean(data)
  meanVals = append(meanVals, thisMean)}

allcountiescrop[,k]= meanVals}


# ## CLIPPING EACH PASTURE LAYER TO EACH COUNTY 

ncounties = dim(US_county_shape)[1]
nYears = nlayers(pastNC.s)
allcountiespast = matrix(, nrow = nYears, ncol = ncounties)

for (k in 1:ncounties){
  clipped_pastNC = stack()
  meanVals = c()
  for (i in 1:nYears){ 
    level = i
    # creating a new clipped raster stack
    
    #Grab this years raster
    thisYearLU_tot = raster(pastNC.s, level)
    
    #Grab this years raster cut to the total extent 
    thisYearLU_WS = crop(thisYearLU_tot, extent(US_county_shape[k,])) # crop the raster file to the shape file extent 
    data = na.omit(values(thisYearLU_WS))
    thisMean = mean(data)
    meanVals = append(meanVals, thisMean)}
  
  allcountiespast[,k]= meanVals}


# NOW SUBTRACT BOTH OF THESE VECTORS FROM ONE TO GET NON-AG

allcountiesNonAg= matrix(, nrow = nYears, ncol = ncounties)

for (i in 1:ncounties){
  allcountiesNonAg[,i]=1-allcountiespast[,i]-allcountiescrop[,i]}

allcountiescrop_USA = allcountiescrop
allcountiespast_USA = allcountiespast

# do we need to scale to the year 2000? 

# NEXT IS CANADA SIDE ##################################################

# go to shapefile folder
setwd('LE_counties_CAN/')
# grab CAN shapefiles 
CAN_county_shape = st_read('LE_counties_CAN.shp')
#transform shapefile projection to that of the LU netcdf data 
CAN_county_shape=st_transform(CAN_county_shape,as.character(crs(LU_rast1))) # set CRS the same

# leave the shapefile folder
setwd("..")

# ## CLIPPING EACH CROP LAYER TO EACH COUNTY 
# 
ncounties = dim(CAN_county_shape)[1]
nYears = nlayers(cropNC.s)
allcountiescrop = matrix(, nrow = nYears, ncol = ncounties)

for (k in 1:ncounties){
  clipped_cropNC = stack()
  meanVals = c()
  for (i in 1:nYears){
    level = i
    # creating a new clipped raster stack
    
    #Grab this years raster
    thisYearLU_tot = raster(cropNC.s, level)
    
    #Grab this years raster cut to the total extent 
    thisYearLU_WS = crop(thisYearLU_tot, extent(CAN_county_shape[k,])) # crop the raster file to the shape file extent 
    data = na.omit(values(thisYearLU_WS))
    thisMean = mean(data)
    meanVals = append(meanVals, thisMean)}
  
  allcountiescrop[,k]= meanVals}


# ## CLIPPING EACH PASTURE LAYER TO EACH COUNTY 

ncounties = dim(CAN_county_shape)[1]
nYears = nlayers(pastNC.s)
allcountiespast = matrix(, nrow = nYears, ncol = ncounties)

for (k in 1:ncounties){
  clipped_pastNC = stack()
  meanVals = c()
  for (i in 1:nYears){ 
    level = i
    # creating a new clipped raster stack
    
    #Grab this years raster
    thisYearLU_tot = raster(pastNC.s, level)
    
    #Grab this years raster cut to the total extent 
    thisYearLU_WS = crop(thisYearLU_tot, extent(CAN_county_shape[k,])) # crop the raster file to the shape file extent 
    data = na.omit(values(thisYearLU_WS))
    thisMean = mean(data)
    meanVals = append(meanVals, thisMean)}
  
  allcountiespast[,k]= meanVals}


# NOW SUBTRACT BOTH OF THESE VECTORS FROM ONE TO GET NON-AG

allcountiesNonAg= matrix(, nrow = nYears, ncol = ncounties)

for (i in 1:ncounties){
  allcountiesNonAg[,i]=1-allcountiespast[,i]-allcountiescrop[,i]}

allcountiescrop_CAN = allcountiescrop
allcountiespast_CAN = allcountiespast

# do we need to scale to the year 2000? 


#---------------------------------------------------------------
## Write the raw data to a csv
write.table(allcountiescrop_CAN,file="allcountiescrop_CAN.csv") # keeps the rownames
write.table(allcountiespast_CAN,file="allcountiespast_CAN.csv") # keeps the rownames
write.table(allcountiescrop_USA,file="allcountiescrop_USA.csv") # keeps the rownames
write.table(allcountiespast_USA,file="allcountiespast_USA.csv") # keeps the rownames


# get table headers 

ncounties = dim(US_county_shape)[1]
headers_USA = matrix(, nrow = 1, ncol = ncounties)
for (k in 1:ncounties){
  this = (US_county_shape[k,]$GEOID)
  headers_USA[k]=as.numeric(levels(this)[this])}

ncounties = dim(CAN_county_shape)[1]
headers_CAN = matrix(, nrow = 1, ncol = ncounties)
for (k in 1:ncounties){
  this = (CAN_county_shape[k,]$CDUID)
  headers_CAN[k]=as.numeric(levels(this)[this])}

write.table(headers_USA,file="headers_USA.csv") # keeps the rownames
write.table(headers_CAN,file="headers_CAN.csv") # keeps the rownames


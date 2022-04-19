rm(list=ls()) # clear the enviornment


# THis script produces land use trajectories for an inputted watershed. 
# It intakes the Annual Crop Inventory (Agriculture and Agri-Food Canada, 2016a) - 2011-2016
# It scales this data set using the Historical Croplands Dataset (Ramankutty, 1999) -1700-2007
# The scale year is 2007 value from Ramankutty and 2011 value from Annual Inventory since there was no change in cropland fraction from 1990 to 2010
# ^ The methods above were first used by Joy (2020)


# Annual crop inventory access: https://www.agr.gc.ca/atlas/rest/services/imageservices/annual_crop_inventory_2011/ImageServer


# a grid cell is crop if it is: 12-38,8 is undifferentiated agriculture
# a grid cell is pasture if it is: 9, 



## SETTING UP
'###############################################################'
# load libraries & packages -  this allows us to use the raster function

install.packages("ncdf4") # for NC files
install.packages("orgutils") # for shape files
install.packages("DBI")
install.packages("sf")
install.packages("Rcpp")
install.packages("sp")
install.packages(c("readxl","writexl","xlsx"))
install.packages("raster")
install.packages("rgdal")

library(raster)
library(rgdal)
library(DBI)
library(sf)
# library(xlsx)
library(readxl)
library(writexl)

# this is where the project will be extacting info from 
setwd("C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/LU_processing/LU_watershed_scale")


## UPLOADING THE NET CDF FILES CONTAINING LAND USE INFORMATION 
'###############################################################'
# look at the fist layver in the net cdf
LU_rast1 = raster('glcrop_1700-2007_0.5.nc', level = 1)
LU_rast2 = raster('glpast_1700-2007_0.5.nc', level = 1)

# upload the stack as a whole
thisNC = 'glcrop_1700-2007_0.5.nc'
thisNC.s = stack(thisNC)

thisNC2 = 'glpast_1700-2007_0.5.nc'
thisNC.s2 = stack(thisNC2)
# 
# plot(thisNC.s)
# plot(thisNC.s2)
# plot(LU_rast1)
# plot(LU_rast2)

CI_2011=raster()




## UPLOADING THE SHAPEFILE OF WS TO CLIP TO 
'###############################################################'
setwd("C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/ELEMENT_run_LE_Nitrogen_mmmcleod/Watershed_shapefiles/LE_WSHD")
WS_shape = st_read('LE_WSHD.shp')
WS_shape=st_transform(WS_shape,as.character(crs(LU_rast1))) # set CRS the same
setwd("C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/LU_processing/LU_watershed_scale")

plot(WS_shape['merge'],
     main = "Shapefile imported into R - Watershed",
     axes = TRUE,
     border = "blue")

## CLIPPING EACH LAYER TO MY GIVEN WATERSHED

nYears = nlayers(thisNC.s)
clipped_raster_stack = stack()
meanVals = c()
DATA = c()

for (i in 1:nYears){
  print(i)
  level = i
  # creating a new clipped raster stack
  thisYearLU_tot = raster(thisNC.s, level)
  thisYearLU_WS = crop(thisYearLU_tot, extent(WS_shape)) # crop the raster file to the shape file
  thisYearLU_WS = mask(thisYearLU_WS,WS_shape)
  clipped_raster_stack = stack (clipped_raster_stack, thisYearLU_WS)
  # creating a verctor with the mean val from each year
  data = na.omit(values(thisYearLU_WS))
  DATA = append(DATA, data)
  thisMean = mean(data)
  meanVals = append(meanVals, thisMean)}


## CLIPPING EACH LAYER TO MY GIVEN WATERSHED

nYears = nlayers(thisNC.s2)
clipped_raster_stack2 = stack()
meanVals2 = c()
DATA2 = c()

for (i in 1:nYears){
  print(i)
  level = i
  # creating a new clipped raster stack
  thisYearLU_tot2 = raster(thisNC.s2, level)
  thisYearLU_WS2 = crop(thisYearLU_tot2, extent(WS_shape)) # crop the raster file to the shape file
  thisYearLU_WS2 = mask(thisYearLU_WS2,WS_shape)
  clipped_raster_stack2 = stack (clipped_raster_stack2, thisYearLU_WS2)
  # creating a verctor with the mean val from each year
  data2 = na.omit(values(thisYearLU_WS2))
  DATA2 = append(DATA2, data)
  thisMean2 = mean(data2)
  meanVals2 = append(meanVals2, thisMean2)}


# plot the last year of Crop and Pasture 
plot(thisYearLU_WS) #crop
plot(thisYearLU_WS2)#past

#taking the mean trajectory to get one vector for the entire watershed 


crop = as.list(meanVals)
crop = as.data.frame(crop)
past = as.list(meanVals2)
past = as.data.frame(past)


plot(ras)
plot(shp, bg="transparent", add=TRUE)



## Quality checking
thisyearbad = raster(thisNC.s, 192) 
 thisyearbadclipped = crop(thisyearbad, extent(WS_shape))
 thisyearbadclipped = mask(thisyearbadclipped,(WS_shape))
# 
thisyearbad2 = raster(thisNC.s2, 192) 
 thisyearbadclipped2 = crop(thisyearbad2, extent(WS_shape))
 thisyearbadclipped2 = mask(thisyearbadclipped2,(WS_shape))

 plot(thisyearbadclipped)
 plot(WS_shape, add=TRUE)
 title('Crop - 1891')
 plot(thisyearbadclipped2)
 plot(WS_shape, add=TRUE)
 title('Pasture - 1891')
# 
 meanVals[192]
 meanVals2[192]

# data("thisyearbadclipped")
 #data("thisyearbadclipped2")
 write.csv(crop, file = "crop.csv")
 write.csv(past, file = "Pasture.csv")

 
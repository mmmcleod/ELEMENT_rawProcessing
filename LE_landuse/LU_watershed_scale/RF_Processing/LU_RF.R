rm(list=ls()) # clear the enviornment


# THis script produces land use trajectories for an inputted watershed. 
# It intakes the Historical Land-Cover Change and Land-Use Conversions Global Dataset
# Data availability: https://www.ncei.noaa.gov/access/metadata/landing-page/bin/iso?id=gov.noaa.ncdc:C00814

#RF
#https://www.ncei.noaa.gov/thredds/ncss/ncFC/sat/landcover-RFAREAVEG-fc/Historical_Land-Cover_Change_and_Land-Use_Conversions_Global_Dataset:_RF_AREAVEG_Feature_Collection_best.ncd/dataset.html
## SETTING UP



whichSet = 3

if (whichSet==1 ){fileOut="output_HYDE_R.csv"}
if (whichSet==2 ){fileOut="output_HH_R.csv"}
if (whichSet==3 ){fileOut="output_RF_R.csv"}

'###############################################################'
# load libraries & packages -  this allows us to use the raster function

library(raster)
library(rgdal)
library(DBI)
library(sf)
library(readxl)
library(ncdf4)



# this is where the project will be extacting info from 
setwd("C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/LU_processing/LU_watershed_scale/RF Processing/")


## UPLOADING THE NET CDF FILES CONTAINING LAND USE INFORMATION 
'###############################################################'

# upload the stack as a whole

if (whichSet==1 ){global_LU_NC = "Historical_Land-Cover_Change_and_Land-Use_Conversions_Global_Dataset__HYDE_AREAVEG_Feature_Collection_best.ncd.nc"}
if (whichSet==2 ){global_LU_NC = "Historical_Land-Cover_Change_and_Land-Use_Conversions_Global_Dataset__HH_AREAVEG_Feature_Collection_best.ncd.nc"}
if (whichSet==3 ){global_LU_NC = "Historical_Land-Cover_Change_and_Land-Use_Conversions_Global_Dataset__RF_AREAVEG_Feature_Collection_best.ncd.nc"}



global_LU_C3crop_NC.stack = stack(global_LU_NC,varname='C3crop')
global_LU_C4past_NC.stack = stack(global_LU_NC,varname='C3past')
global_LU_C4crop_NC.stack = stack(global_LU_NC,varname='C4crop')
global_LU_C3past_NC.stack = stack(global_LU_NC,varname='C4past')

global_LU_past_NC.stack=global_LU_C3past_NC.stack+global_LU_C4past_NC.stack
global_LU_crop_NC.stack=global_LU_C3crop_NC.stack+global_LU_C4crop_NC.stack

# look at the fist layer in the net cdf

layer1_global_LU_C3_crop = raster('Historical_Land-Cover_Change_and_Land-Use_Conversions_Global_Dataset__HYDE_AREAVEG_Feature_Collection_best.ncd.nc',level=1,varname='C3crop')
layer1_global_LU_C4_crop = raster('Historical_Land-Cover_Change_and_Land-Use_Conversions_Global_Dataset__HYDE_AREAVEG_Feature_Collection_best.ncd.nc',level=1,varname='C4crop')
layer1_global_LU_C3_past = raster('Historical_Land-Cover_Change_and_Land-Use_Conversions_Global_Dataset__HYDE_AREAVEG_Feature_Collection_best.ncd.nc',level=1,varname='C3past')
layer1_global_LU_C4_past = raster('Historical_Land-Cover_Change_and_Land-Use_Conversions_Global_Dataset__HYDE_AREAVEG_Feature_Collection_best.ncd.nc',level=1,varname='C4past')


## UPLOADING THE SHAPEFILE OF WS TO CLIP TO 
'###############################################################'
setwd("C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/Shapefile/")
WS_shape = shapefile('ONT.shp')
WS_shape <- spTransform(WS_shape, proj4string(global_LU_crop_NC.stack)) 
WS_shape = shift(WS_shape,360)

setwd("C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/LU_processing/LU_watershed_scale/RF Processing/")



## CLIPPING EACH CROP LAYER TO MY GIVEN WATERSHED

nYears = nlayers(global_LU_crop_NC.stack)
clipped_raster_stack_crop = stack()
meanVals_crop = c()
DATA_crop = c()

for (i in 1:nYears){
  print(i)
  level = i
  # creating a new clipped raster stack
  thisYearLU_tot = raster(global_LU_crop_NC.stack, level)
  
  
  thisYearLU_WS_crop = crop(thisYearLU_tot, extent(WS_shape)) # crop the raster file to the shape file
  thisYearLU_WS_crop = mask(thisYearLU_WS_crop,WS_shape)
  clipped_raster_stack_crop = stack (clipped_raster_stack_crop, thisYearLU_WS_crop)
  # creating a vector with the mean val from each year
  data_crop = na.omit(values(thisYearLU_WS_crop))
  DATA_crop = append(DATA_crop, data_crop)
  thisMean = mean(data_crop)
  meanVals_crop = append(meanVals_crop, thisMean)}


## CLIPPING EACH PASTURE LAYER TO MY GIVEN WATERSHED

nYears = nlayers(global_LU_past_NC.stack)
clipped_raster_stack_past = stack()
meanVals_past = c()
DATA_past = c()

for (i in 1:nYears){
  print(i)
  level = i
  # creating a new clipped raster stack
  thisYearLU_tot = raster(global_LU_past_NC.stack, level)

  thisYearLU_WS_past = crop(thisYearLU_tot, extent(WS_shape)) # crop the raster file to the shape file
  thisYearLU_WS_past = mask(thisYearLU_WS_past,WS_shape)
  clipped_raster_stack_past = stack(clipped_raster_stack_past, thisYearLU_WS_past)
  # creating a vector with the mean val from each year
  data_past = na.omit(values(thisYearLU_WS_past))
  DATA_past = append(DATA_past, data_past)
  thisMean = mean(data_past)
  meanVals_past = append(meanVals_past, thisMean)}


# plot the last year of Crop and Pasture 
plot(thisYearLU_WS_crop) #crop
plot(thisYearLU_WS_past)#past
plot(thisYearLU_WS_crop+thisYearLU_WS_past)


#taking the mean trajectory to get one vector for the entire watershed 


crop = as.numeric(meanVals_crop)
past = as.numeric(meanVals_past)
year = as.numeric(1771:(1770+nYears))


plot(year,crop)
plot(year,past)
plot(year,past+crop)

output=data.frame(year,crop,past)
names(output)=c("YEAR","CROP","PAST")


setwd("C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/LU_processing/LU_watershed_scale")
write.csv(output, file = fileOut)


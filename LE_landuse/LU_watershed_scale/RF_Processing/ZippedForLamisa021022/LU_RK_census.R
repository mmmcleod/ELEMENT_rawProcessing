rm(list=ls()) # clear the environment


# This script produces land use trajectories for an inputted watershed. 
# now it takes in ramankutty data! 

##################################################################################################
## SETTING UP
##################################################################################################

fileOut="output_ramankutty_R.csv"


'###############################################################'
# load libraries & packages -  this allows us to use the raster function

library(raster)
library(rgdal)
library(DBI)
library(sf)
library(readxl)
library(ncdf4)



# this is where the project will be extacting info from 
setwd("C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/LE_landuse/LU_watershed_scale/RF Processing")

## UPLOADING THE global NET CDF FILES CONTAINING GLOBAL LAND USE INFORMATION 
'###############################################################'

# upload the stack as a whole

global_LU_crop_NC = 'glcrop_1700-2007_0.5.nc'
global_LU_past_NC = 'glpast_1700-2007_0.5.nc'


# extract final Crop and Pasture Stack 
global_LU_past_NC.stack= stack(global_LU_past_NC)
global_LU_crop_NC.stack= stack(global_LU_crop_NC)

## UPLOADING THE global LAKE ERIE CENSUS LU rasters made in separate file
'###############################################################'
#call function built my Meghan McLeod which creates 2 raster bricks for LE 
# one brick (called crop_brick) has rasters of crop percentage from the census 
# one brick (called past_brick) has rasters of past percentage from the census

source("Building_Census_LU_rasters_RK.R") # this will give us crop_brick and past_brick

'###############################################################'


## UPLOADING THE SHAPEFILE OF WS TO CLIP TO (also upload census boundaries)
'###############################################################'

#iterate through shapefiles in a list 

setwd("C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/LE_Watershed_shapefiles/LE_ELEMENT_N/Reformatted")
shapelist = list.files(pattern='\\.shp$')
shapelist = shapelist[grepl('CAN',shapelist)] 

for (shp in 1:length(shapelist)){

  setwd("C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/LE_Watershed_shapefiles/LE_ELEMENT_N/Reformatted")
  name = shapelist[shp]
  thisshapeName = substr(name,1,nchar(name)-4)
  WS_shape = shapefile(name)
  WS_shape <- spTransform(WS_shape, proj4string(global_LU_crop_NC.stack)) 
  #WS_shape = shift(WS_shape,360) <-- only need this with RF
  
  setwd("C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/LE_landuse/LU_watershed_scale/RF Processing")
  
  ##################################################################################################
  #                 All FILES ARE SET UP & PROJECTED & IN THE RIGHT FORM 
  ##################################################################################################
  
  ##################################################################################################
  #                     EXTRACTING RK DATA FOR THE UPLOADED SHAPEFILE
  ##################################################################################################
  
  
  
  ## CLIPPING RK DATA TO WATERSHED AND AVERAGING TO GET ONE VAL PER YEAR
  '###############################################################'
  
  ## CLIPPING EACH CROP RASTER LAYER TO MY GIVEN WATERSHED 
  '-------------------------------------------------'
  
  nYears = nlayers(global_LU_crop_NC.stack)
  clipped_raster_stack_crop = stack()
  meanVals_crop = c()
  DATA_crop = c()
  
  print(paste0('clipping RK crop to ',thisshapeName))
  for (i in 1:nYears){
    level = i
    # creating a new clipped raster stack
    thisYearLU_tot = raster(global_LU_crop_NC.stack, level)
    thisYearLU_WS_crop = crop(thisYearLU_tot, extent(WS_shape)) # crop the raster file to the shape file
    thisYearLU_WS_crop_mask = mask(thisYearLU_WS_crop,WS_shape)
    
    #if shapefile is smaller than one grid - we will get an error, in this case, don't use mask just stick with the crop function 
    if (is.na(mean(values(thisYearLU_WS_crop_mask)))){thisYearLU_WS_crop_mask=thisYearLU_WS_crop}
    
    clipped_raster_stack_crop = stack (clipped_raster_stack_crop, thisYearLU_WS_crop_mask)
    # creating a vector with the mean val from each year
    data_crop = na.omit(values(thisYearLU_WS_crop_mask))
    DATA_crop = append(DATA_crop, data_crop)
    thisMean = mean(data_crop)
    meanVals_crop = append(meanVals_crop, thisMean)}
  
  
  ## CLIPPING EACH PASTURE LAYER TO MY GIVEN WATERSHED
  '-------------------------------------------------'
  
  nYears = nlayers(global_LU_past_NC.stack)
  clipped_raster_stack_past = stack()
  meanVals_past = c()
  DATA_past = c()
  
  print(paste0('clipping RK past to ',thisshapeName))
  for (i in 1:nYears){
    level = i
    # creating a new clipped raster stack
    thisYearLU_tot = raster(global_LU_past_NC.stack, level)
    
    thisYearLU_WS_past = crop(thisYearLU_tot, extent(WS_shape)) # crop the raster file to the shape file
    thisYearLU_WS_past_mask = mask(thisYearLU_WS_past,WS_shape)
    
    #if shapefile is smaller than one grid - we will get an error, in this case, don't use mask just stick with the crop function 
    if (is.na(mean(values(thisYearLU_WS_past_mask)))){thisYearLU_WS_past_mask=thisYearLU_WS_past}
    
    clipped_raster_stack_past = stack(clipped_raster_stack_past, thisYearLU_WS_past_mask)
    # creating a vector with the mean val from each year
    data_past = na.omit(values(thisYearLU_WS_past_mask))
    DATA_past = append(DATA_past, data_past)
    thisMean = mean(data_past)
    meanVals_past = append(meanVals_past, thisMean)}
  
  #taking the mean trajectory to get one vector for the entire watershed 
  '-------------------------------------------------'
  
  crop_RK = as.numeric(meanVals_crop)
  past_RK = as.numeric(meanVals_past)
  yearRK = as.numeric(1701:(1700+nYears))
  
  
  ##################################################################################################
  #                 GLOBAL RASTER DATSET IS CLIPPED AND PROCESSED FOR INPUTTED WATERSGED 
  ##################################################################################################
  
  
  ##################################################################################################
  #                                           EXTRACTING CENSUS LU DATA 
  #                      (raster was created using Building_Census_LU_rasters.R)
  ##################################################################################################
  
  
  
  # now manipulate rasters of LU data from the census: 
  '-------------------------------------------------'
  # the entire raster for census LU was calculated in separate script (ran above)
  
  ## CLIPPING EACH CROP LAYER TO MY GIVEN WATERSHED 
  '-------------------------------------------------'
  
  nYears = nlayers(crop_brick)
  clipped_crop_brick= stack()
  meanVals_crop = c()
  DATA_crop = c()
  
  print(paste0('clipping census crop to ',thisshapeName))
  for (i in 1:nYears){
    level = i
    # creating a new clipped raster stack
    thisYearLU_tot = raster(crop_brick, level)
    thisYearLU_WS_crop = crop(thisYearLU_tot, extent(WS_shape)) # crop the raster file to the shape file
    thisYearLU_WS_crop_mask = mask(thisYearLU_WS_crop,WS_shape)
    
    #if shapefile is smaller than one grid - we will get an error, in this case, don't use mask just stick with the crop function 
    if (is.na(mean(values(thisYearLU_WS_crop_mask)))){thisYearLU_WS_crop_mask=thisYearLU_WS_crop}
    
    clipped_crop_brick = stack (clipped_crop_brick, thisYearLU_WS_crop_mask)
    # creating a vector with the mean val from each year
    data_crop = na.omit(values(thisYearLU_WS_crop_mask))
    DATA_crop = append(DATA_crop, data_crop)
    thisMean = mean(data_crop)
    meanVals_crop = append(meanVals_crop, thisMean)}
  
  
  ## CLIPPING EACH PASTURE LAYER TO MY GIVEN WATERSHED
  '-------------------------------------------------'
  
  nYears = nlayers(past_brick)
  clipped_past_brick = stack()
  meanVals_past = c()
  DATA_past = c()
  
  print(paste0('clipping census past to ',thisshapeName))
  for (i in 1:nYears){
    level = i
    # creating a new clipped raster stack
    thisYearLU_tot = raster(past_brick, level)
    
    thisYearLU_WS_past = crop(thisYearLU_tot, extent(WS_shape)) # crop the raster file to the shape file
    thisYearLU_WS_past_mask = mask(thisYearLU_WS_past,WS_shape)
    
    #if shapefile is smaller than one grid - we will get an error, in this case, don't use mask just stick with the crop function 
    if (is.na(mean(values(thisYearLU_WS_past_mask)))){thisYearLU_WS_past_mask=thisYearLU_WS_past}
    
    clipped_past_brick = stack(clipped_past_brick, thisYearLU_WS_past_mask)
    # creating a vector with the mean val from each year
    data_past = na.omit(values(thisYearLU_WS_past_mask))
    DATA_past = append(DATA_past, data_past)
    thisMean = mean(data_past)
    meanVals_past = append(meanVals_past, thisMean)}
  
  #taking the mean trajectory to get one vector for the entire watershed 
  '-------------------------------------------------'
  
  crop_census = as.numeric(meanVals_crop)*100
  past_census = as.numeric(meanVals_past)*100
  yearCensus= 1930:2017
  
  
  
  # plot(yearRK,crop_RK)
  # lines(yearCensus,crop_census)
  # 
  # plot(yearRK,past_RK)
  # lines(yearCensus,past_census)
  # 
  # ##################################################################################################
  # #                 NOW COMBINE RK AND CENSUS BY SCALING RK TO THE BEGINNING OF CENSUS
  # ##################################################################################################
  combineYear = yearCensus[1]
  
  idxYear = match(combineYear,yearRK)
  idxPreYear = yearRK<=combineYear
  
  scalefactorCROP = crop_census[1]/crop_RK[idxYear]
  scalefactorPAST = past_census[1]/past_RK[idxYear] #this is an issue if pasture from RF is 0 in 1930 
  
  
  finalYear = c(yearRK[idxPreYear],yearCensus)
  finalCrop = c(crop_RK[idxPreYear]*scalefactorCROP,crop_census)
  finalPast = c(past_RK[idxPreYear]*scalefactorPAST,past_census)
  
  
  setwd("C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/LE_landuse/LU_watershed_scale/RF Processing/OUTPUTS/census_RK_output")
  write.csv(data.frame(finalYear,finalCrop,finalPast),file=paste0(thisshapeName,'_LU.csv'))
  
}
# 
# 


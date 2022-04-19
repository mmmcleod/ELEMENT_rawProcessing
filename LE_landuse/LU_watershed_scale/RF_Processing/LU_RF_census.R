rm(list=ls()) # clear the environment


# This script produces land use trajectories for an inputted watershed. 
# It intakes the Historical Land-Cover Change and Land-Use Conversions Global Data set
# Data availability: https://www.ncei.noaa.gov/access/metadata/landing-page/bin/iso?id=gov.noaa.ncdc:C00814
# and uses the RF trajectories to clip LU data for pre 1930. while it uses crop area/county area from 1930s on 

#RF
#https://www.ncei.noaa.gov/thredds/ncss/ncFC/sat/landcover-RFAREAVEG-fc/Historical_Land-Cover_Change_and_Land-Use_Conversions_Global_Dataset:_RF_AREAVEG_Feature_Collection_best.ncd/dataset.html

##################################################################################################
## SETTING UP
##################################################################################################

  whichSet = 3 #(we are going to be looking at RF and scaling using census data)
  
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
  
  ## UPLOADING THE global NET CDF FILES CONTAINING GLOBAL LAND USE INFORMATION 
  '###############################################################'
  
  # upload the stack as a whole
  
  if (whichSet==1 ){global_LU_NC = "Historical_Land-Cover_Change_and_Land-Use_Conversions_Global_Dataset__HYDE_AREAVEG_Feature_Collection_best.ncd.nc"}
  if (whichSet==2 ){global_LU_NC = "Historical_Land-Cover_Change_and_Land-Use_Conversions_Global_Dataset__HH_AREAVEG_Feature_Collection_best.ncd.nc"}
  if (whichSet==3 ){global_LU_NC = "Historical_Land-Cover_Change_and_Land-Use_Conversions_Global_Dataset__RF_AREAVEG_Feature_Collection_best.ncd.nc"}
  
  
  # extract crop and pasture variables from LU rasters 
  global_LU_C3crop_NC.stack = stack(global_LU_NC,varname='C3crop')
  global_LU_C4past_NC.stack = stack(global_LU_NC,varname='C3past')
  global_LU_C4crop_NC.stack = stack(global_LU_NC,varname='C4crop')
  global_LU_C3past_NC.stack = stack(global_LU_NC,varname='C4past')
  
  
  # extract final Crop and Pasture Stack 
  global_LU_past_NC.stack=global_LU_C3past_NC.stack+global_LU_C4past_NC.stack
  global_LU_crop_NC.stack=global_LU_C3crop_NC.stack+global_LU_C4crop_NC.stack
  
  
  # look at the fist layer in the net cdf (just for visualization )
  layer1_global_LU_C3_crop = raster('Historical_Land-Cover_Change_and_Land-Use_Conversions_Global_Dataset__HYDE_AREAVEG_Feature_Collection_best.ncd.nc',level=1,varname='C3crop')
  
  ## UPLOADING THE global LAKE ERIE CENSUS LU rasters made in separate file
  '###############################################################'
  #call function built my Meghan McLeod which creates 2 raster bricks for LE 
  # one brick (called crop_brick) has rasters of crop percentage from the census 
  # one brick (called past_brick) has rasters of past percentage from the census
  
  source("Building_Census_LU_rasters.R") # this will give us crop_brick and past_brick

'###############################################################'


## UPLOADING THE SHAPEFILE OF WS TO CLIP TO (also upload census boundaries)
'###############################################################'

#iterate through shapefiles in a list 

setwd('C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/LE_gauges/Extracting Data/Canada/Gauge_Watersheds/CANADA/From OFAT/')
shapelist = list.files(pattern='\\.shp$')

for (shp in 1:length(shapelist)){
setwd('C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/LE_gauges/Extracting Data/Canada/Gauge_Watersheds/CANADA/From OFAT/')
  
name = shapelist[shp]
thisshapeName = substr(name,1,nchar(name)-4)
WS_shape = shapefile(name)
WS_shape <- spTransform(WS_shape, proj4string(global_LU_crop_NC.stack)) 
WS_shape = shift(WS_shape,360)

setwd("C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/LU_processing/LU_watershed_scale/RF Processing/")

##################################################################################################
#                 All FILES ARE SET UP & PROJECTED & IN THE RIGHT FORM 
##################################################################################################

##################################################################################################
#                     EXTRACTING RF DATA FOR THE UPLOADED SHAPEFILE
##################################################################################################



## CLIPPING RF DATA TO WATERSHED AND AVERAGING TO GET ONE VAL PER YEAR
'###############################################################'

## CLIPPING EACH CROP RASTER LAYER TO MY GIVEN WATERSHED 
'-------------------------------------------------'

nYears = nlayers(global_LU_crop_NC.stack)
clipped_raster_stack_crop = stack()
meanVals_crop = c()
DATA_crop = c()

print(paste0('clipping RF crop to ',thisshapeName))
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

print(paste0('clipping RF past to ',thisshapeName))
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

crop_RF = as.numeric(meanVals_crop)
past_RF = as.numeric(meanVals_past)
yearRF = as.numeric(1771:(1770+nYears))


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



# plot(yearRF,crop_RF)
# lines(yearCensus,crop_census)
# 
# plot(yearRF,past_RF)
# lines(yearCensus,past_census)
# 
# ##################################################################################################
# #                 NOW COMBINE RF AND CENSUS BY SCALING RF TO THE BEGINNING OF CENSUS
# ##################################################################################################
combineYear = yearCensus[1]

idxYear = match(combineYear,yearRF)
idxPreYear = yearRF<=combineYear

scalefactorCROP = crop_census[1]/crop_RF[idxYear]
scalefactorPAST = past_census[1]/past_RF[idxYear] #this is an issue if pasture from RF is 0 in 1930 


finalYear = c(yearRF[idxPreYear],yearCensus)
finalCrop = c(crop_RF[idxPreYear]*scalefactorCROP,crop_census)
finalPast = c(past_RF[idxPreYear]*scalefactorPAST,past_census)


setwd("C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/LU_processing/LU_watershed_scale/RF Processing/OUTPUTS/census_RF_output/")
write.csv(data.frame(finalYear,finalCrop,finalPast),file=paste0(thisshapeName,'_LU.csv'))

}
# 
# 
# ##################################################################################################
# #                              FINAL PLOTS FOR VISUALIZATION 
# ##################################################################################################
# 
# 
# 
# # now plot all together (crop)
# plot(0,0,xlim = c(finalYear[1],finalYear[length(finalYear)]),ylim = c(0,100),type = "n",col.lab="white")
# title(main="Crop Percent GRW", ylab="Percent Crop (%)", xlab="YEAR")
# 
# cl <- rainbow(3)
# lines(yearRF,crop_RF,col=cl[1],type="l", lwd=3)
# lines(finalYear,finalCrop,col=cl[3],type="l", lwd=3)
# lines(yearCensus,crop_census,col=cl[2],type="l", lwd=3)
# legend("topleft", legend = c("RF original", "Census", "Combined and Scaled"), col=cl[c(1,3,2)], pch=1) # optional legend
# 
# # now plot all together (past)
# plot(0,0,xlim = c(finalYear[1],finalYear[length(finalYear)]),ylim = c(0,40),type = "n",col.lab="white")
# title(main="Pasture Percent GRW", ylab="Percent Pasture (%)", xlab="YEAR")
# 
# cl <- rainbow(3)
# lines(yearRF,past_RF,col=cl[1],type="l", lwd=3)
# lines(finalYear,finalPast,col=cl[3],type="l", lwd=3)
# lines(yearCensus,past_census,col=cl[2],type="l", lwd=3)
# legend("topleft", legend = c("RF original", "Census", "Combined and Scaled"), col=cl[c(1,3,2)], pch=1) # optional legend
# 
# 
# 
# 
# 
# # plot(year,crop)
# # plot(year,past)
# # plot(year,past+crop)
# # 
# # output=data.frame(year,crop,past)
# # names(output)=c("YEAR","CROP","PAST")
# # 
# # 
# # setwd("C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/LU_processing/LU_watershed_scale/RF")
# # write.csv(output, file = fileOut)
# 

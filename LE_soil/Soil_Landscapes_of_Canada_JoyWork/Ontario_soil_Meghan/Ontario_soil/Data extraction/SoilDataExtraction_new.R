#############################################
#clear global environment and console
#############################################
cat("\014")  
rm(list=ls()) 
#############################################
# load libraries and packages and workplace
# only load packages once
#############################################

install.packages("ncdf4") # for NC files
install.packages("orgutils") # for shape files
install.packages("sf")
install.packages(c("readxl","writexl","xlsx"))
install.packages("raster")
install.packages("rgdal")
install.packages("ggplot2")
install.packages("maptools")
install.packages("xlsx")

library(foreign)
library(raster)
library(rgdal)
library(sf)
library(xlsx)
library(readxl)
library(ggplot2)
library(writexl)
library(ggplot2)
library(maptools)
ggplot()+geom_sf(data=)

##################################################
# set working directory
# where soil maps/ watershed shapefiles are
##################################################

# setwd("C:/Users/kvanm_000/Desktop/SOIL")
setwd("C:\Users\Joy\Documents\MRch_GIS\Ontario_soil_Meghan\Ontario_soil")

# -------------------------------------------------------
#EXTRACTING SOIL DATA FOR A GIVEN WATERSHED
# -------------------------------------------------------


##################################################
# clip the ontario soil shapefile to given shapefile
##################################################

# pull in the shapefiles
Watershed = st_read('GRW_whole_york.shp') #<= this is the watershed polygon
ontarioSoil = st_read('dss_v3_on.shp') #<= this is the ontario soil shapefile (Has POLY_ID)

# ensure the crs of the two match for clipping
Watershed=st_transform(Watershed,st_crs(ontarioSoil))

# clip to the watershed
clipped_Ontario_soil = st_intersection(ontarioSoil,Watershed)


# save this so don't have to repeat clipping 
write_sf(clipped_Ontario_soil, "clipped_Ontario_soil_GRW.shp")

#Wclipped_Ontario_soil = st_read("clipped_Ontario_soil_thames.shp")
##################################################
# ensure data we have is correct
##################################################

head(clipped_Ontario_soil) # this will give us the polygons and their areas
## plot(clipped_Ontario_soil) # plot check 

##################################################
#grabbing info from the other DBF files

# this soil data has multiple component pieces 
# which need to be linked 
##################################################

data1 <- read.dbf("dss_v3_on_cmp.dbf") # this will give us the soil ID(s) for each polygon
head(data1)
data2 <- read.dbf("soil_layer_on_v2.dbf") # this will give us the soil nutrient info for each soil type
head(data2)

# getting soil ID associated with the polyIDs
allPolyIDs = data1$POLY_ID
allPolyIDs = as.list(paste(allPolyIDs))
allSoilIDs = data1$SOIL_ID
allSoilIDs = as.list(paste(allSoilIDs))

# extract the list of polyIDs we need data for
mypolyIDs = unique(clipped_Ontario_soil$POLY_ID)
mypolyIDs = as.list(paste(mypolyIDs))

# extract info only relavent to watershed of interest
WS_polyIDS = rep(list(NA),0)
WS_soilIDS = rep(list(NA),0)

for(i in 1:length(allPolyIDs)){
  if (is.element(allPolyIDs[[i]],mypolyIDs)){
    WS_polyIDS= append(WS_polyIDS,allPolyIDs[[i]])
    WS_soilIDS= append(WS_soilIDS,allSoilIDs[[i]])
  }
}

##################################################
# Now we have poly IDs and their associated soil IDs, next we will need to extract 
# the soil data while considering soil layering
##################################################


# number of soil IDs we are considering
uniqueSoil = unique(WS_soilIDS)
numSoil = length(uniqueSoil)

# extract all soil data of specific interest
soil_data.ID = as.list(paste(data2$SOIL_ID))
soil_data.depth = as.list(paste(data2$LDEPTH))
soil_data.sand = as.list(paste(data2$TSAND))
soil_data.silt = as.list(paste(data2$TSILT))
soil_data.clay = as.list(paste(data2$TCLAY))
soil_data.carbon = as.list(paste(data2$ORGCARB))
soil_data.BD= as.list(paste(data2$BD))

# only collect this info for watershed of interest 
soilDatalist= rep(list(NA),numSoil)

for (i in 1:numSoil){
  this_soil = uniqueSoil[[i]]
  for (j in 1:length(soil_data.ID)){
    if (soil_data.ID[[j]] == this_soil){
      soilDatalist[[i]]=append(soilDatalist[[i]],list(soil_data.depth[[j]],soil_data.sand[[j]],soil_data.silt[[j]],soil_data.clay[[j]],soil_data.carbon[[j]],soil_data.BD[[j]]))
    }
  }
}

##################################################
# now we need to combine this soil data for each of the soil IDs
##################################################

# temporary: remove NaNs, put into matrix form 
for(i in 1:length(soilDatalist)){
  this = soilDatalist[[i]]
  soilDatalist[[i]] = this[-1]
  soilDatalist[[i]] = matrix(soilDatalist[[i]],nrow = 6)
}

# soilDatalist gives a matrix for each soil id which is nxm
# where n is each of the 6 attributes and m is number of layers

WS_dataVals= rep(list(NA),numSoil)

for (i in 1:length(WS_polyIDS)){
  thisSoilID = WS_soilIDS[[i]]
  for (j in 1:length(uniqueSoil)){
    if(uniqueSoil[[j]]==thisSoilID){
      WS_dataVals[[i]] = soilDatalist[[j]]
    }
  }
}

##################################################
# Now we have a list of polyIDs in our watershed, 
# each counties corresponding soil ID(s) and each soil ID's nutrient information 
# the rest will be  weighted averaging the values we have collected
# to first soil layer and then geography
##################################################

# weighting according to soil layer
WS_dataVals_weighted= rep(list(NA),numSoil)

for (i in 1:length(WS_dataVals)){
  thisSoilInfo = WS_dataVals[[i]]
  nLayers = ncol(thisSoilInfo)
  if (nLayers>0)
  {totalDepth = as.numeric(thisSoilInfo[[1,nLayers]])}
  if (nLayers > 1){
    k = nLayers
    for (j in 2:nLayers){
      thisSoilInfo[[1,k]] = (as.numeric(thisSoilInfo[[1,k]])-as.numeric(thisSoilInfo[[1,k-1]]))/totalDepth
      k = k-1
    }
  }
  if (nLayers>0)
  {thisSoilInfo[[1,1]] = as.numeric(thisSoilInfo[[1,1]])/totalDepth}
  WS_dataVals_weighted[[i]] = thisSoilInfo
}

# group together 
WS_dataVals_mean= rep(list(NA),numSoil)


for (i in 1:length(WS_dataVals_weighted)){
  thisSoilInfo = WS_dataVals_weighted[[i]]
  nLayers = ncol(thisSoilInfo)
  average_sand = 0
  average_silt = 0
  average_clay = 0
  average_carbon = 0
  average_BD = 0
  if (nLayers>0){
    for (j in 1:nLayers){
      average_sand = average_sand + as.numeric(thisSoilInfo[[2,j]])*as.numeric(thisSoilInfo[[1,j]])
      average_silt = average_silt + as.numeric(thisSoilInfo[[3,j]])*as.numeric(thisSoilInfo[[1,j]])
      average_clay = average_clay + as.numeric(thisSoilInfo[[4,j]])*as.numeric(thisSoilInfo[[1,j]])
      average_carbon = average_carbon + as.numeric(thisSoilInfo[[5,j]])}*as.numeric(thisSoilInfo[[1,j]])
    average_BD = average_BD + as.numeric(thisSoilInfo[[6,j]])}*as.numeric(thisSoilInfo[[1,j]])
  WS_dataVals_mean[[i]] = list(average_sand,average_silt,average_clay,average_carbon,average_BD)
}
if (nLayers==0){WS_dataVals_mean[[i]] = 0}


##################################################
# collect info on each parameter od interest and get its mean
##################################################

#bulk density ..............................................................
WS_BD= rep(list(NA),length(mypolyIDs))
for (i in 1:length(mypolyIDs))
{
  #print(i)
  L = rep(list(NA),1)
  
  for (j in 1:length(WS_dataVals_mean))
    
  {if(mypolyIDs[[i]] == WS_polyIDS[[j]]) 
  {this = WS_dataVals_mean[[j]]
  if (is.na(this[[5]])){L = append(L,0)} # BD
  if (is.finite(this[[5]])){L = append(L,this[[5]])} # BD
  }
  }
  WS_BD[[i]] = Reduce(mean,L[2:length(L)])
}
mean_BD = mean(unlist(WS_BD[WS_BD!=0])) 
#sand ..............................................................
WS_sand= rep(list(NA),length(mypolyIDs))
for (i in 1:length(mypolyIDs))
{
  #print(i)
  L = rep(list(NA),1)
  
  for (j in 1:length(WS_dataVals_mean))
    
  {if(mypolyIDs[[i]] == WS_polyIDS[[j]]) 
  {this = WS_dataVals_mean[[j]]
  if (is.na(this[[1]])){L = append(L,0)} # sand
  if (is.finite(this[[1]])){L = append(L,this[[1]])} # sand
  }
  }
  WS_sand[[i]] = Reduce(mean,L[2:length(L)])
}
mean_sand = mean(unlist(WS_sand[WS_sand!=0])) 
#silt .............................................................
WS_silt = rep(list(NA),length(mypolyIDs))
for (i in 1:length(mypolyIDs))
{
  #print(i)
  L = rep(list(NA),1)
  
  for (j in 1:length(WS_dataVals_mean))
    
  {if(mypolyIDs[[i]] == WS_polyIDS[[j]]) 
  {this = WS_dataVals_mean[[j]]
  if (length(this)>1){
    if (is.na(this[[2]])){L = append(L,0)} # silt
    if (is.finite(this[[2]])){L = append(L,this[[2]])}}
  if (length(this) ==1) {L = append(L,0)}# silt
  }
  }
  WS_silt[[i]] = Reduce(mean,L[2:length(L)])
}
mean_silt = mean(unlist(WS_silt[WS_silt!=0])) 
#clay .............................................................
WS_clay = rep(list(NA),length(mypolyIDs))
for (i in 1:length(mypolyIDs))
{
  #print(i)
  L = rep(list(NA),1)
  
  for (j in 1:length(WS_dataVals_mean))
    
  {if(mypolyIDs[[i]] == WS_polyIDS[[j]]) 
  {this = WS_dataVals_mean[[j]]
  if (length(this)>1){
    if (is.na(this[[3]])){L = append(L,0)} # clay
    if (is.finite(this[[3]])){L = append(L,this[[3]])}}
  if (length(this) ==1) {L = append(L,0)}# clay
  }
  }
  WS_clay[[i]] = Reduce(mean,L[2:length(L)])
}
mean_clay = mean(unlist(WS_clay[WS_clay!=0])) 
#carbon .............................................................
WS_carbon = rep(list(NA),length(mypolyIDs))
for (i in 1:length(mypolyIDs))
{
  #print(i)
  L = rep(list(NA),1)
  
  for (j in 1:length(WS_dataVals_mean))
    
  {if(mypolyIDs[[i]] == WS_polyIDS[[j]]) 
  {this = WS_dataVals_mean[[j]]
  if (length(this)>1){
    if (is.na(this[[4]])){L = append(L,0)} # carbon
    if (is.finite(this[[4]])){L = append(L,this[[4]])}}
  if (length(this) ==1) {L = append(L,0)}# carbon
  }
  }
  WS_carbon[[i]] = Reduce(mean,L[2:length(L)])
}
mean_carbon = mean(unlist(WS_carbon[WS_carbon!=0])) 


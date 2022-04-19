### for calculating Soil Landscapes of Canada weighted average soil properties (soil depth) --> kg/ha
# KSAT
# Bulk Density (BD) g/cm3 a.k.a. Porosity (n) %

# set up
cat("/014")  
rm(list=ls()) 

# install.packages("orgutils") # for shape files
# install.packages("sf")
# install.packages(c("readxl","writexl","xlsx"))
# install.packages("raster")
# install.packages("rgdal")
# install.packages("ggplot2")
# install.packages("maptools")
# 
library(foreign)
library(rgdal)
library(sf)
library(xlsx)
library(readxl)
library(ggplot2)
library(writexl)
library(ggplot2)
library(maptools)
library(tidyverse)

# read in soil polygon shapefile

setwd("C:/Users/Joy/Documents/MRch_GIS/Ontario_soil_Meghan/Ontario_soil")
SOIL_poly = st_read('clipped_Ontario_soil_GRW.shp')

# read in dss component table
setwd("C:/Users/Joy/Documents/MRch_GIS/Soil Landscapes of Canada")
SOIL_comp = read.dbf("dss_v3_on_cmp.dbf")

# read in soil layer information table 
SOIL_layr = read.dbf("soil_layer_on_v2.dbf")

# ***** EDIT INPUTS ***** (1/2)
fname = "GRW_whole_valid"

  # Weighted average soil properties for all watersheds
  
  # ***** EDIT INPUTS ***** read in subbasin delineation shapefile (2/2)
  
  setwd("C:/Users/Joy/Documents/MRch_GIS/GRW Watershed")
  
  WSHD = st_read(paste0(fname,'.shp'))
  
  # set same CRS
  SOIL_proj = st_transform(SOIL_poly,st_crs(WSHD))
  
  # clip 
  SOIL_subbas_clip = st_intersection(st_buffer(SOIL_proj,0),st_buffer(WSHD,0))
  SOIL_subbas = subset(SOIL_subbas_clip,select = c(POLY_ID,geometry))
  SOIL_subbas$SOIL_ID = c("NULL") # create column for SOIL_ID
  SOIL_subbas$BD = 0
  SOIL_subbas$n = 0
  SOIL_subbas$KSAT = 0
  
  # join clipped SOIL_subbas to component table using POLY_ID to get associated SOIL_ID
  x <- length(SOIL_subbas)
  
  # for each polygon
  for (i in 1:nrow(SOIL_subbas)) {
    idx = match(SOIL_subbas$POLY_ID[i],SOIL_comp$POLY_ID)
    SOIL_subbas$SOIL_ID[i]=as.character(SOIL_comp$SOIL_ID[idx])
  }
  
  # calculate area 
  SOIL_subbas$AREA = st_area(SOIL_subbas)               # sqm
  
  # Calculate soil column mass using bulk density
  SOIL_missing = data.frame(SOIL_ID = NA)
  SOIL_missingBD = data.frame(SOIL_ID = NA)
  SOIL_missingKSAT = data.frame(SOIL_ID = NA)
  SOIL_difflen = data.frame(SOIL_ID = NA)
  
  # for each soil polygon in subbasin, calculate soil characteristic
  for (i in 1:nrow(SOIL_subbas)){
    idx = which(SOIL_subbas$SOIL_ID[i]==SOIL_layr$SOIL_ID)
    
    if (length(idx)==0) {
      SOIL_missing = rbind(SOIL_missing,SOIL_subbas$SOIL_ID[i])
      next
    }
    
    
    RAW = cbind(SOIL_layr$LAYER_NO[idx],SOIL_layr$UDEPTH[idx],SOIL_layr$LDEPTH[idx],SOIL_layr$BD[idx],SOIL_layr$ORGCARB[idx],SOIL_layr$KP33[idx],SOIL_layr$KSAT[idx])
    RAWsort= as.data.frame(RAW[order(RAW[,1]),])
    
    if (length(idx)==1){
      RAWsort = t(RAWsort)
    }
    
    
    # 1 LAYNO | 2 UPDEPTH | 3 LDEPTH | 4 BD | 5 OC | 6 KP33  | 7 Ksat
    # for each layer in soil polygon
    for (j in 1:NROW(RAWsort)){        # calculations for Calculating Org C kg/ha in a polygon
      # also depth weighted averaged Bulk density (g/cm^3)
      
      DPTHj = (RAWsort[j,3]-RAWsort[j,2])/100 # in metres
      
      ## Bulk Density 
      if (RAWsort[j,4]>=0){
        BDj = RAWsort[j,4]*1000 # g/cm^3 to kg/m^3
        
        # if info in a layer is missing
        # ...and there is only 1 row
      } else if (NROW(RAWsort)==1){
        SOIL_missingBD = rbind(SOIL_missingBD,SOIL_subbas$SOIL_ID[i])
        
        #...and it is the first layer, use the next layer info
      } else if (j == 1) {
        BDj = RAWsort[j+1,4]*1000
        
        #...and it is the last layer, use the previous layer
      }else if (j == NROW(RAWsort)) {
        BDj = RAWsort[j-1,4]*1000
        
        #...and it is a layer in the middle, use the average of the bounding layers
      }else if (j < NROW(RAWsort) && j>1){
        BDj = average(RAWsort[j-1,4],RAWsort[j+1,4])*1000
        
      }
      
      ## Organic Carbon
      if (RAWsort[j,5]>-9){
        OCj = RAWsort[j,5]/100
        
      } else if (NROW(RAWsort)==1){
        SOIL_missingOC = rbind(SOIL_missingOC,SOIL_subbas$SOIL_ID[i])
        
        
      } else if (j == 1) {
        OCj = RAWsort[j+1,5]/100
        
      }else if (j == NROW(RAWsort)) {
        OCj = RAWsort[j-1,5]/100
        
        
      }else if (j < NROW(RAWsort) && j>1){
        OCj = average(RAWsort[j-1,5],RAWsort[j+1,5])/100
        
      }
      
      ## water retention at 33 KPa
      if (RAWsort[j,6]>-9){
        THETAj = RAWsort[j,6]/100
        
      } else if (NROW(RAWsort)==1){
        SOIL_missingTHETA = rbind(SOIL_missingTHETA,SOIL_subbas$SOIL_ID[i])
        
      } else if (j ==1){
        THETAj = RAWsort[j+1,6]/100
        
      } else if (j == nrow(RAWsort)) {
        THETAj = RAWsort[j-1,6]/100
        
      }else if (j <NROW(RAWsort) && j>1){
        THETAj = average(RAWsort[j-1,6],RAWsort[j+1,6])/100
      }
      
      ## KSAT 
      if (RAWsort[j,7]>-9){
        KSATj = RAWsort[j,7]
      } else if (nrow(RAWsort)==1){
        SOIL_missingKSAT = rbind(SOIL_missingKSAT,SOIL_subbas$SOIL_ID[i])
        
      } else if (j==1){
        KSATj = Rawsort[j+1,7]
        
      } else if (j == nrow(RAWsort)){
        KSATj = RAWsort[j-1,7]
        
      } else if (j<nrow(RAWsort) && j>1){
        KSATj = average(RAWsort[j-1,7],RAWsort[j+1,7])
      }
      
      SOIL_subbas$BD[i] = SOIL_subbas$BD[i]+BDj*DPTHj 
      SOIL_subbas$KSAT[i] = SOIL_subbas$KSAT[i]+KSATj*DPTHj
      
      
    }
    
    DPTHi = (RAWsort[nrow(RAWsort),3]-RAWsort[1,2])/100   # total depth of soil profile [m]
    SOIL_subbas$BD[i] = SOIL_subbas$BD[i]/DPTHi/1000    # g/cm3
    SOIL_subbas$n[i] = 1-SOIL_subbas$BD[i]/2.65
    
  }
  
  
  ### calculate weighted characteristics for subbasin by polygon area

  # write to file
  setwd("C:/Users/Joy/Documents/MRch_GIS/Soil Landscapes of Canada")
  st_write(SOIL_subbas,"depth_weighted_avg_wholeGRW.shp")
  # 
  # SOIL_subbas_data = st_drop_geometry(SOIL_subbas)
  # setwd("C:/Users/Joy/Documents/MRch_GIS/Soil Landscapes of Canada/Processed Subbasin")
  # write.xlsx(SOIL_subbas_data,paste0('C:/Users/Joy/Documents/MRch_GIS/Soil Landscapes of Canada/Processed Subbasin/depth_weighted_avg_GRW.xlsx'))


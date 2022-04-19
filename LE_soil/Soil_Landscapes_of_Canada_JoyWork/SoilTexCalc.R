### for calculating Soil Landscapes of Canada weighted average soil properties (soil depth)
# soil textures

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

## read in soil polygon shapefile
# please clip the soil polygon shapefile first to your watershed and then read it in as 

setwd("C:/Users/Joy/Documents/MRch_GIS/Ontario_soil_Meghan/Ontario_soil")
SOIL_poly = st_read('dss_v3_on.shp')
# SOIL_poly = st_read('clipped_Ontario_soil_GRW.shp')

# read in dss component table
setwd("C:/Users/Joy/Documents/MRch_GIS/Soil Landscapes of Canada")
SOIL_comp = read.dbf("dss_v3_on_cmp.dbf")

# read in soil layer information table 
SOIL_layr = read.dbf("soil_layer_on_v2.dbf")

# ***** EDIT INPUTS ***** (1/2)
fname = sapply(read_xlsx('C:/Users/Joy/Documents/MRch_GIS/GRW Watershed/subbas_names.xlsx',col_names = FALSE),as.character)
# fname = "GRW_whole_valid"
# fname = t(cbind("subbas_2GA010_nested"))
# fname = "2GA028"
# *************************

SOIL_subbas_avg = data.frame(fname)
SOIL_subbas_avg$SAND = NA
SOIL_subbas_avg$SILT = NA
SOIL_subbas_avg$CLAY = NA

for (k in 1:length(fname)){
  # Weighted average soil properties for all watersheds
  
  fnamek = fname[k]
  # fnamek = fname
  
  # ***** EDIT INPUTS ***** read in subbasin delineation shapefile (2/2)
  
  # setwd("C:/Users/Joy/Documents/MRch_GIS/GRW Watershed")
  setwd("C:/Users/Joy/Documents/MRch_GIS/GRW Watershed/subbas")
  # ***********************
  
  # WSHD = st_read(paste0(fnamek,'.shp'))
  WSHD = st_read(paste0('subbas_',fnamek,'.shp'))
  
  # set same CRS
  SOIL_proj = st_transform(SOIL_poly,st_crs(WSHD))
  
  # clip 
  SOIL_subbas_clip = st_intersection(st_buffer(SOIL_proj,0),st_buffer(WSHD,0))
  SOIL_subbas = subset(SOIL_subbas_clip,select = c(POLY_ID,geometry))
  SOIL_subbas$SOIL_ID = c("NULL") # create column for SOIL_ID
  SOIL_subbas$SAND = 0
  SOIL_subbas$SILT = 0
  SOIL_subbas$CLAY = 0
  
  # join clipped SOIL_subbas to component table using POLY_ID to get assSILTiated SOIL_ID
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
  SOIL_missingSAND = data.frame(SOIL_ID = NA)
  SOIL_missingSILT = data.frame(SOIL_ID = NA)
  SOIL_missingCLAY = data.frame(SOIL_ID = NA)
  SOIL_difflen = data.frame(SOIL_ID = NA)
  
  # for each soil polygon in subbasin, calculate soil characteristic
  for (i in 1:nrow(SOIL_subbas)){
    
    idx = which(SOIL_subbas$SOIL_ID[i]==SOIL_layr$SOIL_ID)
    
      if (length(idx)==0) {
      SOIL_missing = rbind(SOIL_missing,SOIL_subbas$POLY_ID[i])
      SOIL_subbas$SAND[i]=NA
      SOIL_subbas$SILT[i]=NA
      SOIL_subbas$CLAY[i]=NA
      SOIL_subbas$AREA[i]=NA
      
      next
    }
    
    
    RAW = cbind(SOIL_layr$LAYER_NO[idx],SOIL_layr$UDEPTH[idx],SOIL_layr$LDEPTH[idx],SOIL_layr$TSAND[idx],SOIL_layr$TSILT[idx],SOIL_layr$TCLAY[idx])
    RAWsort= as.data.frame(RAW[order(RAW[,1]),])
    
    if (length(idx)==1){
      RAWsort = t(RAWsort)
    }
    
    
    # 1 LAYNO | 2 UPDEPTH | 3 LDEPTH | 4 SAND | 5 SILT | 6 CLAY
    
    # check how many layers have complete soil texture data 
    # assume that if a layer has data for sand, it has data for silt and clay too, and vice versa
    # if only one layer available, use that layer data for all
    
    ind = which(RAWsort[,4]>0)
    
    if (length(ind)==1) {
      
      
      DPTHj = RAWsort[nrow(RAWsort),3]/100 # in metres
      
      SOIL_subbas$SAND[i] = RAWsort[ind,4]*DPTHj
      SOIL_subbas$SILT[i] = RAWsort[ind,5]*DPTHj
      SOIL_subbas$CLAY[i] = RAWsort[ind,6]*DPTHj
      
      
  # if there is no data
    } else if(length(which(RAWsort[,4]>0))==0){  
      
      SOIL_missingSAND = rbind(SOIL_missingSAND,SOIL_subbas$SOIL_ID[i])
      
      } else { # if there is more than 1 layer of data, go through each layer  
       
    #     for each layer in soil polygon, fill in missing data
          for (j in 1:NROW(RAWsort)){
    
          DPTHj = (RAWsort[j,3]-RAWsort[j,2])/100 # in metres
      
      
          ## SAND
          if (any(ind==j)){
            SANDj = RAWsort[j,4]
        
            #...and it is the first layer, use the next available layer info
              } else if (j == 1) {
                SANDj = RAWsort[min(ind),4]
        
            #...and it is the last layer, use the previous available layer
          }else if (j == NROW(RAWsort)) {
            SANDj = RAWsort[tail(ind,1),4]
        
            #...and it is a layer in the middle, use the average of the bounding layers
          }else if (j < NROW(RAWsort) && j>1){
            
            DIF = ind-j
            MINDIF = sort(DIF)[1:2]
            INDAVG = which(DIF %in% MINDIF)
            SANDj = average(RAWsort[INDAVG[1],4],RAWsort[INDAVG[2],4])
        
        }
      
      ## Silt
      if (any(ind==j)){
        SILTj = RAWsort[j,5]
       
        
        } else if (j == 1) {
          SILTj = RAWsort[min(ind),5]
        
        }else if (j == NROW(RAWsort)) {
          SILTj = RAWsort[tail(ind,1),5]
        
        
        }else if (j < NROW(RAWsort) && j>1){

          SILTj = average(RAWsort[INDAVG[1],5],RAWsort[INDAVG[2],5])
        
      }
      
      ## Clay
      if (RAWsort[j,6]>-9){
        CLAYj = RAWsort[j,6]

        } else if (j == 1){
          CLAYj = RAWsort[min(ind),6]
        
        } else if (j == nrow(RAWsort)) {
          CLAYj = RAWsort[tail(ind,1),6]
        
        }else if (j <NROW(RAWsort) && j>1){
          
          CLAYj = average(RAWsort[INDAVG[1],6],RAWsort[INDAVG[2],6])
      }
      
      
      SOIL_subbas$SAND[i] = SOIL_subbas$SAND[i]+SANDj*DPTHj
      SOIL_subbas$SILT[i] = SOIL_subbas$SILT[i]+SILTj*DPTHj
      SOIL_subbas$CLAY[i] = SOIL_subbas$CLAY[i]+CLAYj*DPTHj
      
      
    }
      }
      
    DPTHi = RAWsort[nrow(RAWsort),3]/100   # total depth of soil profile [m]
    SOIL_subbas$SAND[i] = SOIL_subbas$SAND[i]/DPTHi    # 
    SOIL_subbas$SILT[i] = SOIL_subbas$SILT[i]/DPTHi
    SOIL_subbas$CLAY[i] = SOIL_subbas$CLAY[i]/DPTHi

  }
  
  
  ### calculate weighted characteristics for subbasin by polygon area
  SOIL_subbas_avg$subbas_ID[k] = fnamek
  
  TOTAREA = sum(SOIL_subbas$AREA,na.rm=TRUE)                # sqm
  
  # SAND
  SOIL_subbas_avg$SAND[k] = sum(SOIL_subbas$SAND*(SOIL_subbas$AREA/TOTAREA),na.rm=TRUE)
  
  # SILT
  SOIL_subbas_avg$SILT[k] = sum(SOIL_subbas$SILT*(SOIL_subbas$AREA/TOTAREA),na.rm=TRUE)
  
  # CLAY
  SOIL_subbas_avg$CLAY[k] = sum(SOIL_subbas$CLAY*(SOIL_subbas$AREA/TOTAREA),na.rm=TRUE)
  #,na.rm = TRUE
  
  # write to file
  # setwd("C:/Users/Joy/Documents/MRch_GIS/Soil Landscapes of Canada/Processed Subbasin")
  
  # st_write(SOIL_subbas,paste0("SOIL_",fnamek,".shp"),delete_dsn=TRUE)
  # write.xlsx(unique(SOIL_missing),paste0('SOIL_missing',fnamek,'.xlsx'))
  # write.xlsx(unique(SOIL_missingSAND),paste0('SOIL_missingSAND',fnamek,'.xlsx'))
  # write.xlsx(unique(SOIL_missingSILT),paste0('SOIL_missingSILT',fnamek,'.xlsx'))
  # write.xlsx(unique(SOIL_difflen),paste0('SOIL_difflen',fnamek,'.xlsx'))
  
  
}

write.xlsx(SOIL_subbas_avg,paste0('C:/Users/Joy/Documents/MRch_GIS/Soil Landscapes of Canada/Processed Subbasin/SOIL_subbas_SoilText.xlsx'))


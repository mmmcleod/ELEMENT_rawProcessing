### for calculating Soil Landscapes of Canada weighted average soil properties (soil depth) --> kg/ha
## WARNING: THIS CODE NEEDS FIXING! 20190816

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
# # 
# library(foreign)
# library(rgdal)
# library(sf)
# library(xlsx)
# library(readxl)
# library(ggplot2)
# library(writexl)
# library(ggplot2)
# library(maptools)

# read in soil polygon shapefile

setwd("C:/Users/Joy/Documents/MRch_GIS/Ontario_soil_Meghan/Ontario_soil")
SOIL_poly = st_read('clipped_Ontario_soil_GRW.shp')

# read in dss component table
setwd("C:/Users/Joy/Documents/MRch_GIS/Soil Landscapes of Canada")
SOIL_comp = read.dbf("dss_v3_on_cmp.dbf")

# read in soil layer information table 
SOIL_layr = read.dbf("soil_layer_on_v2.dbf")
# 
fname = list.files(path = "C:/Users/Joy/Documents/MRch_GIS/GRW Watershed/subbas",pattern = ".shp")
fname = substr(fname,1,nchar(fname)-4)
# fname = "GRW_whole_york"
# fname = "subbas_2GA014"

SOIL_subbas_avg = data.frame(fname)
SOIL_subbas_avg$OC = NA
SOIL_subbas_avg$n = NA
SOIL_subbas_avg$TSAND = NA
SOIL_subbas_avg$TSILT = NA
SOIL_subbas_avg$TCLAY = NA
SOIL_subbas_avg$CACO = NA
SOIL_subbas_avg$BD = NA

for (k in 1:length(fname)){
  # Weighted average soil properties for all watersheds

  fnamek = fname[k]
  # fnamek = fname
  if (fnamek=="subbas_2GB010"){
    next
  }
  
# read in subbasin delineation shapefile

# setwd("C:/Users/Joy/Documents/MRch_GIS/GRW Watershed")
setwd("C:/Users/Joy/Documents/MRch_GIS/GRW Watershed/subbas")
WSHD = st_read(paste0(fnamek,'.shp'))

# set same CRS
SOIL_proj = st_transform(SOIL_poly,st_crs(WSHD))

# clip 
SOIL_subbas_clip = st_intersection(st_buffer(SOIL_proj,0),st_buffer(WSHD,0))
SOIL_subbas = subset(SOIL_subbas_clip,select = c(POLY_ID,geometry))
SOIL_subbas$SOIL_ID = c("NULL") # create column for SOIL_ID
SOIL_subbas$AREA = NA  # Create column for calculating area in m^2 if shapefile projection was in m
SOIL_subbas$MASS_kg = NA
SOIL_subbas$ORGCARB_avgperc = NA
SOIL_subbas$ORGCARB_kgha = NA
SOIL_subbas$BD_avg = NA
SOIL_subbas$n_avgperc = NA
SOIL_subbas$TSAND_avgperc = NA
SOIL_subbas$TSILT_avgperc = NA
SOIL_subbas$TCLAY_avgperc = NA
SOIL_subbas$CACO_kgha = NA
  
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
SOIL_missingOC = data.frame(SOIL_ID = NA)
SOIL_difflen = data.frame(SOIL_ID = NA)

# for each soil polygon in subbasin, calculate weighted average
for (i in 1:nrow(SOIL_subbas)){
  idx = which(SOIL_subbas$SOIL_ID[i]==SOIL_layr$SOIL_ID)
  
  if (length(idx)==0) {
    SOIL_missing = rbind(SOIL_missing,SOIL_subbas$SOIL_ID[i])
    next
  }

  
  RAW = cbind(SOIL_layr$LAYER_NO[idx],SOIL_layr$UDEPTH[idx],SOIL_layr$LDEPTH[idx],SOIL_layr$BD[idx],SOIL_layr$ORGCARB[idx],SOIL_layr$TSAND[idx],SOIL_layr$TSILT[idx],SOIL_layr$TCLAY[idx],SOIL_layr$CACO3[idx])
  RAWsort= as.data.frame(RAW[order(RAW[,1]),])
  
  if (length(idx)==1){
    RAWsort = t(RAWsort)
  }


  BDi = 0               # weighted avg BD of polygon i by depth
  OCi = 0
  DPTH_BD = 0           # total depth of data available for BD
  DPTH_OC = 0
  
  TSANDi = 0
  TSILTi = 0
  TCLAYi = 0
  CACOi = 0
  
  DPTH_TSAND = 0
  DPTH_TSILT = 0
  DPTH_TCLAY = 0
  DPTH_CACO = 0
  

  
  for (j in 1:nrow(RAWsort)){        # calculations for weighted avg by depth 
    
    if (RAWsort[j,4]>=0){
    BDi = BDi+((RAWsort[j,3]-RAWsort[j,2])*RAWsort[j,4])
    DPTH_BD = DPTH_BD +(RAWsort[j,3]-RAWsort[j,2])
    }

    if (RAWsort[j,5]>=0) {
    OCi = OCi+((RAWsort[j,3]-RAWsort[j,2])*RAWsort[j,5])          # cm x % 
    DPTH_OC = DPTH_OC +(RAWsort[j,3]-RAWsort[j,2])                # cm
    }
    
    if (RAWsort[j,6]>=0) {
      TSANDi = TSANDi+((RAWsort[j,3]-RAWsort[j,2])*RAWsort[j,6])
      DPTH_TSAND = DPTH_TSAND +(RAWsort[j,3]-RAWsort[j,2])
    }
    
    if (RAWsort[j,7]>=0) {
      TSILTi = TSILTi+((RAWsort[j,3]-RAWsort[j,2])*RAWsort[j,7])
      DPTH_TSILT = DPTH_TSILT +(RAWsort[j,3]-RAWsort[j,2])
    }
    
    if (RAWsort[j,8]>=0) {
      TCLAYi = TCLAYi+((RAWsort[j,3]-RAWsort[j,2])*RAWsort[j,8])
      DPTH_TCLAY = DPTH_TCLAY +(RAWsort[j,3]-RAWsort[j,2])
    }
    
    if (RAWsort[j,9]>=0) {
      CACOi = CACOi+((RAWsort[j,3]-RAWsort[j,2])*RAWsort[j,9])
      DPTH_CACO = DPTH_CACO +(RAWsort[j,3]-RAWsort[j,2])               # cm
    }
    

  }

  if (BDi==0)  {    
    SOIL_missingBD = rbind(SOIL_missingBD,SOIL_subbas$SOIL_ID[i])
    next
  }
  
  if (OCi==0)  {    
    SOIL_missingOC = rbind(SOIL_missingOC,SOIL_subbas$SOIL_ID[i])
    next
  }
  
  BD = BDi/DPTH_BD # g/cm^3, weighted average BD over the depth 
  SOIL_subbas$BD_avg[i] = BD
  SOIL_subbas$n_avgperc[i] = 1 - (BD/2.65)
  
  OC = OCi/DPTH_OC                                         # depth weighted avg OCi
  
  TSAND = TSANDi/DPTH_TSAND
  TSILT = TSILTi/DPTH_TSILT
  TCLAY = TCLAYi/DPTH_TCLAY
  CACO = CACOi/DPTH_CACO
  
  # checking for polygons where there are different data availabilities for BD and OC
  if (DPTH_BD-DPTH_OC>0) {
    SOIL_difflen = rbind(SOIL_missing,SOIL_subbas$SOIL_ID[i])
  }
  
  SOIL_subbas$MASS_kg[i] = BD/1000*100^3*SOIL_subbas$AREA[i]*(RAWsort[NROW(RAWsort),3]/100) # total mass of polygon (kg)
  SOIL_subbas$ORGCARB_avgperc[i] = OC/100                                                   # weighted avg OC(%)
  SOIL_subbas$ORGCARB_kgha[i] = SOIL_subbas$ORGCARB_avgperc[i]*(SOIL_subbas$MASS_kg[i])/(SOIL_subbas$AREA[i]/10000) # density of OC (kg/ha)
  SOIL_subbas$TSAND_avgperc[i] = TSAND/100
  SOIL_subbas$TSILT_avgperc[i] = TSILT/100
  SOIL_subbas$TCLAY_avgperc[i] = TCLAY/100
  SOIL_subbas$CACO_kgha[i] = CACO/100*(SOIL_subbas$MASS_kg[i])/(SOIL_subbas$AREA[i]/10000)
}

### calculate weighted characteristics for subbasin by polygon area
SOIL_subbas_avg$subbas_ID[k] = fnamek


TOTAREA = sum(SOIL_subbas$AREA)                # sqm

# Bulk Density (g/cm^3)
SOIL_subbas_avg$BD[k] = sum(SOIL_subbas$BD_avg*(SOIL_subbas$AREA/TOTAREA),na.rm = TRUE)

# Organic Carbon (kg/ha)
SOIL_subbas_avg$OC[k] = sum(SOIL_subbas$ORGCARB_kgha*(SOIL_subbas$AREA/TOTAREA),na.rm = TRUE)

# n
SOIL_subbas_avg$n[k] = sum(SOIL_subbas$n_avgperc*(SOIL_subbas$AREA/TOTAREA),na.rm = TRUE)

# soil texture
SOIL_subbas_avg$TSAND[k] = sum(SOIL_subbas$TSAND_avgperc*SOIL_subbas$AREA/TOTAREA,na.rm = TRUE)
SOIL_subbas_avg$TSILT[k] = sum(SOIL_subbas$TSILT_avgperc*SOIL_subbas$AREA/TOTAREA,na.rm = TRUE)
SOIL_subbas_avg$TCLAY[k] = sum(SOIL_subbas$TCLAY_avgperc*SOIL_subbas$AREA/TOTAREA,na.rm = TRUE)

# total carbon (kg/ha)
SOIL_subbas_avg$CACO[k] = sum(SOIL_subbas$CACO_kgha*SOIL_subbas$AREA/TOTAREA,na.rm = TRUE)

# write to file

setwd("C:/Users/Joy/Documents/MRch_GIS/Soil Landscapes of Canada/Processed Subbasin")

# st_write(SOIL_subbas,paste0("SOIL_",fnamek,"_test.shp"))
# write.xlsx(unique(SOIL_missing),paste0('SOIL_missing',fnamek,'.xlsx'))
# write.xlsx(unique(SOIL_missingBD),paste0('SOIL_missingBD',fnamek,'.xlsx'))
# write.xlsx(unique(SOIL_missingOC),paste0('SOIL_missingOC',fnamek,'.xlsx'))
# write.xlsx(unique(SOIL_difflen),paste0('SOIL_difflen',fnamek,'.xlsx'))


}

write.xlsx(SOIL_subbas_avg,paste0('SOIL_subbas_0816.xlsx'))


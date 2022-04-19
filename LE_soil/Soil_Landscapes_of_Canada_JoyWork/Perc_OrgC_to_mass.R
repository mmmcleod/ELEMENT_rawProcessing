### for calculating Soil Landscapes of Canada weighted average soil properties (soil depth) --> kg/ha
# ORG CARBON kg/ha
# Bulk Density (BD) g/cm3 to calculate Porosity (n) %
# Field Capacity FC % by total soil volume 
# Soil moisture content at 33 kPa 
# saturated hydraulic conductivity 

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
# fname = sapply(read_xlsx('C:/Users/Joy/Documents/MRch_GIS/GRW Watershed/subbas_names.xlsx',col_names = FALSE),as.character)
fname = "GRW_whole_valid"
# fname = t(cbind("subbas_2GA010_nested"))

# fname = "2GA028"

SOIL_subbas_avg = data.frame(fname)
SOIL_subbas_avg$OC = NA
SOIL_subbas_avg$n = NA
SOIL_subbas_avg$BD = NA
SOIL_subbas_avg$THETA = NA
SOIL_subbas_avg$s = NA
SOIL_subbas_avg$ksat = NA

for (k in 1:length(fname)){
  # Weighted average soil properties for all watersheds

  fnamek = fname[k]
  # fnamek = fname

# ***** EDIT INPUTS ***** read in subbasin delineation shapefile (2/2)

setwd("C:/Users/Joy/Documents/MRch_GIS/GRW Watershed")
# setwd("C:/Users/Joy/Documents/MRch_GIS/GRW Watershed/subbas")

WSHD = st_read(paste0(fnamek,'.shp'))
# WSHD = st_read(paste0('subbas_',fnamek,'.shp'))

# set same CRS
SOIL_proj = st_transform(SOIL_poly,st_crs(WSHD))

# clip 
SOIL_subbas_clip = st_intersection(st_buffer(SOIL_proj,0),st_buffer(WSHD,0))
SOIL_subbas = subset(SOIL_subbas_clip,select = c(POLY_ID,geometry))
SOIL_subbas$SOIL_ID = c("NULL") # create column for SOIL_ID
SOIL_subbas$AREA = NA  # Create column for calculating area in m^2 if shapefile projection was in m
SOIL_subbas$ORGCARB_kgha = 0
SOIL_subbas$BD = 0
SOIL_subbas$n = 0
SOIL_subbas$THETA = 0
SOIL_subbas$s = 0
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
SOIL_missingOC = data.frame(SOIL_ID = NA)
SOIL_missingTHETA = data.frame(SOIL_ID = NA)
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
    
    SOIL_subbas$ORGCARB_kgha[i] = SOIL_subbas$ORGCARB_kgha[i]+(BDj*OCj*DPTHj)*10000 
    SOIL_subbas$BD[i] = SOIL_subbas$BD[i]+BDj*DPTHj 
    nj = 1-BDj/1000/2.65
    SOIL_subbas$THETA[i] = SOIL_subbas$THETA[i]+THETAj*DPTHj
    SOIL_subbas$s[i] = SOIL_subbas$s[i]+THETAj/nj*DPTHj
    SOIL_subbas$KSAT[i] = SOIL_subbas$KSAT[i]+KSATj*DPTHj
    
    
  }
  
  DPTHi = (RAWsort[nrow(RAWsort),3]-RAWsort[1,2])/100   # total depth of soil profile [m]
  SOIL_subbas$BD[i] = SOIL_subbas$BD[i]/DPTHi/1000    # g/cm3
  SOIL_subbas$n[i] = 1-SOIL_subbas$BD[i]/2.65
  SOIL_subbas$THETA[i] = SOIL_subbas$THETA[i]/DPTHi
  SOIL_subbas$s[i] = SOIL_subbas$s[i]/DPTHi
    
  }
  

### calculate weighted characteristics for subbasin by polygon area
SOIL_subbas_avg$subbas_ID[k] = fnamek

TOTAREA = sum(SOIL_subbas$AREA)                # sqm

# Organic Carbon (kg/ha)
SOIL_subbas_avg$OC[k] = sum(SOIL_subbas$ORGCARB_kgha*(SOIL_subbas$AREA/TOTAREA),na.rm = TRUE)

# soil bulk density (BD) a.k.a. porosity (n)
SOIL_subbas_avg$BD[k] = sum(SOIL_subbas$BD*(SOIL_subbas$AREA/TOTAREA),na.rm = TRUE)
SOIL_subbas_avg$n[k] = sum(SOIL_subbas$n*(SOIL_subbas$AREA/TOTAREA),na.rm = TRUE)

# soil water retention at 33 kPa a.k.a. Field Capacity a.k.a. average soil moisture
SOIL_subbas_avg$THETA[k] = sum(SOIL_subbas$THETA*(SOIL_subbas$AREA/TOTAREA),na.rm = TRUE)
SOIL_subbas_avg$s[k] = sum(SOIL_subbas$s*(SOIL_subbas$AREA/TOTAREA),na.rm = TRUE)

# Ksat (cm/hr)
SOIL_subbas_avg$KSAT[k]=sum(SOIL_subbas$KSAT*(SOIL_subbas$AREA/TOTAREA),na.rm = TRUE)

# write to file
setwd("C:/Users/Joy/Documents/MRch_GIS/Soil Landscapes of Canada/Processed Subbasin")

st_write(SOIL_subbas,paste0("SOIL_",fnamek,".shp"),delete_dsn=TRUE)
# write.xlsx(unique(SOIL_missing),paste0('SOIL_missing',fnamek,'.xlsx'))
# write.xlsx(unique(SOIL_missingBD),paste0('SOIL_missingBD',fnamek,'.xlsx'))
# write.xlsx(unique(SOIL_missingOC),paste0('SOIL_missingOC',fnamek,'.xlsx'))
# write.xlsx(unique(SOIL_difflen),paste0('SOIL_difflen',fnamek,'.xlsx'))


}

write.xlsx(SOIL_subbas_avg,paste0('C:/Users/Joy/Documents/MRch_GIS/Soil Landscapes of Canada/Processed Subbasin/SOIL_subbas_KSAT_2GA028.xlsx'))


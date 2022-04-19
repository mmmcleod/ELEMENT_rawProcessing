
# DOWNLOAD REQUIRED LIBRARIES AND LOAD THEM XXXXXXXXXXXXXXXXXXXXXXX
library(foreign)
library(rgdal)
library(sf)
library(readxl)
library(ggplot2)
library(writexl)
library(ggplot2)
library(tidyverse)

#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

# SET ANY DIRECTORIES XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
SourceDir = "C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/LE_soil/Soil Landscapes of Canada_ErieNitrogen"
OutputDir = "C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/LE_soil/Soil Landscapes of Canada_ErieNitrogen/Outputs"
RawInputSLCInput = "C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/LE_soil/Soil Landscapes of Canada_ErieNitrogen/SLC_dss_fromJoy"
WshdShapefileDir = "C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/LE_Watershed_shapefiles/LE_ELEMENT_N/Reformatted"
WholeWshdShapefileFir = "C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/Shapefile"
setwd(RawInputSLCInput)
#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

# LOAD IN THE SLC POLYGONES

# each polygon will have it's soil type identified and then soil 
# characteristics will be averaged over its soil layers 

SOIL_poly = st_read('dss_v3_on_ERIE.shp')
head(SOIL_poly)

#DATE OF SLC: DATE:  2011.03.08
#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

# USING THE SLC COMPONENT TABLE, EXTRACT EACH POLYGON'S SOIL types

#The Component Table describes each of the individual soil and 
#landscape features which comprise the polygon

SOIL_comp = read.dbf("dss_v3_on_cmp.dbf")
#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

# USE THE SOIL LAYER CODE TO EXTRACT LATER ATTRIBUTES FOR EACH SOIL COMPONENT 

SOIL_layr = read.dbf("soil_layer_on_v2.dbf")

#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

# SET UP WATERSHEDS THAT WE WANT TO EXTRACT INFO FOR 

setwd(WshdShapefileDir)
NAME=list.files(pattern=".shp$")
NAME=NAME[grepl('CAN',NAME)]
NAME=substr(NAME,5,nchar(NAME)-4)

# Pre-allocate space for average soil parameter values for the watershed 
SOIL_subbas_avg = data.frame(NAME)
SOIL_subbas_avg$OC = NA # ORGANIC CARBOM 
SOIL_subbas_avg$n = NA # SOIL POROSITY
SOIL_subbas_avg$BD = NA # BULK DENSITY 
SOIL_subbas_avg$THETA = NA # WATER RETENTION AT 33KP
SOIL_subbas_avg$s = NA # SOIL WATER CONTENT
SOIL_subbas_avg$KSAT = NA #	SATURATED HYDRAULIC CONDUCTIVITY
#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

# FOR EACH WATERSHED, CLIP THE SOIL POLYGON AND PREPARE FOR DATA EXTRACTION 

for (k in 1:length(NAME)){ # this can be changed to iterate eventually 
NAME_k = NAME[k]

setwd(WshdShapefileDir)
WSHD = st_read(paste0('CAN_',NAME_k,'.shp'))

# set same CRS
SOIL_poly = st_transform(SOIL_poly,st_crs(WSHD))

# clip soil polygons to watershed 
SOIL_subbas_clip = st_intersection(st_buffer(SOIL_poly,0),st_buffer(WSHD,0))
SOIL_subbas = subset(SOIL_subbas_clip,select = c(POLY_ID,geometry))

# set up data columns 
SOIL_subbas$SOIL_ID = c("NULL") # create column for SOIL_ID
SOIL_subbas$AREA = NA  # Create column for calculating area in m^2 if shapefile projection was in m
SOIL_subbas$ORGCARB_kgha = 0
SOIL_subbas$BD = 0
SOIL_subbas$n = 0
SOIL_subbas$THETA = 0
SOIL_subbas$s = 0
SOIL_subbas$KSAT = 0

#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

# EXTRACT SOIL TYPE FOR EACH POLYGON USING COMPONENT TABLE 

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
  
  # find soil ID in the soil layr table (this has the data we need)
  idx = which(SOIL_subbas$SOIL_ID[i]==SOIL_layr$SOIL_ID)
  
  # keep track of missing data (when a soil ID is not in the table)
  
  if (length(idx)==0) {
    SOIL_missing = rbind(SOIL_missing,SOIL_subbas$SOIL_ID[i])
    next
  }
  
  # GET ALL RAW DATA WE NEED (and sort by order) FOR CURRENT POLYGON 
  # [Layer num, upper depth, lower depth, bulk density, organic carbon, water retention at 33 kP,Saturated Hydraulic Conductivity]
  RAW = cbind(SOIL_layr$LAYER_NO[idx],SOIL_layr$UDEPTH[idx],SOIL_layr$LDEPTH[idx],SOIL_layr$BD[idx],SOIL_layr$ORGCARB[idx],SOIL_layr$KP33[idx],SOIL_layr$KSAT[idx])
  RAWsort= as.data.frame(RAW[order(RAW[,1]),])
  
  # if only one soil later, transpose (not sure why .. from joy's code)
  if (length(idx)==1){
    RAWsort = t(RAWsort)
    RAWsort = as.data.frame(RAWsort)
  }
  
  #rename data table with comprehensible headers 
  RAWsort=rename(RAWsort,LAYNO=V1, UDEPTH=V2, LDEPTH=V3, BD=V4, OC=V5, KP33=V6, KSAT=V7)

  # for each layer in soil polygon
  for (j in 1:NROW(RAWsort)){        
    
    # calculations for Calculating Org C kg/ha in a polygon
    # also depth weighted averaged Bulk density (g/cm^3)
    
    DPTH = (RAWsort$LDEPTH[j]-RAWsort$UDEPTH[j])/100 # in metres

    ##################### BULK DENSITY CALC ####################################
    
    if (RAWsort$BD[j]>=0){
      BD = RAWsort$BD[j]*1000} # g/cm^3 to kg/m^3}
      
      # if info in a layer is missing ---- 
      
      # ...and there is only 1 row
     else if (NROW(RAWsort)==1){
      SOIL_missingBD = rbind(SOIL_missingBD,SOIL_subbas$SOIL_ID[i])}
      #...and it is the first layer, use the next layer info
     else if (j == 1) {
      BD = RAWsort$BD[j+1]*1000}
      #...and it is the last layer, use the previous layer
     else if (j == NROW(RAWsort)) {
      BD = RAWsort$BD[j-1]*1000 }
      #...and it is a layer in the middle, use the average of the bounding layers
     else if (j < NROW(RAWsort) && j>1){
      BD = average(RAWsort$BD[j-1],RAWsort$BD[j+1])*1000}
    
    ##################### ORGANIC CARBON ####################################
    
    if (RAWsort$OC[j]>-9){
      OC = RAWsort$OC[j]/100} 
    else if (NROW(RAWsort)==1){
      SOIL_missingOC = rbind(SOIL_missingOC,SOIL_subbas$SOIL_ID[i])} 
    else if (j == 1) {
      OC = RAWsort$OC[j+1]/100}
    else if (j == NROW(RAWsort)) {
      OC = RAWsort$OC[j-1]/100}
    else if (j < NROW(RAWsort) && j>1){
      OC = average(RAWsort$OC[j-1],RAWsort$OC[j+1])/100}
    
    
   ####################### 33 KP WATER RETENTION #############################
    if (RAWsort$KP33[j]>-9){
      THETA = RAWsort$KP33[j]/100} 
    else if (NROW(RAWsort)==1){
      SOIL_missingTHETA = rbind(SOIL_missingTHETA,SOIL_subbas$SOIL_ID[i]) } 
    else if (j ==1){
      THETA = RAWsort$KP33[j+1]/100} 
    else if (j == nrow(RAWsort)) {
      THETA = RAWsort$KP33[j-1]/100}
    else if (j <NROW(RAWsort) && j>1){
      THETA = average(RAWsort$KP33[j-1],RAWsort$KP33[j+1])/100}
    
    ######################## KSAT ############################################
    if (RAWsort$KSAT[j]>-9){
      KSAT = RAWsort$KSAT[j]} 
    else if (nrow(RAWsort)==1){
      SOIL_missingKSAT = rbind(SOIL_missingKSAT,SOIL_subbas$SOIL_ID[i])} 
    else if (j==1){
      KSAT = RAWsort$KSAT[j+1]} 
    else if (j == nrow(RAWsort)){
      KSAT = RAWsort$KSAT[j-1]} 
    else if (j<nrow(RAWsort) && j>1){
      KSATj= average(RAWsort$KSAT[j-1],RAWsort$KSAT[j+1])}
    
    ###############BRINGING TOGETHER FOR THIS LAYER (adds recursively)  ########################
    
    SOIL_subbas$ORGCARB_kgha[i] = SOIL_subbas$ORGCARB_kgha[i]+(BD*OC*DPTH)*10000 # ORGCARB = sum of OC*BD*DEPTH% 
    SOIL_subbas$BD[i] = SOIL_subbas$BD[i]+BD*DPTH # ORGCARB = sum of BD*DEPTH%
    n = 1-BD/1000/2.65 # n=(1-BD/2.65)
    SOIL_subbas$THETA[i] = SOIL_subbas$THETA[i]+THETA*DPTH # THETA = sum of THETA*DEPTH%
    SOIL_subbas$s[i] = SOIL_subbas$s[i]+THETA/n*DPTH # S = sum of THETA/n *DEPTH%
    SOIL_subbas$KSAT[i] = SOIL_subbas$KSAT[i]+KSAT*DPTH # KSAT = sum of KSAT*DEPTH%
    
  }
  
  ############## BRINGING EVERYTHING TOGETHER FOR EACH POLYGON (i) ########################
  
  DPTHi = (RAWsort$LDEPTH[nrow(RAWsort)]-RAWsort$UDEPTH[1])/100   # total depth of soil profile [m]
  SOIL_subbas$BD[i] = SOIL_subbas$BD[i]/DPTHi/1000    # g/cm3
  SOIL_subbas$n[i] = 1-SOIL_subbas$BD[i]/2.65
  SOIL_subbas$THETA[i] = SOIL_subbas$THETA[i]/DPTHi
  SOIL_subbas$s[i] = SOIL_subbas$s[i]/DPTHi
    
}


# AFTER ALL OF THE ABOVE, WE SHOULD HAVE BD, s, n, and THETA FOR ALL THE SOIL POLYGONS IN OUR WATERSHED 

# we should weight them and average over the entire basin (k) <- might be running for multiple basins 

# Organic Carbon (kg/ha)

#Station ID
SOIL_subbas_avg$subbas_ID[k] = NAME_k

#Watershed Area 
TOTAREA = sum(SOIL_subbas$AREA)                # sqm

#Watershed Organic Carbon 
SOIL_subbas_avg$OC[k] = sum(SOIL_subbas$ORGCARB_kgha*(SOIL_subbas$AREA/TOTAREA),na.rm = TRUE)

#Watershed  soil bulk density (BD)
SOIL_subbas_avg$BD[k] = sum(SOIL_subbas$BD*(SOIL_subbas$AREA/TOTAREA),na.rm = TRUE)

#Watershed Soil porosity (n)
SOIL_subbas_avg$n[k] = sum(SOIL_subbas$n*(SOIL_subbas$AREA/TOTAREA),na.rm = TRUE)

# Watersged soil water retention at 33 kPa  
SOIL_subbas_avg$THETA[k] = sum(SOIL_subbas$THETA*(SOIL_subbas$AREA/TOTAREA),na.rm = TRUE)

#Watershed Field Capacity a.k.a. average soil moisture
SOIL_subbas_avg$s[k] = sum(SOIL_subbas$s*(SOIL_subbas$AREA/TOTAREA),na.rm = TRUE)

#Watershed Ksat (cm/hr)
SOIL_subbas_avg$KSAT[k]=sum(SOIL_subbas$KSAT*(SOIL_subbas$AREA/TOTAREA),na.rm = TRUE)

# write to files
setwd(OutputDir)

st_write(SOIL_subbas,paste0("SOIL_",NAME_k,".shp"),delete_dsn=TRUE)


}
write_csv(SOIL_subbas_avg,paste0("SOIL_parameters_watershedsCAN",".csv"))



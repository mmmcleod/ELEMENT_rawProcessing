
# this code aims to take the county-level (not watershed level) surplus 
# vectors for each of the counties in the lake Erie watershed (both countries)
# and plot them in a map with legend in order to eventually obtain a GIF 

# IN: US and Canada county shape files, 
#     1930 to 2016 surplus vectors for all the counties (manure, etc.)
# OUT: a raster map for each year with surplus values for each category 
#      a GIF image for each category iterating through the years 


#data for input here was created in matlab from ELEMENT_plotting_whole_wshd.m

#________________________________________
#________________________________________
#________________________________________

#########################################################
# Functions used below 
#########################################################

# required functions 
createYearAttribute <- function(sf,year,data) {
  sf[[paste(toString(year))]] = data  
  return(sf)
}

##################################################################################################################
# OBTAIN ALL LIBRARIES AND PACKAGES 
##################################################################################################################


#install necessary packages (only once)
#________________________________________
#for(p in c("tidyverse","ggplot2","sf","readxl","magick","raster","rgdal")){install.packages(p,character.only = T)}
#open necessary packages 
#________________________________________
for(p in c("tidyverse","ggplot2","sf","readxl","magick","raster","rgdal")){library(p,character.only = T)}


##################################################################################################################
# GRAB SHAPE FILES (COUNTY OUTLINES) 
##################################################################################################################

#for work computer 
setwd("C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/Shapefile/old_dont_us/")
#for laptop
#setwd("~/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/Shapefile")

list.files()
ERIE_CAN_counties = read_sf('ONT.shp')
ERIE_USA_counties = read_sf('USA.shp')

ERIE_CAN_counties = st_transform(ERIE_CAN_counties, st_crs(7789))    
ERIE_USA_counties = st_transform(ERIE_USA_counties, st_crs(7789)) 
setwd("C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/Shapefile/")
basin = read_sf('greatlakes_subbasins.shp')
basin = st_transform(basin, st_crs(7789)) 



# the Canadian counties have the wrong ID's - switch them to element IDs 
ERIE_CAN_counties$CountyID = c('30000','38000','22000','36000','37000','28000','34000','40000','32000','31000','23000','24000','42000','25000','39000','29000')
ERIE_USA_counties$CountyID =ERIE_USA_counties$N3

#remove all other features to clean 
ERIE_CAN_counties$CDNAME=c();
ERIE_CAN_counties$CDUID=c();
ERIE_CAN_counties$CDTYPE=c();
ERIE_CAN_counties$PRUID=c();
ERIE_CAN_counties$PRNAME=c();
# MOST ERIE_USA_counties WAS DONE IN qgiS
ERIE_USA_counties$N3=c();


#PLOT NEW CAN IDs

ggplot()+theme_void()+
  geom_sf(data = ERIE_CAN_counties, mapping=aes(fill = get('CountyID')),inherit.aes=FALSE,lwd = 0)



#################################  
# GRAB COUNTY SURPLUS FILES 
#################################

#for work computer
setwd("C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/LE_surplus/COUNTY SURPLUS CALCULATIONS/County Surplus Calculations (Using Kim's Code)/")
#for laptop 
#setwd("~/Dropbox/BASULAB_meghan/Proposal/ELEMENT_run_LE_Nitrogen_mmmcleod/County Surplus Calculations (Using Kim's Code)")

CAN_County_bnf=read_xls("ERIE_ON_countySurp.xls",sheet="fert") 
CAN_County_crop=read_xls("ERIE_ON_countySurp.xls",sheet="crop")
CAN_County_dep=read_xls("ERIE_ON_countySurp.xls",sheet="dep")
CAN_County_fert=read_xls("ERIE_ON_countySurp.xls",sheet="fert")
CAN_County_man=read_xls("ERIE_ON_countySurp.xls",sheet="man")
CAN_County_pop=read_xls("ERIE_ON_countySurp.xls",sheet="pop")

USA_County_bnf=read_xls("ERIE_USA_countySurp.xls",sheet="fert")
USA_County_crop=read_xls("ERIE_USA_countySurp.xls",sheet="crop")
USA_County_dep=read_xls("ERIE_USA_countySurp.xls",sheet="dep")
USA_County_fert=read_xls("ERIE_USA_countySurp.xls",sheet="fert")
USA_County_man=read_xls("ERIE_USA_countySurp.xls",sheet="man")
USA_County_pop=read_xls("ERIE_USA_countySurp.xls",sheet="pop")

##################################################################################################################
# For canada add all the surplus data to the county shape files 
##################################################################################################################

#BNF

ERIE_CAN_counties_BNF = ERIE_CAN_counties

year = 1 #this is table index so the actual year minus 1929 

for(year in 1:87){
#order the counties so the data we are adding is properly sorted 
  ERIE_CAN_counties_BNF$CountyID=ERIE_CAN_counties_BNF$CountyID[order(ERIE_CAN_counties_BNF$CountyID)]
#combine haldimand and norfolk 
dataIn = c(CAN_County_bnf[year,2:5],mean(c(CAN_County_bnf[[year,6]],CAN_County_bnf[[year,7]])),CAN_County_bnf[year,8:18])
dataIn = as.numeric(as.character(unlist(dataIn)))
ERIE_CAN_counties_BNF=createYearAttribute(ERIE_CAN_counties_BNF,paste('Y',year+1929,sep=""),dataIn)}


#crop

ERIE_CAN_counties_CROP = ERIE_CAN_counties

year = 1 #this is table index so the actual year minus 1929 

for(year in 1:87){
  #order the counties so the data we are adding is properly sorted 
  ERIE_CAN_counties_CROP$CountyID=ERIE_CAN_counties_CROP$CountyID[order(ERIE_CAN_counties_CROP$CountyID)]
  #combine haldimand and norfolk 
  dataIn = c(CAN_County_crop[year,2:5],mean(c(CAN_County_crop[[year,6]],CAN_County_crop[[year,7]])),CAN_County_crop[year,8:18])
  dataIn = as.numeric(as.character(unlist(dataIn)))
  ERIE_CAN_counties_CROP=createYearAttribute(ERIE_CAN_counties_CROP,paste('Y',year+1929,sep=""),dataIn)}

#deposition

ERIE_CAN_counties_DEP = ERIE_CAN_counties

year = 1 #this is table index so the actual year minus 1929 

for(year in 1:87){
  #order the counties so the data we are adding is properly sorted 
  ERIE_CAN_counties_DEP$CountyID=ERIE_CAN_counties_DEP$CountyID[order(ERIE_CAN_counties_DEP$CountyID)]
  #combine haldimand and norfolk 
  dataIn = c(CAN_County_dep[year,2:5],mean(c(CAN_County_dep[[year,6]],CAN_County_dep[[year,7]])),CAN_County_dep[year,8:18])
  dataIn = as.numeric(as.character(unlist(dataIn)))
  ERIE_CAN_counties_DEP=createYearAttribute(ERIE_CAN_counties_DEP,paste('Y',year+1929,sep=""),dataIn)}

#fertilizer 

ERIE_CAN_counties_FERT = ERIE_CAN_counties

year = 1 #this is table index so the actual year minus 1929 

for(year in 1:87){
  #order the counties so the data we are adding is properly sorted 
  ERIE_CAN_counties_FERT$CountyID=ERIE_CAN_counties_FERT$CountyID[order(ERIE_CAN_counties_FERT$CountyID)]
  #combine haldimand and norfolk 
  dataIn = c(CAN_County_fert[year,2:5],mean(c(CAN_County_fert[[year,6]],CAN_County_fert[[year,7]])),CAN_County_fert[year,8:18])
  dataIn = as.numeric(as.character(unlist(dataIn)))
  ERIE_CAN_counties_FERT=createYearAttribute(ERIE_CAN_counties_FERT,paste('Y',year+1929,sep=""),dataIn)}

#man

ERIE_CAN_counties_MAN = ERIE_CAN_counties

year = 1 #this is table index so the actual year minus 1929 

for(year in 1:87){
  #order the counties so the data we are adding is properly sorted 
  ERIE_CAN_counties_MAN$CountyID=ERIE_CAN_counties_MAN$CountyID[order(ERIE_CAN_counties_MAN$CountyID)]
  #combine haldimand and norfolk 
  dataIn = c(CAN_County_man[year,2:5],mean(c(CAN_County_man[[year,6]],CAN_County_man[[year,7]])),CAN_County_man[year,8:18])
  dataIn = as.numeric(as.character(unlist(dataIn)))
  ERIE_CAN_counties_MAN=createYearAttribute(ERIE_CAN_counties_MAN,paste('Y',year+1929,sep=""),dataIn)}

#pop 

ERIE_CAN_counties_POP = ERIE_CAN_counties

year = 1 #this is table index so the actual year minus 1929 

for(year in 1:87){
  #order the counties so the data we are adding is properly sorted 
  ERIE_CAN_counties_POP$CountyID=ERIE_CAN_counties_POP$CountyID[order(ERIE_CAN_counties_POP$CountyID)]
  #combine haldimand and norfolk 
  dataIn = c(CAN_County_pop[year,2:5],mean(c(CAN_County_pop[[year,6]],CAN_County_pop[[year,7]])),CAN_County_pop[year,8:18])
  dataIn = as.numeric(as.character(unlist(dataIn)))
  ERIE_CAN_counties_POP=createYearAttribute(ERIE_CAN_counties_POP,paste('Y',year+1929,sep=""),dataIn)}

##################################################################################################################
# For USA add all the surplus data to the county shape files 
##################################################################################################################

#BNF

ERIE_USA_counties_BNF = ERIE_USA_counties

year = 1 #this is table index so the actual year minus 1929 

for(year in 1:87){
  #order the counties so the data we are adding is properly sorted 
  ERIE_USA_counties_BNF$CountyID=ERIE_USA_counties_BNF$CountyID[order(ERIE_USA_counties_BNF$CountyID)]
  #combine haldimand and norfolk 
  dataIn = USA_County_bnf[year,2:66]
  dataIn = as.numeric(as.character(unlist(dataIn)))
  ERIE_USA_counties_BNF=createYearAttribute(ERIE_USA_counties_BNF,paste('Y',year+1929,sep=""),dataIn)}

#CROP

ERIE_USA_counties_CROP = ERIE_USA_counties

year = 1 #this is table index so the actual year minus 1929 

for(year in 1:87){
  #order the counties so the data we are adding is properly sorted 
  ERIE_USA_counties_CROP$CountyID=ERIE_USA_counties_CROP$CountyID[order(ERIE_USA_counties_CROP$CountyID)]
  #combine haldimand and norfolk 
  dataIn = USA_County_crop[year,2:66]
  dataIn = as.numeric(as.character(unlist(dataIn)))
  ERIE_USA_counties_CROP=createYearAttribute(ERIE_USA_counties_CROP,paste('Y',year+1929,sep=""),dataIn)}

#DEP

ERIE_USA_counties_DEP = ERIE_USA_counties

year = 1 #this is table index so the actual year minus 1929 

for(year in 1:87){
  #order the counties so the data we are adding is properly sorted 
  ERIE_USA_counties_DEP$CountyID=ERIE_USA_counties_DEP$CountyID[order(ERIE_USA_counties_DEP$CountyID)]
  #combine haldimand and norfolk 
  dataIn = USA_County_dep[year,2:66]
  dataIn = as.numeric(as.character(unlist(dataIn)))
  ERIE_USA_counties_DEP=createYearAttribute(ERIE_USA_counties_DEP,paste('Y',year+1929,sep=""),dataIn)}

#FERT

ERIE_USA_counties_FERT = ERIE_USA_counties

year = 1 #this is table index so the actual year minus 1929 

for(year in 1:87){
  #order the counties so the data we are adding is properly sorted 
  ERIE_USA_counties_FERT$CountyID=ERIE_USA_counties_FERT$CountyID[order(ERIE_USA_counties_FERT$CountyID)]
  #combine haldimand and norfolk 
  dataIn = USA_County_fert[year,2:66]
  dataIn = as.numeric(as.character(unlist(dataIn)))
  ERIE_USA_counties_FERT=createYearAttribute(ERIE_USA_counties_FERT,paste('Y',year+1929,sep=""),dataIn)}

#MAN

ERIE_USA_counties_MAN = ERIE_USA_counties

year = 1 #this is table index so the actual year minus 1929 

for(year in 1:87){
  #order the counties so the data we are adding is properly sorted 
  ERIE_USA_counties_MAN$CountyID=ERIE_USA_counties_MAN$CountyID[order(ERIE_USA_counties_MAN$CountyID)]
  #combine haldimand and norfolk 
  dataIn = USA_County_man[year,2:66]
  dataIn = as.numeric(as.character(unlist(dataIn)))
  ERIE_USA_counties_MAN=createYearAttribute(ERIE_USA_counties_MAN,paste('Y',year+1929,sep=""),dataIn)}

#POP

ERIE_USA_counties_POP = ERIE_USA_counties

year = 1 #this is table index so the actual year minus 1929 

for(year in 1:87){
  #order the counties so the data we are adding is properly sorted 
  ERIE_USA_counties_POP$CountyID=ERIE_USA_counties_POP$CountyID[order(ERIE_USA_counties_POP$CountyID)]
  #combine haldimand and norfolk 
  dataIn = USA_County_pop[year,2:66]
  dataIn = as.numeric(as.character(unlist(dataIn)))
  ERIE_USA_counties_POP=createYearAttribute(ERIE_USA_counties_POP,paste('Y',year+1929,sep=""),dataIn)}

#SURPLUS

#USA 

ERIE_USA_counties_SURP = ERIE_USA_counties
Counties = ERIE_USA_counties_SURP$CountyID[order(ERIE_USA_counties_SURP$CountyID)]


for(year in 1:87){
  #order the counties so the data we are adding is properly sorted 
  ERIE_USA_counties_POP$CountyID=Counties 
  dataIn = USA_County_pop[year,2:66]+USA_County_bnf[year,2:66]-USA_County_crop[year,2:66]+USA_County_dep[year,2:66]+USA_County_fert[year,2:66]+USA_County_man[year,2:66]
  dataIn = as.numeric(as.character(unlist(dataIn)))
  ERIE_USA_counties_SURP=createYearAttribute(ERIE_USA_counties_SURP,paste('Y',year+1929,sep=""),dataIn)}

#CAN 

ERIE_CAN_counties_SURP = ERIE_CAN_counties
counties = ERIE_CAN_counties_SURP$CountyID[order(ERIE_CAN_counties_SURP$CountyID)]

for(year in 1:87){
  #order the counties so the data we are adding is properly sorted 
  ERIE_CAN_counties_SURP$CountyID=counties
  #combine haldimand and norfolk 
  dataIn = c(CAN_County_pop[year,2:5]+CAN_County_man[year,2:5]+CAN_County_bnf[year,2:5]+CAN_County_dep[year,2:5]+CAN_County_fert[year,2:5]-CAN_County_crop[year,2:5],
             mean(c(CAN_County_pop[[year,6]]+CAN_County_man[[year,6]]+CAN_County_bnf[[year,6]]+CAN_County_dep[[year,6]]+CAN_County_fert[[year,6]]-CAN_County_crop[[year,6]],
                    CAN_County_pop[[year,7]]+CAN_County_man[[year,7]]+CAN_County_bnf[[year,7]]+CAN_County_dep[[year,7]]+CAN_County_fert[[year,7]]-CAN_County_crop[[year,7]])),
             CAN_County_pop[year,8:18]+CAN_County_man[year,8:18]+CAN_County_bnf[year,8:18]+CAN_County_dep[year,8:18]+CAN_County_fert[year,8:18]-CAN_County_crop[year,8:18])
  dataIn = as.numeric(as.character(unlist(dataIn)))
  ERIE_CAN_counties_SURP=createYearAttribute(ERIE_CAN_counties_SURP,paste('Y',year+1929,sep=""),dataIn)}

CAN_County_surp = CAN_County_bnf-CAN_County_crop+CAN_County_dep+CAN_County_fert+CAN_County_man+CAN_County_pop
USA_County_surp = USA_County_bnf[1:87,]-USA_County_crop[1:87,]+USA_County_dep+USA_County_fert[1:87,]+USA_County_man[1:87,]+USA_County_pop[1:87,]
##################################################################################################################
# Plot shape files with surplus colored 
##################################################################################################################


ERIE_CAN_counties=st_intersection(ERIE_CAN_counties,basin)
ERIE_USA_counties=st_intersection(ERIE_USA_counties,basin)
ERIE_CAN_counties_BNF=st_intersection(ERIE_CAN_counties_BNF,basin)
ERIE_USA_counties_BNF=st_intersection(ERIE_USA_counties_BNF,basin)
ERIE_CAN_counties_CROP=st_intersection(ERIE_CAN_counties_CROP,basin)
ERIE_USA_counties_CROP=st_intersection(ERIE_USA_counties_CROP,basin)
ERIE_CAN_counties_DEP=st_intersection(ERIE_CAN_counties_DEP,basin)
ERIE_USA_counties_DEP=st_intersection(ERIE_USA_counties_DEP,basin)
ERIE_CAN_counties_FERT=st_intersection(ERIE_CAN_counties_FERT,basin)
ERIE_USA_counties_FERT=st_intersection(ERIE_USA_counties_FERT,basin)
ERIE_CAN_counties_MAN=st_intersection(ERIE_CAN_counties_MAN,basin)
ERIE_USA_counties_MAN=st_intersection(ERIE_USA_counties_MAN,basin)
ERIE_CAN_counties_POP=st_intersection(ERIE_CAN_counties_POP,basin)
ERIE_USA_counties_POP=st_intersection(ERIE_USA_counties_POP,basin)

# make sure projected coordinates are working properly 
library(ggmap)
register_google('AIzaSyCg3TRokhJ71QGotW1CWksnHzswfIEA38c')
xbounds=seq(-86,-77,1)
ybounds=seq(40,45,1)
#al1 = get_map(location = c(lon = -81.5, lat = 42.5), zoom = 6, maptype = 'satellite')

##################################################################################################################
#SURPLUS
##################################################################################################################
for (i in  c(1931,2016)){
  #combine both into one shape 
  
  thisyear=paste0('Y', i)
  
  #ggmap(al1)+
  thisplot=ggplot()+theme_void()+
    geom_sf(data = ERIE_CAN_counties_SURP, mapping=aes(fill = get(thisyear)),inherit.aes=FALSE,lwd = 0) + #polygons filled based on the 1950 value
    geom_sf(data = ERIE_USA_counties_SURP, mapping=aes(fill = get(thisyear)),inherit.aes=FALSE,lwd = 0) + #polygons filled based on the 1950 value
    
    
    ggtitle(paste("SURPLUS N (kg per ha)",toString(i),sep="\n"))+
    theme(legend.position = "right", legend.key.height = unit(2, "cm"),legend.key.width = unit(1, "cm"))+
    scale_fill_gradientn(colours = terrain.colors(10),
                         limits=c(min(min(CAN_County_surp[,2:18]),min(USA_County_surp[,2:66])), max(max(CAN_County_surp[,2:18]),max(USA_County_surp[,2:66]))))
  
  ggsave(thisplot,filename=paste0('IMAGES_withOldCode/surplus_',i,'.jpg'))
}


#SEPARATE PLOTS
##################################################################################################################

#crop  ****************************************************************************************************


for (i in c(1931,2016)){
#combine both into one shape 

thisyear=paste0('Y', i)

#ggmap(al1)+
thisplot=ggplot()+theme_void()+
  geom_sf(data = ERIE_CAN_counties_CROP, mapping=aes(fill = get(thisyear)),inherit.aes=FALSE,lwd = 0) + #polygons filled based on the 1950 value
  geom_sf(data = ERIE_USA_counties_CROP, mapping=aes(fill = get(thisyear)),inherit.aes=FALSE,lwd = 0) + #polygons filled based on the 1950 value
  
  
  ggtitle(paste("CROP (kg per ha)",toString(i),sep="\n"))+
  theme(legend.position = "right", legend.key.height = unit(2, "cm"),legend.key.width = unit(1, "cm"))+
  scale_fill_gradient2(low="darkolivegreen2", mid="darkolivegreen2", high="darkgreen",
                       limits=c(0, max(CAN_County_crop[,2:18]+50)))

ggsave(thisplot,filename=paste0('IMAGES_withOldCode/crop_',i,'.jpg'))
}


# #fert  ****************************************************************************************************

for (i in c(1931,2016)){
  #combine both into one shape 
  
  thisyear=paste0('Y', i)
  
  #ggmap(al1)+
  thisplot=ggplot()+theme_void()+
    geom_sf(data = ERIE_CAN_counties_FERT, mapping=aes(fill = get(thisyear)),inherit.aes=FALSE,lwd = 0) + #polygons filled based on the 1950 value
    geom_sf(data = ERIE_USA_counties_FERT, mapping=aes(fill = get(thisyear)),inherit.aes=FALSE,lwd = 0) + #polygons filled based on the 1950 value
    
    
    ggtitle(paste("FERT (kg per ha)",toString(i),sep="\n"))+
    theme(legend.position = "right", legend.key.height = unit(2, "cm"),legend.key.width = unit(1, "cm"))+
    scale_fill_gradient2(low="mediumpurple1", mid="mediumpurple1", high="purple4",
                         limits=c(0, max(CAN_County_fert[,2:18])+50))
  
  ggsave(thisplot,filename=paste0('IMAGES_withOldCode/fert_',i,'.jpg'))
}


#man  ****************************************************************************************************

for (i in c(1931,2016)){
  #combine both into one shape 
  
  thisyear=paste0('Y', i)
  
  #ggmap(al1)+
  thisplot=ggplot()+theme_void()+
    geom_sf(data = ERIE_CAN_counties_MAN, mapping=aes(fill = get(thisyear)),inherit.aes=FALSE,lwd = 0) + #polygons filled based on the 1950 value
    geom_sf(data = ERIE_USA_counties_MAN, mapping=aes(fill = get(thisyear)),inherit.aes=FALSE,lwd = 0) + #polygons filled based on the 1950 value
    
    
    ggtitle(paste("MAN (kg per ha)",toString(i),sep="\n"))+
    theme(legend.position = "right", legend.key.height = unit(2, "cm"),legend.key.width = unit(1, "cm"))+
    scale_fill_gradient2(low="brown1", mid="brown1", high="red4",
                         limits=c(0, max(CAN_County_man[,2:18])+10))
  
  ggsave(thisplot,filename=paste0('IMAGES_withOldCode/man_',i,'.jpg'))
}


#pop

for (i in c(1931,2016)){
  #combine both into one shape 
  
  thisyear=paste0('Y', i)
  
  #ggmap(al1)+
  thisplot=ggplot()+theme_void()+
    geom_sf(data = ERIE_CAN_counties_POP, mapping=aes(fill = get(thisyear)),inherit.aes=FALSE,lwd = 0) + #polygons filled based on the 1950 value
    geom_sf(data = ERIE_USA_counties_POP, mapping=aes(fill = get(thisyear)),inherit.aes=FALSE,lwd = 0) + #polygons filled based on the 1950 value
    
    
    ggtitle(paste("POP (kg per ha)",toString(i),sep="\n"))+
    theme(legend.position = "right", legend.key.height = unit(2, "cm"),legend.key.width = unit(1, "cm"))+
    scale_fill_gradient2(low="gold1", mid="gold1", high="goldenrod4",
                         limits=c(0, max(CAN_County_pop[,2:18])+40))
  
  ggsave(thisplot,filename=paste0('IMAGES_withOldCode/pop_',i,'.jpg'))
}


# #dep  ****************************************************************************************************
# 
for (i in c(1931,2016)){
  #combine both into one shape 
  
  thisyear=paste0('Y', i)
  
  #ggmap(al1)+
  thisplot=ggplot()+theme_void()+
    geom_sf(data = ERIE_CAN_counties_DEP, mapping=aes(fill = get(thisyear)),inherit.aes=FALSE,lwd = 0) + #polygons filled based on the 1950 value
    geom_sf(data = ERIE_USA_counties_DEP, mapping=aes(fill = get(thisyear)),inherit.aes=FALSE,lwd = 0) + #polygons filled based on the 1950 value
    
    
    ggtitle(paste("DEP (kg per ha)",toString(i),sep="\n"))+
    theme(legend.position = "right", legend.key.height = unit(2, "cm"),legend.key.width = unit(1, "cm"))+
    scale_fill_gradient2(low="darkslategray2", mid="darkslategray2", high="darkcyan",
                         limits=c(0, max(CAN_County_dep[,2:18])+10))
  
  ggsave(thisplot,filename=paste0('IMAGES_withOldCode/dep_',i,'.jpg'))
}



# #bnf ****************************************************************************************************
# 
for (i in c(1931,2016)){
  #combine both into one shape 
  
  thisyear=paste0('Y', i)
  
  #ggmap(al1)+
  thisplot=ggplot()+theme_void()+
    geom_sf(data = ERIE_CAN_counties_BNF, mapping=aes(fill = get(thisyear)),inherit.aes=FALSE,lwd = 0) + #polygons filled based on the 1950 value
    geom_sf(data = ERIE_USA_counties_BNF, mapping=aes(fill = get(thisyear)),inherit.aes=FALSE,lwd = 0) + #polygons filled based on the 1950 value
    
    
    ggtitle(paste("BNF (kg per ha)",toString(i),sep="\n"))+
    theme(legend.position = "right", legend.key.height = unit(2, "cm"),legend.key.width = unit(1, "cm"))+
    scale_fill_gradient2(low="darkorange", mid="darkorange", high="darkorange3",
                         limits=c(0, max(CAN_County_bnf[,2:18])+60))
  
  ggsave(thisplot,filename=paste0('IMAGES_withOldCode/bnf_',i,'.jpg'))
}






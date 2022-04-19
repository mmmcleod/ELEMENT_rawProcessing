## CLIPPING CENSUS DATA TO WATERSHED AND AVERAGING TO GET ONE VAL PER YEAR
'###############################################################'

# get percent crop and percent pasture per county per year
'-------------------------------------------------'

#CAN 

numrows=length(can_crops[,1])
numcols = length(can_crops[1,])

#convert county area from m^2 to ha (since crop areas are ha)
can_county_area_ha = can_county_area
can_county_area_ha[,4]=can_county_area[,4]*.0001

#this section will create a table for present crop/pasture for each county over the years 
'-------------------------------------------------'

years = sort(na.omit(unique(can_crops[,3])))
counties = can_crops[1,4:numcols]

# get total county area matrix (total area for each county over the years - each year we assume same area)
totalcountyArea=matrix(,nrow=length(years),ncol=length(counties))

for (i in 1:length(years)){
  totalcountyArea[i,]= t(can_county_area_ha[,4])
}


# set up crop and pasture area for each county 
totalCrop = matrix(,nrow=length(years),ncol=length(counties))
totalPasture = matrix(,nrow=length(years),ncol=length(counties))

for (i in 1:length(years)){
  thisyear = years[i]
  
  #extract the year we want for each LU type
    thisyearPastMatrix = can_crops[(can_crops[,3]==thisyear)&(can_crops[,1]==2001|can_crops[,1]==2002),] #extract this year and only pasture area types
  thisyearCropMatrix = can_crops[(can_crops[,3]==thisyear)&(can_crops[,1]!=2001&can_crops[,1]!=2002),] #extract this year and only crop area types
  
  #sum together all areas for that year for each county 
  
  for (j in 1:length(counties)){
    thiscountyTotalCrop = sum(thisyearCropMatrix[,j+3],na.rm=TRUE)
    thiscountyTotalPast = sum(thisyearPastMatrix[,j+3],na.rm=TRUE)
    
    totalCrop[i,j]=thiscountyTotalCrop
    totalPasture[i,j]=thiscountyTotalPast
  }
}


#now divide each counties/year's crop and past are with total area (total area we did above)
percentCrop_CAN = totalCrop/totalcountyArea
percentPasture_CAN = totalPasture/totalcountyArea

CAN_countycrop=data.frame(years,percentCrop_CAN)
names(CAN_countycrop)=c("YEAR",counties)

CAN_countypast=data.frame(years,percentPasture_CAN)
names(CAN_countypast)=c("YEAR",counties)

# map each year's counties onto a raster
'-------------------------------------------------'
countyMap = ONT_shape
r = raster(ncol=4001, nrow=4001)
extent(r)=extent(countyMap)


#replace the CDNAME with the ID so that we can match up later 
countyMap$CDNAME[countyMap$CDNAME=="Waterloo"]=30000;countyMap$CDNAME[countyMap$CDNAME=="Lambton"]=38000;countyMap$CDNAME[countyMap$CDNAME=="Dufferin"]=22000;countyMap$CDNAME[countyMap$CDNAME=="Chatham-Kent"]=36000;countyMap$CDNAME[countyMap$CDNAME=="Essex"]=37000
countyMap$CDNAME[countyMap$CDNAME=="Haldimand-Norfolk"]=28000;countyMap$CDNAME[countyMap$CDNAME=="Elgin"]=34000;countyMap$CDNAME[countyMap$CDNAME=="Huron"]=40000;countyMap$CDNAME[countyMap$CDNAME=="Oxford"]=32000;countyMap$CDNAME[countyMap$CDNAME=="Perth"]=31000
countyMap$CDNAME[countyMap$CDNAME=="Wellington"]=23000;countyMap$CDNAME[countyMap$CDNAME=="Halton"]=24000 ;countyMap$CDNAME[countyMap$CDNAME=="Grey"]=42000 ;countyMap$CDNAME[countyMap$CDNAME=="Hamilton"]=25000;countyMap$CDNAME[countyMap$CDNAME=="Middlesex"]=39000;countyMap$CDNAME[countyMap$CDNAME=="Brant"]=29000
countyMap$ID = as.numeric(countyMap$CDNAME)

#turn county shapefile into a raster (then a brick, each year is the same)

countyMapRaster = rasterize(countyMap,r,"ID")
countyMapRaster = crop(countyMapRaster,WS_shape)


countyMapBrick= brick(countyMapRaster)

for (i in 2:length(years)){
  countyMapBrick=addLayer(countyMapBrick,countyMapRaster)
}


# map each year's percent crop and percent pasture onto the county raster 
'-------------------------------------------------'

crop_brick = brick()
past_brick = brick()

for (i in 1:length(years))
{
  thislayerCrop = countyMapRaster
  thislayerPast = countyMapRaster
  
  for (j in 1:length(counties))
  {
    if (j==5 | j==6) {thisCounty=28000} # this calls for when we have separate counties haldimand and norfolk 
    if (j!=5 & j!=6) {thisCounty = as.numeric(counties[j])}
    
    if (j==5 | j==6){ 
      thislayerCrop[thislayerCrop==thisCounty]=mean(percentCrop_CAN[i,8],percentCrop_CAN[i,9])
      thislayerPast[thislayerPast==thisCounty]=mean(percentPasture_CAN[i,8],percentPasture_CAN[i,9])}
    if (j!=5 & j!=6) {
      thislayerCrop[thislayerCrop==thisCounty]=percentCrop_CAN[i,j]
      thislayerPast[thislayerPast==thisCounty]=percentPasture_CAN[i,j]}
  }
  
  #dont include before 1931 
  
  if (i<4){}
  if (i>=4){
  crop_brick=addLayer(crop_brick,thislayerCrop)
  past_brick=addLayer(past_brick,thislayerPast)}
}



crop_brick
past_brick


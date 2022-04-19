## CLIPPING CENSUS DATA TO WATERSHED AND AVERAGING TO GET ONE VAL PER YEAR
'###############################################################'

# get percent crop and percent pasture per county per year
'-------------------------------------------------'

#USA 

numrows=length(usa_crops[,1])
numcols = length(usa_crops[1,])

#convert county area from m^2 to ha (since crop areas are ha)
usa_county_area_ha = usa_county_area
usa_county_area_ha[,4]=usa_county_area[,4]*.0001

#this section will create a table for present crop/pasture for each county over the years 
'-------------------------------------------------'

years = sort(na.omit(unique(usa_crops[,3])))
counties = colnames(usa_crops)[4:numcols] 
counties = as.numeric(substring(counties, 2))#turn to numeric 'x22000' to 22000 for example 


# get total county area matrix (total area for each county over the years - each year we assume same area)
totalcountyArea=matrix(,nrow=length(years),ncol=length(counties))

for (i in 1:length(years)){
  totalcountyArea[i,]= t(usa_county_area_ha[,4])
}


# set up crop and pasture area for each county 
totalCrop = matrix(,nrow=length(years),ncol=length(counties))
totalPasture = matrix(,nrow=length(years),ncol=length(counties))

for (i in 1:length(years)){
  thisyear = years[i]
  
  #extract the year we want for each LU type
  thisyearPastMatrix = usa_crops[(usa_crops[,3]==thisyear)&(usa_crops[,1]==1060|usa_crops[,1]==1057),] #extract this year and only pasture area types
  thisyearCropMatrix = usa_crops[(usa_crops[,3]==thisyear)&(usa_crops[,1]!=1060&usa_crops[,1]!=1057),] #extract this year and only crop area types
  
  #sum together all areas for that year for each county 
  
  for (j in 1:length(counties)){
    thiscountyTotalCrop = sum(thisyearCropMatrix[,j+3],na.rm=TRUE)
    thiscountyTotalPast = sum(thisyearPastMatrix[,j+3],na.rm=TRUE)
    
    totalCrop[i,j]=thiscountyTotalCrop
    totalPasture[i,j]=thiscountyTotalPast
  }
}


#now divide each counties/year's crop and past are with total area (total area we did above)
percentCrop_USA = totalCrop/totalcountyArea
percentPasture_USA = totalPasture/totalcountyArea

USA_countycrop=data.frame(years,percentCrop_USA)
names(USA_countycrop)=c("YEAR",counties)

USA_countypast=data.frame(years,percentPasture_USA)
names(USA_countypast)=c("YEAR",counties)

# map each year's counties onto a raster
'-------------------------------------------------'
countyMap = USA_shape
r = raster(ncol=4001, nrow=4001)
extent(r)=extent(countyMap)

countyMap$ID = as.numeric(countyMap$N3)

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
  
  for (j in 1:length(counties)){
    thisCounty = as.numeric(counties[j])
    thislayerCrop[thislayerCrop==thisCounty]=percentCrop_USA[i,j]
    thislayerPast[thislayerPast==thisCounty]=percentPasture_USA[i,j]
  }
  
  #dont include before 1931 
  
  if (i<2){}
  if (i>=2){
    crop_brick=addLayer(crop_brick,thislayerCrop)
    past_brick=addLayer(past_brick,thislayerPast)}
}



crop_brick
past_brick


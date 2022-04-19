rm(list=ls()) # clear the enviornment

# Load in neccesary packages 
library(raster)
library(rgdal)
library(sf)
# library(readxl)
# library(writexl)


# this is where the project will be extacting info from & where this script should be saved 
#setwd("C:/fill in WD")
setwd("~/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/LU processing")

#ramenkutty's data is in netcdf form, we can extract each year as a raster (one raster per year)

# look at the fist layver in the net cdf (test)
LU_rast1 = raster('glcrop_1700-2007_0.5.nc', level = 1)
LU_rast2 = raster('glpast_1700-2007_0.5.nc', level = 1)

# plot for sanity check 
plot(LU_rast1)
plot(LU_rast2)

# upload the stack as a whole

# Upload the entire crop dataset from Ramankutty 
cropNC = 'glcrop_1700-2007_0.5.nc'
cropNC.s = stack(cropNC)
# Upload the entire pasture dataset from Ramankutty 
pastNC = 'glpast_1700-2007_0.5.nc'
pastNC.s = stack(pastNC)

pastANDcropNC.s = cropNC.s+pastNC.s
nYears = nlayers(pastANDcropNC.s)

pastCropBool_stack=list()
for (i in 1:nYears){
  level = i
  print(level)
  #Grab this years raster
  thisYearLU_tot = raster(pastANDcropNC.s, level)
  #set values greater than 1 to one and less than 1 to 0 
  thisboolean_raster = thisYearLU_tot
  thisboolean_raster[thisboolean_raster<1]=0
  thisboolean_raster[thisboolean_raster>=1]=1
  # add to the stack of boolean values (greater than 1 or not)
  pastCropBool_stack[[i]]=thisboolean_raster
  ######setValues(pastANDcrop_greaterthan1_NC.s, values(thisboolean_raster), layer =level)
}

pastCropBool_stack = stack(pastCropBool_stack)
pastANDcrop_greaterthan1= stackApply(pastCropBool_stack,1,fun = sum)

pastANDcrop_greaterthan1[pastANDcrop_greaterthan1<1]=0
pastANDcrop_greaterthan1[pastANDcrop_greaterthan1>=1]=1

plot(pastANDcrop_greaterthan1)

writeRaster(pastANDcrop_greaterthan1,'pastANDcrop_greaterthan1.tif')

##########################################################################################
## comparing ramankuttys LU for 2000 to sedac 2000 pasture raster 

setwd("~/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/LU processing")
pastNC = 'glpast_1700-2007_0.5.nc'
pastNC.s = stack(pastNC)
nYears = nlayers(pastNC.s) #1700-2007 

#which layer is year 2000 
year2000idx=nYears-7

#grab ramankutty year 2000 
pastNC.s_2000 = pastNC.s[[year2000idx]]
#grab sedac pasture 2000 
setwd('na-pastures-geotif/')
past_sedac2000 = raster('na_pasture.tif')
setwd('..')

#plot both - North America 
extentNA = extent(past_sedac2000)
pastramankutty_2000 = crop(pastNC.s_2000,extentNA)

plot(pastramankutty_2000)
plot(past_sedac2000)

mean(values(pastramankutty_2000),na.rm=TRUE)
mean(values(past_sedac2000),na.rm=TRUE)

#plot both - Great Lakes 

GL_extent = c(-94,-71,39,52)
pastramankutty_2000 = crop(pastramankutty_2000,GL_extent)
past_sedac2000=crop(past_sedac2000,GL_extent)

plot(pastramankutty_2000)
plot(past_sedac2000)

plot(past_sedac2000,breaks= seq(0, 1, by = .005))
plot(pastramankutty_2000,breaks= seq(0, 1, by = .005))

mean(values(past_sedac2000),na.rm=TRUE)
mean(values(pastramankutty_2000),na.rm=TRUE)



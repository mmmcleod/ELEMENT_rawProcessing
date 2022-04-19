library(raster)
filename = 'pdep_2013'
d <- read.csv(paste0(filename, '.csv'))
r <- rasterFromXYZ(d)
writeRaster(r, paste0(filename, '.tif'),overwrite=TRUE)

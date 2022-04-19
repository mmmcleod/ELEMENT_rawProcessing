# Clipping Watersheds to N Surp
library(rgdal)        # To load "shapefiles" into R and use in conversions of spatial formats 
library(sf)           # To load "shapefiles" into R and use in conversions of spatial formats 
library(raster)
library(tidyverse)
library(ggplot2)
library(sp)

rm(list = ls(all.names = TRUE)) #will clear all objects includes hidden objects.
gc() #free up memory and report the memory usage.
cat("/014") # clear console 

data("pdep_2013.dat")
dat <- as.DataFrame("pdep_2013.dat")

nrow <- 1200
ncol <- 3600
filename <- "pdep_2013.dat"

data <- matrix(read_gsmap(filename, (nrow * ncol)),
               nrow = nrow,
               ncol = ncol,
               byrow = TRUE)






read_gsmap <- function(fname, nvals){
  ## gsmap daily world data is 4 byte little endian float
  on.exit(close(flcon))
  flcon <- file(fname, 'rb')
  readBin(flcon, "double", n = nvals, endian = "little", size = 4)
}

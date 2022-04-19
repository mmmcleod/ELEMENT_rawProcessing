# To run WRTDS using original R code (see USGS User Guide to EGRET and dataRetrieval: R Packages for Hydrologic Data, by Hirsch and Cicco)
# Written by Joy Liu
# Last updated October 19, 2019

### SET UP
rm(list=ls()) # clear the enviornment

install.packages("EGRET")
install.packages("readxl")
install.packages("writexl")

library(EGRET)
library(readxl)
library(writexl)

install.packages("viridisLite")
library(viridisLite)
install.packages("viridis")
library(viridis)
install.packages("gridExtra")
library(gridExtra)

### ACTION REQUIRED: Set to your working folder with folders for each station containing raw flow and concentration data
setwd('C:/Lamisa/Lake Erie trend data/Canada/NewNov21_WRTDS_removeoutlier/WRTDS')

### To retrieve the names of all station folders (name the folders the same way as you name the stations)
##### Used when you want to run multiple stations
##### ACTION REQUIRED only when the station name prefix is different
# file_name = list.files(path = ".",pattern="16018*")

### Used when you want to manually specify the station name
##### ACTION REQUIRED only when you want to change the station you want to run for
file_name = c("1.04001304402")

### running WRTDS for each station you've specified above under the vector file_name
for (i in 1:length(file_name)){

  
  filePath = file_name[i]
  fileName = paste0(file_name[i],'_clean_Q.csv')
  Daily = readUserDaily(filePath,fileName,qUnit=2)
  
  fileName = paste0(file_name[i],'_clean_C.csv')
  Sample = readUserSample(filePath,fileName)
  out.1 <- mean(Sample$ConcAve, na.rm=TRUE)+ 4*sd(Sample$ConcAve, na.rm=TRUE)
  r1<- Sample$ConcAve>out.1
  Sample[r1,-c(1,2,3,4,6,8:13)]<- NA
  Sample = removeDuplicates(Sample)

  
  INFO = read.csv(paste0(filePath,'/',file_name[i],'_INFO.csv'))
  INFO = INFO[1,]
  
  eList = mergeReport(INFO,Daily,Sample)
  eList = modelEstimation(eList,edgeAdjust = TRUE, verbose = TRUE, run.parallel = FALSE)

  
  eList = setPA(eList,paStart = 1, paLong = 12)
  
  # png(paste0(filePath,"/test.png"))
  # plotConcHist(eList)
  # dev.off()
  
  DailyOUTPUT = eList$Daily
  
  OUTPUT = cbind.data.frame(DailyOUTPUT$Date,DailyOUTPUT$Q,DailyOUTPUT$ConcDay)
  
  write_xlsx(OUTPUT,paste0(filePath,'/',file_name[i],"_Results.xlsx"))
  
  saveResults(paste0(filePath,'/'),eList)
  
}

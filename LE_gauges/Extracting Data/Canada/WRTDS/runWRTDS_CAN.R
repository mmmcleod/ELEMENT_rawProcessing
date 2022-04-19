# To run WRTDS using original R code (see USGS User Guide to EGRET and dataRetrieval: R Packages for Hydrologic Data, by Hirsch and Cicco)
# Written by Joy Liu
# Last updated October 19, 2019

### SET UP
rm(list=ls()) # clear the enviornment

#install.packages("EGRET")
#install.packages("readxl")
#install.packages("writexl")

library(EGRET)
library(readxl)
library(writexl)

#install.packages("viridisLite")
library(viridisLite)
#install.packages("viridis")
library(viridis)
#install.packages("gridExtra")
library(gridExtra)


### ACTION REQUIRED: Set to your working folder with folders for each station containing raw flow and concentration data
filePath="C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/LE_gauges/Extracting Data/Canada/WRTDS/Input_cleaned"
outPath = "C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/LE_gauges/Extracting Data/Canada/WRTDS/Output_wrtds"
setwd(filePath)

### To retrieve the names of all station folders (name the folders the same way as you name the stations)
##### Used when you want to run multiple stations
##### ACTION REQUIRED only when the station name prefix is different
# file_name = list.files(path = ".",pattern="16018*")

### Used when you want to manually specify the station name
##### ACTION REQUIRED only when you want to change the station you want to run for
file_names = list.files(path = ".",pattern="clean_C*")
file_names = unique(substr(file_names,1,11))

### running WRTDS for each station you've specified above under the vector file_name
#for (i in 1:length(file_names)){
for (i in c(1,4,6,7,8)){
  
  file_name=file_names[i]
  
  print(paste('Running WRTDS for ',file_name))
  fileName = paste0(file_name,'_clean_Q.csv')
  Daily = readUserDaily(filePath,fileName,qUnit=2)
  
  fileName = paste0(file_name,'_clean_C.csv')
  Sample = readUserSample(filePath,fileName)

  #remove outliers
  out.1 <- mean(Sample$ConcAve, na.rm=TRUE)+ 4*sd(Sample$ConcAve, na.rm=TRUE)
  r1<- Sample$ConcAve>out.1
  Sample[r1,-c(1,2,3,4,6,8:13)]<- NA
  Sample = removeDuplicates(Sample)
  
  
  INFO = read.csv(paste0(filePath,'/',file_name,'_INFO.csv'))
  INFO = INFO[1,]
  
  MNobs = 100 #default 
  MNuncert = 50 #default
  WINDs = 0.5 #default 
  WINDq = 2 #default
  WINDy = 7 #default
  
  if (i==1|i==4|i==6|i==11|i==12){MNobs=80} #these sites have fewer than 100 obs sampples 
  if(i==1|i==4 |i==6|i== 7|i== 8){}#WINDq=0.25} #these sites are overestimated using default window parameters
  eList = mergeReport(INFO,Daily,Sample)
  eList = modelEstimation(eList,edgeAdjust = TRUE, verbose = TRUE, run.parallel = FALSE,minNumObs = MNobs, minNumUncen = MNuncert, windowQ=WINDq, windowS=WINDs, windowY=WINDy) #-----<
  
  
  eList = setPA(eList,paStart = 1, paLong = 12)
  
  # par(mfrow=c(4,1))
  # plot(Daily$Date,Daily$Q)
  # plot(Daily$Date[is.element(Daily$Date,Sample$Date)],Daily$Q[is.element(Daily$Date,Sample$Date)])
  # plot(Sample$Date,Sample$ConcAve)
  # plot(eList$Daily$Date,eList$Daily$ConcDay)
  
  # png(paste0(filePath,"/test.png"))
  # plotConcHist(eList)
  # dev.off()
  
  DailyOUTPUT = eList$Daily
  
  OUTPUT = cbind.data.frame(DailyOUTPUT$Date,DailyOUTPUT$Q,DailyOUTPUT$ConcDay)
  
  write_xlsx(OUTPUT,paste0(outPath,'/',file_name,"_Results.xlsx"))
  
  saveResults(paste0(outPath,'/'),eList)
  
}

# To run WRTDS using original R code (see USGS User Guide to EGRET and dataRetrieval: R Packages for Hydrologic Data, by Hirsch and Cicco)
# Written by Joy Liu
# Last updated October 19, 2019

### SET UP
rm(list=ls()) # clear the enviornment

install.packages("EGRET")
install.packages("readxl")
install.packages("writexl")
install.packages("tidyr")

library(EGRET)
library(readxl)
library(writexl)
library(tidyr)

############################################
#removing outlier Nitin's code start

elistSRP<- eList
elistTP<- eList
x<-elistSRP
y<-elistTP

file_name = c("2.04001305802")
file_nameS = c("2.04001305802_SRP") 

plot(x$Sample$Date,x$Sample$ConcAve,type="o",col="red")

#removeoutlier<- function(x,y){
out.1 <- mean(x$Sample$ConcAve, na.rm=TRUE)+ 4*sd(x$Sample$ConcAve, na.rm=TRUE)
r1<- x$Sample$ConcAve>out.1
x$Sample[r1,-c(1,2,3,6,8:13)]<- NA
out.2 <- mean(y$Sample$ConcAve, na.rm=TRUE)+ 4*sd(y$Sample$ConcAve, na.rm=TRUE)
r2<- y$Sample$ConcAve>out.2
y$Sample[r2,-c(1,2,3,6,8:13)]<- NA
elist<- list(x,y)
#  return(elist)
#} #comment- x, y are lists for SRP, TP

ratiocheck<- function(x,y){   
  SRP<- x$Sample[,c(1,7,18)]
  colnames(SRP)[2:3]<- c("SRPC","SRPH")
  TP <- y$Sample[,c(1,7,18)]
  colnames(TP)[2:3]<- c("TPC","TPH")
  df <- inner_join(SRP,TP,by="Date") #require 'diplyr' and 'tidyr' library
  df$rawratio<- df$SRPC/df$TPC
  df$modratio<- df$SRPH/df$TPH
  plot(df$Date,df$SRPC/df$TPC,type="o",col="red")
  lines(df$Date,df$SRPH/df$TPH,type="l",col="black")
  return(df)
}

#removebadata<- function(x,y){
uu <- ratiocheck(x,y) # uses the function below to plot ratios for obs and modeled data; X=SRP lists, Y=TP lists
uu1<- uu[uu$rawratio>=1,]
hhx <-  x$Sample$Date  %in% uu1$Date
hhy<-   y$Sample$Date  %in% uu1$Date
x$Sample[hhx,-c(1,2,3,6,8:13)]<- NA
y$Sample[hhy,-c(1,2,3,6,8:13)]<- NA
elist<- list(x,y)
# return(elist)
#}
#elist<- list(x,y)
plot(elist[[1]]$Sample$Julian,elist[[1]]$Sample$ConcAve,type="o",col="red")
#--------------------------------------
### ACTION REQUIRED: Set to your working folder with folders for each station containing raw flow and concentration data
setwd('C:/Lamisa/Lake Erie trend data/Canada/JOY_WRTDS_removeoutlier')

### To retrieve the names of all station folders (name the folders the same way as you name the stations)
##### Used when you want to run multiple stations
##### ACTION REQUIRED only when the station name prefix is different
# file_name = list.files(path = ".",pattern="16018*")

### Used when you want to manually specify the station name
##### ACTION REQUIRED only when you want to change the station you want to run for
#TP
### running WRTDS for each station you've specified above under the vector file_name
for (i in 1:length(file_name)){
  filePath = file_name[i]
  # fileName = paste0(file_name[i],'_clean_Q.csv')
  # Daily = readUserDaily(filePath,fileName,qUnit=2)
  # fileName = paste0(file_name[i],'_clean_C.csv')
  # Sample = readUserSample(filePath,fileName)
  # Sample = removeDuplicates(Sample)
  INFO = read.csv(paste0(filePath,'/',file_name[i],'_INFO.csv'))
  INFO = INFO[1,]
  Sample= elist[[2]]$Sample
  startDate=min(as.character(Sample$Date))
  endDate=max(as.character(Sample$Date))
  Daily=elist[[2]]$Daily
  Daily <- subset(Daily, Date >= startDate)
  Daily <- subset(Daily, Date <= endDate)
  elist_TP = mergeReport(INFO,Daily,Sample)
  eList_TP = modelEstimation(elist_TP)
  eList_TP = setPA( eList_TP,paStart = 1, paLong = 12)
  png(paste0(filePath,"/test.png"))
  plotConcHist(eList_TP)
  dev.off()
  
  DailyOUTPUT =  eList_TP$Daily
  
  OUTPUT = cbind.data.frame(DailyOUTPUT$Date,DailyOUTPUT$Q,DailyOUTPUT$ConcDay)
  
  write_xlsx(OUTPUT,paste0(filePath,'/',file_name[i],"_Results.xlsx"))
  
  saveResults(paste0(filePath,'/'),eList_TP)
  
}
#------------------------------------------------
#SRP
### running WRTDS for each station you've specified above under the vector file_name
for (i in 1:length(file_nameS)){
  filePath = file_nameS[i]
  # fileName = paste0(file_name[i],'_clean_Q.csv')
  # Daily = readUserDaily(filePath,fileName,qUnit=2)
  # fileName = paste0(file_name[i],'_clean_C.csv')
  # Sample = readUserSample(filePath,fileName)
  # Sample = removeDuplicates(Sample)
  INFO = read.csv(paste0(filePath,'/',file_nameS[i],'_INFO.csv'))
  INFO = INFO[1,]
  Sample= elist[[1]]$Sample
  startDate=min(as.character(Sample$Date))
  endDate=max(as.character(Sample$Date))
  Daily=elist[[1]]$Daily
  Daily <- subset(Daily, Date >= startDate)
  Daily <- subset(Daily, Date <= endDate)
  elist_SRP = mergeReport(INFO,Daily,Sample)
  eList_SRP = modelEstimation(elist_SRP)
  eList_SRP = setPA( eList_SRP,paStart = 1, paLong = 12)
  png(paste0(filePath,"/test.png"))
  plotConcHist(eList_SRP)
  dev.off()
  
  DailyOUTPUT =  eList_SRP$Daily
  
  OUTPUT = cbind.data.frame(DailyOUTPUT$Date,DailyOUTPUT$Q,DailyOUTPUT$ConcDay)
  
  write_xlsx(OUTPUT,paste0(filePath,'/',file_name[i],"_Results.xlsx"))
  
  saveResults(paste0(filePath,'/'),eList_SRP)
  
}







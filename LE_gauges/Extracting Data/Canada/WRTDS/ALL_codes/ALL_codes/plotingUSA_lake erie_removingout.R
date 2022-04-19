for(p in c("ggplot2","raster","sf","plyr","dplyr","grid","gridExtra",
           "ggplotify","ggsn","EGRET","dataRetrieval")){
  if(!require(p,character.only=T)){install.packages(p)}
  library(p,character.only=T,quietly=TRUE) }

theme_set(theme_bw()+
            theme(panel.background= element_rect(fill="white",color=1),
                  panel.border= element_rect(fill="transparent",color=1),
                  panel.grid=element_line(color="white")
            ))

# #see site name
# siteNumbers <- c("04161820","04165500","04167150","04168400","04174500","04175600","04183500","04185318","04186500","04188100","04188496","04190000","04191500","04192500","04193500","04195500","04200500", "04208000", "04166500", "04176500", "04213500", "04199500")
# siteINFO <- readNWISsite(siteNumbers)
# write.table (siteINFO,file = "USA_lake_erie_station.csv")
# dailyDataAvailable <- whatNWISdata(siteNumbers,
#                                    service="dv", statCd="00003")
install.packages("EGRET")
install.packages("readxl")
install.packages("writexl")
install.packages("dataretrieval")
install.packages("httr")
install.packages("xml2")
install.packages("curl")
install.packages("readr")
install.packages("hms")
install.packages("lubridate")

#SRP ID= 00671

siteID <- "04198000" #Cuyahoga River 

dataavail <- whatNWISdata(siteNumber=siteID)
for(param in c("00665")){
  INFO1=readNWISInfo(siteID,param,interactive=F)
  Sample1=readNWISSample(siteID,param)
  startDate=min(as.character(Sample1$Date))
  endDate=max(as.character(Sample1$Date))
  # Gather discharge data:
  Daily1=readNWISDaily(siteID,"00060",startDate,endDate)
  # Merge discharge with sample data:
  eList_TP=mergeReport(INFO1, Daily1, Sample1)
  name=paste0("eList_TP-",siteID)
  eval(call("<-", as.name(name), eList_TP))
}
eListTP <- modelEstimation(eList_TP)


tableResults(eListTP, qUnit = 3, fluxUnit = 6)
# siteID <- "04161820" #Cuyahoga River 
dataavail <- whatNWISdata(siteNumber=siteID)
for(param in c("00671")){
  INFO2=readNWISInfo(siteID,param,interactive=F)
  Sample2=readNWISSample(siteID,param)
  startDate=min(as.character(Sample2$Date))
  endDate=max(as.character(Sample2$Date))
  # Gather discharge data:
  Daily2=readNWISDaily(siteID,"00060",startDate,endDate)
  # Merge discharge with sample data:
  eList_SRP=mergeReport(INFO2, Daily2, Sample2)
  name=paste0("eList_SRP-",siteID)
  eval(call("<-", as.name(name), eList_SRP))
}
eListSRP <- modelEstimation(eList_SRP)

############################################
#removing outlier Nitin's code start

x<-eListSRP
y<-eListTP

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

#-----------------------

setwd('C:/Lamisa/Lake Erie trend data/Canada/JOY_WRTDS_removeout')
file_name = c("8.Maumee")
file_nameS = c("8.Maumee_SRP")

#TP
### running WRTDS for each station you've specified above under the vector file_name
for (i in 1:length(file_name)){
  filePath = file_name[i]
  # fileName = paste0(file_name[i],'_clean_Q.csv')
  # Daily = readUserDaily(filePath,fileName,qUnit=2)
  # fileName = paste0(file_name[i],'_clean_C.csv')
  # Sample = readUserSample(filePath,fileName)
  # Sample = removeDuplicates(Sample)
  Sample= elist[[2]]$Sample
  # startDate=min(as.character(Sample$Date))
  # endDate=max(as.character(Sample$Date))
  # Daily=elist[[2]]$Daily
  # Daily <- subset(Daily, Date >= startDate)
  # Daily <- subset(Daily, Date <= endDate)
  elist_TP = mergeReport(INFO1,Daily1,Sample)
  eList_TP = modelEstimation(elist_TP)
  # eList_TP = setPA( eList_TP,paStart = 1, paLong = 12)
  # png(paste0(filePath,"/test.png"))
  # plotConcHist(eList_TP)
  # dev.off()
  # 
  DailyOUTPUT =  eList_TP$Daily
  B2 <-fluxBiasStat(eList_TP$Sample)
  OUTPUT = cbind.data.frame(DailyOUTPUT$Date,DailyOUTPUT$Q,DailyOUTPUT$ConcDay,B2)
  
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
  # INFO = read.csv(paste0(filePath,'/',file_nameS[i],'_INFO.csv'))
  # INFO = INFO[1,]
  Sample= elist[[1]]$Sample
  # startDate=min(as.character(Sample$Date))
  # endDate=max(as.character(Sample$Date))
  # Daily=elist[[1]]$Daily
  # Daily <- subset(Daily, Date >= startDate)
  # Daily <- subset(Daily, Date <= endDate)
  elist_SRP = mergeReport(INFO2,Daily2,Sample)
  eList_SRP = modelEstimation(elist_SRP)
  # eList_SRP = setPA( eList_SRP,paStart = 1, paLong = 12)
  # png(paste0(filePath,"/test.png"))
  # plotConcHist(eList_SRP)
  # dev.off()
  # 
  DailyOUTPUT =  eList_SRP$Daily
  B1 <-fluxBiasStat(eList_SRP$Sample)
  OUTPUT = cbind.data.frame(DailyOUTPUT$Date,DailyOUTPUT$Q,DailyOUTPUT$ConcDay,B1)
  
  write_xlsx(OUTPUT,paste0(filePath,'/',file_nameS[i],"_Results.xlsx"))
  
  saveResults(paste0(filePath,'/'),eList_SRP)
  
}










####################################

jpeg("FVsT-station11.jpg") 
plotFluxTimeDaily(eList, fluxUnit=8)
dev.off ();
tableResults(eList)
returnDF <- tableResults(eList)
jpeg("CVsT-station11.jpg") 
plotConcTime(eList)
dev.off ();
jpeg("CVsQ-station11.jpg") 
plotConcQ(eList, qUnit=2)
dev.off ();
jpeg("FVsQ-station11.jpg") 
plotFluxQ(eList, fluxUnit=8)
dev.off ();
jpeg("Chist-station11.jpg")
plotConcHist(eList)
dev.off ();
jpeg("FVsT-station11.jpg") 
dev.off ();

for (siteNumber in c("04161820","04165500","04167150","04168400","04174500","04175600","04183500","04185318","04186500","04188100","04188496","04190000","04191500","04192500","04193500","04195500","04200500", "04208000")){
dataavail <- whatNWISdata(siteNumber)


param<-"00665" #5 digit USGS code
subset(dataavail,parm_cd==param) # subset by parameter equal to 00665
readNWISInfo(siteNumber,parameterCd=param,interactive= FALSE)
create.eList=function(siteNumber,param){
  INFO=readNWISInfo(siteNumber,param,interactive=F)
Sample=readNWISSample(siteNumber,param,verbose=F)
startDate=min(as.character(Sample$Date))
endDate=max(as.character(Sample$Date))
# Gather discharge data:
Daily=readNWISDaily(siteNumber,"00060",startDate,endDate)
#Merge discharge with sample data:
  eList=mergeReport(INFO, Daily, Sample)
name=paste0("eList",siteNumber)
eval(call("<-", as.name(name), eList))
}
}



siteID <- "04186500" #Cuyahoga River 
dataavail <- whatNWISdata(siteNumber=siteID)
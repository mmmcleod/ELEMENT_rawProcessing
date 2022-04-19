#  LOAD LIBRARIES 
library(naniar)
library(rgdal)
library(DBI)
library(sf)
library(readxl)
library(dplyr)
library(dataRetrieval)
vignette("dataRetrieval", package = "dataRetrieval")


# UP TO THIS POINT - GAUGES HAVE BEEN SELECTED, 
# THIS CODE EXTRACTS THEIR DATA FROM USGS OR ALTERNATELY DOWNLOADED DATESETS 

# SET UP DIRECTORIES 
sourceDir="C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/LE_gauges/Extracting Data/USA/Gauge_discharge_WQ/"
stationDir="C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/LE_gauges/Gauge_pairing/USA"
#

# GET LIST OF STATIONS 
setwd(stationDir)
stationSummary = read.csv('USA_gauge_ELEMENT_N.csv')
# #make a new column 
stationSummary$IDstrings=stationSummary$Unique.sites.between.Danyka.and.Lamisa
# #extract the list from table
stationlist = stationSummary$IDstrings[2:21]
#

# FOR EACH STATION CREATE AND WRITE A TABLE WITH DISCHARGE DATA 
param='00060' #<- discharge from USGS 

setwd(paste0(sourceDir,'/ExtractedDischarge/'))
for (i in 1:length(stationlist)){
  thisStation = paste0('0',toString(stationlist[i]))
  thisStationQ = readNWISdv(thisStation,param)
  thisStationQ$X_00060_00003=thisStationQ$X_00060_00003*0.0283168 #turn to m^3 from ft^3
  write.table(thisStationQ,paste0(thisStation,'DischargeDaily.csv'))
}
setwd(sourceDir)


# FOR EACH STATION, EXTRACT WQ DATA (EITHER NITRATE OR NITRATE&NITRITE DATA)
# Data either comes from MIDEQ, USGS, OHEPA, Heidelberg, or a combination 
# To be long-winded, but precise, each gauge will get it's own section

# note, you can query USGS parameter codes here: https://help.waterdata.usgs.gov/parameter_cd_nm 

# 00618 -> Nitrate, water, filtered, milligrams per liter as nitrogen
# 00631 ->Nitrate plus nitrite, water, filtered, milligrams per liter as nitrogen


# START BY EXTRACTING SITES WHICH *ONLY* HAVE USGS DATA -------------------------------------------------
stationListUSGS = c("4161820","4165500","4191500","4192500","4213500","4186500")

# Indicate earliest and latest date 
earliestDate = "1838-01-01"
latestDate = "2021-01-01"

#iterate through each site IDs and extract relevant data from USGS
setwd(paste0(sourceDir,'/ExtractedWQ/'))
for (i in 1:length(stationListUSGS)){
  siteNumber=paste("0",as.character(stationListUSGS[i]),sep="")
  siteInfo=readNWISsite(siteNumber)
  
  parameterCd="00631" #(this is the parameter for the N data we need) [mg/L]
  thisNitrateNitrite = readNWISqw(siteNumber,parameterCd,earliestDate,latestDate)
  parameterCd="00618"
  thisNitrate = readNWISqw(siteNumber,parameterCd,earliestDate,latestDate)
  
  #combine the two data sources and only take relevant rows 
  thisDailyData = bind_rows(thisNitrateNitrite,thisNitrate) #combine
  thisCleanTable = thisDailyData[,FALSE]
  thisCleanTable$SITE = thisDailyData$site_no
  thisCleanTable$DATE = thisDailyData$sample_dt
  thisCleanTable$PARAM = thisDailyData$parm_cd
  thisCleanTable$VALUE = thisDailyData$result_va
  
  #eliminate duplicate dates (take the higher since it should have nitrate&nitrite)
  thisCleanTable=thisCleanTable[order(thisCleanTable$VALUE,decreasing = TRUE),]#order so only larger of the duplicates are taken 
  thisCleanTable=thisCleanTable[!duplicated(thisCleanTable$DATE),] #now remove the duplicates with lower values
  thisCleanTable=thisCleanTable[order(thisCleanTable$DATE,decreasing = FALSE),]
  
  write.csv(thisCleanTable,paste('WQ_',siteNumber,'.csv',sep=''))
  
  }
setwd(sourceDir)

# NEXT, EXTRACT SITES WITH MIDEQ DATA (AND USGS),  -------------------------------------------------

stationListMIDEQ=c("4166500","4174500")

#iterate through each site IDs and extract relevant data from MIDEQ (and USGS)

for (i in 1:length(stationListMIDEQ)){
  
  #extract mideq data for this station 
  siteNumber=paste("0",as.character(stationListMIDEQ[i]),sep="")
  siteInfo=readNWISsite(siteNumber) 
  setwd(paste0(sourceDir,'/RawData_MIDEQ_OHEPA_Heidleburg/'))
  #extract table
  MIDEQInfo=read_xlsx(paste0(stationListMIDEQ[i],'_MIDEQ.xlsx'))
  setwd(paste0(sourceDir,'/ExtractedWQ/'))
  
  #EXTRACT MIDEQ DATA
  
  #only take param we want (nitrate/nitrite) 
  thisMIDEQ = MIDEQInfo[(MIDEQInfo$`Parameter Name`== 'Nitrate + Nitrite'|MIDEQInfo$`Parameter Name`== 'Total Nitrate'),]
  
  
  #EXTRACT USGS DATA 
  
  parameterCd="00631" #(this is the parameter for the N data we need) [mg/L]
  thisNitrateNitrite = readNWISqw(siteNumber,parameterCd,earliestDate,latestDate)
  parameterCd="00618"
  thisNitrate = readNWISqw(siteNumber,parameterCd,earliestDate,latestDate)
  
  #MERGE THEM TOGETHER 
  
  DATE = c(thisNitrateNitrite$sample_dt,thisNitrate$sample_dt,thisMIDEQ$`Sample Collection Date`)
  SITE = c(thisNitrateNitrite$site_no,thisNitrate$site_no,thisMIDEQ$`STORET ID`)
  VALUE = c(thisNitrateNitrite$result_va,thisNitrate$result_va,thisMIDEQ$`Result Value`)
  PARAM = c(thisNitrateNitrite$parm_cd,thisNitrate$parm_cd,thisMIDEQ$`Parameter Name`)
  
  thisCleanTable=data.frame(SITE,DATE,PARAM,VALUE)
  
  #eliminate duplicate dates (take the higher since it should have nitrate&nitrite)
  thisCleanTable=thisCleanTable[order(thisCleanTable$VALUE,decreasing = TRUE),]#order so only larger of the duplicates are taken 
  thisCleanTable=thisCleanTable[!duplicated(thisCleanTable$DATE),] #now remove the duplicates with lower values
  thisCleanTable=thisCleanTable[order(thisCleanTable$DATE,decreasing = FALSE),]
  
  write.csv(thisCleanTable,paste('WQ_',siteNumber,'.csv',sep=''))
  
  
}
setwd(sourceDir)

# NEXT, EXTRACT SITES WITH HEIDLEBURG DATA (+USGS),  -------------------------------------------------

stationListHEID =c("4176500","4193500","4197100","4197170","4198000","4199500","4208000")

#iterate through each site IDs and extract relevant data from HEID (and USGS)

for (i in 1:length(stationListHEID)){
  
  #extract heidleburg data for this station 
  siteNumber=paste("0",as.character(stationListHEID[i]),sep="")
  siteInfo=readNWISsite(siteNumber) 
  setwd(paste0(sourceDir,'/RawData_MIDEQ_OHEPA_Heidleburg/'))
  #extract table
  HEIDInfo=read_xlsx(paste0(stationListHEID[i],'_HEID.xlsx'))
  setwd(paste0(sourceDir,'/ExtractedWQ/'))
  
  #EXTRACT HEID DATA
  
  #only take param we want (nitrate/nitrite) 
  thisHEID = HEIDInfo
  
  #EXTRACT USGS DATA 
  
  parameterCd="00631" #(this is the parameter for the N data we need) [mg/L]
  thisNitrateNitrite = readNWISqw(siteNumber,parameterCd,earliestDate,latestDate)
  parameterCd="00618"
  thisNitrate = readNWISqw(siteNumber,parameterCd,earliestDate,latestDate)
  
  #MERGE THEM TOGETHER 
  
  VALUE = c(thisNitrateNitrite$result_va,thisNitrate$result_va,thisHEID$`NO23, mg/L as N`)#remove negs (heidleburg has some)
  idx=!(VALUE<0)
  DATE = c(thisNitrateNitrite$sample_dt,thisNitrate$sample_dt,as.Date(thisHEID$`Datetime (date and time of sample collection)`)) #turn Heid's datetime into date
  if (is.null(thisNitrateNitrite$sample_dt)){
    DATE = as.Date(thisHEID$`Datetime (date and time of sample collection)`) # for sites with no USGS data
    }
  SITE = c(thisNitrateNitrite$site_no,thisNitrate$site_no,rep(NA,length(thisHEID$Month))) #heidleburg doesnt have a site column
  PARAM = c(thisNitrateNitrite$parm_cd,thisNitrate$parm_cd,rep("NO23 mg/L as N",length(thisHEID$Month)))
  VALUE=VALUE[idx];DATE=DATE[idx];SITE=SITE[idx];PARAM=PARAM[idx]

  
  
  thisCleanTable=data.frame(SITE,DATE,PARAM,VALUE)
  
  #eliminate duplicate dates (take the higher since it should have nitrate&nitrite)
  thisCleanTable=thisCleanTable[order(thisCleanTable$VALUE,decreasing = TRUE),]#order so only larger of the duplicates are taken 
  thisCleanTable=thisCleanTable[!duplicated(thisCleanTable$DATE),] #now remove the duplicates with lower values
  thisCleanTable=thisCleanTable[order(thisCleanTable$DATE,decreasing = FALSE),]
  
  write.csv(thisCleanTable,paste('WQ_',siteNumber,'.csv',sep=''))
  
}


# NEXT, EXTRACT SITES WITH OHEPA DATA (+USGS),  -------------------------------------------------

stationListOHEPA =c("4199000","4200500","4201500","4209000")

#iterate through each site IDs and extract relevant data from OHEPA (and USGS)

for (i in 1:length(stationListOHEPA)){
  
  #extract heidleburg data for this station 
  siteNumber=paste("0",as.character(stationListOHEPA[i]),sep="")
  siteInfo=readNWISsite(siteNumber) 
  setwd(paste0(sourceDir,'/RawData_MIDEQ_OHEPA_Heidleburg/'))
  #extract table
  OHEPAInfo=read_xlsx(paste0(stationListOHEPA[i],'_OHEPA.xlsx'))
  setwd(paste0(sourceDir,'/ExtractedWQ/'))
  
  #EXTRACT OHEPA DATA
  
  #only take param we want (nitrate/nitrite) 
  thisOHEPA = OHEPAInfo[(OHEPAInfo$Parameter== 'Nitrate+nitrite'),]
  
  #EXTRACT USGS DATA 
  
  if (i!=4){ #some sites do not have USGS data
  parameterCd="00631" #(this is the parameter for the N data we need) [mg/L]
  thisNitrateNitrite = readNWISqw(siteNumber,parameterCd,earliestDate,latestDate)
  parameterCd="00618"
  thisNitrate = readNWISqw(siteNumber,parameterCd,earliestDate,latestDate)
  
  
  #MERGE THEM TOGETHER 
  
  DATE = c(thisNitrateNitrite$sample_dt,thisNitrate$sample_dt,as.Date(thisOHEPA$`Sample Dt`)) 
  SITE = c(thisNitrateNitrite$site_no,thisNitrate$site_no,thisOHEPA$Station) 
  VALUE = c(thisNitrateNitrite$result_va,thisNitrate$result_va,thisOHEPA$Result)
  PARAM = c(thisNitrateNitrite$parm_cd,thisNitrate$parm_cd,thisOHEPA$Parameter) 
  
  }
  
  if (i==3){
    DATE = c(thisNitrate$sample_dt,as.Date(thisOHEPA$`Sample Dt`)) #turn Heid's datetime into date
    SITE = c(thisNitrate$site_no,thisOHEPA$Station) 
    VALUE = c(thisNitrate$result_va,thisOHEPA$Result)
    PARAM = c(thisNitrate$parm_cd,thisOHEPA$Parameter) 
  }
  
  if (i==4){
    DATE = as.Date(thisOHEPA$`Sample Dt`) #turn Heid's datetime into date
    SITE = thisOHEPA$Station #heidleburg doesnt have a site column
    VALUE = thisOHEPA$Result
    PARAM = thisOHEPA$Parameter 
  }
  
  thisCleanTable=data.frame(SITE,DATE,PARAM,VALUE)
  
  #eliminate duplicate dates (take the higher since it should have nitrate&nitrite)
  thisCleanTable=thisCleanTable[order(thisCleanTable$VALUE,decreasing = TRUE),]#order so only larger of the duplicates are taken 
  thisCleanTable=thisCleanTable[!duplicated(thisCleanTable$DATE),] #now remove the duplicates with lower values
  thisCleanTable=thisCleanTable[order(thisCleanTable$DATE,decreasing = FALSE),]
  
  write.csv(thisCleanTable,paste('WQ_',siteNumber,'.csv',sep=''))
  
}


# FINALLY GRAB THE STATION WHICH NEEDS both HEID AND OHEPA data 


siteNumber=paste("0",as.character(4212100),sep="")
siteInfo=readNWISsite(siteNumber) 
setwd(paste0(sourceDir,'/RawData_MIDEQ_OHEPA_Heidleburg/'))
#extract table
OHEPAInfo=read_xlsx(paste0('4212100','_OHEPA.xlsx'))
HEIDInfo=read_xlsx(paste0('4212100','_HEID.xlsx'))
setwd(paste0(sourceDir,'/ExtractedWQ/'))

thisOHEPA = OHEPAInfo[(OHEPAInfo$Parameter== 'Nitrate+nitrite'),]
thisHEID = HEIDInfo

VALUE = c(thisOHEPA$Result,thisHEID$`Value [NO23] Nitrite + Nitrate (mg-N/L)`)#remove negs (heidleburg has some)
idx=!(VALUE<0)
DATE = c(thisOHEPA$`Sample Dt`,as.Date(thisHEID$`Datetime (date and time of sample collection)`)) #turn Heid's datetime into date
SITE = c(thisOHEPA$Station,rep(NA,length(thisHEID$DateTime))) #heidleburg doesnt have a site column
PARAM = c(thisOHEPA$Parameter,rep("NO23 mg/L as N",length(thisHEID$DateTime)))
VALUE=VALUE[idx];DATE=DATE[idx];SITE=SITE[idx];PARAM=PARAM[idx]

thisCleanTable=data.frame(SITE,DATE,PARAM,VALUE)

#eliminate duplicate dates (take the higher since it should have nitrate&nitrite)
thisCleanTable=thisCleanTable[order(thisCleanTable$VALUE,decreasing = TRUE),]#order so only larger of the duplicates are taken 
thisCleanTable=thisCleanTable[!duplicated(thisCleanTable$DATE),] #now remove the duplicates with lower values
thisCleanTable=thisCleanTable[order(thisCleanTable$DATE,decreasing = FALSE),]

write.csv(thisCleanTable,paste('WQ_',siteNumber,'.csv',sep=''))





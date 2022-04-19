# for usgs, state,tribal, and other data: readWQPSample (only use USGS if you use USGS-####)
# for usgs: readNWISSample 





#run the install pakages 
#SRP ID= 00671 #TP="00665"

#See the list of stations to run WRTDS

#----------Additional sites-------------
siteIDTab <- read_excel( "additionalstations_25Oct.xlsx")
# siteIDTab <- read_excel( "Old_USA_for_plotting.xlsx")
head(siteIDTab)
siteID <-as.character(siteIDTab$`Site Number`)

#-------------when specified station----------------
# siteID <- "01491000" #USGS side ID
#siteID <-c("01491000","01645000") #another way to write it (multiple stations)

#------------plot for WQ anD Q for checking--------------
dataavail <- whatNWISdata(siteNumber=siteID)
for(i in 18: length(siteID)){
  for(param in c("00665")){
    siteNumber=siteID[i]
    INFO1=readNWISInfo(siteID[i],param,interactive=F)
    Sample1=readNWISSample(siteID[i],param)
    startDate=min(as.character(Sample1$Date))
    endDate=max(as.character(Sample1$Date))
    # Gather discharge data:
    DailyQ_sample=readNWISDaily(siteID[i],"00060")#all avaialble
    startDateQ=min(as.character(DailyQ_sample$Date))
    endDateQ=max(as.character(DailyQ_sample$Date))
    DailyQ=readNWISDaily(siteID[i],"00060",startDateQ,endDateQ)#all avaialble
    Daily1=readNWISDaily(siteID[i],"00060",startDate,endDate) #cut for WQ
    #Daily1=readNWISDaily(siteID[i],"00060")
    # Merge discharge with sample data:
    eList_TP=mergeReport(INFO1, Daily1, Sample1)
    name=paste0("eList_TP",siteID[i])
    eval(call("<-", as.name(name), eList_TP))
  } 
#print plots
png(paste0(siteNumber,"C-Q_availability.png"))
par(mfrow=c(3,1))
plot(Sample1$Date,Sample1$ConcAve,type="o",col="red")
plot(Daily1$Date,Daily1$Q,type="l",col="black")
plot(DailyQ$Date,DailyQ$Q,type="l",col="blue")
dev.off()
}

#-------------running WRTDS-------------

for(i in 1: length(siteNumber)){
for(param in c("00665")){
  INFO1=readNWISInfo(siteID[i],param,interactive=F)
  Sample1=readNWISSample(siteID[i],param)
  startDate=min(as.character(Sample1$Date))
  endDate=max(as.character(Sample1$Date))
  # Gather discharge data:
  Daily1=readNWISDaily(siteID[i],"00060",startDate,endDate)
  # Merge discharge with sample data:
  eList_TP=mergeReport(INFO1, Daily1, Sample1)
  name=paste0("eList_TP",siteID[i])
  eval(call("<-", as.name(name), eList_TP))
}
eListTP <- modelEstimation(eList_TP,minNumObs=100) }

#-----------extracting data from storet----------------------------
#(no addtional station found that matches the criteria)
#state code (https://www.waterqualitydata.us/Codes/statecode?countrycode=US)
#OH=39;MI=26;IN=18;PA=42;NY=36
type <- "Stream"
LEstates<-c("US:39","US:26","US:18","US:42","US:36")
#sitesSTORETcheck <- whatWQPsites(statecode=LEstates,
#  characteristicName="Phosphorus",siteType=type)
Storet_read <- readWQPdata(statecode=LEstates,
                           characteristicName="Phosphorus", ResultSampleFractionText="Total",siteType=type)
write.csv(Storet_read,"C:/Lamisa/Lake Erie trend data/R-USA/OCT_Data_Retrieval/STORET.csv", row.names = FALSE)


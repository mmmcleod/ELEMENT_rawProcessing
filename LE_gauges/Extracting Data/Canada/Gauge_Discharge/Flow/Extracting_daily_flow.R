# Set up 
'______________________________________________'
library(readxl)
library(tidyhydat)
library(writexl)

#download_hydat()

thisFileLocation="C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/LE_gauges/Extracting Data/Canada/Gauge_Discharge/Flow"

# get list of sites to extract data for
'______________________________________________'
pathToPairs="C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/LE_gauges/Gauge_pairing/CANADA/Meghan_lamisa_CAN pairs/"
setwd(pathToPairs)

pairsTable=read.csv('CanadianSET.csv')
listofQ = pairsTable$Q.station.ID
#fix weird /t thing: 
listofQ[11]="02GH003"


#extract data 
'______________________________________________'

setwd(thisFileLocation)
for (i in c(1:26,28:length(listofQ))) { #skilling 27th item which is york which we already have
  thistation = listofQ[i]
  print(thistation)
  thisdailyflow=hy_daily_flows(thistation)
  write_xlsx(thisdailyflow,paste0(thistation,"_dailyQ.xlsx"))
}

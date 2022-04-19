library(EGRET)

#PATH TO R RESULTS -------------------------------------------------------------

pathResults = "C:/Users/Meghan McLeod/Dropbox/BASULAB_meghan/Proposal/Lake Erie Data processing/LE_gauges/Extracting Data/Canada/WRTDS/Output_wrtds/R_files/"
problemSites = c("02GH002","02GD003","02GH003","02GA023") #4th is unproblematic (for comparison)
problemSiteIDs = c('04001000302','04002701602','10000200202','16018401602')  #4th is unproblematic (for comparison)

#which site to look at  --------------------------------------------------------
site =1

load(paste0(pathResults,problemSites[site],".NA.RData"))

InputConcDaily = Sample$ConcAve
InputConcDate = Sample$Date
InputDisDaily = Daily$Q
InputDisDate = Daily$Date
OutputConcDaily = DailyOUTPUT$ConcDay
OutputConcDate = DailyOUTPUT$Date

Overlap = is.element(InputDisDate,InputConcDate)
InputDisOnConcDate = InputDisDate[Overlap]
InputDisOnConcDaily = InputDisDaily[Overlap]
print(mean(InputDisDaily))
print(mean(InputDisOnConcDaily))

OutputConcOnConcDate = OutputConcDate[Overlap]
OutputConcOnConcDaily = OutputConcDaily[Overlap]

#Preliminary plot --------------------------------------------------------------

par(mfrow=c(4,1),omi=c(0.5,0.3,0,0), plt=c(0.1,0.9,0,0.7))

plot(InputDisDate,InputDisDaily)
title(problemSiteIDs[site])
plot(InputDisOnConcDate,InputDisOnConcDaily)
plot(InputConcDate,InputConcDaily)
plot(OutputConcDate,OutputConcDaily)

#Modeled vs Observed -----------------------------------------------------------

par(mfrow=c(1,1))
plot(InputConcDaily,OutputConcOnConcDaily,xlab = "Measured",ylab = "Modelled",main = "Modelled vs Observed (only on days with obs data)")
abline(lm(OutputConcOnConcDaily ~ InputConcDaily), col = "red")

#CDF of total discharge vs discharge on conc.data days -------------------------

p1 = ecdf(InputDisDaily)
plot(p1, xlab='Discharge', ylab='CDF', lwd = 3,main='CDF of Discharge (Total vs measured Days)',col="Green") 
p2 = ecdf(InputDisOnConcDaily)
plot(p2,col="red",add=TRUE) 

# Plot histograms/density plot of discharge  -----------------------------------

#multiPlotDataOverview(eList)#,logScaleConc = FALSE)

# par(mfrow=c(1,1))
# boxplot(InputDisDaily,InputDisOnConcDaily, 
#         main = "Discharge Sampled Days vs Total Discharge", 
#         ylab = "Discharge, m3 / s",
#         names = c("Total Days", "Sample Days"))
# 
# # #all discharge
# h<-hist(InputDisDaily, breaks=100,col="red", xlab="Total Discharge Data",main="Distribution of all Discharge")
# xfit = seq(min(InputDisDaily),max(InputDisDaily),length=50)
# yfit = dnorm(xfit,mean=mean(InputDisDaily),sd = sd(InputDisDaily))
# yfit = yfit*diff(h$mids[1:2])*length(InputDisDaily)
# lines(xfit,yfit,col="blue",lwd=2)
# 
# #discharge only on concentration days
# h<-hist(InputDisOnConcDaily, breaks=25,col="red", xlab="Total Discharge Data",main="Distribution of Dis on Concentration Days")
# xfit = seq(min(InputDisOnConcDaily),max(InputDisOnConcDaily),length=50)
# yfit = dnorm(xfit,mean=mean(InputDisOnConcDaily),sd = sd(InputDisOnConcDaily))
# yfit = yfit*diff(h$mids[1:2])*length(InputDisOnConcDaily)
# lines(xfit,yfit,col="blue",lwd=2)



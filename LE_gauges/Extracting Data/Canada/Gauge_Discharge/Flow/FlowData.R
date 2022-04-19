#the package manual
#https://cran.r-project.org/web/packages/fasstr/vignettes/fasstr_users_guide.html
#--------------------------------------------------------------------------

#1. This setion is for running indivudual station
#----------------gather data-----------------------
siteID <- "02GH011"
dailyflow<- tidyhydat::hy_daily_flows(station_number = siteID)

#write_xlsx(dailyflow,paste0(siteID,"dailyQ.xlsx"))

dailyflow<- fill_missing_dates(station_number = siteID)%>% 
  add_date_variables() %>% 
  add_basin_area()%>%
  add_daily_yield()
Area<-dailyflow$Basin_Area_sqkm[1]

#------------------flow visualizations and other----------------
#------------------comment when u do not need
plot_flow_data(station_number = siteID) #plot to see
screen_flow_data(station_number = siteID)  #review no. of flow value per year
plot_data_screening(station_number = siteID) # max min stats

#-----------Annual statistics for element
AnnualStat<- calc_annual_stats(station_number = siteID)
Annual_yield<- data.frame(((AnnualStat$Mean)*1000*31536000)/(Area*1000000))
Final<- cbind(AnnualStat$Year,AnnualStat$Mean,Annual_yield)
write_xlsx(Final,paste0(siteID,"_Results.xlsx"))

#plot_annual_stats(station_number = "02GE003") 

#-----------------------------------------------------------------------------------

#2. This setion is for running all te selected station
#-----------------------------------------------------

siteIDTab <- read_excel( "Qsites_Canada.xlsx")
siteID <-as.character(siteIDTab$`Site Number`)

for(i in 1: length(siteID)){
  dailyflow<- tidyhydat::hy_daily_flows(station_number = siteID[i])
  dailyflow<- fill_missing_dates(station_number = siteID[i])%>% 
    add_date_variables() %>% 
    add_basin_area()%>%
    add_daily_yield()
  Area<-dailyflow$Basin_Area_sqkm[1]
  AnnualStat<- calc_annual_stats(station_number = siteID[i])
  Annual_yield<- data.frame(((AnnualStat$Mean)*1000*31536000)/(Area*1000000))
  Final<- cbind(AnnualStat$Year,AnnualStat$Mean,Annual_yield)
  write_xlsx(Final,paste0(siteID[i],"_Results.xlsx"))
}
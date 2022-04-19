clear 
clc 
close all 

directory = 'Input_Meghan_July21/Canada Inputs/';
cropfile = [directory,'CROP.mat'];
countyAreaFile = [directory,'WSHD.mat'];
load(cropfile)
load(countyAreaFile)

clearvars -except crop_area wshd_admin_inputs

%get a vector of total crop/pasture area for each county for each year 

years = unique(crop_area.YEAR(2:end));
counties = table2array(crop_area(1,4:end));


%calculating percent crop/past

%for each year, fill in the county areas, should be the same each year
totalcountyArea=nan(length(years),length(counties));
for i=1:length(years) 
    totalcountyArea(i,:) = (wshd_admin_inputs.AREA_admin)';
    totalcountyArea(i,:) = totalcountyArea(i,:)*1e-4; %convert from m^2 to ha
end 

%set up crop and pasture areas for each year 
totalCrop = nan(length(years),length(counties));
totalPasture = nan(length(years),length(counties));


%getting areas 
for i = 1:length(years) 
    thisyear = years(i);
 
    thisYearPast = crop_area((crop_area.YEAR==thisyear & (crop_area.CROP_ID==2001 | crop_area.CROP_ID==2002)),:);
    thisYearCrop = crop_area((crop_area.YEAR==thisyear & (crop_area.CROP_ID~=2001 & crop_area.CROP_ID~=2002)),:); 
    
    for j=1:length(counties) 
        
        thiscounty_total_crop=nansum(table2array((thisYearCrop(:,j+3))));
        thiscounty_total_past=nansum(table2array((thisYearPast(:,j+3))));
        
        totalCrop(i,j) = thiscounty_total_crop;
        totalPasture(i,j) = thiscounty_total_past;
    end
end

percentCrop = totalCrop./totalcountyArea; percentCrop(isnan(percentCrop))=0;
percentPast = totalPasture./totalcountyArea; percentPast(isnan(percentPast))=0;


%plot percent crop for each county 
figure()
for i =1:length(counties) 
    thistitle = num2str(counties(i)); 
    subplot(4,5,i) 
    
    plot(years, percentCrop(:,i),'g:','Linewidth',2)
    title(thistitle) 
    legend('crop')
end 

%plot percent pasture for each county 
figure()
for i =1:length(counties) 
    thistitle = num2str(counties(i)); 
    subplot(4,5,i) 
    
    plot(years, percentPast(:,i),'r:','Linewidth',2)
    title(thistitle) 
    legend('past')
end 


%-----------------------------------------------------------------------

%plot percent pasture for all counties together (erie) 
TotalCropErie = sum(totalCrop');
TotalPastErie = sum(totalPasture');
TotalAreaErie = sum(totalcountyArea');

percentCropErie = TotalCropErie./TotalAreaErie; 
percentPastErie = TotalPastErie./TotalAreaErie; 

%plot against RF, HH, HYDE (for all erie) 

RF = readtable('output_RF_R_cancounties.csv');
HH = readtable('output_HH_R_cancounties.csv');
HYDE = readtable('output_HYDE_R_cancounties.csv');

idxRF = RF.YEAR>=1901 & RF.YEAR<=2016;
idxHH = HH.YEAR>=1901 & HH.YEAR<=2016;
idxHYDE= HYDE.YEAR>=1901 & HYDE.YEAR<=2016;

figure() 
subplot(1,2,1)

plot(years,percentCropErie','k:','Linewidth',2)
ylim([0 0.8])
xlim([1931 2016])
hold on 
plot(RF.YEAR(idxRF),RF.CROP(idxRF)/100,'Linewidth',2)
plot(HH.YEAR(idxHH),HH.CROP(idxHH)/100,'Linewidth',2)
plot(HYDE.YEAR(idxHYDE),HYDE.CROP(idxHYDE)/100,'Linewidth',2)
title('County Crop Erie (CANADA) ') 
legend('Census Erie Inputs','RF','HH','HYDE')
hold off

subplot(1,2,2) 

plot(years,percentPastErie','k:','Linewidth',2)
ylim([0 0.8])
xlim([1931 2016])
hold on 
plot(RF.YEAR(idxRF),RF.PAST(idxRF)/100,'Linewidth',2)
plot(HH.YEAR(idxHH),HH.PAST(idxHH)/100,'Linewidth',2)
plot(HYDE.YEAR(idxHYDE),HYDE.PAST(idxHYDE)/100,'Linewidth',2)
title('County Pasture Erie (CANADA)') 
legend('Census Erie Inputs','RF','HH','HYDE')
hold off




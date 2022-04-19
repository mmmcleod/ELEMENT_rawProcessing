clear 
clc 

directory = '';
cropfile = [directory,'CROP.mat'];
load(cropfile)

clearvars -except crop_area

%get a vector of total crop/pasture area for each county for each year 

years = unique(crop_area.YEAR(2:end));
counties = table2array(crop_area(1,4:end));


%calculating percent crop/past
totalCropPasture = nan(length(years),length(counties));
totalCrop = nan(length(years),length(counties));
totalPasture = nan(length(years),length(counties));

percentCrop = nan(length(years),length(counties));
percentPast = nan(length(years),length(counties));


%getting areas 
for i = 1:length(years) 
    thisyear = years(i);
    thisYearAreas = crop_area((crop_area.YEAR==thisyear),:);
    thisYearPast = crop_area((crop_area.YEAR==thisyear & crop_area.Crop==thisyear),:);

    for j=1:length(counties) 
        thiscounty_total_area=nansum(table2array((thisYearAreas(:,j+3))));
        
        totalCropPasture(i,j) = thiscounty_total_area;
    end
end







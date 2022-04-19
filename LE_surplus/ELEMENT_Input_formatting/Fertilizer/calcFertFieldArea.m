% this script removes legume crops from crop_area to get total area of
% fertilized fields per county per year (this will be used in fertilizer
% calculations) 
clc
clear

load 'INPUTS/CROP.mat'

%delete N fixing crops
crop_fert_area = crop_area; 
todelete = crop_fert_area.CROP_ID==1001|crop_fert_area.CROP_ID==1003|crop_fert_area.CROP_ID==1010|crop_fert_area.CROP_ID==1018; %alfalfa, soybeans, beans, allhay
crop_fert_area(todelete,:)=[];

C = varfun(@nansum,crop_fert_area([1:20,21:30],4));
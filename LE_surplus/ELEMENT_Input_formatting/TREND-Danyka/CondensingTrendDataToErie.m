 % This script is taking the csv's from the trend datasets and condensing
% and clipping them to only include LE counties while also combiining the
% surplus into element categories

clc 
clear

% these are the counties that are within the LE watershed boundry (either
% fully or partially) 
GeoIDs_Erie = [18001	36003	18003	39003	39005	39007	39011	26023	36009	36013	39033	42039	39035	39039	18033	36029	39043	42049	39051	39055	36037	39063	39065	39069	26059	26063	39077	26065	26075	39085	26087	26091	26093	39093	39095	26099	39101	39103	39107	26115	36063	18113	26125	39123	39125	39133	39137	39139	39143	26151	39147	39149	26147	39151	18151	39153	39155	39161	26161	26163	18179	39171	39173	39175	36121];

%convert into strings (to match column type) 
for i = 1:length(GeoIDs_Erie)
    this = num2str(GeoIDs_Erie(i)); 
    GeoIDs_Erie_strs{i} = ['x',this]; 
end

% get a list of counties to remove 
removeThese = {}; 
idx = 1; 
sampleTable = readtable('Atmospheric_Oxidized.csv','ReadVariableNames',true); 
allCounties = sampleTable.Properties.VariableNames(2:end);

for i = 1:length(allCounties)
    if ~ismember(allCounties{i},GeoIDs_Erie_strs)
        removeThese{idx} = allCounties{i};
        idx=idx+1;
    end
end

%%  Atmospheric N Deposition (+)
N_Atmospheric_Oxidized = readtable('Atmospheric_Oxidized.csv','ReadVariableNames',true); 
N_Atmospheric_Reduced = readtable('Atmospheric_Reduced.csv','ReadVariableNames',true);

% Now collect the shortened tables 
N_Atmospheric_Oxidized = removevars(N_Atmospheric_Oxidized,removeThese);
N_Atmospheric_Reduced = removevars(N_Atmospheric_Reduced,removeThese);

% combine 
total_N_DEP = table();
total_N_DEP.NaN = N_Atmospheric_Oxidized.NaN;
columns = N_Atmospheric_Oxidized.Properties.VariableNames(2:end);
for i = 1:length(columns)
    total_N_DEP.(columns{i}) = N_Atmospheric_Oxidized.(columns{i})+N_Atmospheric_Reduced.(columns{i});
end

%%  Manure N Inputs (+)
N_Lvst_SheepGoat= readtable('Lvst_SheepGoat.csv','ReadVariableNames',true); 
N_Lvst_Poultry = readtable('Lvst_Poultry.csv','ReadVariableNames',true);
N_Lvst_DairyCattle = readtable('Lvst_DairyCattle.csv','ReadVariableNames',true);
N_Lvst_OtherCattle= readtable('Lvst_OtherCattle.csv','ReadVariableNames',true);
N_Lvst_Hogs = readtable('Lvst_Hogs.csv','ReadVariableNames',true);
N_Lvst_Equine = readtable('Lvst_Equine.csv','ReadVariableNames',true);

% Now collect the shortened tables 
N_Lvst_SheepGoat = removevars(N_Lvst_SheepGoat,removeThese);
N_Lvst_Poultry = removevars(N_Lvst_Poultry,removeThese);
N_Lvst_DairyCattle = removevars(N_Lvst_DairyCattle,removeThese);
N_Lvst_OtherCattle = removevars(N_Lvst_OtherCattle,removeThese);
N_Lvst_Hogs = removevars(N_Lvst_Hogs,removeThese);
N_Lvst_Equine = removevars(N_Lvst_Equine,removeThese);

% combine 
total_N_MAN = table();
total_N_MAN.NaN = N_Lvst_SheepGoat.NaN;
columns = N_Lvst_SheepGoat.Properties.VariableNames(2:end);
for i = 1:length(columns)
    total_N_MAN.(columns{i}) = N_Lvst_SheepGoat.(columns{i})+N_Lvst_Poultry.(columns{i})+N_Lvst_DairyCattle.(columns{i})+N_Lvst_OtherCattle.(columns{i})+N_Lvst_Hogs.(columns{i})+N_Lvst_Equine.(columns{i});
end
%%  Biological N Fixation (+)
N_Fix_Pasture= readtable('Fix_Pasture.csv','ReadVariableNames',true); 
N_Fix_Cropland = readtable('Fix_Cropland.csv','ReadVariableNames',true);

N_Fix_Pasture= removevars(N_Fix_Pasture,removeThese);
N_Fix_Cropland = removevars(N_Fix_Cropland,removeThese);

% combine 
total_N_BNF = table();
total_N_BNF.NaN = N_Fix_Pasture.NaN;
columns = N_Fix_Pasture.Properties.VariableNames(2:end);
for i = 1:length(columns)
    total_N_BNF.(columns{i}) = N_Fix_Pasture.(columns{i})+N_Fix_Cropland.(columns{i});
end

%%  N Fertilizer (+)
N_Fertilizer_Domestic= readtable('Fertilizer_Domestic.csv','ReadVariableNames',true); 
N_Fertilizer_Agriculture = readtable('Fertilizer_Agriculture.csv','ReadVariableNames',true);

N_Fertilizer_Domestic= removevars(N_Fertilizer_Domestic,removeThese);
N_Fertilizer_Agriculture = removevars(N_Fertilizer_Agriculture,removeThese);

% combine 
total_N_FERT = table();
total_N_FERT.NaN = N_Fertilizer_Domestic.NaN;
columns = N_Fertilizer_Domestic.Properties.VariableNames(2:end);
for i = 1:length(columns)
    total_N_FERT.(columns{i}) = N_Fertilizer_Domestic.(columns{i})+N_Fertilizer_Agriculture.(columns{i});
end

%%  Crop N Uptake (-)
N_CropUptake_Pasture= readtable('CropUptake_Pasture.csv','ReadVariableNames',true); 
N_CropUptake_Cropland = readtable('CropUptake_Cropland.csv','ReadVariableNames',true);

N_CropUptake_Pasture= removevars(N_CropUptake_Pasture,removeThese);
N_CropUptake_Cropland = removevars(N_CropUptake_Cropland,removeThese);

% combine 
total_N_CROP = table();
total_N_CROP.NaN = N_CropUptake_Cropland.NaN;
columns = N_CropUptake_Cropland.Properties.VariableNames(2:end);
for i = 1:length(columns)
    total_N_CROP.(columns{i}) = N_CropUptake_Pasture.(columns{i})+N_CropUptake_Cropland.(columns{i});
end

%% Human N Waste Inputs (+)
N_Human= readtable('Human.csv','ReadVariableNames',true); 

N_Human= removevars(N_Human,removeThese);

%combine
total_N_HUMAN = N_Human;

%% County Area (Lake Erie Counties only) 
COUNTY_Area = readtable('County_Area.csv','ReadVariableNames',true); 

removingAreas=ismember(COUNTY_Area.GEOID,GeoIDs_Erie);
COUNTY_Area = COUNTY_Area(removingAreas,:);
total_COUNTY_Area = COUNTY_Area;


%%
%% Combine all 
total_N_surplus = table();
total_N_surplus.NaN = N_CropUptake_Cropland.NaN;
columns = N_CropUptake_Cropland.Properties.VariableNames(2:end);

for i = 1:length(columns)
    total_N_surplus.(columns{i}) = total_N_BNF.(columns{i})+total_N_CROP.(columns{i})+total_N_DEP.(columns{i})+total_N_FERT.(columns{i})+total_N_HUMAN.(columns{i})+total_N_MAN.(columns{i});
end


%% test plot for county 18001 


plot(total_N_BNF.(columns{1}))
title(columns{2})
hold on 
plot(total_N_CROP.(columns{1}))
plot(total_N_DEP.(columns{1}))
plot(total_N_FERT.(columns{1}))
plot(total_N_HUMAN.(columns{1}))
plot(total_N_MAN.(columns{1}))

plot(total_N_surplus.(columns{1}),'k','LineWidth',2)
legend('BNF','CROP','DEP','FERT','HUMAN','MAN','SURP')
hold off

figure() 
for i = 1:length(columns) 
    plot(1930:2017,total_N_surplus.(columns{i}),'LineWidth',2)
    hold on 
end
hold off


save ('RAW_summed_TREND_erie.mat','total_N_BNF','total_N_CROP','total_N_DEP','total_N_FERT','total_N_HUMAN','total_N_MAN')
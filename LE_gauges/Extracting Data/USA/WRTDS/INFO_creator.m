%SET UP ENVIRONMENT
%%
clc, clear, close all

PairingFolder = 'C:\Users\Meghan McLeod\Dropbox\BASULAB_meghan\Proposal\Lake Erie Data processing\LE_gauges\Gauge_pairing\USA\';
RawQFolder ='C:\Users\Meghan McLeod\Dropbox\BASULAB_meghan\Proposal\Lake Erie Data processing\LE_gauges\Extracting Data\USA\Gauge_discharge_WQ\ExtractedDischarge\';
RawCFolder ='C:\Users\Meghan McLeod\Dropbox\BASULAB_meghan\Proposal\Lake Erie Data processing\LE_gauges\Extracting Data\USA\Gauge_discharge_WQ\ExtractedWQ\';

%GET PAIR DATA
%%

%Download the pairs we are interested in

opts = detectImportOptions([PairingFolder,'USA_gauge_ELEMENT_N.csv']);
opts = setvartype(opts,{'UniqueSitesBetweenDanykaAndLamisa'}, 'string'); % tuen the water quality IDs into strings so that the numbers are not rounded
pairs = readtable([PairingFolder,'USA_gauge_ELEMENT_N.csv'],opts);

gauges_WQ=pairs.UniqueSitesBetweenDanykaAndLamisa;

% add 0's to the beginning of the id's 
for i=1:length(gauges_WQ) 
    gauges_WQ{i} = append('0',gauges_WQ{i}); 
end

names = gauges_WQ;


flowIDS = names;
areas = pairs.Var12;
fullNames = pairs.Var2;
shortNames = pairs.Var13;

% GETTING INFO FILES FOR EACH WATERSHED 
%%

%get header names for the INFO table 
headers = {'site_no','station_nm','shortName','drainSqKm','staAbbrev','param.nm','param.units','paramShortName','paramShortName2','constitAbbrev'};

% get values that we know 
paramNM={'Nitrate, milligrams per litre'};
paramUnits={'mg/L'};
paramShortName={'Nitrate'};
paramShortName2 = {'NNOTUR'};
constitAbbrev={''};


for i = [1:length(names)] 
    
thisSite = flowIDS(i);
thisName = fullNames(i); 
thisArea = areas(i); 
shortName = shortNames(i);
%add underscores for the staAbbr
strName = shortNames{i};
strName(strName==' ')='_';
thisStaAbbrev = {[flowIDS{i},'_',strName]};


thisInfoTable = table(thisSite, thisName, thisSite, thisArea, thisStaAbbrev, paramNM, paramUnits, paramShortName, paramShortName2, constitAbbrev,'VariableNames',headers);

writetable(thisInfoTable,['Input_cleaned/',names{i},'_INFO.csv'])
end
%SET UP ENVIRONMENT
%%
clc, clear, close all

PairingFolder = 'C:\Users\Meghan McLeod\Dropbox\BASULAB_meghan\Proposal\Lake Erie Data processing\LE_gauges\Gauge_pairing\CANADA\Meghan_lamisa_CAN pairs\';
RawQFolder ='C:\Users\Meghan McLeod\Dropbox\BASULAB_meghan\Proposal\Lake Erie Data processing\LE_gauges\Extracting Data\Canada\Gauge_Discharge\Flow\';
RawCFolder ='C:\Users\Meghan McLeod\Dropbox\BASULAB_meghan\Proposal\Lake Erie Data processing\LE_gauges\Extracting Data\Canada\Gauge_WQ\';

%GET PAIR DATA
%%

%Download the pairs we are interested in

opts = detectImportOptions([PairingFolder,'CanadianSET.csv']);
opts = setvartype(opts, 'ID', 'string'); % tuen the water quality IDs into strings so that the numbers are not rounded
pairs = readtable([PairingFolder,'CanadianSET.csv'],opts);

gauges_Q=pairs.QStationID; gauges_Q{21} = gauges_Q{20}; %for double
gauges_WQ=pairs.ID;

%add a 0 to gauges beginning with 4

for i=1:8
    gauges_WQ{i}=append('0',gauges_WQ{i});
end

% fix an odd gauge (with a space)
gauges_Q{9}='02GH003';

names = gauges_WQ;
flowIDS = pairs.QStationID;
areas = pairs.Area_km2_;
fullNames = pairs.Name;
shortNames = pairs.SHORTNAME;

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


for i = [1:24,26:length(names)] %omitting the grand @ york
    
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
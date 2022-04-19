clear all 
allCANstationData = readtable('extraction_results.xlsx');
stationNames = unique(allCANstationData.STATION);

for i=1:length(stationNames) 
    thisStation = stationNames{i}; 
    thisStationData = allCANstationData(ismember(allCANstationData.STATION,thisStation),:);
    tablename = ['WQ_',thisStation,'.csv']; 
    writetable(thisStationData,tablename);
end
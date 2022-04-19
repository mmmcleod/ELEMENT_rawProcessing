%% WQ and Q Gauge pairing

clear
clc

% This script will be used to roughly pair together discharge gauges 
% and WQ guages 

%Pull in discharge and WQ gauges in Lake Erie region 

Dis_table = readtable('CAN_gauges/DISCHARGE_25yrs_lakeErueBoundary/discharge_over_25_years.csv');
WQ_table = readtable('CAN_gauges/PWQMN1_15yrs_lakeErieBoundary/PWQMN1_15yrs_lakeErieBoundary.csv');

station_Dis = Dis_table.StationNumber;
lat_Dis = Dis_table.Latitude;
lon_Dis = Dis_table.Longitude;


station_WQ =WQ_table.STATION;
lat_WQ = WQ_table.LATITUDE;
lon_WQ = WQ_table.LONGITUDE;


Pairs = cell(50,2);
pair_idx = 1; 


for i = 1:length(lat_Dis)
    for k = 1:length(lat_WQ) 
        this_Dis = station_Dis{i};
        this_WQ = station_WQ(k);
        distance = sqrt((lat_Dis(i)-lat_WQ(k))^2+(lon_Dis(i)-lon_WQ(k))^2); 
        if distance<=0.035 & distance>=0.007
            Pairs{pair_idx,1} = this_Dis;
            Pairs{pair_idx,2} = this_WQ;
            pair_idx=pair_idx+1;
        end
    end
end



        
        
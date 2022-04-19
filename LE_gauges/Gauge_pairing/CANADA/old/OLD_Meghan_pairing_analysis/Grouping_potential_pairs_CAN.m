%% Grouping together gauges that are near each other

clc
clear

closedist1 = 0.007;
closedist2 = 0.02;

scenario = 2; %is one for the closest threshold and changes when allow points further
%% read in the data

% read in the discharge
discharge = shaperead('flow_25.shp');
nutrients = shaperead('pwqmn_10.shp');

num_Q_gauges = length(extractfield(discharge,'GaugeID'));
num_nutrient_gauges = length(extractfield(nutrients,'STATION'));
Q_gauges = extractfield(discharge,'GaugeID');
nutrient_gaugesnum = (extractfield(nutrients,'STATION'));

%side processing to turn nutrient gauge numbers into strs rather than nums
for i=1:length(nutrient_gaugesnum)
    nutrient_gauges{i} = num2str(nutrient_gaugesnum(i));
end


lats_Q = (extractfield(discharge,'LATDD'));
lons_Q = (extractfield(discharge,'LONDD'));
lats_nutrient = (extractfield(nutrients,'LATITUDE'));
lons_nutrient = (extractfield(nutrients,'LONGITUDE'));

%% FIRST - pair up watersheds right on top of each other (easy to pair)
%% NEXT - accept those further apart



% make a cell as long as there is Q stations and populate each cell with
% discharge stations which have a close neighbor

potentialPairs = cell(1,num_Q_gauges);

for i =1:num_Q_gauges
    potentialPairs{i}={};
    for j = 1:num_nutrient_gauges
        % fill in difference function
        % if the distance is small enough then (0.012 degrees distance)
        lat_Q = lats_Q(i);
        lon_Q = lons_Q(i);
        lat_nutrient = lats_nutrient(j);
        lon_nutrient = lons_nutrient(j);
        distanceBetween=sqrt((lat_nutrient-lat_Q)^2+(lon_nutrient-lon_Q)^2);
        %display(distanceBetween)
        
        if scenario == 1
            if distanceBetween<closedist1
                potentialPairs{i}{end+1}=nutrient_gauges{j};
            end
            
        elseif scenario == 2
            if distanceBetween>closedist1 & distanceBetween<closedist2
                potentialPairs{i}{end+1}=nutrient_gauges{j};
            end
        end
    end
    
end


% make a table where each column corrresponds to a discharge gauge
% populate table so that each discharge gauge has listed beneath paired PQWMN stations

stationPairsTable = table();

for i = 1:length(Q_gauges)
    this_Q = string(Q_gauges{i});
    this_lat = string(lats_Q(i));
    this_lon = string(lons_Q(i));
    if ~isempty(potentialPairs{i})
        %stationPairsTable.(this_Q)=potentialPairs{i};
        stationPairsTable.(this_Q)={potentialPairs{i};this_lat;this_lon};
    end
end

%%

if scenario == 1
    writetable(stationPairsTable,'stationPairsTable1.xlsx')
elseif scenario == 2
    writetable(stationPairsTable,'stationPairsTable2.xlsx')
end




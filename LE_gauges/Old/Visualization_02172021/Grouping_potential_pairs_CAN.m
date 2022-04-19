%% Grouping together gauges that are near each other

clc
clear

%% read in the data

% read in the discharge
discharge = shaperead('CAN_Q_25yrs.shp');
nutrients = shaperead('CAN_Nutrient_15yrs.shp');

num_Q_gauges = length(extractfield(discharge,'StationNu'));
num_nutrient_gauges = length(extractfield(nutrients,'STATION'));
Q_gauges = extractfield(discharge,'StationNu');
nutrient_gaugesnum = (extractfield(nutrients,'STATION'));

%side processing to turn nutrient gauge numbers into strs rather than nums
for i=1:length(nutrient_gaugesnum)
    nutrient_gauges{i} = num2str(nutrient_gaugesnum(i));
end


lats_Q = (extractfield(discharge,'Latitude'));
lons_Q = (extractfield(discharge,'Longitude'));
lats_nutrient = (extractfield(nutrients,'LATITUDE'));
lons_nutrient = (extractfield(nutrients,'LONGITUDE'));

%% pair up watersheds based on distance (only for now)

% make a cell as long as there is Q stations and populate each cell with
% another cell containing potential pairs

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
        
        if distanceBetween<0.009
            potentialPairs{i}{end+1}=nutrient_gauges{j};
        end
        
    end
end

%% make a table where each column corrresponds to a discharge gauge
%% populate table so that each discharge gauge has listed beneath paired PQWMN stations

stationPairsTable = table();

for i = 1:length(Q_gauges)
    this_Q = string(Q_gauges{i});
    if ~isempty(potentialPairs{i})
        stationPairsTable.(this_Q)=potentialPairs{i};
    end
end

%% Now we can look for a list of stations which are too far away from others (more than 0.22 degrees)

% start with the q stations

idx=1;
for i = 1:num_Q_gauges
    numNeighbors = 0;
    for j = 1:num_nutrient_gauges
        lat_Q = lats_Q(i);
        lon_Q = lons_Q(i);
        lat_nutrient = lats_nutrient(j);
        lon_nutrient = lons_nutrient(j);
        distanceBetween=sqrt((lat_nutrient-lat_Q)^2+(lon_nutrient-lon_Q)^2);
        if distanceBetween<0.2
            numNeighbors=numNeighbors+1;
        end
    end
    display(numNeighbors)
    if numNeighbors==0
        q_loners{idx} = Q_gauges{i};
        idx=idx+1;
    end
end


idx=1;
for j = 1:num_nutrient_gauges
    numNeighbors = 0;
    for i = 1:num_Q_gauges
        lat_Q = lats_Q(i);
        lon_Q = lons_Q(i);
        lat_nutrient = lats_nutrient(j);
        lon_nutrient = lons_nutrient(j);
        distanceBetween=sqrt((lat_nutrient-lat_Q)^2+(lon_nutrient-lon_Q)^2);
        if distanceBetween<0.2
            numNeighbors=numNeighbors+1;
        end
    end
    display(numNeighbors)
    if numNeighbors==0
        nutrient_loners{idx} = nutrient_gauges{j};
        idx=idx+1;
    end
end













writetable(stationPairsTable,'stationPairsTable.xlsx')





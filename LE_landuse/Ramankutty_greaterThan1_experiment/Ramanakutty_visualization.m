% Visualizing LU data 

crop_can_raw = readtable('ramankutty_Eriecountiescrop_CAN.csv');
crop_usa_raw = readtable('ramankutty_Eriecountiescrop_USA.csv');
past_can_raw = readtable('ramankutty_Eriecountiespast_CAN.csv');
past_usa_raw = readtable('ramankutty_Eriecountiespast_USA.csv');

figure(1) 
title('Ramankutty Crop Trajectory, all LE counties') 
hold on 
plot(table2array(crop_usa_raw(2:end,2)),table2array(crop_usa_raw(2:end,3:end)),'b','Linewidth',2)
plot(table2array(crop_can_raw(2:end,2)),table2array(crop_can_raw(2:end,3:end)),'r','Linewidth',2)
hold off


figure(2) 
title('Ramankutty Pasture Trajectory, all LE counties') 
hold on 
plot(table2array(past_usa_raw(2:end,2)),table2array(past_usa_raw(2:end,3:end)),'b','Linewidth',2)
plot(table2array(past_can_raw(2:end,2)),table2array(past_can_raw(2:end,3:end)),'r','Linewidth',2)
hold off

figure(3) 
title('Ramankutty Pasture AND Crop Trajectory, all LE counties') 
hold on 
plot(table2array(past_usa_raw(2:end,2)),table2array(past_usa_raw(2:end,3:end))+table2array(crop_usa_raw(2:end,3:end)),'b','Linewidth',2)
plot(table2array(past_can_raw(2:end,2)),table2array(past_can_raw(2:end,3:end))+table2array(crop_can_raw(2:end,3:end)),'r','Linewidth',2)
hold off


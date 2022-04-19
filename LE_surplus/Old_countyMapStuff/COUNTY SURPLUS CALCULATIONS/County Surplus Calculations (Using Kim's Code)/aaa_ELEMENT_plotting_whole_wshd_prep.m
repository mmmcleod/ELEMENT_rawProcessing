%%Plotting the USA side and the CAN side with surplus 
clc
clear

%bring in the canadian county shapefiles 
ShapeFolder='C:\Users\Meghan McLeod\Dropbox\BASULAB_meghan\Proposal\Lake Erie Data processing\Shapefile\';
TRENDFolder = 'C:\Users\Meghan McLeod\Dropbox\BASULAB_meghan\Proposal\Lake Erie Data processing\LE_surplus\ELEMENT_Input_formatting\TREND-Danyka\';

filename='LE_CA.shp';
S_ON=shaperead([ShapeFolder,filename], 'UseGeoCoords', true);

filename='LE_USA.shp';
S_USA=shaperead([ShapeFolder,filename], 'UseGeoCoords', true);

%Obtain required files 

run([TRENDFolder,'CondensingTrendDataToErie.m']);
clearvars -except total_COUNTY_Area total_N_BNF total_N_CROP total_N_DEP total_N_FERT total_N_HUMAN total_N_MAN total_N_surplus

load('OUTPUTS/LE_COUNTY_PROCESSING.mat')

load('INPUTS/WSHD.mat')


%population

subplot(2,3,1)
admin_pop_kg_ha=admin_pop_kg./wshd_admin_inputs.AREA_admin'; admin_pop_kg_ha=admin_pop_kg_ha*10000; %(m^2 to ha) 
%usa
plot(1930:2016,total_N_HUMAN{1:87,2:end},'b','Linewidth',2)
hold on 
%ontario (normalized by area) 
plot(1930:2016,admin_pop_kg_ha,'r','Linewidth',2)
ylim([0 30])
title ({'HUMAN N','(per hectare)'})
hold off

%crop 


subplot(2,3,2)


admin_crop_kg_ha=admin_crop_kg./wshd_admin_inputs.AREA_admin'; admin_crop_kg_ha=admin_crop_kg_ha*10000;%(m^2 to ha) 
%usa
plot(1930:2016,total_N_CROP{1:87,2:end},'b','Linewidth',2)
hold on 
%ontario (normalized by area) 
plot(1930:2016,admin_crop_kg_ha,'r','Linewidth',2)
title ({'CROP N','(per hectare)'})
hold off

%manure 

subplot(2,3,3)

admin_man_kg_ha=admin_crop_kg./wshd_admin_inputs.AREA_admin'; admin_man_kg_ha=admin_man_kg_ha*10000;%(m^2 to ha) 
%usa
plot(1930:2016,total_N_MAN{1:87,2:end},'b','Linewidth',2)
hold on 
%ontario (normalized by area) 
plot(1930:2016,admin_man_kg_ha,'r','Linewidth',2)
title ({'MANURE N','(per hectare)'})
hold off

%deposition (don't have to area normalize) 

subplot(2,3,4)

admin_dep_kg_ha=admin_dep_kg;%./wshd_admin_inputs.AREA_admin'; admin_dep_kg_ha=admin_dep_kg_ha*10000;%(m^2 to ha) 
admin_dep_USA_kg_ha = admin_dep_USA_kg;%./total_COUNTY_Area.AREA_HA';

%usa
plot(1930:2016,admin_dep_USA_kg_ha,'b','Linewidth',2)
hold on 
%ontario (normalized by area) 
plot(1930:2016,admin_dep_kg_ha,'r','Linewidth',2)
title ({'DEPOSITION N', '(per hectare)'})
hold off

%bnf 

subplot(2,3,5)
%usa
admin_bnf_kg_ha=admin_bnf_kg./wshd_admin_inputs.AREA_admin'; admin_bnf_kg_ha=admin_bnf_kg_ha*10000;%(m^2 to ha) 
%usa
plot(1930:2016,total_N_BNF{1:87,2:end},'b','Linewidth',2)
hold on 
%ontario (normalized by area) 
plot(1930:2016,admin_bnf_kg_ha,'r','Linewidth',2)
title ({'BNF','(per hectare)'})
hold off

%fert

subplot(2,3,6)
%usa
admin_fert_kg_ha=admin_fert_kg./wshd_admin_inputs.AREA_admin'; admin_fert_kg_ha=admin_fert_kg_ha*10000;%(m^2 to ha) 
%usa
plot(1930+18:2016,total_N_FERT{1+18:87,2:end},'b','Linewidth',2)
hold on 
%ontario (normalized by area) 
plot(1930+18:2016,admin_fert_kg_ha(1+18:end,:),'r','Linewidth',2)
title ({'FERT','(per hectare)'})
hold off


%Write all of these county surplus tables to excel ---------------

%get a table header made
ON_variable_names = cell(1,18); 
ON_variable_names{1}='Year';
for i=2:18
ON_variable_names{i}=num2str(wshd_admin_inputs.ID(i-1));
end

USA_variablenames=cell(1,66);
USA_variable_names{1}='Year';
for i=2:66
USA_variable_names{i}=num2str(total_COUNTY_Area.GEOID(i-1));
end


%ONTARIO COUNTIES 

 filename = 'ERIE_ON_countySurp.xls';

%bnf
T = array2table([(1930:2016)' admin_bnf_kg_ha]);
T.Properties.VariableNames(1:18) = ON_variable_names;
writetable(T,filename,'Sheet','bnf')
%crop
T = array2table([(1930:2016)' admin_crop_kg_ha]);
T.Properties.VariableNames(1:18) = ON_variable_names;
writetable(T,filename,'Sheet','crop')
%dep
T = array2table([(1930:2016)' admin_dep_kg_ha]);
T.Properties.VariableNames(1:18) = ON_variable_names;
writetable(T,filename,'Sheet','dep')
%fert
T = array2table([(1930:2016)' admin_fert_kg_ha]);
T.Properties.VariableNames(1:18) = ON_variable_names;
writetable(T,filename,'Sheet','fert')
%man
T = array2table([(1930:2016)' admin_man_kg_ha]);
T.Properties.VariableNames(1:18) = ON_variable_names;
writetable(T,filename,'Sheet','man')
%pop
T = array2table([(1930:2016)' admin_pop_kg_ha]);
T.Properties.VariableNames(1:18) = ON_variable_names;
writetable(T,filename,'Sheet','pop')

%AMERICAN COUNTIES 

filename = 'ERIE_USA_countySurp.xls';

%bnf
T = total_N_BNF;
T.Properties.VariableNames(1:66) = USA_variable_names;
writetable(T,filename,'Sheet','bnf')
%crop
T = total_N_CROP;
T.Properties.VariableNames(1:66) = USA_variable_names;
writetable(T,filename,'Sheet','crop')
%dep
T = array2table([(1930:2016)' admin_dep_USA_kg_ha]);
T.Properties.VariableNames(1:66) = USA_variable_names;
writetable(T,filename,'Sheet','dep')
%fert
T = total_N_FERT;
T.Properties.VariableNames(1:66) = USA_variable_names;
writetable(T,filename,'Sheet','fert')
%man
T = total_N_MAN;
T.Properties.VariableNames(1:66) = USA_variable_names;
writetable(T,filename,'Sheet','man')
%pop
T = total_N_MAN;
T.Properties.VariableNames(1:66) = USA_variable_names;
writetable(T,filename,'Sheet','pop')




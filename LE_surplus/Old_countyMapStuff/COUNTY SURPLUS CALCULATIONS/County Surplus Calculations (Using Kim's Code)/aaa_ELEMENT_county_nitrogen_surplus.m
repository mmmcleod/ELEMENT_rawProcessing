clc
clear
close all

%%

% SET UP PRELIMINARY INFO ---------------------------------------------

InputDir = 'C:\Users\Meghan McLeod\Dropbox\BASULAB_meghan\Proposal\Lake Erie Data processing\LE_surplus\ELEMENT_Input_formatting\Collecting CAN Input data\INPUTS (N_ERIE)\'
START=1930; %starting year for simulations
FINISH=2016;   %ending year for simulations
RES=100;  %resolution for landscape time series (larger values provide greater resolution, e.g. 100, 1000)
DEP_1860=3;  %kg/ha (get deposition estimates from Dentener

YEAR=(START:1:FINISH)';

load([InputDir,'WSHD.mat'])
T=wshd_admin_inputs;
admin_ID=T{:,1};

AREA=sum(T{:,3})/10^6; %basin area in km2 (converted from m2)  

%get USA IDs
load([InputDir,'DEP_USA.mat'])
admin_ID_USA=sort(total_deposition_USA{:,1});
input_ID_USA=admin_ID_USA;

%------------------------------------------------------------------------------------------
% START SURPLUS 
%------------------------------------------------------------------------------------------

%% Population (5kg per person) ******

[admin_pop_kg,input_ID]=county_element_pop(YEAR,admin_ID);
%save population admin code (counties only) 
save ('OUTPUTS/LE_COUNTY_PROCESSING.mat','admin_pop_kg','input_ID','-append');

% Calculate net inputs for cropland ---------

%% Fertilizer ******

[admin_fert_kg]=county_element_fert(YEAR,admin_ID,input_ID);

save ('OUTPUTS/LE_COUNTY_PROCESSING.mat','admin_fert_kg','-append');
%% Crop Production ******
%run crop admin code (counties only) 
[admin_prod,admin_crop_kg, admin_crop_area,CROP_ID]=county_element_crop_prod(YEAR,admin_ID,input_ID);
%save crop admin code (counties only) 
save ('OUTPUTS/LE_COUNTY_PROCESSING.mat','admin_crop_kg', 'admin_crop_area','-append')


%% Biological Nitrogen Fixation ******

%run bnf admin code (counties only)
[admin_bnf_kg]=county_element_bnf(YEAR,admin_ID,admin_prod,CROP_ID);
%save bnf admin code (counties only) 
save ('OUTPUTS/LE_COUNTY_PROCESSING.mat','admin_bnf_kg','-append')

%% Atmospheric N Deposition
%run deposition admin code (counties only) 
[admin_dep_kg]=county_element_dep(YEAR,admin_ID,input_ID,START);
%save deposition admin code (counties only) 
[admin_dep_USA_kg]=county_element_dep_USA(YEAR,admin_ID_USA,input_ID_USA,START);
save ('OUTPUTS/LE_COUNTY_PROCESSING.mat','admin_dep_kg','admin_dep_USA_kg','-append')

%% Livestock Manure

[admin_man_kg,admin_consumption_kg]=county_element_manure(YEAR,admin_ID,input_ID);
save ('OUTPUTS/LE_COUNTY_PROCESSING.mat','admin_man_kg','admin_consumption_kg','-append')

clear 
load 'OUTPUTS/LE_COUNTY_PROCESSING.mat'

%% Bringing it all together 

% Cropland N Surplus Calculations

% % % % [a_c]=county_element_crop_net_inputs(0,0,0,fert_ha_cropland,dep_ha_cropland,man_ha_crop,bnf_ha_cropland,crop_ha_cropland,YEAR);
% % % % 
% % % % save (['OUTPUTS/',NAME,'_PROCESSING.mat'],'a_c','-append')
% % % % 
% % % % % Pastureland N Surplus Calculations
% % % % 
% % % % [a_p]=county_element_past_net_inputs(0,0,0,dep_ha_pastland,man_ha_past,fert_ha_pastland,bnf_ha_pastland,consumption_ha_past,YEAR,bnf_n);
% % % % 
% % % % save (['OUTPUTS/',NAME,'_PROCESSING.mat'],'a_p','-append')
% % % % 
% % % % % Other Land, N Surplus Calculations
% % % % 
% % % % a_n=dep_ha_non_ag+bnf_ha_non_ag;
% % % % 
% % % % save (['OUTPUTS/',NAME,'_PROCESSING.mat'],'a_n','-append')
% % % % 
% % % % % watershed N surplus calculations
% % % % 
% % % % [a_wshd]=county_element_wshd_net_inputs(YEAR,AREA,LU_summary,a_c,a_n,a_p);
% % % % 
% % % % save (['OUTPUTS/',NAME,'_PROCESSING.mat'],'a_wshd','-append')



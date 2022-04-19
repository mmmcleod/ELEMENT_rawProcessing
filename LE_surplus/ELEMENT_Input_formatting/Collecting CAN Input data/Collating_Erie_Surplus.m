%% This script formats inputs to be used by surplus code (in ELEMeNT)

clc
clear

%% Collating N surplus using county-level census data and Danyka's N conversion values \

%(Ensuring they are in proper element format and THEN using elements surplus code to get surplus values)

%% *******************************************************************************************************
%% CANADIAN COUUNTY SUMMARY
%% *******************************************************************************************************

% the Canadian side of the Lake Erie watershed should have 17 counties -
% each has a distinct ID which should stay consistent thoughout all INPUT
% files. They counties are summarized below (NOTE haldimand & norfolk are
% considered different counties for the whole simulation period):

% %  22000,'DUFFERIN';
% %  23000,'WELLINGTON';
% %  24000,'HALTON';
% %  25000,'HAMILTON';
% %  28005,'HALDIMAND';
% %  28030,'NORFOLK';
% %  29000,'BRANT';
% %  30000,'WATERLOO';
% %  31000,'PERTH';
% %  32000,'OXFORD';
% %  34000,'ELGIN';
% %  36000,'CHATHAM-KENT';
% %  37000,'ESSEX';
% %  38000,'LAMBTON';
% %  39000,'MIDDLESEX';
% %  40000,'HURON';
% %  42000,'GREY';


%File Locations 
Finalized_folder = 'C:\Users\Meghan McLeod\Dropbox\BASULAB_meghan\Proposal\Lake Erie Data processing\LE_surplus\ELEMENT_Input_formatting\Collecting CAN Input data\INPUTS (N_ERIE)\';
Lamisa_Census_Inputs = 'C:\Users\Meghan McLeod\Dropbox\BASULAB_meghan\Proposal\Lake Erie Data processing\LE_surplus\ELEMENT_Input_formatting\CensusData_from_Lamisa\Input_Meghan_July21\Canada INPUTS\';

Trend_Vals_and_Conversion_old = 'C:\Users\Meghan McLeod\Dropbox\BASULAB_meghan\Proposal\Lake Erie Data processing\LE_surplus\ELEMENT_Input_formatting\TREND-Danyka\N_Conversion_Vals.xlsx';
%Updated in 2022 with new manure values 
Trend_Vals_and_Conversion = 'C:\Users\Meghan McLeod\Dropbox\BASULAB_meghan\Proposal\Lake Erie Data processing\LE_surplus\ELEMENT_Input_formatting\TREND-Danyka\N_Conversion_Vals_021922.xlsx';

Fert_Folder = 'C:\Users\Meghan McLeod\Dropbox\BASULAB_meghan\Proposal\Lake Erie Data processing\LE_surplus\ELEMENT_Input_formatting\Fertilizer\';
Dep_Folder = 'C:\Users\Meghan McLeod\Dropbox\BASULAB_meghan\Proposal\Lake Erie Data processing\LE_surplus\ELEMENT_Input_formatting\Deposition\Global Gridded\RESULTS_ON\';

%% *******************************************************************************************************
%% WSHD input
%% *******************************************************************************************************
disp ('CREATING WSHD.mat') 
% these are from lamisa - make sure the correct number of counties are
% there. Lamisa has confirmed that all counties areas should be corrected
% if the original shapefiles extended past the water boundary

% SOURCE::::: Ontario Municipal Boundary

load([Lamisa_Census_Inputs,'WSHD.mat']);

% save this in the canada inputs for N-ERIE
save([Finalized_folder,'WSHD.mat'],'wshd_admin_inputs')

clearvars -except 'Run_surplus' 'wshd_admin_inputs' 'Lamisa_Census_Inputs' 'Finalized_folder' 'Trend_Vals_and_Conversion' 'Fert_Folder' 'Dep_Folder'

%% *******************************************************************************************************
%% POP input
%% *******************************************************************************************************
disp ('CREATING POP.mat') 
% these are from lamisa - should be the same regardless of N or P

% SOURCE::::: Canadian Census of population

load([Lamisa_Census_Inputs,'POP.mat']);

% save this in the canada inputs for N-ERIE

pop_param = 5; % this changes between N and P

%fix an ID (25005 to 25000)
pop_inputs.Properties.VariableNames{5} = 'x25000';

save([Finalized_folder,'POP.mat'],'pop_inputs','pop_hist_inputs','pop_param')

clearvars -except 'Run_surplus' 'wshd_admin_inputs' 'pop_inputs' 'pop_hist_inputs' 'pop_param' 'Lamisa_Census_Inputs' 'Finalized_folder' 'Trend_Vals_and_Conversion' 'Fert_Folder' 'Dep_Folder'

%% *******************************************************************************************************
%% LVSTK input
%% *******************************************************************************************************
disp ('CREATING LVSTK.mat') 
% the livestock headcounts are from lamisa - now including broilers and
% goats

% SOURCE::::: Canadian Census of Agriculture

load([Lamisa_Census_Inputs,'LVSTK.mat']);

% the lvstk_inputs can be left unchanged (just headcount)

% Update - combine the pre-40 data with the post (now just one category) 

%remove interpolated 1939 year 
lvstk_inputs(lvstk_inputs.YEAR==1939,:)=[];

%beefcows 
idxPost = lvstk_inputs.ID==101&lvstk_inputs.YEAR<=1940; 
idxPre = lvstk_inputs.ID==1101&lvstk_inputs.YEAR<=1940; 
lvstk_inputs{idxPost,4:20}=lvstk_inputs{idxPre,4:20};
lvstk_inputs(idxPre,:)=[];

%dairycows 
idxPost = lvstk_inputs.ID==102&lvstk_inputs.YEAR<=1940; 
idxPre = lvstk_inputs.ID==1102&lvstk_inputs.YEAR<=1940; 
lvstk_inputs{idxPost,4:20}=lvstk_inputs{idxPre,4:20};
lvstk_inputs(idxPre,:)=[];

%othercows 
idxPost = lvstk_inputs.ID==110&lvstk_inputs.YEAR<=1940; 
idxPre = lvstk_inputs.ID==1110&lvstk_inputs.YEAR<=1940; 
lvstk_inputs{idxPost,4:20}=lvstk_inputs{idxPre,4:20};
lvstk_inputs(idxPre,:)=[];

% the lvstk_params need to be updated to match Danyka's N-values

livestock_N_params_raw = readtable(Trend_Vals_and_Conversion,'Sheet','Animal_Excretion','VariableNamingRule','preserve');
% Dayka and Lamisa use different ID's so this rematches them

livestock_N_params_raw.Code(1) = 101; %beef cows
livestock_N_params_raw.Code(2) = 102; %dairy cows
livestock_N_params_raw.Code(3) = 110; %other cows
livestock_N_params_raw.Code(9) = 402; %broilers 
livestock_N_params_raw.Code(10) = 401; %other chicken 
livestock_N_params_raw.Code(4) = 700; %goats
livestock_N_params_raw.Code(5) = 200; %pigs
livestock_N_params_raw.Code(8) = 600; %horses
livestock_N_params_raw.Code(6) = 300; %sheep 
livestock_N_params_raw.Code(7) = 500; %turkeys 

% create a new lvstk_param variable with danyka's values

lvstk_params=table();
lvstk_params.CATEGORY = (livestock_N_params_raw.Type);
lvstk_params.ID= (livestock_N_params_raw.Code);

%sort
lvstk_params = sortrows(lvstk_params,'ID','ascend');

% add in consumption

lvstk_params.CONSUMPTION = zeros(size(lvstk_params.ID));

for i = 1:10
    thisID = lvstk_params.ID(i);
    thisIDconsumption=livestock_N_params_raw.("Animal N Intake (kg-N/animal/yr)")(find(livestock_N_params_raw.Code==thisID));
    lvstk_params.CONSUMPTION(find(lvstk_params.ID==thisID))=thisIDconsumption;
end

% add in excretion

lvstk_params.EXCRETION= zeros(size(lvstk_params.ID));

for i = 1:10
    thisID = lvstk_params.ID(i);
    thisIDexcretion=livestock_N_params_raw.("N in Animal Excretion (kg-N/animal/yr)")(find(livestock_N_params_raw.Code==thisID));
    lvstk_params.EXCRETION(find(lvstk_params.ID==thisID))=thisIDexcretion;
end

% Make a PASTURE matrix - this matrix accounts for livestock in either unconfined or confined fractions based on Kellogg et al. (2000) and Smil (1999)
% using joy's values 
ManurePastureMatrix=zeros(length(lvstk_params.ID),2); 
ManurePastureMatrix(1,:) = [.75,.65];
ManurePastureMatrix(2,:) = [.9,.4];
ManurePastureMatrix(3,:) = [.75,.65]; 
ManurePastureMatrix(4,:) = [0,0]; %pigs from joy 
ManurePastureMatrix(5,:) = [0.9,0.9]; %sheep from joy 
ManurePastureMatrix(6,:) = [0,0]; %all other chicken from joy's average chicken 
ManurePastureMatrix(7,:) = [0,0]; %broilers from joy's average chicken 
ManurePastureMatrix(8,:) = [0,0]; %turkeys from joy
ManurePastureMatrix(9,:) = [.5,.5]; %horses from joy 
ManurePastureMatrix(10,:) = [0.9,0.9]; %goats from joy's sheep (since in Kellog paper sheep/goats seem grouped) 
% add in PASTURE (use same assumption as joy) 
lvstk_params.PASTURE = ManurePastureMatrix;

% add in valatilization (use same assumption as joy) 
lvstk_params.VOL= ones(size(lvstk_params.ID));
lvstk_params.VOL=lvstk_params.VOL*0.36;

% Now adding in livestock weights -------------------------------

livestock_N_weights_raw = readtable(Trend_Vals_and_Conversion,'Sheet','Animal_WeightConversion','VariableNamingRule','preserve');
%rename with element labels 
livestock_N_weights_raw{1,2}  = 101; %beef cows
livestock_N_weights_raw{1,3}  = 102; %dairy cows
livestock_N_weights_raw{1,4}  = 110; %other cows
livestock_N_weights_raw{1,7}  = 402; %broilers 
livestock_N_weights_raw{1,8}  = 401; %other chicken 
livestock_N_weights_raw{1,10} = 700; %goats
livestock_N_weights_raw{1,5}  = 200; %pigs
livestock_N_weights_raw{1,11} = 600; %horses
livestock_N_weights_raw{1,6}  = 300; %sheep 
livestock_N_weights_raw{1,9}  = 500; %turkeys 

%interpolate weights between years 

modelledYears = 1901:2017; 
totalYears = 1930:2017; 
publishedYears = livestock_N_weights_raw.Year(2:end); 

lvstk_weights = array2table(zeros(length(modelledYears)+1,length(livestock_N_weights_raw{1,:}))); 
lvstk_weights.Properties.VariableNames = livestock_N_weights_raw.Properties.VariableNames;

%fill in colums with raw table data and interpolate (plus extend back
%starting values to 1901 

lvstk_weights.Year = [livestock_N_weights_raw{1,1};modelledYears']; 
lvstk_weights.("Cattle, beef") = [livestock_N_weights_raw{1,2};livestock_N_weights_raw{end,2}*ones(29,1);interp1(publishedYears,livestock_N_weights_raw{2:end,2},totalYears)']; 
lvstk_weights.("Cattle, milk") = [livestock_N_weights_raw{1,3};livestock_N_weights_raw{end,3}*ones(29,1);interp1(publishedYears,livestock_N_weights_raw{2:end,3},totalYears)']; 
lvstk_weights.("Cattle, other") = [livestock_N_weights_raw{1,4};livestock_N_weights_raw{end,4}*ones(29,1);interp1(publishedYears,livestock_N_weights_raw{2:end,4},totalYears)']; 
lvstk_weights.("Hog") = [livestock_N_weights_raw{1,5};livestock_N_weights_raw{end,5}*ones(29,1);interp1(publishedYears,livestock_N_weights_raw{2:end,5},totalYears)']; 
lvstk_weights.("Sheep") = [livestock_N_weights_raw{1,6};livestock_N_weights_raw{end,6}*ones(29,1);interp1(publishedYears,livestock_N_weights_raw{2:end,6},totalYears)']; 
lvstk_weights.("Broiler") = [livestock_N_weights_raw{1,7};livestock_N_weights_raw{end,7}*ones(29,1);interp1(publishedYears,livestock_N_weights_raw{2:end,7},totalYears)']; 
lvstk_weights.("Chicken") = [livestock_N_weights_raw{1,8};livestock_N_weights_raw{end,8}*ones(29,1);interp1(publishedYears,livestock_N_weights_raw{2:end,8},totalYears)']; 
lvstk_weights.("Turkey") = [livestock_N_weights_raw{1,9};livestock_N_weights_raw{end,9}*ones(29,1);interp1(publishedYears,livestock_N_weights_raw{2:end,9},totalYears)']; 
lvstk_weights.("Goat") = [livestock_N_weights_raw{1,10};livestock_N_weights_raw{end,10}*ones(29,1);interp1(publishedYears,livestock_N_weights_raw{2:end,10},totalYears)']; 
lvstk_weights.("Horses") = [livestock_N_weights_raw{1,11};livestock_N_weights_raw{end,11}*ones(29,1);interp1(publishedYears,livestock_N_weights_raw{2:end,11},totalYears)']; 

%switch chicken and broiler columns (so they are in ascending order) 
lvstk_weights = movevars(lvstk_weights,7,'After',8);
lvstk_weights = movevars(lvstk_weights,10,'After',11);

save([Finalized_folder,'LVSTK.mat'],'lvstk_weights','lvstk_params','lvstk_inputs','lvstk_manure_landuse_params')

clearvars -except 'Run_surplus' 'wshd_admin_inputs' 'pop_inputs' 'pop_hist_inputs' 'pop_param' 'lvstk_weights' 'lvstk_params' 'lvstk_inputs' 'lvstk_manure_landuse_params' 'Lamisa_Census_Inputs' 'Finalized_folder' 'Trend_Vals_and_Conversion' 'Fert_Folder' 'Dep_Folder'

%% *******************************************************************************************************
%% Fertilizer
%% *******************************************************************************************************
disp ('CREATING FERT.mat')

fertilizer_N_params_raw = readtable([Fert_Folder,'FertilizerCalculations.xlsx'],'Sheet','ForMatlab', 'ReadVariableNames', true);
fert_inputs=fertilizer_N_params_raw;

save([Finalized_folder,'FERT.mat'],'fert_inputs')
clearvars -except 'Run_surplus' 'wshd_admin_inputs' 'pop_inputs' 'pop_hist_inputs' 'pop_param' 'lvstk_weights' 'lvstk_params' 'lvstk_inputs' 'lvstk_manure_landuse_params' 'fert_inputs' 'Lamisa_Census_Inputs' 'Finalized_folder' 'Trend_Vals_and_Conversion' 'Fert_Folder' 'Dep_Folder'




%% *******************************************************************************************************
%% Deposition
%% *******************************************************************************************************
disp ('CREATING DEP.mat') 
% this was done separately (in the Deposition folder) by processing a
% global gridded dataset and aggregating at the county scale

% SOURCE::::: Check in with Kim

oxidized_deposition = readtable([Dep_Folder,'GLOBAL_deposition_nox.txt'],'VariableNamingRule','preserve');
reduced_deposition = readtable([Dep_Folder,'GLOBAL_deposition_nhx.txt'],'VariableNamingRule','preserve');

% need to rename county IDs to match those used above
reduced_deposition.BASIN(reduced_deposition.BASIN==3529)=29000;
reduced_deposition.BASIN(reduced_deposition.BASIN==3536)=36000;
reduced_deposition.BASIN(reduced_deposition.BASIN==3522)=22000;
reduced_deposition.BASIN(reduced_deposition.BASIN==3534)=34000;
reduced_deposition.BASIN(reduced_deposition.BASIN==3537)=37000;
reduced_deposition.BASIN(reduced_deposition.BASIN==3542)=42000;
reduced_deposition.BASIN(reduced_deposition.BASIN==3524)=24000;
reduced_deposition.BASIN(reduced_deposition.BASIN==3525)=25000;
reduced_deposition.BASIN(reduced_deposition.BASIN==3540)=40000;
reduced_deposition.BASIN(reduced_deposition.BASIN==3538)=38000;
reduced_deposition.BASIN(reduced_deposition.BASIN==3539)=39000;
reduced_deposition.BASIN(reduced_deposition.BASIN==3532)=32000;
reduced_deposition.BASIN(reduced_deposition.BASIN==3531)=31000;
reduced_deposition.BASIN(reduced_deposition.BASIN==3530)=30000;
reduced_deposition.BASIN(reduced_deposition.BASIN==3523)=23000;

% add oxidized and reduced

total_deposition = oxidized_deposition;

for i = 2:220
    total_deposition{:,i} = oxidized_deposition{:,i}+reduced_deposition{:,i};
end

% split up haldimand-norfolk based on area
haldimand_area = wshd_admin_inputs.AREA_admin(wshd_admin_inputs.ID==28005);
norfolk_area = wshd_admin_inputs.AREA_admin(wshd_admin_inputs.ID==28030);
haldimand_frac = haldimand_area/(haldimand_area+norfolk_area);
norfolk_frac = norfolk_area/(haldimand_area+norfolk_area);

haldimand_row = total_deposition(total_deposition.BASIN==3528,:);
haldimand_row{1,1}=28005;
haldimand_row{1,2:end}=haldimand_row{1,2:end}.*haldimand_frac;

norfolk_row = total_deposition(total_deposition.BASIN==3528,:);
norfolk_row{1,1}=28030;
norfolk_row{1,2:end}=norfolk_row{1,2:end}.*norfolk_frac;

% add the new separated haldimand-norfolk to the table  and remove the
% combined

total_deposition=[total_deposition;norfolk_row;haldimand_row];
total_deposition(total_deposition.BASIN==3528,:)=[];

% finally get total deposition in the order we want for element 

%order the counties 
total_deposition = sortrows(total_deposition,'BASIN','ascend');

clearvars -except 'Run_surplus' 'wshd_admin_inputs' 'pop_inputs' 'pop_hist_inputs' 'pop_param' 'lvstk_weights' 'lvstk_params' 'lvstk_inputs' 'lvstk_manure_landuse_params' 'total_deposition' 'Lamisa_Census_Inputs' 'Finalized_folder' 'Trend_Vals_and_Conversion' 'Fert_Folder' 'Dep_Folder'

save([Finalized_folder,'DEP.mat'],'total_deposition')


% now we should do the same for the USA side 


Dep_Folder_US = 'C:\Users\Meghan McLeod\Dropbox\BASULAB_meghan\Proposal\Lake Erie Data processing\LE_surplus\ELEMENT_Input_formatting\Deposition\Global Gridded\RESULTS_US\';

oxidized_deposition = readtable([Dep_Folder_US,'GLOBAL_deposition_nox.txt'],'VariableNamingRule','preserve');
reduced_deposition = readtable([Dep_Folder_US,'GLOBAL_deposition_nhx.txt'],'VariableNamingRule','preserve');

% add oxidized and reduced

total_deposition_USA = oxidized_deposition;

for i = 2:220
    total_deposition_USA{:,i} = oxidized_deposition{:,i}+reduced_deposition{:,i};
end

% finally get total deposition in the order we want for element 

%order the counties 
total_deposition_USA = sortrows(total_deposition_USA,'BASIN','ascend');

save([Finalized_folder,'DEP_USA.mat'],'total_deposition_USA')


%% *******************************************************************************************************
%% Crop
%% *******************************************************************************************************
disp ('CREATING CROP.mat') 
% the crop areas are from lamisa - (though they include pasture crops
% (should remove?)

% SOURCE::::: Canadian Census of Agriculture

load([Lamisa_Census_Inputs,'CROP.mat'])
crop_area_L = crop_area;
% the crop_area can be left unchanged (except delete unneeded pasture areas)
idxDelete = find(crop_area.CROP_ID==2001);
crop_area(idxDelete,:)=[];
idxDelete = find(crop_area.CROP_ID==2002);
crop_area(idxDelete,:)=[];

% create a CROP_info variable (used in joy's code, not sure if needed)
CROP_info = unique(crop_area(:,[1 2])); CROP_info(end,:)=[];%remove redundant last row
% some of lamisa's data have inconsistant "" so this just makes them
% uniform


% this convoluted code picks which duplicate rows can be deleted
n=[];
todelete = [];
CROP_info_track=CROP_info;
for i=1:length(CROP_info_track.CROP_ID)
    if ~ismember(CROP_info_track.CROP_ID(i),n)
        n=[n;CROP_info_track.CROP_ID(i)];
    else
        todelete=[todelete;i];
    end
end

% delete duplicated rows
CROP_info(todelete,:)=[];

%crop_yield should be consistent between n and p (thus should not be
%altered for field crops)
crop_yield = crop_yield;

% remove the pasture area
idxDelete = find(crop_yield.ID==2001);
crop_yield(idxDelete,:)=[];
idxDelete = find(crop_yield.ID==2002);
crop_yield(idxDelete,:)=[];

% the N_content need to be updated to match Danyka's N-values

crop_N_params_raw=readtable(Trend_Vals_and_Conversion,'Sheet','Crop_Prod','VariableNamingRule','preserve');

N_content=CROP_info; N_content.N=zeros(size(CROP_info.Crop)); % add a new column

% manually will have to update this param file since TREND and lamisa are
% using different crop IDs

%Alfalfa
N_content.N(1) = crop_N_params_raw.("N Content (kg-N/kg)2")(1);
%Barley
N_content.N(2) = crop_N_params_raw.("N Content (kg-N/kg)2")(7);
%Beans
N_content.N(3) = crop_N_params_raw.("N Content (kg-N/kg)2")(8);
%Buckwheat
N_content.N(4) = crop_N_params_raw.("N Content (kg-N/kg)2")(80); % assuming same as wheat like joy
%Canola
N_content.N(5) = crop_N_params_raw.("N Content (kg-N/kg)2")(13);
%Corn - Fodder
N_content.N(6) = 0.013; % not a TREND category - using Joy's value
%Corn - Grain
N_content.N(7) = crop_N_params_raw.("N Content (kg-N/kg)2")(17);
%Flaxseed
N_content.N(8) = crop_N_params_raw.("N Content (kg-N/kg)2")(25);
%Ginsenf
N_content.N(9) =  0; % not a TREND category - using 0 (a placeholder)
%Hay, all
N_content.N(10) = crop_N_params_raw.("N Content (kg-N/kg)2")(1); % assuming same as alfalfa like joy 
%Hay, other
N_content.N(11) = crop_N_params_raw.("N Content (kg-N/kg)2")(28);
%Mixed grains
N_content.N(12) = 0.022; % use the same as joy
%Oats
N_content.N(13) = crop_N_params_raw.("N Content (kg-N/kg)2")(37);
%Other crops
N_content.N(14) = 0.027; % use same as joy
%Peas
N_content.N(15) = 0.065; % use same as joy
%Potatoes
N_content.N(16) = crop_N_params_raw.("N Content (kg-N/kg)2")(48);
% Rye
N_content.N(17) = crop_N_params_raw.("N Content (kg-N/kg)2")(56);
%Soybeans
N_content.N(18) = crop_N_params_raw.("N Content (kg-N/kg)2")(63);
%Sugar beets
N_content.N(19) = crop_N_params_raw.("N Content (kg-N/kg)2")(66);
%Sunflowers
N_content.N(20) = crop_N_params_raw.("N Content (kg-N/kg)2")(69);
%Tobaco
N_content.N(21) = crop_N_params_raw.("N Content (kg-N/kg)2")(74);
%Triticale
N_content.N(22) = crop_N_params_raw.("N Content (kg-N/kg)2")(76);
%Turnips
N_content.N(23) = 0.016; %same as joys
%Wheat
N_content.N(24) = crop_N_params_raw.("N Content (kg-N/kg)2")(80);

% per dry matter can be taken right from lamisa - will want to confirm the
% order so that proper ordering can be done down the line

per_dry_matter_L = per_dry_matter;

% i am going to convert to a table so we can ensure proper labels are used
per_dry_matter=table();
per_dry_matter.Crop=crop_param.Crop;
per_dry_matter.ID=crop_param.ID;
per_dry_matter.per_dry_area=per_dry_matter_L;
%remove last 2 redundant columns
per_dry_matter([25;26],:)=[];

% need to fix crop area (the first row is headers not data) 

%get proper headers 
newheaders = num2cell(crop_area{1,4:end});
%convert them to strings 
for i=1:length(newheaders) 
    newheaders{i} = num2str(newheaders{i}); 
end 
%replace the headers with the proper ones 
crop_area.Properties.VariableNames(4:end)= newheaders;
%delete the first row
crop_area(1,:)=[];
clearvars -except 'Run_surplus' 'wshd_admin_inputs' 'pop_inputs' 'pop_hist_inputs' 'pop_param' 'lvstk_weights' 'lvstk_params' 'lvstk_inputs' 'lvstk_manure_landuse_params' 'total_deposition' 'crop_area' 'CROP_info' 'crop_yield' 'N_content' 'per_dry_matter' 'Lamisa_Census_Inputs' 'Finalized_folder'  'Lamisa_Census_Inputs' 'Finalized_folder' 'Trend_Vals_and_Conversion' 'Fert_Folder' 'Dep_Folder'
save([Finalized_folder,'CROP.mat'],'crop_area', 'CROP_info' ,'crop_yield', 'N_content' ,'per_dry_matter')

%% *******************************************************************************************************
%% BNF
%% *******************************************************************************************************
disp ('CREATING BNF.mat') 
% the BNF conversions are from TREND

% SOURCE::::: Canadian Census of Agriculture
bnf_N_params_raw=readtable(Trend_Vals_and_Conversion,'Sheet','Crop_Fix','VariableNamingRule','preserve');

% only keep relavent parameters

% alfalfa, beans, hay(other), soybeans
BNF_info = bnf_N_params_raw([1,2,3,10],:);

BNF_info= removevars(BNF_info,{'Item Name','Reporting Unit','Square Kilometers or Kilograms Per Reporting Unit'});

%redo the codes to match lamisa's 
BNF_info.Code(1)=1018;
BNF_info.Code(2)=1001;
BNF_info.Code(3)=1011;
BNF_info.Code(4)=1003;
clearvars -except 'Run_surplus' 'wshd_admin_inputs' 'pop_inputs' 'pop_hist_inputs' 'pop_param' 'lvstk_weights' 'lvstk_params' 'lvstk_inputs' 'lvstk_manure_landuse_params' 'total_deposition' 'crop_area' 'CROP_info' 'crop_yield' 'N_content' 'per_dry_matter' 'BNF_info' 'Lamisa_Census_Inputs' 'Finalized_folder'  'Lamisa_Census_Inputs' 'Finalized_folder' 'Trend_Vals_and_Conversion' 'Fert_Folder' 'Dep_Folder'
save([Finalized_folder,'BNF.mat'],'BNF_info')

%!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
%% now all inputs should be formatted to be processed
%% by element and it's current surplus code; if I were
%% not using Van Meter's surplus processing code,
%% I could also do my own processing separately to obtain
%% surplus vectors
%!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


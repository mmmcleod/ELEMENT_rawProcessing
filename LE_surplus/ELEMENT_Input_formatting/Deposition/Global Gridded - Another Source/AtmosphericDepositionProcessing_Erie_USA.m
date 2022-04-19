clc, clear

filename='C:\Users\Meghan McLeod\Dropbox\BASULAB_meghan\Proposal\Lake Erie Data processing\Shapefile\LE_USA.shp';
S=shaperead(filename);
entB=size(S,1);

files = dir('ndep_*.dat');
files = files(1:22);
%load(('pdep_2000.dat'),'-mat'); % pdep mg/m2/yr
%year = 2000;
DepExport = NaN(length(files), length(S)+1);
for k = 1:length(files)
  k/length(files)
   files_k = files(k).name;
   load(files_k,'-mat'); % pdep mg/m2/yr
   year = str2num(files_k(6:end-4));
   display(year) 
   DepExport(k,1) = year;
    
ndep_resampled = NaN(180,360);
i_v = 1:0.1:180; i_v(end) = [];
j_v = 1:0.1:360; j_v(end) = [];
for i=1:length(i_v) % 90S to 90N

    for j=1:length(j_v) % 180W-0-180E
        %lat=i-0.5;
        %lon=j-0.5;
        lat = i_v(i);
        lon = j_v(j);

        ii=floor((lat+0.6338)/1.2676)+1;
        jj=floor(lon/2.5)+1;

        pgrid=ndep(jj,144-ii); %  mg total N/m2/yr

        if year==1960 || year==1970 || year==1980 || year==1990
            pgrid=ndep(jj,144-ii)*1.2; %  mg total P/m2/yr
        end
        pgrid = pgrid/1000/1000*10000; % Convering to kg/ha/yr
        ndep_resampled(i,j) = pgrid;
    end
end
ndep_resampled = flip(ndep_resampled);
 %imwrite(ndep_resampled,'ndep_resampled.tiff','tiff')

y=(-90:0.1:90)*-1; y(find(y==0)) = [];
x=-180:0.1:180; x(find(x==0)) = [];

x_half=(x(2)-x(1))/2;
y_half=(y(2)-y(1))/2;

[X,Y]=meshgrid(x,y);

for i=1:entB        
    
	rx = S(i).X(1:end-1);
    ry = S(i).Y(1:end-1) ; 
    COUNTY(i,1)=str2num(S(i).GEOID); 
    %COUNTY{i,1}=S(i).CDNAME; 
    %AREA(i,1)=S(i).AREATOTAL/10000; 
%make mask 
    mask = inpolygon(X,Y,rx,ry);
    
    if sum(mask,'all')>=1
        [r,c] = find(mask ~= 0);
        Dep = nanmean(ndep_resampled(r,c),'all');
        S(i).(sprintf('ndep_kgha_%d',year)) = Dep;
    else
        [ry2,rx2] =  bufferm(ry,rx,0.1);
         mask = inpolygon(X,Y,rx2,ry2);
        if sum(mask,'all')>=1
            [r,c] = find(mask ~= 0);
            Dep = nanmean(ndep_resampled(r,c),'all');
            S(i).(sprintf('ndep_kgha_%d',year)) = Dep;
        else
            S(i).(sprintf('ndep_kgha_%d',year)) = NaN;
        end

    end
    DepExport(k,i+1) = Dep;%*AREA(i,1);
end
end
save('DepoLoops_USA.mat')
shapewrite(S,'Atmosphericndeposition.shp');
yearinterp = [1850:2017]';
yearinterp(ismember(yearinterp, DepExport(:,1)))= [];

interpData = [yearinterp, NaN(length(yearinterp),size(DepExport,2)-1)];
interpData = [DepExport;interpData];
interpData = sortrows(interpData,1);

DepExport = fillmissing(interpData, 'linear', 'EndValues','nearest');
%DepExport(find(DepExport(:,1) < 1930),:) = [];

Header = {'YEAR'};
for i = 1:length(COUNTY)
   Header(i+1) = {sprintf('x%4d',COUNTY(i))};
end

AtmosphericDeposition = array2table(DepExport,...
    'VariableNames',Header);
save('Results\N_AtmosphericDeposition_USA.mat','AtmosphericDeposition')

%% Scale pre-1960 deposition using Houlton's NOx U.S. emisions data 

orig_data_years = {files.name}.'; 
orig_data_years = str2num(cell2mat(cellfun(@(x) x(6:9),orig_data_years,'UniformOutput',false)));


HoultonData = readtable('Houlton_NOxEmissionDataset.csv');
RemIdx = find(HoultonData{:,1} == 1970); % grab 1970 as scaling year 
HoultonData = HoultonData(1:RemIdx,:); % only take before this date
Houlton_scale = HoultonData{end,2}; 
Dep_scale = AtmosphericDeposition{AtmosphericDeposition.YEAR==1970,2:end}; 
scalefactor1970 = Dep_scale/Houlton_scale;
scaledData = [HoultonData.Var1(2:end), HoultonData.Var2(2:end)*scalefactor1970];

%now tack on this scaled emissions data to the deposition data before 1970 
%delete old
AtmosphericDeposition_withHoulton = AtmosphericDeposition; 
AtmosphericDeposition_withHoulton(AtmosphericDeposition_withHoulton.YEAR<1970,:)=[]; 
%add new
AtmosphericDeposition_withHoulton=[scaledData; AtmosphericDeposition_withHoulton{:,:}];
%%
save('Results\N_AtmosphericDeposition_scaled.mat','AtmosphericDeposition_withHoulton')
%% Plot to compare with TREND for example 
figure()
for i=1:65
    plot(AtmosphericDeposition{:,1},AtmosphericDeposition{:,i+1},'g:','LineWidth',2)
    hold on
end

% Load trend dataset
T_r = readtable('C:\Users\Meghan McLeod\Dropbox\BASULAB_meghan\Proposal\Lake Erie Data processing\LE_surplus\ELEMENT_Input_formatting\Deposition\Global Gridded\DEP_Atmospheric_Reduced_TREND_COMP.csv','ReadVariableNames', true);
T_o = readtable('C:\Users\Meghan McLeod\Dropbox\BASULAB_meghan\Proposal\Lake Erie Data processing\LE_surplus\ELEMENT_Input_formatting\Deposition\Global Gridded\DEP_Atmospheric_Oxidized_TREND_COMP.csv','ReadVariableNames', true);
T_trend=T_r; T_trend{:,2:end}=T_o{:,2:end}+T_r{:,2:end};
% do is member of COUNTIES to only keep ERIE ones 
T_trend_names = T_trend.Properties.VariableNames; T_trend_names(1)=[];
T_trendIDs = cellfun(@(x) str2num(x(2:end)),T_trend_names);
idx = [1,ismember(T_trendIDs,COUNTY)]; idx=find(idx);
T_trend = T_trend(:,idx);

for i=1:65
    plot(T_trend{:,1},T_trend{:,i+1},'k:','LineWidth',1.5)
end
%Load global datset (old)
Tr=readtable('C:\Users\Meghan McLeod\Dropbox\BASULAB_meghan\Proposal\Lake Erie Data processing\LE_surplus\ELEMENT_Input_formatting\Deposition\Global Gridded\RESULTS_US\GLOBAL_deposition_nhx');
To=readtable('C:\Users\Meghan McLeod\Dropbox\BASULAB_meghan\Proposal\Lake Erie Data processing\LE_surplus\ELEMENT_Input_formatting\Deposition\Global Gridded\RESULTS_US\GLOBAL_deposition_nox');
%add together
T_global=Tr; T_global{:,2:end}=To{:,2:end}+Tr{:,2:end};
T_global = sortrows(T_global,'BASIN','ascend');

for i=1:65
    plot(1800:2018,T_global{i,2:end},'r:','LineWidth',1.5)
end

hold off

figure()
% 36009
subplot(3,1,1)
plot(AtmosphericDeposition_withHoulton(:,1),AtmosphericDeposition_withHoulton(:,2),'LineStyle','-','Color','#0000ff','LineWidth',2)
hold on
plot(AtmosphericDeposition{:,1},AtmosphericDeposition{:,2},':c','LineWidth',2)
plot(T_trend{:,1},T_trend{:,24},':k','LineWidth',2)
%plot(1800:2018,T_global{1,2:end},':r','LineWidth',2)
title('x36009')
legend('Houlton weighted','Regular Global ','TREND')
% 
% 18113
subplot(3,1,2)
plot(AtmosphericDeposition_withHoulton(:,1),AtmosphericDeposition_withHoulton(:,50),'LineStyle','-','Color','#0000ff','LineWidth',2)
hold on
plot(AtmosphericDeposition{:,1},AtmosphericDeposition{:,50},':c','LineWidth',2)
plot(T_trend{:,1},T_trend{:,5},':k','LineWidth',2)
%plot(1800:2018,T_global{65,2:end},':r','LineWidth',2)
title('x18113')

% 39123
subplot(3,1,3)
plot(AtmosphericDeposition_withHoulton(:,1),AtmosphericDeposition_withHoulton(:,30),'LineStyle','-','Color','#0000ff','LineWidth',2)
hold on
plot(AtmosphericDeposition{:,1},AtmosphericDeposition{:,30},':c','LineWidth',2)
plot(T_trend{:,1},T_trend{:,50},':k','LineWidth',2)
%plot(1800:2018,T_global{7,2:end},':r','LineWidth',2)
title('x39123')


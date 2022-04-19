clc, clear

filename='C:\Users\Meghan McLeod\Dropbox\BASULAB_meghan\Proposal\Lake Erie Data processing\Shapefile\LE_CA_fullCounties_noWater.shp';
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
    %COUNTY(i,1)=str2num(S(i).CDNAME); 
    COUNTY{i,1}=S(i).CDNAME; 
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
save('DepoLoops.mat')
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
   Header(i+1) = {sprintf('x%4d',COUNTY{i})};
end

AtmosphericDeposition = array2table(DepExport,...
    'VariableNames',Header);
save('Results\N_AtmosphericDeposition.mat','AtmosphericDeposition')


%% Scale pre-1960 deposition using CDIAC's. emisions data 

orig_data_years = {files.name}.'; 
orig_data_years = str2num(cell2mat(cellfun(@(x) x(6:9),orig_data_years,'UniformOutput',false)));


CDIACdata = readtable('CDIAC_nation_1751_2014.csv');
CDIACdata=CDIACdata(string(CDIACdata.Var1)=='CANADA',:); % only looking at canada
RemIdx = find(CDIACdata{:,2} == 1970); % grab 1970 as scaling year 
CDIACdata = CDIACdata(1:RemIdx,:); % only take before this date
CDIACdata_scale = CDIACdata{end,3}; 
Dep_scale = AtmosphericDeposition{AtmosphericDeposition.YEAR==1970,2:end}; 
scalefactor1970 = Dep_scale/CDIACdata_scale;
scaledData = [CDIACdata.Var2(2:end), CDIACdata.Var3(2:end)*scalefactor1970];

%now tack on this scaled emissions data to the deposition data before 1970 
%delete old
AtmosphericDeposition_withCDIAC = AtmosphericDeposition; 
AtmosphericDeposition_withCDIAC(AtmosphericDeposition_withCDIAC.YEAR<1970,:)=[]; 
%add new
AtmosphericDeposition_withCDIAC=[scaledData; AtmosphericDeposition_withCDIAC{:,:}];
%%
save('Results\N_AtmosphericDeposition_scaledCDIAC.mat','AtmosphericDeposition_withCDIAC')

%% Plot to compare with joy's GRW for example 

% % for i=1:17 
% % plot(AtmosphericDeposition{:,1},AtmosphericDeposition{:,i+1},'g','LineWidth',2)
% % hold on 
% % end
% % 
% % load('C:\Users\Meghan McLeod\Dropbox\BASULAB_meghan\Proposal\Lake Erie Data processing\LE_surplus\ELEMENT_Input_formatting\Deposition\Global Gridded\DEP_Atmo_NACID_JOY_COMP.mat')
% % load('C:\Users\Meghan McLeod\Dropbox\BASULAB_meghan\Proposal\ELEMENT_run_LE_Nitrogen_mmmcleod\MODEL\INPUTS\INPUTS_joy\WSHD_2GAC06.mat')
% % dep_inputs_joy = removevars(dep_inputs, 'x21000');
% % load('C:\Users\Meghan McLeod\Dropbox\BASULAB_meghan\Proposal\ELEMENT_run_LE_Nitrogen_mmmcleod\MODEL\INPUTS\INPUTS_erie\INPUTS_03-Feb-2022\DEP.mat')
% % dep_inputs_erieGlobal = removevars(total_deposition, {'x28005','x28030','x34000','x36000','x37000','x38000','x39000','x40000'});
% % 
% % for i=1:10
% %     plot(dep_inputs_joy{:,1},dep_inputs_joy{:,i+1},'k','LineWidth',1.5)
% % end
% % 
% % for i=1:9
% %     plot(dep_inputs_erieGlobal{:,1},dep_inputs_erieGlobal{:,i+1},'r','LineWidth',1.5)
% % end
% % hold off 
% Waterloo 
subplot(3,1,1) 
plot(AtmosphericDeposition_withCDIAC(:,1),AtmosphericDeposition_withCDIAC(:,1+1),'LineStyle','-','Color','#0000ff','LineWidth',2)
hold on 
plot(AtmosphericDeposition{:,1},AtmosphericDeposition{:,1+1},':c','LineWidth',2)
plot(dep_inputs_joy{:,1},dep_inputs_joy.x30000,':k','LineWidth',2)
%plot(dep_inputs_erieGlobal{:,1},dep_inputs_erieGlobal.x30000,':r','LineWidth',2)
title('WATERLOO')
legend('CDIAC weighted','Regular Global ','Checkered GRW')

% Dufferin 
subplot(3,1,2) 
plot(AtmosphericDeposition_withCDIAC(:,1),AtmosphericDeposition_withCDIAC(:,2+1),'LineStyle','-','Color','#0000ff','LineWidth',2)
hold on 
plot(AtmosphericDeposition{:,1},AtmosphericDeposition{:,2+1},':c','LineWidth',2)
plot(dep_inputs_joy{:,1},dep_inputs_joy.x22000,':k','LineWidth',2)
%plot(dep_inputs_erieGlobal{:,1},dep_inputs_erieGlobal.x22000,':r','LineWidth',2)
title('DUFFERIN')

%Oxford

subplot(3,1,3) 
plot(AtmosphericDeposition_withCDIAC(:,1),AtmosphericDeposition_withCDIAC(:,14+1),'LineStyle','-','Color','#0000ff','LineWidth',2)
hold on 
plot(AtmosphericDeposition{:,1},AtmosphericDeposition{:,14+1},':c','LineWidth',2)
plot(dep_inputs_joy{:,1},dep_inputs_joy.x32000,':k','LineWidth',2)
%plot(dep_inputs_erieGlobal{:,1},dep_inputs_erieGlobal.x32000,':r','LineWidth',2)
title('OXFORD')



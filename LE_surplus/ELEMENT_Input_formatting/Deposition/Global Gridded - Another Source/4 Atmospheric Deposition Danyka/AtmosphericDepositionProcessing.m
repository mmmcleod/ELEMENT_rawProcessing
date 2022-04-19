clc, clear

filename='..\0 Raw Datasets\Merge County shp\MergedCountyTotalArea_4326.shp';
S=shaperead(filename);
entB=size(S,1);

files = dir('pdep_*.dat');
files = files(1:22);
%load(('pdep_2000.dat'),'-mat'); % pdep mg/m2/yr
%year = 2000;
DepExport = NaN(length(files), length(S)+1);
for k = 1:length(files)
  k/length(files)
   files_k = files(k).name;
   load(files_k,'-mat'); % pdep mg/m2/yr
   year = str2num(files_k(6:end-4));
   DepExport(k,1) = year;
    
pdep_resampled = NaN(180,360);
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

        pgrid=pdep(jj,144-ii); %  mg total N/m2/yr

        if year==1960 || year==1970 || year==1980 || year==1990
            pgrid=pdep(jj,144-ii)*1.2; %  mg total P/m2/yr
        end
        pgrid = pgrid/1000/1000*10000; % Convering to kg/ha/yr
        pdep_resampled(i,j) = pgrid;
    end
end
pdep_resampled = flip(pdep_resampled);
 %imwrite(pdep_resampled,'pdep_resampled.tiff','tiff')

y=(-90:0.1:90)*-1; y(find(y==0)) = [];
x=-180:0.1:180; x(find(x==0)) = [];

x_half=(x(2)-x(1))/2;
y_half=(y(2)-y(1))/2;

[X,Y]=meshgrid(x,y);

for i=1:entB        
    
	rx = S(i).X(1:end-1);
    ry = S(i).Y(1:end-1) ; 
    COUNTY(i,1)=str2num(S(i).GEOID); 
    AREA(i,1)=S(i).AREATOTAL/10000; 
%make mask 
    mask = inpolygon(X,Y,rx,ry);
    
    if sum(mask,'all')>=1
        [r,c] = find(mask ~= 0);
        Dep = nanmean(pdep_resampled(r,c),'all');
        S(i).(sprintf('PDep_kgha_%d',year)) = Dep;
    else
        [ry2,rx2] =  bufferm(ry,rx,0.1);
         mask = inpolygon(X,Y,rx2,ry2);
        if sum(mask,'all')>=1
            [r,c] = find(mask ~= 0);
            Dep = nanmean(pdep_resampled(r,c),'all');
            S(i).(sprintf('PDep_kgha_%d',year)) = Dep;
        else
            S(i).(sprintf('PDep_kgha_%d',year)) = NaN;
        end

    end
    DepExport(k,i+1) = Dep*AREA(i,1);
end
end
save('DepoLoops.mat')
shapewrite(S,'AtmosphericPDeposition.shp');
yearinterp = [1850:2017]';
yearinterp(ismember(yearinterp, DepExport(:,1)))= [];

interpData = [yearinterp, NaN(length(yearinterp),size(DepExport,2)-1)];
interpData = [DepExport;interpData];
interpData = sortrows(interpData,1);

DepExport = fillmissing(interpData, 'linear', 'EndValues','nearest');
DepExport(find(DepExport(:,1) < 1930),:) = [];

Header = {'YEAR'};
for i = 1:length(COUNTY)
   Header(i+1) = {sprintf('x%4d',COUNTY(i))};
end

AtmosphericDeposition = array2table(DepExport,...
    'VariableNames',Header);
save('..\6 Results\P_AtmosphericDeposition.mat','AtmosphericDeposition')
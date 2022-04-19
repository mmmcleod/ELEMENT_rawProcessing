clc, clear

%load(('ndep_2000.dat'),'-mat'); % ndep mg/m2/yr
%load(('pdep_2000.dat'),'-mat'); % pdep mg/m2/yr

filename='..\0 Raw Datasets\Merge County shp\MergedCountyTotalArea_4326.shp';
S=shaperead(filename);
entB=size(S,1);
files = dir('pdep_*.dat');
files = files(1:22);

for k = 1:length(files)
   files_k = files(k).name;
   load(files_k,'-mat'); % pdep mg/m2/yr

    pdep_resampled = NaN(180,360);
    count = 1;
    ascii = [];
for i=1:180 % 90S to 90N

    for j=1:360 % 180W-0-180E

        year = 2000;
        lat=i-0.5;
        lon=j-0.5;

        ii=floor((lat+0.6338)/1.2676)+1;
        jj=floor(lon/2.5)+1;

        pgrid=pdep(jj,144-ii); %  mg total N/m2/yr

        if year==1960 || year==1970 || year==1980 || year==1990
            pgrid=pdep(jj,144-ii)*1.2; %  mg total P/m2/yr
        end
        pgrid = pgrid/1000/1000*10000; % Convering to kg/ha/yr
        pdep_resampled(i,j) = pgrid;
        ascii(count,1:3) = [j-180,i-90,pgrid];
        count = count+1;
    end

end
pdep_resampled = flip(pdep_resampled);
exportfilename = files(k).name;
exportfilename = exportfilename(1:end-3);
exportfilename = ['PointFiles/',exportfilename,'csv'];
writematrix(ascii,exportfilename)
end
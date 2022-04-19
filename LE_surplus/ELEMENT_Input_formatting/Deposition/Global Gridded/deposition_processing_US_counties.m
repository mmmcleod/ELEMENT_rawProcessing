clear
clc

datacat='deposition';

% open basin shapefile

folder='DATA/';
filename='LE_USA_counties.shp';
S=shaperead([folder,filename], 'UseGeoCoords', true);

%% plot states

figure()
geoshow(S)

%%

entB=size(S,1);

% identify folder with raster files

folder='DATA/';
filename = 'ann_drynoy_ncdf4.nc'; %DEP FILE NAME
C_dry_noy= permute(ncread([folder,filename],'drynoy'),[2 1 3])*10^4*60*60*24*365; % Convert units to kg/ha

d1=size(C_dry_noy,1); %lat
d2=size(C_dry_noy,2); %lon
d3=size(C_dry_noy,3); %year

filename = 'ann_wetnoy_ncdf4.nc'; %DEP FILE NAME
C_wet_noy= permute(ncread([folder,filename],'wetnoy'),[2 1 3])*10^4*60*60*24*365; % Convert units to kg/ha

filename = 'ann_drynhx_ncdf4.nc'; %DEP FILE NAME
C_dry_nhx= permute(ncread([folder,filename],'drynhx'),[2 1 3])*10^4*60*60*24*365; % Convert units to kg/ha

filename = 'ann_wetnhx_ncdf4.nc'; %DEP FILE NAME
C_wet_nhx= permute(ncread([folder,filename],'wetnhx'),[2 1 3])*10^4*60*60*24*365; % Convert units to kg/ha

% Replace missing values with Nan
% missing valof 1.00000003318135e+32 used in ncdf

for i=1:d1
    for j=1:d2
        for m=1:d3
            if C_dry_noy(i,j,:)>1E32
                C_dry_noy(i,j,:)=NaN;
                C_wet_noy(i,j,:)=NaN;
                C_dry_nhx(i,j,:)=NaN;
                C_wet_nhx(i,j,:)=NaN;
            end
        end
    end
end


%% plot drynoy (just one year)
figure()

ncfile = [folder,'ann_drynoy_ncdf4.nc'];
lon = ncread(ncfile,'lon') ; nx = length(lon) ;
lat = ncread(ncfile,'lat') ; ny = length(lat) ;

% grab just one year
year=22;
z = ncread(ncfile,'drynoy',[1 1 year],[nx ny 1]);

% plot
pcolor(lon,lat,z') ;
shading interp
drawnow
colorbar

%%
% READ LAT LONx=(ncread(filename,'lon'))';
x=(ncread([folder,filename],'lon'));
y=(ncread([folder,filename],'lat'));

% adjust lat/lon values

% % % for i=1:length(x)
% % %     if i==1
% % %         x(i)=-180+(360/length(x)/2);
% % %     else
% % %         x(i)=x(i-1)+(360/length(x));
% % %     end
% % % end
% % %
% % % for i=1:length(y)
% % %     if i==1
% % %         y(i)=90-(180/length(y)/2);
% % %     else
% % %         y(i)=y(i-1)-(180/length(y));
% % %     end
% % % end

x_half=(x(2)-x(1))/2;
y_half=(y(2)-y(1))/2;

[X,Y]=meshgrid(x,y);


DEP_NOX_wet=NaN(entB,size(C_dry_noy,3));  % Create empty mattrix
DEP_NOX_dry=NaN(entB,size(C_dry_noy,3));  % Create empty mattrix
DEP_NHX_wet=NaN(entB,size(C_dry_noy,3));  % Create empty mattrix
DEP_NHX_dry=NaN(entB,size(C_dry_noy,3));  % Create empty mattrix


for i=1:entB
    
    rx = S(i).Lon(1:end-1);
    %rx = S(i).X(1:end-1)+360; %adjust for western hemisphere
    
    for r=1:length(rx)
        if rx(r)<0
            rx(r)=rx(r)+360;
        end
    end
    ry = S(i).Lat(1:end-1) ;
    COUNTY(i,1)=str2num(S(i).N3);  %this should be the geoID
    
    
    %make mask
    
    mask = inpolygon(X,Y,rx,ry);
    
    
    
    if sum(mask,'all')>=1
        zz=1
        for j=1:d3
            C_temp=C_dry_noy(:,:,j);
            DEP_NOX_dry(i,j)=nanmean(C_temp(mask));
            C_temp=C_wet_noy(:,:,j);
            DEP_NOX_wet(i,j)=nanmean(C_temp(mask));
            C_temp=C_dry_nhx(:,:,j);
            DEP_NHX_dry(i,j)=nanmean(C_temp(mask));
            C_temp=C_wet_nhx(:,:,j);
            DEP_NHX_wet(i,j)=nanmean(C_temp(mask));
        end
        
    else
        for j=1:d1
            if ry(1)>=(Y(j,1)-y_half) && ry(1)<=(Y(j,1)+y_half)
                for k=1:d2
                    if rx(1)>=(X(j,k)-x_half) && rx(1)<=(X(j,k)+x_half)
                        for m=1:d3
                            DEP_NOX_dry(i,m)=C_dry_noy(j,k,m);
                            DEP_NOX_wet(i,m)=C_wet_noy(j,k,m);
                            DEP_NHX_dry(i,m)=C_dry_nhx(j,k,m);
                            DEP_NHX_wet(i,m)=C_wet_nhx(j,k,m);
                        end
                        break
                    end
                end
            end
        end
        i
    end
    
    
end

Y_data=1850:1:2014;
YEAR=1800:2018;
entY=length(YEAR);

DEP_NOX_dry_temp=DEP_NOX_dry;
DEP_NOX_wet_temp=DEP_NOX_wet;
DEP_NHX_dry_temp=DEP_NHX_dry;
DEP_NHX_wet_temp=DEP_NHX_wet;

DEP_NOX_dry=NaN(entB,entY);
DEP_NOX_wet=NaN(entB,entY);
DEP_NHX_dry=NaN(entB,entY);
DEP_NHX_wet=NaN(entB,entY);

for i=1:entY
    if YEAR(i)<Y_data(1)
        DEP_NOX_dry(:,i)=DEP_NOX_dry_temp(:,1);
        DEP_NOX_wet(:,i)=DEP_NOX_wet_temp(:,1);
        DEP_NHX_dry(:,i)=DEP_NHX_dry_temp(:,1);
        DEP_NHX_wet(:,i)=DEP_NHX_wet_temp(:,1);
    elseif YEAR(i)>Y_data(end)
        DEP_NOX_dry(:,i)=DEP_NOX_dry_temp(:,end);
        DEP_NOX_wet(:,i)=DEP_NOX_wet_temp(:,end);
        DEP_NHX_dry(:,i)=DEP_NHX_dry_temp(:,end);
        DEP_NHX_wet(:,i)=DEP_NHX_wet_temp(:,end);
    else
        idx=Y_data==YEAR(i);
        DEP_NOX_dry(:,i)=DEP_NOX_dry_temp(:,idx);
        DEP_NOX_wet(:,i)=DEP_NOX_wet_temp(:,idx);
        DEP_NHX_dry(:,i)=DEP_NHX_dry_temp(:,idx);
        DEP_NHX_wet(:,i)=DEP_NHX_wet_temp(:,idx);
    end
end

DEP_NOX=DEP_NOX_dry+DEP_NOX_wet;
DEP_NHX=DEP_NHX_dry+DEP_NHX_wet;

Y=string(YEAR);

for i=1:entY
    Y_temp(i)=strcat("Y",Y(i));
end

H=["BASIN" Y_temp]';

T=array2table([COUNTY DEP_NOX_dry],'VariableNames',H);

filename='RESULTS_US/GLOBAL_deposition_nox_dry';
writetable(T,filename);

T=array2table([COUNTY DEP_NOX_wet],'VariableNames',H);

filename='RESULTS_US/GLOBAL_deposition_nox_wet';
writetable(T,filename);

T=array2table([COUNTY DEP_NHX_dry],'VariableNames',H);

filename='RESULTS_US/GLOBAL_deposition_nhx_dry';
writetable(T,filename);

T=array2table([COUNTY DEP_NHX_wet],'VariableNames',H);

filename='RESULTS_US/GLOBAL_deposition_nhx_wet';
writetable(T,filename);

T=array2table([COUNTY DEP_NHX],'VariableNames',H);

filename='RESULTS_US/GLOBAL_deposition_nhx';
writetable(T,filename);

T=array2table([COUNTY DEP_NOX],'VariableNames',H);

filename='RESULTS_US/GLOBAL_deposition_nox';
writetable(T,filename);

%% compare with deposition in the TREND dataset

%compare reduced for county #

ERIE_IDs = T.BASIN;

for i=1:20%length(ERIE_IDs)
    ID = ERIE_IDs(i);%+20+40+60);
    IdString = ['x',num2str(ID)];
    %from GLOBAL
    T=array2table([COUNTY DEP_NHX],'VariableNames',H);
    
    global_reduced = table2array(T(T.BASIN==ID,:)); global_reduced=global_reduced(2:end);
    
    T=array2table([COUNTY DEP_NOX],'VariableNames',H);
    global_oxidized = table2array(T(T.BASIN==ID,:)); global_oxidized=global_oxidized(2:end);
    
    global_year = YEAR;
    
    %from Danyka
    T_r = readtable('DEP_Atmospheric_Reduced_TREND_COMP.csv','ReadVariableNames', true);
    trend_reduced = T_r.(IdString);
    
    T_o = readtable('DEP_Atmospheric_Oxidized_TREND_COMP.csv','ReadVariableNames', true);
    trend_oxidized = T_o.(IdString);
    
    trend_year = T_r.NaN;
    
    subplot(4,5,i)
    plot(global_year,(global_reduced+global_oxidized),'k','Linewidth',2)
    hold on
    plot(trend_year,trend_reduced+trend_oxidized,'r','Linewidth',2)
    % ylabel('total Deposition (oxidized+reduced)')
    % xlabel('year')
    title(['Deposition for ',IdString])
    legend('global','trend')
    #US_counties_erie_dep(:,i) = trend_reduced+trend_oxidized;
end


mean_trend_dep = mean(US_counties_erie_dep');

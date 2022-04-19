% checking EGRET WRTDS output against observed values
% to be used before QC_annavg.m
clc, clear, close all

wrtdsOutputFolder = 'Output_wrtds\';
wrdsInputCleanFolder = 'Input_cleaned\';
foldir = dir([wrtdsOutputFolder,'\*.xlsx']); 

%build a list of station names 
stn_name = [];
for i = 1:length(foldir)
    stn_name = [stn_name; extractBetween(string(foldir(i).name),1,8)];
end

for i = 1:length(stn_name)
    
   MODraw = readtable([wrtdsOutputFolder,char(stn_name(i)),'_Results.xlsx']);
   OBSraw = readtable([wrdsInputCleanFolder,char(stn_name(i)),'_clean_C.csv']);
   
   plot(MODraw{:,1},MODraw{:,3},'r-','LineWidth',1.5)
   hold on
   plot(OBSraw{:,1},OBSraw{:,3},'ko')
   grid on
   ylabel('Concentration (mg/L)')
   title(['WRTDS vs observed timeseries for ',char(stn_name(i))])
   saveas(gcf,['Output_qualityCheck\',char(stn_name(i)),' WRTDS vs observed timeseries.png'])
   close all
   
   ind = ismember(MODraw{:,1},OBSraw{:,1});
   MOD = MODraw{ind,3};
   ind = ismember(OBSraw{:,1},MODraw{ind,1});
   OBS = OBSraw{ind,3};
   plot(OBS,MOD,'o')
   grid on
   hold on
   plot(OBSraw{:,3},OBSraw{:,3},'k-')
   axis([0 max(OBSraw{:,3}) 0 max(OBSraw{:,3})])
   xlabel('Observed')
   ylabel('Modelled')
   title(['WRTDS vs observed for ',char(stn_name(i))])
   saveas(gcf,['Output_qualityCheck\',char(stn_name(i)),'WRTDS vs observed.png'])
   close all
end
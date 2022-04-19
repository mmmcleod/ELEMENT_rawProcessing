% --- To clean up concentration data before running EGRET's R code for WRTDS
% --- Before using this code, manually check for long periods of 0 flow in
% time series data. If consecutive 0 flows occur for > 2 weeks, delete
% those data points. This code interpolates 0 flows and is acceptable for
% short periods of time but if long periods of time get interpolated, the
% output data to be put into WRTDS will not be acceptable
% --- uses dates in Excel's general format

clc, clear, close all
% RAWINFO = readtable('C:\Users\Joy\Documents\ELEMeNT\Data\Water Quality\CQ_Station_Pairing.xlsx');
% 
% foldir = dir('160184*');
% 
% stn_name = [];
% 
% for i = 1:length(foldir)
% 
% stn_name = [stn_name; string(foldir(i).name)];
% 
% end

stn_name = "7.16015900302"; %_____change this____

for j = 1:length(stn_name)
    
    opts = detectImportOptions([char(stn_name(j)),'/',char(stn_name(j)),'.xlsx'],'Sheet','Sheet1');
    RAW = readtable([char(stn_name(j)),'/',char(stn_name(j)),'.xlsx'],'ReadVariableNames',false,'Sheet','Sheet1');

%%

CRAW = RAW{:,3:4};
CRAW = unique(CRAW,'rows');
DCraw = CRAW(:,1)+693960;
Craw = CRAW(:,2);

Craw(isnan(DCraw))=[];
DCraw(isnan(DCraw))=[];
DCraw = datetime(datestr(DCraw));

DCraw(isnan(Craw))=[];
Craw(isnan(Craw))=[];

DCraw(Craw==0)=[];
Craw(Craw==0)=[];

QRAW = RAW{:,1:2};
QRAW = unique(QRAW,'rows');

DQraw = QRAW(:,1)+693960;
Qraw = QRAW(:,2);

% find C samples that were done multiple times a day

DC_ind = [];

for i = 1:length(DCraw)
    if length(find(ismember(DCraw,DCraw(i))))>1
        DC_ind = [DC_ind;i];
    else
    end
end
 
DC_same=unique(DCraw(DC_ind));
C_same=Craw(DC_ind);

DC_clean = DCraw;
C_clean = Craw;

for i = 1:length(DC_same)
    ind = find(ismember(DCraw,DC_same(i)));
    C_clean(ind(1))=mean(Craw(ind));
    C_clean(ind(2:end))=[];
    DC_clean(ind(2:end))=[];   
    
    DCraw(ind(2:end))=[];
end

% % get rid of 1979 - 1982
% 
% del_yr = 1979:1982;
% del_indQ = [];
% del_indC = [];
% 
% for i = 1:length(del_yr)
%     if sum(ismember(year(DQraw),del_yr(i)))>0
%         del_indQ = [del_indQ;find(year(DQraw)==del_yr(i))];  
%         del_indC = [del_indC;find(year(DC_clean)==del_yr(i))];
%     end 
% end
% 
DQ_clean = DQraw;
% DQ_clean(del_indQ)=[];
Q_clean = Qraw;
% Q_clean(del_indQ)=[];
% 
% DC_clean(del_indC)=[];
% C_clean(del_indC)=[];
% 

% interpolating zero flows

z_ind = find(Q_clean==0);
Q_clean(z_ind)=NaN;
Q_clean=fillmissing(Q_clean,'linear');

scatter (DC_clean, C_clean)
saveas(gcf,[char(stn_name(j)),'\Conc.datarange.png'])

% changing date format
DQ_clean = string(datestr(DQ_clean,'yyyy-mm-dd'));
DC_clean = string(datestr(DC_clean,'yyyy-mm-dd'));

%% write table
T = table(DQ_clean,Q_clean);
writetable(T,[char(stn_name(j)),'/',char(stn_name(j)),'_clean_Q.csv'],'WriteVariableNames',true);

T = table(DC_clean,NaN(length(C_clean),1),C_clean);
writetable(T,[char(stn_name(j)),'/',char(stn_name(j)),'_clean_C.csv'],'WriteVariableNames',true);


end
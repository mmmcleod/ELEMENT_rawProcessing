% --- To clean up concentration data before running EGRET's R code for WRTDS
% --- Before using this code, manually check for long periods of 0 flow in
% time series data. If consecutive 0 flows occur for > 2 weeks, delete
% those data points. This code interpolates 0 flows and is acceptable for
% short periods of time but if long periods of time get interpolated, the
% output data to be put into WRTDS will not be acceptable
% --- uses dates in Excel's general format

%SET UP ENVIRONMENT
%%
clc, clear, close all

PairingFolder = 'C:\Users\Meghan McLeod\Dropbox\BASULAB_meghan\Proposal\Lake Erie Data processing\LE_gauges\Gauge_pairing\USA\';
RawQFolder ='C:\Users\Meghan McLeod\Dropbox\BASULAB_meghan\Proposal\Lake Erie Data processing\LE_gauges\Extracting Data\USA\Gauge_discharge_WQ\ExtractedDischarge\';
RawCFolder ='C:\Users\Meghan McLeod\Dropbox\BASULAB_meghan\Proposal\Lake Erie Data processing\LE_gauges\Extracting Data\USA\Gauge_discharge_WQ\ExtractedWQ\';

%GET PAIR DATA
%%

%Download the pairs we are interested in

opts = detectImportOptions([PairingFolder,'USA_gauge_ELEMENT_N.csv']);
opts = setvartype(opts,{'UniqueSitesBetweenDanykaAndLamisa'}, 'string'); % tuen the water quality IDs into strings so that the numbers are not rounded
pairs = readtable([PairingFolder,'USA_gauge_ELEMENT_N.csv'],opts);

gauges_WQ=pairs.UniqueSitesBetweenDanykaAndLamisa;

% add 0's to the beginning of the id's 
for i=1:length(gauges_WQ) 
    gauges_WQ{i} = append('0',gauges_WQ{i}); 
end

names = gauges_WQ;

%cleaning function
%%
for j = [1:length(names)] 
    
    %%
    
    RAW_WQ = readtable([RawCFolder,'WQ_',gauges_WQ{j},'.csv']); %from other sources
    RAW_Q = readtable([RawQFolder,gauges_WQ{j},'DischargeDaily.csv']); %from USGS
    
    
    % concentration --------------------------------------
    CRAW = [datenum(RAW_WQ.DATE) RAW_WQ.VALUE];
    CRAW = unique(CRAW,'rows');
    
    %date_cRAW = cRAW(:,1)+693960;
    DCraw = CRAW(:,1);
    Craw = CRAW(:,2);
    
    %clean
    Craw(isnan(DCraw))=[];
    DCraw(isnan(DCraw))=[];
    DCraw = datetime(datestr(DCraw));
    
    DCraw(isnan(Craw))=[];
    Craw(isnan(Craw))=[];
    
    DCraw(Craw==0)=[];
    Craw(Craw==0)=[];
    
    % discharge  --------------------------------------
    
    QRAW = [datenum(RAW_Q.Var4) RAW_Q.Var5]; %headers are missing but should be consistent since all from USGS
    QRAW = unique(QRAW,'rows');
    
    %date_qRAW = qRAW(:,1)+693960;
    DQraw = QRAW(:,1);
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
    
    Q_clean(Q_clean<0)=0; %incase of negatives!
    
    %saveas(gcf,[char(names(j)),'\Conc.datarange.png'])
    
    
    % --- only take Q which overlays C ----
    
    minDC = min(DC_clean);
    maxDC = max(DC_clean); 
    
    idxKeep = DQ_clean<=datenum(maxDC)&DQ_clean>=datenum(minDC);
    
    DQ_clean = DQ_clean(idxKeep); 
    Q_clean = Q_clean(idxKeep);
    
    figure()
    plot(DQ_clean,Q_clean)
    hold on 
    scatter (datenum(DC_clean), C_clean)
    hold off
    
    % ---------------------------------
    
    % changing date format
    DQ_clean = string(datestr(DQ_clean,'yyyy-mm-dd'));
    DC_clean = string(datestr(DC_clean,'yyyy-mm-dd'));
    

    
    %% write table
    T = table(DQ_clean,Q_clean);
    writetable(T,['Input_cleaned/',char(names(j)),'_clean_Q.csv'],'WriteVariableNames',true);
    
    T = table(DC_clean,NaN(length(C_clean),1),C_clean);
    writetable(T,['Input_cleaned/',char(names(j)),'_clean_C.csv'],'WriteVariableNames',true);
    
    
end
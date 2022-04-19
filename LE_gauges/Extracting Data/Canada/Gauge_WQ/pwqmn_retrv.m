% Script overview
%% ---
% Retrieve N water quality data for water quality stations in Lake
% 1964 - 2016 from the PWQMN excel files, to append onto Xiaoyi's data
% put in same file directory as 'pwqmn_rawdata_yyyy.xlsx' files
% chemical code id listed in variable 'id'
% replace strings in parmind with chemical code ids
% change time frame in variable 'yr'
% ---
clc, clear

%Getting station list
%%
pairDirectory = 'C:\Users\Meghan McLeod\Dropbox\BASULAB_meghan\Proposal\Lake Erie Data processing\LE_gauges\Gauge_pairing\CANADA\Meghan_lamisa_CAN pairs\';

%download the pairs, formatted properly
opts = detectImportOptions([pairDirectory,'CanadianSET.csv']);
opts = setvartype(opts, 'ID', 'string'); % tuen the water quality IDs into strings so that the numbers are not rounded
pairs = readtable([pairDirectory,'CanadianSET.csv'],opts);
pairs = pairs([1:24,26:31],:); %removing one station we already have data for (ERIE-specific)

IDList = pairs.ID;

%make sure buffer 0's are there if needed

for i=1:length(IDList)
    if length(IDList{i})<11
        IDList{i} = ['0',IDList{i}];
    end
end

% COLLECT DATA
%%

%get raw table
%get list of stations
stn_name=IDList;
%get variables of interest
id1 = 'NNOTFR';
id2 = 'NNOTUR';
id3 = 'NNO3FR';

yr = 2000:2016; % these are post-2000 years

for i = 1:length(stn_name)
    
    % pre-2000 to initiate
    %%
    
    RAW = readtable('PWQMN_1964_1999.xlsx');
    
    DATE = [];
    TYPE = [];
    DATA = [];
    UNIT = [];
    
    % find where in the data table this gaige is
    stnind = find(RAW{:,1}==stn_name(i));
    STN = RAW(stnind,:);
    parmind = find(string(STN{:,2})==id1|string(STN{:,2})==id2|string(STN{:,2})==id3);
    
    DATE = [DATE;STN{parmind,4}];
    TYPE = [TYPE;STN{parmind,2}];
    DATA = [DATA;STN{parmind,7}];
    UNIT = [UNIT;STN{parmind,12}];
    
    %now collect post-2000
    %%
    for j = 1:length(yr)
        
        RAW = readtable(['pwqmn_rawdata_',char(string(yr(j))),'.xlsx']);
        % find where in the data table this gauge is
        stnind = find(RAW{:,1}==stn_name(i));
        STN = RAW(stnind,:);
        parmind = find(string(STN{:,2})==id1|string(STN{:,2})==id2|string(STN{:,2})==id3);
        
        DATE = [DATE;STN{parmind,4}];
        TYPE = [TYPE;STN{parmind,2}];
        DATA = [DATA;STN{parmind,8}];
        UNIT = [UNIT;STN{parmind,11}];
        
    end
    
    %some wonky outliers in PWQMN .. remove rediculus ones 
    DATE = DATE(DATA<100&DATA>0);
    TYPE = TYPE(DATA<100&DATA>0);
    DATA = DATA(DATA<100&DATA>0);
    UNIT = UNIT(DATA<100&DATA>0);
    
    figure()
    scatter(DATE,DATA)
    saveas(gcf,['nitrate_',char(string(stn_name(i))),'_full','.png'])
    
    T = table(DATE,TYPE,DATA,UNIT);
    writetable(T,['pwqmn_',char(string(stn_name(i))),'_full','.xlsx'])            
    
end

scatter(DATE(DATA<100),DATA(DATA<100))



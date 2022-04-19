

% To be used after QualityCheck.m
% Takes WRTDS output of daily data of flow and concentration to yearly
% flow weighted mean concentrations
% takes daily date as Excel's general date number
%%
clc, clear, close all
%%
wrtdsOutputFolder = 'Output_wrtds\';
wrdsInputCleanFolder = 'Input_cleaned\';
foldir = dir([wrtdsOutputFolder,'\*.xlsx']);

%build a list of station names
stn_name = [];
for i = 1:length(foldir)
    stn_name = [stn_name; extractBetween(string(foldir(i).name),1,8)];
end
%%
for j = 1:length(stn_name)
    
    RAW = readtable([wrtdsOutputFolder,char(stn_name(j)),'_Results.xlsx']);
    WQ_orig = readtable([wrdsInputCleanFolder,char(stn_name(j)),'_clean_C.csv']);
    
    
    %find years which have WRTDS output but did not have WQ input - we need
    %to remove these years 
    
    rawCYears = WQ_orig.DC_clean;
    yearsRaw = unique(year(rawCYears)); %<- these are only the years of output we can accept 
    
    
    d = RAW{:,1};
    t = year(d);
    y = unique(t);              % unique years
    
    
    q = RAW{:,2};
    c = RAW{:,3};
    ind = q~=0;                 % get rid of 0 flows
    q = q(ind);
    c = c(ind);
    t = t(ind);                 % clean time vector (year only)
    d = d(ind);
    numYear = length(y);
    
    FWMC = NaN(numYear,1);
    FWMC_num = NaN(numYear,1);
    LOAD = NaN(numYear,1);
    AC = NaN(numYear,1);
    q_tot = NaN(length(y),1);       % total flow of year (m^3)
    q_avg = NaN(length(y),1);       % annual average Q (m^3/s)
    
    % find years with days of data missing
    t_incomp = [];
    for i = 1:numYear
        
        q_nan = q(~isnan(q(t==y(i))));
        
        if length(q_nan)< 365
            t_incomp = [t_incomp;y(i)];
        end
        
    end
    
    
    for i = 1:numYear
        
        qi = q(t==y(i));                        % Q of year i
        q_tot(i) = nansum(qi*86400);            % total Q (m^3)
        q_avg(i) = nanmean(qi);                    % average annual Q (m^3/s)
        ci = c(t==y(i));
        
        FWMC(i) = nansum(ci.*qi*1)/nansum(1*qi);        % mg/L
        LOAD(i) = nansum(ci.*qi/1000*86400);            % kg/yr ( 1day=86400 seconnd)
        AC(i)= (nansum (ci)/length (ci));
        %AC= asas' ;
        
    end
    
    
    
    fnamej = ['Output_yearly\',char(stn_name(j)),'_annavg.xlsx'];
    if exist(fnamej)
        delete(fnamej);
    else
    end
    
    % now - only accept output where the year was included as a WQ input===
    idx = ismember(y, yearsRaw);
    y=y(idx); 
    q_avg=q_avg(idx); 
    FWMC=FWMC(idx); 
    LOAD = LOAD(idx); 
    AC = AC(idx); 
    % =====================================================================
    
    writetable(table(y,q_avg,FWMC,LOAD,AC),fnamej);
    
    if ~isempty(t_incomp)
        xlswrite(['Output_yearly\',char(stn_name(j)),'_t_incomp.xlsx'],t_incomp);
    end
    
    Ta= table(y,q_avg,FWMC,LOAD,AC);
    writetable(Ta,['Output_yearly\',char(stn_name(j)),'_WRTDSyear.csv'],'WriteVariableNames',true);
    
    
    figure(1)
    fig1 = plot(y,LOAD,'o');
    title('Loading (kg/yr)')
    grid on
    
    figure(2)
    fig2 = plot(y,FWMC,'o');
    title('FWMC (mg/L)')
    grid on
    
    saveas(fig1,['Output_yearly\',char(stn_name(j)),'_loading.png'])
    saveas(fig2,['Output_yearly\',char(stn_name(j)),'_FWMC.png'])
    
    close all
end


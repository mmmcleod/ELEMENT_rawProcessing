

% To be used after QualityCheck.m
% Takes WRTDS output of daily data of flow and concentration to yearly
% flow weighted mean concentrations
% takes daily date as Excel's general date number

clc, clear, close all

% RAWINFO = readtable('C:\Users\Joy\Documents\ELEMeNT\Data\Water Quality\CQ_Station_Pairing.xlsx');

% foldir = dir('16018*');
% stn_name = [];
% 
% for i = 1:length(foldir)
% 
% stn_name = [stn_name; string(foldir(i).name)];
% 
% end

stn_name = "19.16018406702"; %_____SRP____________

for j = 1:length(stn_name)
    
RAW = readtable([char(stn_name(j)),'/',char(stn_name(j)),'_Results.xlsx']);
% RAW = readtable([char(stn_name(j)),'/',char(stn_name(j)),'_clean_Q.xlsx']);

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
a = length(y);

FWMC = NaN(a,1);
FWMC_num = NaN(a,1);
LOAD = NaN(a,1);
q_tot = NaN(length(y),1);       % total flow of year (m^3)
q_avg = NaN(length(y),1);       % annual average Q (m^3/s)

% find years with days of data missing
t_incomp = [];
for i = 1:a
    
    q_nan = q(~isnan(q(t==y(i))));      

    if length(q_nan)< 365
        t_incomp = [t_incomp;y(i)];
    end 
    
end


for i = 1:a
    
    qi = q(t==y(i));                        % Q of year i
    q_tot(i) = nansum(qi*86400);            % total Q (m^3)
    q_avg(i) = nanmean(qi);                    % average annual Q (m^3/s)
    ci = c(t==y(i));
        
    FWMC(i) = nansum(ci.*qi*1)/nansum(1*qi);        % mg/L
    LOAD(i) = nansum(ci.*qi/1000*86400);            % kg/yr ( 1day=86400 seconnd)
   asas(i)= (nansum (ci)/length (ci));  
   AC= asas' ;
    %FWMC_num(i) = nansum(ci.*qi*1);
end

% ind = find(ismember(string(RAWINFO{:,2}),stn_name(j)));
% if (RAWINFO{ind,7})~=0
%     if char(RAWINFO{ind,3})=='Q'
%         
%         exArea = RAWINFO{ind,7};
%         drArea = RAWINFO{ind,6};
%         frac = exArea/drArea;
%         Qj = q_avg;
%         LOADj = LOAD;
%         Q_corr = Qj+frac*Qj;
%         LOAD_corr = LOADj+frac*LOADj;
%     else
%         Q_corr = NaN(length(q_avg));
%         LOAD_corr = NaN(length(LOAD));
%     end  
% else
%       Q_corr = NaN(length(q_avg));
%       LOAD_corr = NaN(length(LOAD));
%     
% end

        fnamej = [char(stn_name(j)),'/',char(stn_name(j)),'_annavg.xlsx'];
        if exist(fnamej)
            delete(fnamej);
        else
        end

% writetable(table(y,q_avg,FWMC,LOAD,Q_corr,LOAD_corr),fnamej);
writetable(table(y,q_avg,FWMC,LOAD,AC),fnamej);

if ~isempty(t_incomp)
xlswrite([char(stn_name(j)),'/',char(stn_name(j)),'_t_incomp.xlsx'],t_incomp);
end

Ta= table(y,q_avg,FWMC,LOAD,AC)
writetable(Ta,[char(stn_name(j)),'/',char(stn_name(j)),'_WRTDSyear.csv'],'WriteVariableNames',true);


figure(1)
fig1 = plot(y,LOAD,'o');
title('Loading (kg/yr)')
grid on

figure(2)
fig2 = plot(y,FWMC,'o');
title('FWMC (mg/L)')
grid on

saveas(fig1,[char(stn_name(j)),'/',char(stn_name(j)),'_loading.png'])
saveas(fig2,[char(stn_name(j)),'/',char(stn_name(j)),'_FWMC.png'])

close all
end


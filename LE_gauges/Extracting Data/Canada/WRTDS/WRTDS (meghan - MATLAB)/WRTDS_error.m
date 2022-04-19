function [] = WRTDS_error(name, contam, row)


%   make graphs, 0 or 1
make_graphs = 1;

%   -----------------------------------------------------------------------

load(['Input_data','/',name,'/',name,'_',contam,'_weights.mat']);
load(['Input_data','/',name,'/',name,'_',contam,'_concentration_interp.mat']);

%   -----------------------------------------------------------------------
u = unique(DATE);
n = histc(DATE,u);
a = u(n>1);
for i = 1:length(a)
    loc = find(DATE==a(i));
    C(loc(1)) = mean(C(loc));
    C(loc(2):loc(end)) = [];
    Q(loc(1)) = mean(Q(loc));
    Q(loc(2):loc(end)) = [];
    DATE(loc(1)) = mean(DATE(loc));
    DATE(loc(2):loc(end)) = [];
end

dates = ismember(Q_date,DATE);
predicted_conc = c_interp_days(dates,2);

% % Remove zero values
% nonzero_days = predicted_conc~=0;
% predicted_conc = predicted_conc(nonzero_days);
% DATE = DATE(nonzero_days);
% C = C(nonzero_days);

% filter by season
DATES = datevec(DATE);

% C(DATES(:,2) < 6 | DATES(:,2) > 8) = [];
% predicted_conc(DATES(:,2) < 6 | DATES(:,2) > 8) = [];

% Mean Error
me = mean(predicted_conc-C)

% Mean Absolute Error
mae = sum(abs(predicted_conc-C));
mae = mae/length(predicted_conc)

% Root Mean Squared Error
rmse = sum((predicted_conc-C).^2);
rmse = sqrt(rmse/length(predicted_conc))

% Nash Sutcliffe Efficeny Coefficent
nse_top = sum((C-predicted_conc).^2);
nse_bottom = sum((C-mean(C)).^2);
nse = 1 - (nse_top/nse_bottom)

% Bias Calc
bias = (sum(predicted_conc)-sum(C))/sum(predicted_conc)

% Scatter Plot of Results
if make_graphs == 1
    i = figure(1)
    hold on
    scatter(C,predicted_conc)
    MaxPlot = max(max(predicted_conc),max(C));
    plot([0,MaxPlot],[0,MaxPlot],'k')
    
    xlabel('Observed Concentrations (mg/l)')
    ylabel('Predicted Concentrations (mg/l)')
    title(sprintf('Observed vs Predicted Values for Station %s',name))
    saveas(i,['Input_Data/',name,'/',name,'_',contam,'_Observed_Predicted_Concentration.png'])


    i = figure(2)
    loglog(Q,C./predicted_conc,'o')
    hold on
    loglog([10^1,10^3],[1,1],'k')
    xlabel('Observed Discharge (m^3/s)')
    ylabel('Observed Concentration/Predicted Concentration (-)')
    ylim([10^-2,10^2])
    title(sprintf('Predicted Concentrations vs Observed Discharge for Station %s',name))
    saveas(i,['Input_Data/',name,'/',name,'_',contam,'_Concentration_Discharge.png'])
    close all
end
    
% save data to excel sheet
catagories = {'Station','Mean Error','Mean Absolute Error','RMSE','NSE','Bias','# Samples'};
inputs = [{'Date'},{'Q'},{'C Raw'},{'C Est'}];
data = [DATE-693960,Q,C,predicted_conc];

% Excel_1 was the old one, from now on it will save as a more descriptive
% title
%xlswrite(['Input_data/',name,'/',name,'_Excel_1.xlsx'],inputs,contam,'A1:D1')
%xlswrite(['Input_data/',name,'/',name,'_Excel_1.xlsx'],data,contam,['A2:D',num2str(size(data,1))])

xlswrite(['Input_data/',name,'/',name,'_ErrorData.xlsx'],inputs,contam,'A1:D1')
xlswrite(['Input_data/',name,'/',name,'_ErrorData.xlsx'],data,contam,['A2:D',num2str(size(data,1))])

xlswrite('WRTDS_error_data.xlsx',catagories,['error_results_',contam],['A1:G1'])
xlswrite('WRTDS_error_data.xlsx',str2num(name),['error_results_',contam],['A',row])
xlswrite('WRTDS_error_data.xlsx',[me,mae,rmse,nse,bias,length(predicted_conc)],['error_results_',contam],['B',row,':G',row])
end
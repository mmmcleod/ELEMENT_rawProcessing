function [] = WRTDS_flux_bias_calc(name,contam,row)

%   plot and save observed vs predicted flux, 0 or 1
plot_flux = 1;
figure('Visible','off');
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

predict_flux = flux_interp_days(dates,2);
observed_flux = 86.4*Q.*C;

% % Remove zero values
% nonzero_days = predict_flux~=0;
% predict_flux = predict_flux(nonzero_days);
% DATE = DATE(nonzero_days);
% observed_flux = observed_flux(nonzero_days);

%   look at flux relationship
if plot_flux == 1
    hold on
    scatter(observed_flux,predict_flux)
    i = plot([1,max([observed_flux;predict_flux])],[1,max([observed_flux;predict_flux])]);
    xlabel('Observed Flux'), ylabel('Predicted Flux');
    saveas(i,['Input_Data/',name,'/',name,'_',contam,'_Observed_Predicted_Flux.png']);
    close
end

flux_bias = (sum(predict_flux)-sum(observed_flux))/sum(predict_flux);

% write to excel
xlswrite('WRTDS_error_data.xlsx',{'Site','FluxBias'},['flux_bias_',contam],['A1:B1'])
xlswrite('WRTDS_error_data.xlsx',str2num(name),['flux_bias_',contam],['A',num2str(row+1)])
xlswrite('WRTDS_error_data.xlsx',flux_bias,['flux_bias_',contam],['B',num2str(row+1)])
end
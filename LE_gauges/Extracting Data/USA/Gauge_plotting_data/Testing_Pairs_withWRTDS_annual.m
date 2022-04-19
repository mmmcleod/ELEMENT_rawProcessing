
clear
clc
close all

%% Download the pairs we are interested in

pathToGauges='C:\Users\Meghan McLeod\Dropbox\BASULAB_meghan\Proposal\Lake Erie Data processing\LE_gauges\Gauge_pairing\USA\';
opts = detectImportOptions([pathToGauges,'USA_gauge_ELEMENT_N.csv']);
opts = setvartype(opts, 'UniqueSitesBetweenDanykaAndLamisa', 'string'); % tuen the water quality IDs into strings so that the numbers are not rounded
pairs = readtable([pathToGauges,'USA_gauge_ELEMENT_N.csv'],opts);

gauges=pairs.UniqueSitesBetweenDanykaAndLamisa;

for i=1:length(gauges)
    gauges{i}=append('0',gauges{i});
end


%% Extract the WQ and the flow data for each and plot them on top of each other


plotNum=1; %used to keep track of plotting
for i =[1:length(gauges)]% extract all but york which we have
    this_gauge = gauges{i};
    
    %extract each pair's data
    pathToExtractedQ='C:\Users\Meghan McLeod\Dropbox\BASULAB_meghan\Proposal\Lake Erie Data processing\LE_gauges\Extracting Data\USA\Gauge_discharge_WQ\ExtractedDischarge\';
    this_Q_file = [pathToExtractedQ,this_gauge,'DischargeDaily.csv'];
    if i==21
        %just use last entry's table
    else
        this_Q_table = readtable(this_Q_file);
        this_Q_date = this_Q_table.Var4;
        this_Q_value = this_Q_table.Var5;
    end
    
    
    pathToExtractedWQ='C:\Users\Meghan McLeod\Dropbox\BASULAB_meghan\Proposal\Lake Erie Data processing\LE_gauges\Extracting Data\USA\Gauge_discharge_WQ\ExtractedWQ\';
    this_WQ_file = [pathToExtractedWQ,'WQ_',this_gauge,'.csv'];
    this_WQ_table = readtable(this_WQ_file);
    this_WQ_date = this_WQ_table.DATE;
    this_WQ_value = this_WQ_table.VALUE;
    
    
    pathToExtractedWRDTSWQ='C:\Users\Meghan McLeod\Dropbox\BASULAB_meghan\Proposal\Lake Erie Data processing\LE_gauges\Extracting Data\USA\WRTDS\Output_yearly\';
    this_WQ_wrtds_file = [pathToExtractedWRDTSWQ,char(this_gauge),'_annavg.xlsx'];
    this_WQ_wrtds_table = readtable(this_WQ_wrtds_file);
    this_WQ_wrtds_date = this_WQ_wrtds_table.y;
    this_WQ_wrtds_date=datetime(string(this_WQ_wrtds_date), 'Format', 'yyyy');
    this_WQ_wrtds_value = this_WQ_wrtds_table.FWMC;
    
    
    %throw in a figure for visualization
    subplot(4,5,plotNum)
    plotNum=plotNum+1;
    yyaxis left
    plot(this_Q_date,this_Q_value)
    yyaxis right
    scatter(this_WQ_date,this_WQ_value,'filled')
    hold on 
    scatter(this_WQ_wrtds_date,this_WQ_wrtds_value,'filled','k')
    legend('Raw Q','Raw WQ','Annual FWC')
    title({[char(this_gauge)]})
    
    %saveas(gcf,['testing_pair_data_',char(this_WQ),'_',this_Q,'.png'])
end

set(gcf, 'Units', 'Inches', 'Position', [0, 0, 21, 10.5], 'PaperUnits', 'Inches', 'PaperSize', [21, 10.5])
saveas(gcf,['testing_pair_data_with_annual_WRTDS.png'])




clear
clc
close all

runDaily=1;

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
for i =1:length(gauges)
    this_gauge = gauges{i};
    
    
    %extract each pair's data
    pathToExtractedQ='C:\Users\Meghan McLeod\Dropbox\BASULAB_meghan\Proposal\Lake Erie Data processing\LE_gauges\Extracting Data\USA\Gauge_discharge_WQ\ExtractedDischarge\';
    this_Q_file = [pathToExtractedQ,this_gauge,'DischargeDaily.csv'];
    
    this_Q_table = readtable(this_Q_file);
    this_Q_date = this_Q_table.Var4;
    this_Q_value = this_Q_table.Var5;
    
    
    
    pathToExtractedWQ='C:\Users\Meghan McLeod\Dropbox\BASULAB_meghan\Proposal\Lake Erie Data processing\LE_gauges\Extracting Data\USA\Gauge_discharge_WQ\ExtractedWQ\';
    this_WQ_file = [pathToExtractedWQ,'WQ_',this_gauge,'.csv'];
    this_WQ_table = readtable(this_WQ_file);
    this_WQ_date = this_WQ_table.DATE;
    this_WQ_value = this_WQ_table.VALUE;
    
    years = year(this_WQ_date);
    [Y,YR]=findgroups(years);
    yearlyWQ=splitapply(@mean,this_WQ_value,Y);
    
    
    %throw in a figure for visualization
    if runDaily==1
        subplot(4,5,plotNum)
        plotNum=plotNum+1;
        scatter(this_WQ_date,this_WQ_value,'filled')
        title({this_gauge})
        
    else
        subplot(4,5,plotNum)
        plotNum=plotNum+1;
        scatter(YR,yearlyWQ,'filled')
        title({this_gauge})
    end
    
    %saveas(gcf,['testing_gauge_data_',this_gauge,'.png'])
end

set(gcf, 'Units', 'Inches', 'Position', [0, 0, 21, 10.5], 'PaperUnits', 'Inches', 'PaperSize', [21, 10.5])
if runDaily==1
    saveas(gcf,['testing_WQ_data.png'])
else
    saveas(gcf,['testing_WQ_data_DAILY.png'])
end
    
    

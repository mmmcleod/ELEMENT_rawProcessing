
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
%     if (i==11|i==16)
%     this_WQ_date=this_WQ_date+693960+25200;
%     this_WQ_date = datetime(this_WQ_date,'ConvertFrom','datenum','Format','yyyy'); % makesure all are in datetime
%     end
    this_WQ_value = this_WQ_table.VALUE;
    
    %turn WQ into yearly averages -----------------------------------
    yearsWQ = unique(year(this_WQ_date));
    annualValWQ = yearsWQ*0;
    
    for j=1:length(yearsWQ) 
        yr = yearsWQ(j);
        thisYearIdx = year(this_WQ_date)==yr;
        thisYearWQ = this_WQ_value(thisYearIdx); 
        thisYearMean = mean(thisYearWQ); 
        annualValWQ(j)=thisYearMean;
    end
    %----------------------------------------------------------------------
 
    %throw in a figure for visualization
    subplot(4,5,plotNum)
    plotNum=plotNum+1;
    yyaxis left
    plot(this_Q_date,this_Q_value)
    yyaxis right
    scatter(datetime(string(yearsWQ),'Format','yyyy'),annualValWQ,'filled')
    %legend('Q','WQ')
    title({this_gauge})
    
    %saveas(gcf,['testing_gauge_data_',this_gauge,'.png'])
end

set(gcf, 'Units', 'Inches', 'Position', [0, 0, 21, 10.5], 'PaperUnits', 'Inches', 'PaperSize', [21, 10.5])
saveas(gcf,['testing_pair_data_annualWQ.png'])



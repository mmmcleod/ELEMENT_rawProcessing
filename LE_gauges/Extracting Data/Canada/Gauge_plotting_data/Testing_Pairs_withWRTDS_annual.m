
clear
clc
close all

%% Download the pairs we are interested in

pathToPairs='C:\Users\Meghan McLeod\Dropbox\BASULAB_meghan\Proposal\Lake Erie Data processing\LE_gauges\Gauge_pairing\CANADA\Meghan_lamisa_CAN pairs\';
opts = detectImportOptions([pathToPairs,'CanadianSET.csv']);
opts = setvartype(opts, 'ID', 'string'); % tuen the water quality IDs into strings so that the numbers are not rounded
pairs = readtable([pathToPairs,'CanadianSET.csv'],opts);

gauges_Q=pairs.QStationID; gauges_Q{21} = gauges_Q{20}; %for double
gauges_WQ=pairs.ID;

%add a 0 to gauges beginning with 4

for i=1:8
    gauges_WQ{i}=append('0',gauges_WQ{i});
end

% fix an odd gauge 
gauges_Q{9}='02GH003';


%% Extract the WQ and the flow data for each and plot them on top of each other


plotNum=1; %used to keep track of plotting
for i =[1:24,26:length(gauges_Q)]% extract all but york which we have
    this_Q = gauges_Q{i};
    this_WQ=gauges_WQ(i);
    
    %extract each pair's data
    pathToExtractedQ='C:\Users\Meghan McLeod\Dropbox\BASULAB_meghan\Proposal\Lake Erie Data processing\LE_gauges\Extracting Data\Canada\Gauge_Discharge\Flow\';
    this_Q_file = [pathToExtractedQ,this_Q,'_dailyQ.xlsx'];
    if i==21
        %just use last entry's table
    else
        this_Q_table = readtable(this_Q_file);
        this_Q_date = this_Q_table.Date;
        this_Q_value = this_Q_table.Value;
    end
    
    
    pathToExtractedWQ='C:\Users\Meghan McLeod\Dropbox\BASULAB_meghan\Proposal\Lake Erie Data processing\LE_gauges\Extracting Data\Canada\Gauge_WQ\';
    this_WQ_file = [pathToExtractedWQ,'pwqmn_',char(this_WQ),'_full.xlsx'];
    this_WQ_table = readtable(this_WQ_file);
    this_WQ_date = this_WQ_table.DATE;
    this_WQ_value = this_WQ_table.DATA;
    
    
    pathToExtractedWRDTSWQ='C:\Users\Meghan McLeod\Dropbox\BASULAB_meghan\Proposal\Lake Erie Data processing\LE_gauges\Extracting Data\Canada\WRTDS\Output_yearly\';
    this_WQ_wrtds_file = [pathToExtractedWRDTSWQ,char(this_WQ),'_annavg.xlsx'];
    this_WQ_wrtds_table = readtable(this_WQ_wrtds_file);
    this_WQ_wrtds_date = this_WQ_wrtds_table.y;
    this_WQ_wrtds_date=datetime(string(this_WQ_wrtds_date), 'Format', 'yyyy');
    this_WQ_wrtds_value = this_WQ_wrtds_table.FWMC;
    
    
    %throw in a figure for visualization
    subplot(5,6,plotNum)
    plotNum=plotNum+1;
    yyaxis left
    plot(this_Q_date,this_Q_value)
    yyaxis right
    scatter(this_WQ_date,this_WQ_value,'filled')
    hold on 
    scatter(this_WQ_wrtds_date,this_WQ_wrtds_value,'filled','k')
   % legend('Raw Q','Raw WQ','Annual FWC')
    title({[char(this_WQ)]})
    
    %saveas(gcf,['testing_pair_data_',char(this_WQ),'_',this_Q,'.png'])
end

set(gcf, 'Units', 'Inches', 'Position', [0, 0, 21, 10.5], 'PaperUnits', 'Inches', 'PaperSize', [21, 10.5])
saveas(gcf,['testing_pair_data_with_annual_WRTDS.png'])



clc, clear, format compact

ListContam = [{'total phosphorus'}]; %[{'orthophosphate'}, {'total phosphorus'},{'nitrate'}, {'doc'}, {'iron'}];
set(0,'DefaultFigureVisible','off')

for j = 1:length(ListContam)
    
% define folder (station number) to run, type 'all' to run all
inputs = {'all'};

contam = ListContam{j};

% create list of data inputs
if strcmp(inputs,'all') == 1
     folders = dir('Input_data');
     folders = folders(3:end);
else
     folders = 1;
end

for i = 1:length(folders)
    if strcmp(inputs,'all') == 1
        name = folders(i).name;
    else
        name = inputs{1};
    end
    
    name
    contam
    
    try
        xlsread(['Input_data','/',name,'/',name,'.xlsx'],contam);
    catch
        continue
    end

   WRTDS_weights(name,contam)
   WRTDS_concentration_interp(name,contam)
%  WRTDS_flow_norm(name,contam)   
%  WRTDS_flow_norm_decades(name,contam)
   WRTDS_flux_bias_calc(name, contam, i) 
   WRTDS_error(name, contam, num2str(i+1))

end

end

function [admin_pop_kg,input_ID]=county_element_pop(YEAR,admin_ID)

load ('INPUTS/POP.mat')% calculate inputs for all years, with linear interpolation

% between census years

T=pop_inputs;

% list of county IDs
input_ID = str2double(strip(string(cell2mat(T.Properties.VariableNames...
    (2:end)')),'x'));
% list of census years 
Y_inputs=T{:,1};

%length of years we want to simulate 
entY=length(YEAR);
%number of IDs 
entID=length(admin_ID);
%number of census years included 
entI=length(Y_inputs);
%actual census population data 
admin_pop_input=T{:,2:end};
%new population matrix we want to populate 
admin_pop=NaN(entY,entID);

% admin_pop_frac=NaN(entY,entID);

%start date 
Y_start=Y_inputs(1);
%overwrite for now 
Y_start=1931; 

for k = 1:entID
    
    ind = find(input_ID==admin_ID(k));
    for i=1:entY
        for j=1:entI
            if YEAR(i)==Y_inputs(j)
                admin_pop(i,k)=admin_pop_input(j,ind);
            end
        end
    end
end

% now only census years are filled in - the rest are NaN .... 


%  Bring in coarser historical timeseries

%ontario data series 
T=pop_hist_inputs;
%M is historical 
M=T{:,:};

M2=sortrows(M);
entM2=size(M2,1);
%create a population vector the length of simulation 
pop_hist=NaN(entY,1);

% populate pop_hist with historical dataset 
for i=1:entY
    for j=1:entM2
        if YEAR(i)==M2(j,1)
            pop_hist(i)=M2(j,2);
        end
    end
end

%account for earlier years
pop_hist_start=M2(1,1);

for i=1:entY
    if YEAR(i)<pop_hist_start
        pop_hist(i)=M2(1,2);
    end
end



%  Fill in gaps in historical time series

pop_hist=fillmissing(pop_hist,'linear');



%  Use historical time series to populate gaps in time series for
%  individual admin units

for i=1:entY
    for j=1:entID
        if YEAR(i)==Y_start
            coeff(j)=admin_pop_input(1,j)/pop_hist(i);
        end
    end
end



for i=1:entY
    if YEAR(i)==Y_start
        pin=i;
    end
end

if exist('coeff')
    
    for i=1:entY
        for j=1:entID
            if i<pin
                admin_pop(i,j)=coeff(j)*pop_hist(i);
            end
        end
    end
    
else
    
    for i=1:entY
        for j=1:entID
            if i<pin
                admin_pop(i,:)=admin_pop_input(1);
            end
        end
    end
    
end

% Fill in remaining gaps, linear interpolation

for i=1:entID
    admin_pop(:,i)=fillmissing(admin_pop(:,i),'linear');
    admin_pop_kg(:,i)=admin_pop(:,i)*pop_param; 
end

end




function [admin_dep]=county_element_dep(YEAR,admin_ID,input_ID,START)

load 'INPUTS/DEP.mat'

T=total_deposition;  %inputs in what unit?? 

YR=1800:2018;%global dataset 
entYR=length(YR);
Y_inputs=unique(YR);

entY=length(YEAR);
entID=length(admin_ID);
entI=length(Y_inputs);

admin_dep_input = T{:,2:end}';

admin_dep = NaN(entY,entID);

% Create yearly input matrix

for i=1:entY
    for j=1:entI
        for k=1:entID
            for m=1:length(input_ID)
                if admin_ID(k)==input_ID(m)
                    if YEAR(i)==START
                        admin_dep(i,k)=admin_dep_input(1,m);
                    elseif YEAR(i)==1860
                        admin_dep(i,k)=admin_dep_input(1,m);
                    elseif YEAR(i)==Y_inputs(j)
                        admin_dep(i,k)=admin_dep_input(j,m);
                    elseif YEAR(i)>Y_inputs(end)
                        admin_dep(i,k)=admin_dep_input(end,m);
                    end
                end
            end
        end
    end
end

for i=1:entID
    admin_dep(:,i)=fillmissing(admin_dep(:,i),'linear');
end

end



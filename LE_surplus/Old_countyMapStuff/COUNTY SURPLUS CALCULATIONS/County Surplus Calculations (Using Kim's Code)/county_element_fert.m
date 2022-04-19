
function [admin_fert]=county_element_fert(YEAR,admin_ID,input_ID)

load 'INPUTS/FERT.mat' % kg


T=fert_inputs;

% calculate inputs for all years, with linear interpolation
% between census years

Y_inputs=T{:,1};

entY=length(YEAR);
entID=length(admin_ID);

Y_start=min(Y_inputs);

%entY=length(YEAR);
entI=length(Y_inputs);
entID=length(admin_ID);

admin_fert_input=T{:,2:end};
admin_fert=NaN(entY,entID);
admin_fert_frac=NaN(entY,entID);



%admin_fert_temp=admin_fert(:,i);
for i=1:entY
    for j=1:entI
        if YEAR(i)<=Y_start;
            for k=1:entID
                for m=1:length(input_ID)
                    if admin_ID(k)==input_ID(m)
                        admin_fert(i,k)=admin_fert_input(1,m);
                    end
                end
            end
        end
        if YEAR(i)==Y_inputs(j)
            for k=1:entID
                for m=1:length(input_ID)
                    if admin_ID(k)==input_ID(m)
                        admin_fert(i,k)=admin_fert_input(j,m);
                    end
                end
            end
        elseif and(YEAR(i)>Y_inputs(end),YEAR(i)>Y_inputs(end-1))
            for k=1:entID
                for m=1:length(input_ID)
                    if admin_ID(k)==input_ID(m)
                        admin_fert(i,k)=admin_fert_input(end,m);
                    end
                end
            end
        end
    end
end


for k=1:entID
    admin_fert(:,k)=fillmissing(admin_fert(:,k),'linear');
end




end



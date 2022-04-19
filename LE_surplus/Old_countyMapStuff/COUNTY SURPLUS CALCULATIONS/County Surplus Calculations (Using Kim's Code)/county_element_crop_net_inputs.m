function [a_c]=element_crop_net_inputs(SCENARIO,YearsToExtend,reductionCoeff,fert_ha_cropland,dep_ha_cropland,man_ha_crop,bnf_ha_cropland,crop_ha_cropland,YEAR)

% get the index of the YEAR vector of where we change from past to future 
idx=YEAR==(YEAR(end)-YearsToExtend);
% get the actual index placeholder 
ent=length(YEAR);
numYears=1:ent;
e=numYears(idx);



if SCENARIO == 0 %(no future)
    a_c=fert_ha_cropland+dep_ha_cropland+man_ha_crop+bnf_ha_cropland-crop_ha_cropland;
end

INTERVENTION=YEAR(e); % last year of 'present'

% now consider future
for i=1:ent
    if YEAR(i)<=INTERVENTION %(not in future)
        a_c(i)=fert_ha_cropland(i)+dep_ha_cropland(i)+man_ha_crop(i)+bnf_ha_cropland(i)-crop_ha_cropland(i);
    else 
        if SCENARIO == 1 %(BAU)
            a_c(i)=fert_ha_cropland(e)+dep_ha_cropland(e)+man_ha_crop(e)+bnf_ha_cropland(e)-crop_ha_cropland(e);
        elseif SCENARIO == 2 % (0 Ag) 
            a_c(i)=0;
        elseif SCENARIO == 3 % percent reduction from last year 
            a_c(i)=(reductionCoeff/100)*(fert_ha_cropland(e)+dep_ha_cropland(e)+man_ha_crop(e)+bnf_ha_cropland(e)-crop_ha_cropland(e));
        end
    end
end

X1=YEAR;
Y1=fert_ha_cropland;
Y2=dep_ha_cropland;
Y3=man_ha_crop;
Y4=bnf_ha_cropland;
Y5=crop_ha_cropland;
Y6=a_c;

% element_cropland_N_bal_fig(X1, Y1, Y2, Y3, Y4, Y5, Y6)

% close all

end



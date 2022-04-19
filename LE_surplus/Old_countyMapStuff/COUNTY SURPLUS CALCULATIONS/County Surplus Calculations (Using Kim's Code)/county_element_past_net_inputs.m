
function [a_p]=element_past_net_inputs(SCENARIO,YearsToExtend,reductionCoeff,dep_ha_pastland,man_ha_past,fert_ha_pastland,bnf_ha_pastland,consumption_ha_past,YEAR,bnf_n);

bnf_background=bnf_n(1);  %kg/ha, BNF not ready to be varied yet

entY=length(YEAR);
bnf_background=bnf_background*ones(entY,1);

% now considering the future
% =====================================
% get the index of the YEAR vector of where we change from past to future
idx=YEAR==(YEAR(end)-YearsToExtend);
% get the actual index placeholder
ent=length(YEAR);
numYears=1:ent;
e=numYears(idx);

if SCENARIO ==0 % not going into the future, nothing changes 
    a_p=dep_ha_pastland+man_ha_past+bnf_ha_pastland+fert_ha_pastland-consumption_ha_past;
end

INTERVENTION=YEAR(e); % last year of 'present'

% now consider future
for i=1:ent
    if YEAR(i)<=INTERVENTION %(not in future)
        a_p(i)=dep_ha_pastland(i)+man_ha_past(i)+bnf_ha_pastland(i)+fert_ha_pastland(i)-consumption_ha_past(i);
    else 
        if SCENARIO == 1 %(BAU)
            a_p(i)=dep_ha_pastland(e)+man_ha_past(e)+bnf_ha_pastland(e)+fert_ha_pastland(e)-consumption_ha_past(e);
        elseif SCENARIO == 2 % (0 Ag) 
            a_p(i)=0;
        elseif SCENARIO == 3 % percent reduction from last year 
            a_p(i)=(reductionCoeff/100)*(dep_ha_pastland(e)+man_ha_past(e)+bnf_ha_pastland(e)+fert_ha_pastland(e)-consumption_ha_past(e));
        end
    end
end


X1=YEAR;
Y1=fert_ha_pastland;
Y2=dep_ha_pastland;
Y3=man_ha_past;
Y4=bnf_ha_pastland;
Y5=consumption_ha_past;
Y6=a_p;
%
% element_cropland_N_bal_fig(X1, Y1, Y2, Y3, Y4, Y5, Y6)
%
% close all

end
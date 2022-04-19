
function [admin_bnf_kg]=county_element_bnf(YEAR,admin_ID,admin_prod,CROP_ID);
% [bnf_ha_wshd bnf_ha_cropland bnf_ha_pastland bnf_ha_non_ag]=element_bnf(YEAR,admin_ID,admin_AREA,admin_FRAC,AREA,LU_summary,admin_prod,bnf_n,CROP_ID);
load 'INPUTS/BNF.mat'

% calculate inputs for all years, with linear interpolation
% between census years

%length of simulation period
entY=length(YEAR);
%number of counties 
entID=length(admin_ID);
%summary with dimensions years, bnf crops, counties 
BNF_summary = NaN(entY,size(BNF_info,1),entID);

for m = 1:size(BNF_info,1)
    
    ind = find(CROP_ID==BNF_info.Code(m));
    BNF_summary(:,m,:) = admin_prod(:,ind,:)*BNF_info{m,3};     % take crop N production (kg crop) and find kg N fixed
    
end

%------------------------------------------------------------------
%simply sum over the crops to get a value for each county 

admin_bnf_kg=squeeze(sum(BNF_summary,2));

end
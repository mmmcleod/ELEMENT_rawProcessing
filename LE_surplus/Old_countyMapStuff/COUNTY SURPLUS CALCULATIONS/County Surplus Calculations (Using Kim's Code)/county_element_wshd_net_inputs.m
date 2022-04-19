
function [a_wshd]=element_wshd_net_inputs(YEAR,AREA,LU_summary,a_c,a_n,a_p)
% ,man_ha_agland_runoff

crop_component=a_c;%+man_ha_agland_runoff;
past_component=a_p;%+man_ha_agland_runoff;
non_ag_component=a_n;

% % % % temporary fix 
crop_component = ones(size(a_n));
for i = 1:length(a_n(1,:))
    crop_component(:,i) = a_c';
end

past_component = ones(size(a_n));
for i = 1:length(a_n(1,:))
    past_component(:,i) = a_p';
end


for i=1:length(YEAR)
    a_wshd(i,:)=crop_component(i,:)*LU_summary(i,2)+past_component(i,:)*LU_summary(i,3)+non_ag_component(i,:)*(1-sum(LU_summary(i,2:3)));  %kg/ha
end
end

% X1=YEAR;
% Y1=fert_ha_wshd;
% Y2=dep_ha_wshd;
% Y3=man_ha_wshd;
% Y4=crop_ha_wshd;
% Y5=a_wshd;
% 
% element_fig_wshd_P_bal(X1, Y1, Y2, Y3, Y4, Y5)







function [admin_prod,admin_N_prod, admin_crop_area,CROP_ID]=county_element_crop_prod(YEAR,admin_ID,input_ID)

load 'INPUTS/CROP.mat'

%grab crop areas of each county over the years
T=crop_area;
%grab the years that crop areas are available (census)
YR=T{:,3};
Y_inputs=unique(YR);
%grab the number of years we have crop area available times crops
entYR=length(YR);

%grab the IDs of the crops
CROP_ID_inputs=T{:,1};
CROP_ID=unique(CROP_ID_inputs);

%remove crops less than 1% of watershed area

%retrieve the number of crops considered
entCROP=length(CROP_ID);
%extreact the areas
M=T{:,4:end};  % county crop area in hectares

%extract length of county IDs
entID_in=length(input_ID);

%get length of simulated years
entY=length(YEAR);
%get length of simulated counties
entID=length(admin_ID);
% get length of available years
entI=length(Y_inputs);

%crop area by county
admin_crop_area_input=M;
%build a 3d matrix for crop with dimentions year, county id, crop id
admin_crop_area=NaN(entY,entCROP,entID);

Y_start=Y_inputs(1);
%overwrite
Y_start=1931;

Y_end=Y_inputs(end);
%overwrite
Y_end=2016;


% Create Complete Matrix of Crop Areas

for i=1:entY
    for m=1:entYR
        if YEAR(i)==YR(m)
            for j=1:entCROP
                if CROP_ID_inputs(m)==CROP_ID(j)
                    for k=1:entID
                        for n=1:entID_in
                            if input_ID(n)==admin_ID(k)
                                admin_crop_area(i,j,k)=admin_crop_area_input(m,n);
                            end
                        end
                    end
                end
            end
        end
    end
end

% ..... now we should have a matrix (3d) for all of the years, but only census
% years are NaN



% Combine alfalfa and other hay data to calculate for other hay data
% for years where there is only "all hay" data using first 3 census years of data

alfalfaIDX = find(CROP_info.CROP_ID==1001);
otherhayIDX= find(CROP_info.CROP_ID==1011);
allhayIDX = find(CROP_info.CROP_ID==1010);

alfalfa_area_temp=squeeze(admin_crop_area(:,alfalfaIDX,:));

for i=1:entY
    for k=1:entID
        if YEAR(i)<1931
            idx=find(ismember(YEAR,[1931 1941 1951]));
            alfalfa_area_temp2=alfalfa_area_temp(idx,:);
            alfalfa_area_mean_temp=nanmean(alfalfa_area_temp2,1);
            other_hay_temp=squeeze(admin_crop_area(:,otherhayIDX,:));
            other_hay_temp=other_hay_temp(idx,:);
            other_hay_mean_temp=nanmean(other_hay_temp,1);
            all_mean_temp=alfalfa_area_mean_temp+other_hay_mean_temp;
            hay_coeff=alfalfa_area_mean_temp./all_mean_temp;
            admin_crop_area(i,1,k)=admin_crop_area(i,allhayIDX,k)*hay_coeff(k);
            admin_crop_area(i,otherhayIDX,k)=admin_crop_area(i,allhayIDX,k)*(1-hay_coeff(k));
        elseif YEAR(i)==1986
            idx = [i-5 i+5];
            alfalfa_area_temp2=alfalfa_area_temp(idx,:);
            alfalfa_area_mean_temp=nanmean(alfalfa_area_temp2,1);
            other_hay_temp=squeeze(admin_crop_area(:,otherhayIDX,:));
            other_hay_temp=other_hay_temp(idx,:);
            other_hay_mean_temp=nanmean(other_hay_temp,1);
            all_mean_temp=alfalfa_area_mean_temp+other_hay_mean_temp;
            hay_coeff=alfalfa_area_mean_temp./all_mean_temp;
            admin_crop_area(i,1,k)=admin_crop_area(i,allhayIDX,k)*hay_coeff(k);
            admin_crop_area(i,11,k)=admin_crop_area(i,10,k)*(1-hay_coeff(k));
        end
        
    end
end

% eliminate crops less than threshold value of watershed area or for other top-down
% reasons

thresh=0.001;

crop_per=NaN(entY,entCROP);
admin_crop_area_temp_1=NaN(entY,entCROP);
admin_crop_area_temp_2=NaN(entY,entCROP);

for i=1:entY
    for j=1:entCROP
        admin_crop_area_temp_1(i,j)=nansum(admin_crop_area(i,j,:));
    end
    admin_crop_area_temp_2(i)=nansum(admin_crop_area_temp_1(i,:));
    for j=1:entCROP
        crop_per(i,j)=admin_crop_area_temp_1(i,j)/admin_crop_area_temp_2(i);
    end
end

crop_per_mean=NaN(entCROP,1);
crop_include=NaN(entCROP,1);

for j=1:entCROP
    crop_per_mean(j)=nanmean(crop_per(:,j));
    if crop_per_mean(j)<thresh
        crop_include(j)=0;
    else
        crop_include(j)=1;
    end
end

idx=crop_include==1;
CROP_ID=CROP_ID(idx);
admin_crop_area=admin_crop_area(:,idx,:);

%remove 'all hay'

idx=CROP_ID~=1010;
admin_crop_area=admin_crop_area(:,idx,:);
CROP_ID=CROP_ID(idx);
entCROP=length(CROP_ID);

% Give zero values to soybeans prior to 1951

for i=1:entY
    for j=1:entCROP
        if CROP_ID(j)==1018
            if YEAR(i)<1951
                admin_crop_area(i,j,:)=0;
            end
        end
    end
end

% Give zero values to canola prior to 1976

for i=1:entY
    for j=1:entCROP
        if CROP_ID(j)==1005
            if YEAR(i)<1976
                admin_crop_area(i,j,:)=0;
            end
        end
    end
end



% allow for future scenarios

for j=1:entCROP
    crop_temp=squeeze(admin_crop_area(:,j,:));
    for k=1:entID
        idx=crop_temp(:,k)>=0;
        YEAR_temp=YEAR(idx);
        YEAR_max(j,k)=max(YEAR_temp);
        idx=YEAR==YEAR_max(j,k);
        for i=1:entY
            if idx(i)==1
                e(j,k)=i;
            end
        end
        admin_crop_area(end,j,k)=admin_crop_area(e(j,k),j,k);
    end
end



% Fill Missing

for j=1:entCROP
    for k=1:entID
        admin_crop_area(:,j,k)=fillmissing(admin_crop_area(:,j,k),'linear');
    end
end

% .... now area should be interpolated per county for the yearly simulated
% period

T=crop_yield; %kg/ha

% Census year yields only ----------------------------------------

Y_area = unique(crop_area{:,3});
idx = find(ismember(T{1,:},string(Y_area)));
T = T(:,[1:2,idx]);

% 2001 to 2003 were particularly low yield years, using 2000 as an
% interpolation year for 1997-2000
idx = find(crop_yield{1,:}=="2000");
T = [T(:,1:15),table(crop_yield{:,idx}),T(:,16:end)];


% ----------------------------------------------------------------

entCROP=length(CROP_ID);
admin_prod=NaN(entY,entCROP,entID);

CROP_ID_inputs=T{2:end,2};
CROP_ID_in=unique(CROP_ID_inputs);
entCROP_in=length(CROP_ID_in);

admin_yield=T{2:end,3:end}; %kg/ha

Y_yield=T{1,3:end};
entYR=length(Y_yield);

for i=1:entY
    for m=1:entYR
        if YEAR(i)<Y_yield(1)
            for j=1:entCROP
                for n=1:entCROP_in
                    if CROP_ID(j)==CROP_ID_inputs(n)
                        % get first 10 years of yield data to average
                        % for previous years
                        [M yield_idx] = min(abs(Y_yield-(Y_yield(1)+10)));
                        yield_temp=nanmean(admin_yield(n,1:yield_idx));
                        if nansum(admin_crop_area(i,j,:))==0
                            for k=1:entID
                                if admin_crop_area(i,j,k)~=0
                                    admin_prod(i,j,k)=admin_crop_area(i,j,k)*yield_temp;
                                else
                                    admin_prod(i,j,k)=0;
                                end
                            end
                        else
                            admin_prod(i,j,:)=admin_crop_area(i,j,:)*yield_temp;
                        end
                        
                    end
                end
            end
        elseif YEAR(i)==Y_yield(m)
            for j=1:entCROP
                for n=1:entCROP_in
                    if CROP_ID(j)==CROP_ID_inputs(n)
                        for k=1:entID
                            if admin_crop_area(i,j,k)~=0
                                admin_prod(i,j,k)=admin_crop_area(i,j,k)*admin_yield(n,m);
                            else
                                admin_prod(i,j,k)=0;
                            end
                        end
                    end
                end
            end
        end
        
    end
    
end

idx=YEAR==Y_yield(end);
for i=1:entY
    if idx(i)==1
        e=i;   %last year of yield input data
    end
end


% Fill Missing

for j=1:entCROP
    for k=1:entID
        admin_prod(:,j,k)=fillmissing(admin_prod(:,j,k),'linear');
    end
end

% ... now we have interpolated crop production AND area

% Load Parameters to convert crop production to N production

PARAM_ID=CROP_info{:,1};
entP=length(PARAM_ID);

admin_N_prod=NaN(entY,entCROP,entID);

for i=1:entY
    for j=1:entCROP
        for p=1:entP
            if CROP_ID(j)==PARAM_ID(p)
                admin_N_prod(i,j,:)=admin_prod(i,j,:)*N_content.N(p)*per_dry_matter.per_dry_area(p);
            end
        end
        
    end
    

end

%     ---------------------------------------------------------------------

% sum together all of the crops so each county has one mass 
admin_N_prod=squeeze(sum(admin_N_prod,2));
end


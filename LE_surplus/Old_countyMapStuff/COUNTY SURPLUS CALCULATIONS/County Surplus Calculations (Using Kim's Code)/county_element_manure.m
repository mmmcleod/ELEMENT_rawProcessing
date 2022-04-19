
function [admin_man,admin_consumption]=county_element_manure(YEAR,admin_ID,input_ID)

load 'INPUTS/LVSTK.mat'
load 'INPUTS/POP.mat'
pop_hist = pop_hist_inputs;

%load livestock inputs
T=lvstk_inputs;

%get years
YR=T{:,3};
entYR=length(YR);
Y_inputs=unique(YR);

%get counties
ID_inputs=T.ID;
ID=unique(ID_inputs);
entLVSTK=length(ID);
admin_ID_ind = find(ismember(input_ID,admin_ID));

%grab the data alone (without years and lvstk names)
M=T{:,admin_ID_ind+3};

%get counts
entY=length(YEAR);
entID=length(admin_ID);
entI=length(Y_inputs);

admin_lvstk_input=M;
admin_lvstk=NaN(entY,entLVSTK,entID);
admin_man=NaN(entY,entLVSTK,entID);


Y_start=Y_inputs(1);
%overwrite
Y_start = 1931;

% Load Parameters for manure nutrient content and distribution to different
% land types

T=lvstk_params;

ID_params=T.ID;

excr=T.EXCRETION;  %kg N excreted annually per animal (kg-N/animal/yr)
cons=T.CONSUMPTION; %kg N consumed annually per animal (kg-N/animal/yr)


entP=length(ID_params);
coeff=NaN(entLVSTK,entID);

%  Scale livestock values to human population prior to first year of data

for i=1:entY
    for m=1:entYR
        if YEAR(i)==Y_start
            if YEAR(i)==YR(m)
                for j=1:entLVSTK
                    for k=1:entID
                        if ID_inputs(m)==ID(j)
                            coeff(j,k)=admin_lvstk_input(m,k)/pop_hist.POP(i);
                        end
                    end
                end
            end
        end
    end
end



for j=1:entLVSTK
    for k=1:entID
        for m=1:length(input_ID)
            if admin_ID(k)==input_ID(m)
                for i=1:entY
                    if YEAR(i)<Y_start
                        admin_lvstk(i,j,k)=pop_hist.POP(i)*coeff(j,k);
                    end
                    for n=1:entYR
                        if YEAR(i)==YR(n)
                            if ID(j)==ID_inputs(n)
                                admin_lvstk(i,j,k)=admin_lvstk_input(n,k);
                            end
                        end
                    end
                end
            end
        end
    end
end

idx=YEAR==Y_inputs(end);
for i=1:entY
    if idx(i)==1
        e=i;   %last year of input data
    end
end

% Fill in remaining gaps, linear interpolation

for j=1:entLVSTK
    for k=1:entID
        admin_lvstk(:,j,k)=fillmissing(admin_lvstk(:,j,k),'linear');
    end
end

% Convert livestock numbers to kg-N

admin_consumption=NaN(entY,entLVSTK,entID);


for i=1:entY
    for j=1:entLVSTK
        for k=1:entID
            for m=1:entP
                if ID(j)==ID_params(m)
                    admin_man(i,j,k)=admin_lvstk(i,j,k)*excr(m);  %kg-N per year
                    admin_consumption(i,j,k)=admin_lvstk(i,j,k)*cons(m);  %kg-N per year, consumed
                    
                end
            end
            
        end
        
    end
    
    
end

% add up all livestock types 
admin_man = squeeze(sum(admin_man,2));
admin_consumption = squeeze(sum(admin_consumption,2));

end

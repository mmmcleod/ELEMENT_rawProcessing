function [] = WRTDS_concentration_interp(name, contam)
%   Function takes weights from WRTDS_weights and uses them to give daily
%   concentration estimates. Deisgned for use with the input_fetch.m file.

%   -----------------------------------------------------------------------

load(['Input_data','/',name,'/',name,'_',contam,'_weights.mat']);

%   -----------------------------------------------------------------------

% use assigned weights to predict concentrations at each observation

C_hat_adj = zeros(1,entQ);
for i = 1:entQ
    for j = 1:entY
        if VQ(i,1)~=YEAR(j)
            continue
        end
        int_yr = [j,j];
        for k = 1:12
            if VQ(i,2)~=k
                continue
            end
            x = [k,k+1];
            if k == 12 && int_yr(2) ~= entY
                x(2) = 1;
                int_yr(2) = j+1;
            elseif k ==12
                x(2) = k;
            end
            xq = VQ(i,3)/31;
            for m=2:entQR
                if ln_Q_raw(i)>Q_raw_rng_ln(m-1) && ln_Q_raw(i)<=Q_raw_rng_ln(m)
                    y = [m-1;m];
                    yq = (m-1)+(ln_Q_raw(i)-Q_raw_rng_ln(m-1))/(Q_raw_rng_ln(m)-Q_raw_rng_ln(m-1));
                    v = [permute(coeff(int_yr(1),x(1),y(1),:),[4,1,2,3]), ...
                        permute(coeff(int_yr(2),x(2),y(1),:),[4,1,2,3]), ...
                        permute(coeff(int_yr(1),x(1),y(2),:),[4,1,2,3]), ...
                        permute(coeff(int_yr(2),x(2),y(2),:),[4,1,2,3])];
                    vq = zeros(5,1);
                    x = [0,1];
                    for n = 1:5
                        if x(1) == x(2) || y(1) == y(2)
                            vq(n) = coeff(j,k,m,n);
                            continue
                        end
                        vq(n) = interp2(x,y,[v(n,1:2);v(n,3:4)],xq,yq);
                    end
                    ln_C_hat_raw(i)=vq(1)+vq(2)*t_data_raw(i)+vq(3)*ln_Q_raw(i)+vq(4)*sin(2*pi*DY_raw_frac(i))+vq(5)*cos(2*pi*DY_raw_frac(i));
                    C_hat(i)=exp(ln_C_hat_raw(i));
                    C_hat_adj(i)=alph(j,k,m)*exp(ln_C_hat_raw(i))-1;
                elseif m == entQR
                    ln_C_hat_raw(i)=coeff(j,k,m,1)+coeff(j,k,m,2)*t_data_raw(i)+coeff(j,k,m,3)*ln_Q_raw(i)+coeff(j,k,m,4)*sin(2*pi*DY_raw_frac(i))+coeff(j,k,m,5)*cos(2*pi*DY_raw_frac(i));
                    C_hat(i)=exp(ln_C_hat_raw(i));
                    C_hat_adj(i)=alph(j,k,m)*exp(ln_C_hat_raw(i))-1;
                end
            end
        end
    end
end

% find monthly and yearly average concentrations
month_means = zeros(length(YEAR),12);
month_means2 = zeros(length(YEAR)*12,1);
MONTHS = zeros(length(YEAR)*12,1);
year_means = zeros(length(YEAR),1);
for i = 1:length(YEAR)
    for k = 1:12
        C_month = C_hat_adj(VQ(:,1)==YEAR(i)&VQ(:,2)==k);
        month_means(i,k) = mean(C_month);
    end
    C_year = C_hat_adj(VQ(:,1)==YEAR(i));
    if sum(isnan(month_means(i,:))) ~= 0
        year_means(i) = NaN;
    else
        year_means(i) = mean(C_year);
    end
end
for  i = 1:length(YEAR)
    month_means2(12*i-11:12*i) = month_means(i,:);
    MONTHS(12*i-11:12*i) = YEAR(i)+linspace(0,11/12,12);
end

%prepare variables for export
c_interp_days = [Q_date,C_hat_adj'];
c_interp_months = [MONTHS, month_means2];
c_interp_years = [YEAR',year_means];

flux_interp_days = [Q_date,C_hat_adj'.*Q_raw*86.4]; %(mg/l)*(m3/s) to (kg/d)

%   -----------------------------------------------------------------------

save(['Input_data','/',name,'/',name,'_',contam,'_concentration_interp.mat'],...
    'c_interp_days','c_interp_months','c_interp_years','flux_interp_days','month_means');

inputs = [{'Date'},{'Q'},{'C Est'}];
data = [Q_date-693960,Q_raw,c_interp_days(:,2)];

xlswrite(['Input_data/',name,'/',name,'_Excel.xlsx'],inputs,contam,'A1:C1')
xlswrite(['Input_data/',name,'/',name,'_Excel.xlsx'],data,contam,['A2:C',num2str(size(c_interp_days,1))])

%   -----------------------------------------------------------------------
end
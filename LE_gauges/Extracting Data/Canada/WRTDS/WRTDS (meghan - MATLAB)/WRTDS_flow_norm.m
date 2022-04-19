function [] = WRTDS_flow_norm(name, contam)

'WRTDS_flow_norm'

% clc, clear
% % define input information
% name = '403702';
% contam = 'nitrates';

load(['Input_data','/',name,'/',name,'_',contam,'_weights.mat']);
% find each recorded discharge at each date
month_days =[1 32 61 92 122 153 183 214 245 275 306 336]-1;

ln_day_discharge = cell(366,1);
for k=1:12
    if k == 2
        days = 29;
    elseif sum(k == [4,6,9,11])==1
        days = 30;
    else
        days = 31;
    end
    for j = 1:days
        ln_day_discharge{month_days(k)+j}=log(Q_raw(VQ(:,2)==k&VQ(:,3)==j));
    end
end

% Calculate Concentration Values
% Use Interpolation While Finding Concentration
q_count = 0
for i = 1:entQ
    pot_discharge = ln_day_discharge{month_days(VQ(i,2))+VQ(i,3)};
	for p = 1:length(pot_discharge)
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
					if pot_discharge(p)>Q_raw_rng_ln(m-1) && pot_discharge(p)<=Q_raw_rng_ln(m)
						y = [m-1;m];
						yq = (m-1)+(pot_discharge(p)-Q_raw_rng_ln(m-1))/(Q_raw_rng_ln(m)-Q_raw_rng_ln(m-1));
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
						ln_C_hat_raw=vq(1)+vq(2)*t_data_raw(i)+vq(3)*pot_discharge(p)+vq(4)*sin(2*pi*DY_raw_frac(i))+vq(5)*cos(2*pi*DY_raw_frac(i));
						C_hat_adj(p)=alph(j,k,m)*exp(ln_C_hat_raw);
					elseif m == entQR
						ln_C_hat_raw=coeff(j,k,m,1)+coeff(j,k,m,2)*t_data_raw(i)+coeff(j,k,m,3)*pot_discharge(p)+coeff(j,k,m,4)*sin(2*pi*DY_raw_frac(i))+coeff(j,k,m,5)*cos(2*pi*DY_raw_frac(i));
						C_hat_adj(p)=alph(j,k,m)*exp(ln_C_hat_raw);
					end
				end
			end
		end	
	end
	C_hat_mean(i) = mean(C_hat_adj);
    if rem(i,100) == 0
       q_count = 100*i/entQ
    end
end

% find monthly and yearly average concentrations
month_means = zeros(length(YEAR),12);
month_means2 = zeros(length(YEAR)*12,1);
MONTHS = zeros(length(YEAR)*12,1);
year_means1 = zeros(length(YEAR),1);
for i = 1:length(YEAR)
    for k = 1:12
        C_month = C_hat_mean(VQ(:,1)==YEAR(i)&VQ(:,2)==k);
        month_means(i,k) = mean(C_month);
    end
    C_year = C_hat_mean(VQ(:,1)==YEAR(i));
    if sum(isnan(month_means(i,:))) ~= 0
        year_means1(i) = NaN;
    else
        year_means1(i) = mean(C_year);    
    end
end
for  i = 1:length(YEAR)
    month_means2(12*i-11:12*i) = month_means(i,:);
    MONTHS(12*i-11:12*i) = YEAR(i)+linspace(0,11/12,12);
end

%prepare variables for export
flow_norm_days = [Q_date,C_hat_mean'];
flow_norm_months = [MONTHS, month_means2];
flow_norm_years = [YEAR',year_means1];

save(['Input_data','/',name,'/',name,'_',contam,'_flow_norm.mat'],...
    'flow_norm_days','flow_norm_months','flow_norm_years');
end
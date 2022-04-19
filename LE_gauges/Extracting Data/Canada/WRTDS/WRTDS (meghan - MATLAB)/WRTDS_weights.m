function [] = WRTDS_weights(name, contam)
%   Function used to to assign weights to contaminant samples using the
%   WRTDS algorithm. Deisgned for use with the input_fetch.m file.

%   use time weights? 1 to use, 0 to not
use_time = 1;

%   desired time range [YYYY,MM,DD]
start_date = [1900,1,1];
end_date = [2100,1,1];

%   number of flow values
discharge_count = 20;

%   maximum flow percentile
max_flow_prct = 95;

%   half-window widths
half_time = 10;
half_season = 0.5;
half_discharge = 2; 

%   max half-window expansions
max_expansion = 10;

%   -----------------------------------------------------------------------

% import data from excel
[M] = xlsread(['Input_data','/',name,'/',name,'.xlsx'],contam);

Q_date=M(:,1)+693960; % date, converted from excel date format
Q_raw=M(:,2);

C_date=M(:,3)+693960; % date, converted from excel date format
C_raw=M(:,4);

%   -----------------------------------------------------------------------
for i = 1:length(Q_raw)
    if Q_raw(i) < 0 && i ~= 1 && i ~= length(Q_raw)
        Q_raw(i) = (Q_raw(i-1)+Q_raw(i+1))/2;
    elseif Q_raw(i) < 0
        Q_raw(i) = [];
        i = i-1;
    end
end

C_date(C_raw<0) = [];
C_raw(C_raw<0) = [];

% trim to desired dates
start_date = datenum(start_date);
end_date = datenum(end_date);

Q_raw = Q_raw(Q_date>=start_date&Q_date<=end_date);
Q_date = Q_date(Q_date>=start_date&Q_date<=end_date);
C_raw = C_raw(C_date>=start_date&C_date<=end_date);
C_date = C_date(C_date>=start_date&C_date<=end_date);

ln_Q_raw=log(Q_raw);
entQR = discharge_count;
Q_raw_rng=(linspace(0.001,prctile(Q_raw,max_flow_prct),entQR))';
Q_raw_rng_ln=log(Q_raw_rng);

VQ=datevec(Q_date);
VQ=VQ(:,1:3);  %[n x 3] array, no time
VQ_2=VQ;       %[n x 3] array, no time
VQ_2(:,2:3)=0; %[n x 3], day before 01.Jan
DY_raw=cat(2,VQ(:,1), datenum(VQ)-datenum(VQ_2));
DY_raw_frac=DY_raw(:,2)/366;
t_data_raw=VQ(:,1)+DY_raw_frac;

idx=(C_date>=0);
C_date=C_date(idx,:);
C_raw=C_raw(idx,:);

entQ=length(Q_date);
entC=length(C_date);

DATE=zeros(entC,1);
Q=zeros(entC,1);
C=zeros(entC,1);
ln_C=zeros(entC,1);

for i=1:entQ
    for j=1:entC
        if Q_date(i)==C_date(j)
            DATE(j)=Q_date(i);
            Q(j)=Q_raw(i);
            C(j)=C_raw(j);
            if C(j)~=0
                ln_C(j)=log(C(j));
            else
                ln_C(j)=log(0.001);
            end
        end
    end
end

idx=(Q>0);
Q=Q(idx,:);
ln_Q=log(Q);
C=C(idx,:);
ln_C=ln_C(idx,:);
DATE=DATE(idx,:);

entC=length(C);

V=datevec(DATE);        %date vector for concentration input data
V=V(:,1:3);     %[n x 3] array, no time
V2=V;
V2(:,2:3)=0;    %[n x 3], day before 01.Jan
DY=cat(2,V(:,1), datenum(V)-datenum(V2));
DY_frac=DY(:,2)/366;
DY_frac_months=[1 32 60 91 121 152 182 213 244 274 305 335]/366;
YEAR=VQ(1,1):VQ(end,1);
Y_cq =V(:,1);
entY=length(YEAR);

% set half-window widths

h_t= half_time;     % time
h_s= half_season;    % season
h_d= half_discharge;    % discharge

y_val = 1:entY;
s_val = 1:12;
qr_val = 1:entQR;
counts = 0;
fails = 0;
while true
    % time distance
    for i=1:length(y_val)
		n = y_val(i);
		d_t(n,:)=abs(Y_cq-YEAR(n));
		w_t(n,:)=(1-(d_t(n,:)/h_t).^3).^3;
		w_t(w_t<0)=0;
    end
    if use_time == 0
        w_t(w_t~=1)=1;
    end    

    % season distance
	for i=1:length(s_val)
		n = s_val(i);
		d(n,:)=abs(DY_frac-DY_frac_months(n));
		r_u = ceil(d(n,:));
		r_d = floor(d(n,:));
		d_s(n,:) = min(r_u-d(n,:),d(n,:)-r_d);
		w_s(n,:)=(1-(d_s(n,:)/h_s).^3).^3;
        w_s(w_s<0)=0;
	end

    % discharge distance
	for i=1:length(qr_val)
		n = qr_val(i);
		d_d(n,:)=abs(ln_Q-Q_raw_rng_ln(n));
		w_d(n,:)=(1-(d_d(n,:)/h_d).^3).^3;
		w_d(w_d<0)=0;
	end

	% combine the weights
    y_check = []; 
	s_check = [];
	qr_check = [];
    for j=1:entY
		for k = 1:12
			for m=2:entQR
				w_tot(j,k,m,:)=w_t(j,:).*w_s(k,:).*w_d(m,:); 
				if sum(w_tot(j,k,m,:)>0) < 100  % adjust value as desired
					y_check = [y_check,j]; 
					s_check = [s_check,k];
					qr_check = [qr_check,m];
                    fails = fails + 1;
				end
			end
		end
    end
    fprintf('%d locations failed out of %d\n',fails,entY*12*entQR)
    fprintf('   for half-windows %0.2f%% of original size\n',100*1.1^counts)
    if isempty(y_check) == 1 || counts >= max_expansion % adjust value as desired
		break
    elseif (fails/(entY*12*entQR)) <= 0.0
        break        
    else
        h_t = h_t*1.1;
        h_s = h_s*1.1;
        h_d = h_d*1.1;
    end
    fails = 0;
    counts = counts+1;
end
t_data=Y_cq+DY_frac;
Y=ln_C;
X=[t_data ln_Q sin(2*pi*DY_frac) cos(2*pi*DY_frac)];

% Calculate regression relationships for dataset   
create_regress_relationships=0
for j=1:entY
    for k=1:12
        for m=2:entQR
            wt=squeeze(w_tot(j,k,m,:));
            mdl=fitlm(X,Y,'linear','Weights',wt);
            coeff(j,k,m,:)=mdl.Coefficients.Estimate;
            w_alpha(j,k,m,:)=squeeze(w_tot(j,k,m,:));
            eps(j,k,m,:)=mdl.Residuals.Raw;
            w_eps(j,k,m,:)=w_alpha(j,k,m,:).*exp(eps(j,k,m,:));
            sum_w_eps(j,k,m)=sum(w_eps(j,k,m,:));
            sum_w_alpha(j,k,m)=sum(w_alpha(j,k,m,:));
            alph(j,k,m)=sum_w_eps(j,k,m)/sum_w_alpha(j,k,m);            
        end
    end
    create_regress_relationships=100*j/entY
end

save(['Input_data','/',name,'/',name,'_',contam,'_weights.mat']);
end
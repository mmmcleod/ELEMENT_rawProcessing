%% **********************************************************
%% CENSUS data extraction (ODESI Census of Agriculture) 
%% **********************************************************
clear
clc 
%% ********************************************
%% Processing Digitized Censes (1961-on) 
%% ********************************************

%loadInTables
Table1961=readtable('1961/1961_lvsk.xls','VariableNamingRule','preserve');
Table1966=readtable('1966/1966_lvsk.xls','VariableNamingRule','preserve');
Table1971=readtable('1971/1971_lvsk.xls','VariableNamingRule','preserve');
Table1976=readtable('1976/1976_lvsk.xls','VariableNamingRule','preserve');
Table1981=readtable('1981/1981_lvsk.xls','VariableNamingRule','preserve');
Table1986=readtable('1986/1986_lvsk.xls','VariableNamingRule','preserve');
Table1991=readtable('1991/1991_lvsk.xls','VariableNamingRule','preserve');
Table1996=readtable('1996/1996_lvsk.xls','VariableNamingRule','preserve');
Table2001=readtable('2001/2001_lvsk.xls','VariableNamingRule','preserve');
Table2006=readtable('2006/2006_lvsk.xls','VariableNamingRule','preserve');
Table2011=readtable('2011/2011_lvsk_broilers_goats.xlsx','VariableNamingRule','preserve');

%% For each year specify the county names and how they change 

% cut down the tables to only erie counties 
newTable1961=Table1961;
newTable1966=Table1966;
newTable1971=Table1971;
newTable1976=Table1976;
newTable1981=Table1981;
newTable1986=Table1986;
newTable1991=Table1991;
newTable1996=Table1996;
newTable2001=Table2001;
newTable2006=Table2006;
newTable2011=Table2011;

% a list of county names over the census years
countyNames = readtable('LakeErieCountyNamesStandardized.xlsx','ReadVariableNames',true);

%clip census only to years we are interestedin 
todelete=~ismember(newTable1961.("Geographic Identification"),countyNames.x1961);
newTable1961(todelete,:)=[];
todelete=~ismember(newTable1966.("Geographic Identification"),countyNames.x1966);
newTable1966(todelete,:)=[];
todelete=~ismember(newTable1971.("Geographic Identification"),countyNames.x1971);
newTable1971(todelete,:)=[];
todelete=~ismember(newTable1976.("Geographic Identification"),countyNames.x1976);
newTable1976(todelete,:)=[];
todelete=~ismember(newTable1981.("Geographic Identification"),countyNames.x1981);
newTable1981(todelete,:)=[];
todelete=~ismember(newTable1986.("Geographic Identification"),countyNames.x1986);
newTable1986(todelete,:)=[];
todelete=~ismember(newTable1996.("Geographic Identification"),countyNames.x1996);
newTable1996(todelete,:)=[];
%--fix these
todelete=~ismember(newTable1991.("Geographic Identification"),strcat({'- '},countyNames.x1991));
newTable1991(todelete,:)=[];
todelete=~ismember(newTable2001.("geogaphic identification"),countyNames.x2001);
newTable2001(todelete,:)=[];
todelete=~ismember(newTable2006.("Geographic identification"),countyNames.x2006);
newTable2006(todelete,:)=[];
todelete=~ismember(newTable2011.("Geographic identification"),countyNames.x2011);
newTable2011(todelete,:)=[];
newTable2011(16:end,:) = []; % these are just the 

% ** multiple kents so need to remove (only a couple years should have 17)
% ** also removing doubles 

todelete=newTable1961.("Province")==13;
newTable1961(todelete,:)=[];
todelete=newTable1966.("Province")==13;
newTable1966(todelete,:)=[];
todelete=newTable1971.("Province")==13;
newTable1971(todelete,:)=[];
todelete=newTable1976.("Province")==13;
newTable1976(todelete,:)=[];
todelete=newTable1981.("Province")==13;
newTable1981(todelete,:)=[];
todelete=newTable1986.("Province")==13;
newTable1986(todelete,:)=[];
todelete=newTable1991.("Province")==13;
newTable1991(todelete,:)=[];
todelete=newTable1996.("Province")==13;
newTable1996(todelete,:)=[];
todelete=newTable2006.("Province")~=35;
newTable2006(todelete,:)=[];
todelete=newTable2006.("Census Consolidated Subdivision")~=0;
newTable2006(todelete,:)=[];

%% Now the tables are cut to the proper counties 
% cut them down to only the livestock we need 

% goats ------

Goats1961Idx = find(strcmp(newTable1961.Properties.VariableNames, 'Goats - Number'), 1);
% no 1966 goats 
Goats1971Idx = find(strcmp(newTable1971.Properties.VariableNames, 'Goats - Number'), 1);
% no 1976 goats 
Goats1981Idx = find(strcmp(newTable1981.Properties.VariableNames, "Goats - Number"), 1);
Goats1986Idx = find(strcmp(newTable1986.Properties.VariableNames, "Goats - Number"), 1);
Goats1991Idx = find(strcmp(newTable1991.Properties.VariableNames, "T23:Goats - Number"), 1);
Goats1996Idx = find(strcmp(newTable1996.Properties.VariableNames, "Goats - Number"), 1);
Goats2001Idx = find(strcmp(newTable2001.Properties.VariableNames, "Goats - Number"), 1);
Goats2006Idx = find(strcmp(newTable2006.Properties.VariableNames, "Goats - Number"), 1);
Goats2011Idx = find(strcmp(newTable2011.Properties.VariableNames, "Goats"), 1);


% boiler chickens ---- 
Broiler1961Idx = find(strcmp(newTable1961.Properties.VariableNames, "Chicken Broilers placed on feed during past 12 months - Number"), 1);
% no 1966 broilers 
Broiler1971Idx = find(strcmp(newTable1971.Properties.VariableNames, "Commercial Chicken Broilers - Number"), 1);
Broiler1976Idx = find(strcmp(newTable1976.Properties.VariableNames, "Broilers and Cornish - Number"), 1);
% no 1981 broilers 
% no 1986 broilers 
% no 1991 broilers 
Broiler1996Idx = find(strcmp(newTable1996.Properties.VariableNames, "Broilers, roasters and cornish - Number"), 1);
Broiler2001Idx = find(strcmp(newTable2001.Properties.VariableNames, "Broilers, roasters and cornish - Number"), 1);
Broiler2006Idx = find(strcmp(newTable2006.Properties.VariableNames, "Broilers, roasters and Cornish - Number of birds"), 1);
Broiler2011Idx = find(strcmp(newTable2011.Properties.VariableNames, "Broilers, roasters and Cornish (66)"), 1);

% 1961 - both 
finalTable1961 = newTable1961(:,sort([Goats1961Idx,Broiler1961Idx]));
finalTable1961.County = newTable1961.("Geographic Identification");

% 1966 - no broilers OR goats 

% 1971 - both 
finalTable1971 = newTable1971(:,sort([Goats1971Idx,Broiler1971Idx]));
finalTable1971.County = newTable1971.("Geographic Identification");

% 1976 - only broilers 
finalTable1976 = newTable1976(:,sort([Broiler1976Idx]));
finalTable1976.County = newTable1976.("Geographic Identification");

% 1981 - only goats 
finalTable1981 = newTable1981(:,sort([Goats1981Idx]));
finalTable1981.County = newTable1981.("Geographic Identification");

% 1986 - only goats
finalTable1986 = newTable1986(:,sort([Goats1986Idx]));
finalTable1986.County = newTable1986.("Geographic Identification");

% 1991 - only goats 
finalTable1991 = newTable1991(:,sort([Goats1991Idx]));
finalTable1991.County = newTable1991.("Geographic Identification");

% 1996 - both
finalTable1996 = newTable1996(:,sort([Goats1996Idx,Broiler1996Idx]));
finalTable1996.County = newTable1996.("Geographic Identification");

% 2001 - both
finalTable2001 = newTable2001(:,sort([Goats2001Idx,Broiler2001Idx]));
finalTable2001.County = newTable2001.("geogaphic identification");

% 2006 - both
finalTable2006 = newTable2006(:,sort([Goats2006Idx,Broiler2006Idx]));
finalTable2006.County = newTable2006.("Geographic identification");

% 2011 - both
finalTable2011 = newTable2011(:,sort([Goats2011Idx,Broiler2011Idx]));
finalTable2011.County = newTable2011.("Geographic identification");


% write them for now 

writetable(finalTable1961,'Broilers_Goat.xls','Sheet','1961');
%writetable(finalTable1966,'Broilers_Goat.xls','Sheet','1966');
writetable(finalTable1971,'Broilers_Goat.xls','Sheet','1971');
writetable(finalTable1976,'Broilers_Goat.xls','Sheet','1976');
writetable(finalTable1981,'Broilers_Goat.xls','Sheet','1981');
writetable(finalTable1986,'Broilers_Goat.xls','Sheet','1986');
writetable(finalTable1991,'Broilers_Goat.xls','Sheet','1991');
writetable(finalTable1996,'Broilers_Goat.xls','Sheet','1996');
writetable(finalTable2001,'Broilers_Goat.xls','Sheet','2001');
writetable(finalTable2006,'Broilers_Goat.xls','Sheet','2006');
writetable(finalTable2011,'Broilers_Goat.xls','Sheet','2011');


% 2016 was done by hand (for now) 

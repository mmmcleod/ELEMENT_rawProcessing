%% **********************************************************
%% CENSUS data extraction (ODESI Census of Agriculture) 
%% **********************************************************
clear
clc 
%% ********************************************
%% Processing Digitized Censes (1961-on) 
%% ********************************************

%loadInTables
Table1961=readtable('1961/1961.xls','VariableNamingRule','preserve');
Table1966=readtable('1966/1966.xls','VariableNamingRule','preserve');
Table1971=readtable('1971/1971.xls','VariableNamingRule','preserve');
Table1976=readtable('1976/1976.xls','VariableNamingRule','preserve');
Table1981=readtable('1981/1981.xls','VariableNamingRule','preserve');
Table1986=readtable('1986/1986.xls','VariableNamingRule','preserve');
Table1991=readtable('1991/1991.xls','VariableNamingRule','preserve');
Table1996=readtable('1996/1996.xls','VariableNamingRule','preserve');
Table2001=readtable('2001/2001.xls','VariableNamingRule','preserve');
Table2006=readtable('2006/2006.xls','VariableNamingRule','preserve');
Table2011=readtable('2011/2011.xlsx','VariableNamingRule','preserve');

%% For each year specify the county names and how they change 

%% For each year specify the crop names and how they change



% choose county names/IDs

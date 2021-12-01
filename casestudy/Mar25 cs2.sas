*Yixuan Zhao 03/25/21;
*INFO 201 Case Study 1 B;

*Import data file;
proc import datafile='c:\users\yz6ca\desktop\airlineroutesgermany.xlsx' dbms=xlsx out=routesnoname replace;
   getnames=yes;
proc print data=routesnoname (obs=10);
run;

proc import datafile='c:\users\yz6ca\desktop\airlinenames.xlsx' dbms=xlsx out=airlinenames replace;
   getnames=yes;
proc print data=airlinenames (obs=10);
run;


*Combine two datasets into one dataset;
proc sql;
create table routes as select r.*, n.airlinename
from routesnoname as r, airlinenames as n
where r.airlinecode=n.airlinecode
order by destinationairportcode, airlinecode;
quit;
proc print data=routes (obs=10);
run;

*Two-way frequency table top airlines and top countries;
proc freq data=routes order=freq;
   tables airlinename*destinationcountryname;
where airlinename in ('Air Berlin', 'Condor Flugdienst', 'easyJet UK', 'Germanwings', 'Lufthansa', 'TUIfly', 'Ryanair')
and destinationcountryname in ('Germany', 'Greece', 'Italy', 'Spain', 'Turkey', 'United Kingdom', 'United States');
run;

*Tabulate procedure top airlines and top countries;
proc tabulate data=routes;
   class airlinename destinationcountryname;
   table airlinename, destinationcountryname;
where airlinename in ('Air Berlin', 'Condor Flugdienst', 'easyJet UK', 'Germanwings', 'Lufthansa', 'TUIfly', 'Ryanair')
and destinationcountryname in ('Germany', 'Greece', 'Italy', 'Spain', 'Turkey', 'United Kingdom', 'United States');
run;

*Tabulate procedure top countries and top cities;
proc tabulate data=routes;
   class destinationcountryname destinationcity airlinename;
   table destinationcountryname, destinationcity, airlinename;
where airlinename in ('Air Berlin', 'Condor Flugdienst', 'easyJet UK', 'Germanwings', 'Lufthansa', 'TUIfly', 'Ryanair')
and destinationcountryname in ('Germany', 'Greece', 'Italy', 'Spain', 'Turkey', 'United Kingdom', 'United States');
run;

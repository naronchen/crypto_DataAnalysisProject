*Case Study 1B;

proc import datafile='c:\users\nc4wa\desktop\airlineroutesgermany.xlsx'
dbms=xlsx out=routesnoname replace;
getnames=yes;
proc import datafile='c:\users\nc4wa\desktop\airlinenames.xlsx'
dbms=xlsx out=airlinenames replace;
getnames=yes;

proc sql;
create table routes as select r.*, n.airlinename
from routesnoname as r, airlineames as n
where r.airlinecode=n.airlinecode
order by destinationairportcode, airlinecode;
quit;
proc print data=routes (obs=10);
*Two-way frequency tables with top airlines and top countries;
proc freq data=routes order=freq;
tables airlinename*destinationcountryname;
where airlinename is ('Air Berline','Condor Flugdienst', 'easyJet UK',
'Germanwings', 'Lufthansa','TUIfly','Ryanair')
and destinationcountryname in('Germany', 'Greece','Italy', 'Spain','Turkey','United Kingdom','United States');


*Yixuan Zhao 04/06/21;
*INFO 201 Case Study 3 A;

data statfc;
set 'c:\users\yz6ca\desktop\statfc';
data manfc;
set'c:\users\yz6ca\desktop\manfc';
data material;
set 'c:\users\yz6ca\desktop\material';

*A.1 Merge statistical and manual forecast data;

proc sort data=statfc out=statfcsort;
   by id targetmonth createmonth;
proc sort data=manfc out=manfcsort;
   by id targetmonth createmonth;
data fc fcall fcstatonly fcmanonly fcactualmismatch;
merge statfcsort (in=instat rename=(actual=actualstat))
   manfcsort (in=inman rename=(actual=actualman));
   by id targetmonth createmonth;
statind=instat;
manind=inman;
statmanind=cats(statind,manind);
rename actualstat=atual;
drop actualman;
output fcall;
if instat and inman then do;
   if actualstat=actualman then output fc;
   else output fcactualmismatch;
   end;
else if instat then output fcstatonly;
else output fcmanonly;
proc print data=fcstatonly (obs=5);
proc print data=fcmanonly (obs=5);
proc print data=fc (obs=5);
run;

*A.2 Create forecast data mart;

proc sql;
create table fcmart 
	as select a.*,b.productgroup,b.priceindex,b.launchdate,
	month(b.launchdate) as launchmonth, year(b.launchdate) as launchyear
	from fc as a right join material as b
	on a.id=b.id where actual>0 and a.actual not in (.)
order by id, targetmonth,createmonth;
quit;
data fcmart;
format fcid 8.;
	set fcmart;
	fcid=_N_;
if priceindex in (0,999) then priceindex=.;
createcalmonth=month(createmonth);
createyear=year(createmonth);
targetcalmonth=month(targetmonth);
targetyear=year(targetmonth);
leadtime=intck('Month',createmonth,targetmonth);
productage=intck('Month',launchdate,targetmonth);
if productage > 120 then productage=120;
format apeman apemanshift apestat apestatshift 8.1;
apestat=abs((statfc-actual)/actual)*100;
apeman=abs((manfc-actual)/actual)*100;
apestatshift=min(apestat,300);
apemanshift=min(apeman,300);
if actual >50 and statfc not in (0,.) and manfc not in (0,.);
label priceindex='Price Index';
createyearrel=createyear-2009;
launyearrel=launyear-1980;
format targetyear 4. productgroup 2.;
proc print data=fcmart (obs=5);
proc means data=fcmart mean std n min p10 q1 median q3 p90 p95
	max maxdec=1;
var apestat;
run;

* A.3 Graphics and tables for forecast error;
ods graphics/ antialiasmax=10800;
proc sgplot data=fcmart;
histogram apestatshift;
refline 84.7/ axis=x label='Mean';
refline 40.6/ axis=x label='Median';
proc sgplot data=fcmart;
	vbox apestat / category=productgroup nooutliers;
	yaxis max=300;
proc sgpanel data=fcmart;
	panelby model / novarname;
	vbox apestatshift / category=targetyear nooutliers;
proc means data=fcmart nway noprint;
	var apestat;
	class model targetyear;
	output out=apemeans mean= median= / autoname;
proc print data=apemeans (obs=5);
proc sgplot data=apemeans;
	series x=targetyear y=apestat_median / group=model;
yaxis label='Average Percentage Error' min=0 max=100;
run;

* A.4 Compare statistical models;
proc format;
value midtmp 1='Long' 4='Short' 5='Long' 6='Long' 7='Short';
proc means data=fcmart nway noprint;
format model midtmp.;
	var apestat;
	class model targetyear;
	output out=apemeans2grp mean= median= / autoname;
proc print data=apemeans2grp (obs=5);
proc sgplot data=apemeans2grp;
	series x=targetyear y=apestat_median / group=model;
yaxis label='Average Percentage Error' min=0 max=100;
proc means data=fcmart nway noprint;
	var apestat;
	class priceindex;
	output out=quartileprice median=median q1=q1 q3=q3;
proc sgplot data=quartileprice noautolegend;
	band lower=q1 upper=q3 x=priceindex;
	series x=priceindex y=median;
yaxis label='Average Percentage Error';
	where priceindex < 500;
run;

* A.5 Generalized linear model and quantile regression;
data fcmart;
set fcmart;
targetyearshift=targetyear-2009;
proc glmselect data=fcmart;
	class productgroup launchmonth model targetcalmonth / 
	param=effect show;
model apestatshift=productgroup|priceindex|launchmonth|productage|
	model|leadtime|targetcalmonth|targetyearshift @1 /
details=steps selection=stepwise (select=adjrsq) orderselect
	showpvalues;
proc surveyselect data=fcmart out=fcmartsample method=srs
	sampsize=10000 seed=19416;
proc means data=fcmartsample q1;
	class model;
	var apestat;
proc quantselect data=fcmartsample;
	class productgroup launchmonth model targetcalmonth / 
	param=effect show;
model apestat=productgroup|priceindex|launchmonth|productage|
	model|leadtime|targetcalmonth|targetyearshift @1 /
	quantile=(0.25,0.5,0.75) details=summary selection=stepwise;
run;

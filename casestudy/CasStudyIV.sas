data employees;
set 'c:\users\nc4wa\desktop\employees';

*a.1 Duration for all employees;
proc means data=employees mean;
var duration;
proc lifetest data=employees plots=(hazard(bandwidth=3)) conftype=linear;
   time duration*status(1);
ods select censoredsummary survivalplot hazardplot;
%let snapdate='31DEC2016'd;
%let start='01JAN2004'd;
proc sort data=employees out=employeessort;
by empno;
proc transpose data= employeessort (keep=empno department start end)
   out=employeestp(rename=(col1=date));
by empno;
data employeestp;
set employeestp;
by empno;
format start date9.;
retain start;
if first.empno then start=date;
if date=. then date=&snapdate;
proc sort data=employeestp;
by start;
data employeestp;
set employeestp;
   _ID_=ceil(_n_/2);
proc sgplot data=employeestp;
series x=date y=_ID_/group=empno lineattrs=(thickness=1 pattern=solid color=black);
run;

*A. 2 Factors that may influence duration;
proc means data=employees mean;
   class department;
   var duration;
   proc lifetest data=employees plots=(hazard(bandwidth=3)) conftype=linear;
      time duration*status(1);
	  strata department;
ods select homtests survivalplot hazardplot;
   proc lifetest data=employees plots=(hazard(bandwidth=3)) conftype=linear;
      time duration*status(1);
	  strata gender;
ods select homtests survivalplot hazardplot;
proc lifetest data=employees plots=(hazard(bandwidth=3)) conftype=linear;
      time duration*status(1);
	  strata startperiod;
ods select homtests survivalplot hazardplot;
   proc lifetest data=employees plots=(hazard(bandwidth=3)) conftype=linear;
      time duration*status(1);
	  strata techknowhow;
ods select homtests survivalplot hazardplot;
run;

*A.3 Employee hire-leave chart;
data _null_;
	monthcount=intck('Month', &start, &snapdate);
	call symput('MonthCount', monthcount);
data allmonths;
format month date9.;
do i=1 to &monthcount;
month=intnx('MONTH', &start, i-1);
drop i;
output;
end;
proc sql;
create table empcount as select month, count(distinct empno) as empcount
	from allmonths as a left join employees as b on
	intnx('MONTH',b.end,0)>a.month and b.start<=a.month group by month;
create table departure as select intnx('MONTH', end, 0) as end format=data9.,
	count(distinct empno) as departures from employees where end ne . group by end;
create table arrival as select start, count(distinct empno) as arrivals from
	employees where start ne . group by start;
create table allcounts as select a.month, a.empcount,
	case when b.arrivals=. then 0 else b.arrivals end as arrivals,
	case when c.departures=. then 0 else c.departures end as departures
	from empcount as a left join arrival as b on a.month=b.start
	left join departure as c on a.month=c.end;
quit;
data allcounts;
set allcounts;
retain numbertmp;
numbertmp2=sum(numbertmp,arrivals,-lag(departures));
numbertmp=numbertmp2;
employees=numbertmp2-arrivals-departures;
drop numbertmp numbertmp2 empcount;
proc transpose data=allcounts out=allcountstp(rename=(_name_=type col1=number));
	by month;
data allcountstp;
set allcountstp;
	label type='Type';
proc sgplot data=allcountstp;
format month yymmp7.;
	vbar month / group=type response=number;
	xaxis fitpolicy=thin;
	where month>='01JAN2009'd;
run;

*a.4 cUMULATIVE KNOWLEDGE CHART;
proc sql;
create table knowhowyearsempno as select month, empno,
	round(sum(intck('MONTH',b.start,a.month)),1) as knowledgemonths
	from allmonths as a left join employees(where=(techknowhow='YES')) as b
	on intnx('MONTH', sum(b.end,(b.end=.)*&snapdate),0) > a.month and b.start
	<= a.month group by month,empno;
quit;
proc sgplot data=knowhowyearsempno;
format month yymmp7.;
	vbar month / group=empno response=knowledgemonths;
	xaxis fitpolicy=thin;
	where month>='01JAN2009'd;
run;

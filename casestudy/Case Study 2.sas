* Naron Chen 04/01/21;
* INFO 201 Case Study 2 A;

data transactions;
set 'c:\users\nc4wa\desktop\transactions';

* A.1 Plot data by transaction amount;
proc sgplot data=transactions;
	histogram amountusd;
	where amountusd < 100000;
yaxis label='Number of transactions';
xaxis label='Transaction amount';

* A.2 Compute and plot expected Benford distribution;
data benfordexpected;
format firstdigit 8. expfreq 8.3;
do firstdigit = 1 to 9;
	expfreq=(log10(1+(1/firstdigit))*100);
	output;
	end;
proc sgplot data=benfordexpected;
	vbar firstdigit/response=expfreq datalabel;
yaxis label='Expected distribution';
xaxis label='First digit';

* A.3 Compute actual distribution by first digit;
data observedfrequency (keep=amountusd firstdigit count);
set 'c:\users\nc4wa\desktop\transactions';
firstdigit=input(substr(compress(put(amountusd,16.2),'.0 '),1,1),8.);
count=1;
proc freq data=observedfrequency;
tables firstdigit/chisq(testp=benfordexpected(rename=(expfreq=_testp_)))
	nocum out=benfordoutput;
ods select onewayfreqs;


* A.4 Join and plot actual vs. expected distribution;
data benfordplot;
format firstdigit 3. expfreq obsfreq 8.3;
merge benfordexpected benfordoutput (rename=(percent=obsfreq));
	by firstdigit;
label obsfreq='Actual distribution' expfreq='Expected distribution';
proc sgplot data=benfordplot;
	vline firstdigit/ response=obsfreq lineattrs=(pattern=2);
	vline firstdigit/ response=expfreq lineattrs=(pattern=3);
yaxis label='Frequency in percent';
xaxis label='First digit';
run;
proc sql;
select firstdigit label='First digit' format=8.,
	count label='Frequency' format=8.,
	obsfreq label='Actual distribution' format=8.2,
	expfreq label='Expected distribution' format=8.2,
	obsfreq-expfreq as difference label='Difference' format=8.2
	from benfordplot;
quit;

* A.5 Additional analysis by customer;
data observedfrequencycustomer (keep=customerid amountusd firstdigit count);
set 'c:\users\nc4wa\desktop\transactions';
firstdigit=input(substr(compress(put(amountusd,16.2),'.0 '),1,1),8.);
count=1;
proc sort data=observedfrequencycustomer;
	by customerid;
proc freq data=observedfrequencycustomer;
tables firstdigit/chisq(testp=benfordexpected(rename=(expfreq=_testp_)))
	nocum out=benfordoutputcustomerid(rename=(percent=obsfreq));
weight count;
	by customerid;
ods output onewaychisq=chi2;
ods select onewaychisq;

* A.6 Rank Chi2 by customer;
proc transpose data=chi2 out=chi2results (drop=_name_ df_pchi);
	by customerid;
	var nvalue1;
	id name1;
proc sort data=chi2results;
	by descending _pchi_;
data chi2results;
format rank 3.;
	set chi2results;
	rank=_N_;
	rename _pchi_=chi2_value p_pchi=p_value;
format p_pchi percent8.3 _pchi_ 8.1;
proc sgplot data=chi2results;
	series x=rank y=p_value;
yaxis label='Probability Benford';
xaxis label='Ranking';

* A.7 Detailed investigation for one customer;
proc sql;
create table benfordcustomeridxt as 
select a.customerid, a.firstdigit, a.obsfreq format=8.3,
	b.expfreq, a.obsfreq-b.expfreq as delta format=8.3,
	c.rank, c.chi2_value, c.p_value from benfordoutputcustomerid as a left join
	benfordexpected as b on
	a.firstdigit=b.firstdigit left join chi2results as c on
	a.customerid=c.customerid
order by a.customerid, a.firstdigit;
quit;
proc sgplot data=benfordcustomeridxt;
	vline firstdigit/ response=obsfreq lineattrs=(pattern=2);
	vline firstdigit/ response=expfreq lineattrs=(pattern=3);
yaxis label='Frequency in percent';
xaxis label='First digit';
	where customerid=9000;
run;

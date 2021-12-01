/*
Naron Chen
https://www.kaggle.com/prasoonkottarathil/btcinusd (Main dataset I used, took BTCUSD_DAY.csv). Also used ETH dataset from Kaggle.https://www.kaggle.com/kingburrito666/ethereum-historical-data?select=EtherPriceHistory%28USD%29.csv
Word Count:866 words (without Comments)

*/

/*
First Half(Stats Portion):  first compaing Bitcoin to Etherium, get a sense of Bitcoin flow
							second part is to turn BTCUSD_Day into BTCUSD_Month
Task BreakDown:
	1. Use Proc Report to compare and contrast Etherium(ETH) price with Bitcoin(BtC)
	2. Find The highest&lowest price of each month as month_high & month_low / note: careful with stats of different year but same month
    3. Find the opening and closing price of each month as month_open & month_close / note: Different month has different number of days
				 																	/ note2: need to find the price of first day of month & last day of month
	4. Find the comulative sum of Volume for each month as month_volume 

*/

data BTC_Day;
	infile 'c:\users\nc4wa\desktop\BTCUSD_day.csv' dsd dlm=',' firstobs=2;
	input Date : mmddyy10. 
			Symbol : $6. 
			Open High Low Close Volume_BTC Volume_USD;
	Month = month(Date);
	Year = year(Date);
	DayofMonth = day(Date);
	LastDateofMonth=intnx ('month',date,0,'E');
	format Date LastDateofMonth mmddyy10.;
	if DayofMonth=1 then Month_open=open;
	if LastDateofMonth=date then Month_close=close;

PROC IMPORT DATAFILE="c:\users\nc4wa\desktop\EtherPricehistory(USD).csv" 
DBMS=csv OUT=Ether_Day REPLACE; getnames=yes;

Ods excel file='c:\users\nc4wa\desktop\BTCEther_Day.xlsx';

proc sql;
title 'BTCEther_Day';
select a.date, high, low, value
	from BTC_Day as a,
		Ether_Day as b
	where a.date = b.Date_UTC_;
quit;

ods excel close ;

PROC IMPORT DATAFILE="c:\users\nc4wa\desktop\BTCEther_Day.xlsx" 
DBMS=xlsx OUT=BTCEther_Day REPLACE; getnames=yes;

data BTCEther_Day_2;
set BTCEther_Day;
AvgBTCPrice = (high + low) /2;
BTCPrice_lag=lag(AvgBTCPrice);
EtherPrice_lag=lag(value);
EthChange = value - EtherPrice_lag;
BTCChange = AvgBTCPrice - BTCPrice_lag;
if BTCChange > 0 then BTCstatus='positive';
else BTCstatus='negative';
if ETHChange > 0 then ETHstatus='positive';
else ETHstatus='negative';

proc print data=BTCEther_Day_2 (obs=10);
title 'BTCEther Daily Data';
run;

title 'BTC/ETH Daily Data Report';
proc report data=BTCEther_Day_2;
	column date avgBTCPrice BTCChange value EthChange Difference BTCstatus ETHstatus;
			define date/display 'date';
			define avgBTCPrice/display 'BitCoin Daily Price' width=12 format=dollar8.2;
			define BTCChange/display 'flutuation in BTC Price' width=9 format=5.2;
			define value/display 'Etherium Daily Price' width=12 format=dollar8.2;
			define EthChange/display 'flutuation in ETH Price' width=8 format=4.2;
			define Difference/computed 'Difference in flutuation ' width=8 format=5.2 ;
			define BTCstatus/display 'BTC rise/fall daily';
			define ETHstatus/display 'ETH rise/fall daily';
	compute Difference;
		Difference = BTCChange - EthChange;
	endcomp;
run;

*Here we start creating BTC_Month;
data BTC_DayTwo;
set BTC_Day;
retain _Month_close;
if not missing(Month_close) then _Month_close=Month_close;
else Month_close=_Month_close;
drop _Month_close;
run;
proc sort data= BTC_DayTwo;
by descending year descending month DayofMonth;
data BTC_DayThree;
set BTC_DayTwo;
retain _Month_open;
if not missing(Month_open) then _Month_open=Month_open;
else Month_open=_Month_open;
drop _Month_open;
run;
proc print data=BTC_DayThree(obs=15);
title 'Month_Open & Month_Close';
run;

proc sort data=BTC_Day;
by year month;
proc means data = BTC_Day max min sum std q1 q3 p10 p90;
title 'stats of BTC_Day';
by year month;
var high low Volume_BTC Volume_USD;
output out = BTC_Day_stats
		max(high) = Month_high
		min(low) = Month_low
		sum(Volume_BTC Volume_USD) = Month_Volume_BTC Month_Volume_USD;
proc print data=BTC_Day_stats(obs=10);
title 'Month High Low Volume';
run;

Ods excel file='c:\users\nc4wa\desktop\BTCUSD_month.xlsx';

proc sql;
title 'BTCUSD_Month';
select min(a.Month) 'Month' ,min(a.Year) 'Year',
	min(Month_high) as high 'high',
	min(Month_low) as low 'low',
	min(Month_open) as open'open',
	min(Month_close) as close 'close',
	min(Month_Volume_BTC) as volume 'volume',
	min(Month_Volume_USD) as USDvolume 'USDvolume'
	from BTC_Day_stats as a,
		BTC_DayThree as b
	where a.year = b.year and a.month=b.month
	group by a.year,a.month;
quit;

ods excel close ;

PROC IMPORT DATAFILE="c:\users\nc4wa\desktop\BTCUSD_month.xlsx" 
DBMS=xlsx OUT=BTCUSD_Month REPLACE; getnames=yes;

data YearMonth;
set BTCUSD_Month;
YearMonth = MDY(month, 1, year);
changeinPrice=close - open;
if changeinPrice>0 then PriceChangestatus=1;
else PriceChangestatus=-1;
run;

 proc format;
	value PriceChangestatus			 1 = 'positive'
									-1 = 'Negative';
	value ChangeinPrice				0-50 = 'Small Rise'
									51-100 = 'Moderate Rise'
									101-high = 'Drastic Rise'
									-50 - -1 = 'Small Fall'
									-100 - -50 = 'Moderate Fall'
									low - -100 = 'Drastic Fall';
;
proc print data=YearMonth (obs=10);
format PriceChangestatus PriceChangestatus.
		ChangeinPrice ChangeinPrice.;
run;

/*
Second Half(graph portion): This part is about using different graphic tools to introduce&analyize BTCUSD_Month
Task Breakdown: 1. Time series, scatterplot, histogram,
				2. Attempt an adaptivereg process to measure btcvolume&date as well as btcvolume&USDvolume/note: USDvolume is much larger than btcVolume, so I need to scale one of them before putting them together on the same graph
				3. Attempt new procedure (sgscatter with matrix, Proc Forecast)
*/


proc sgplot data=YearMonth;
	series x=YearMonth y=high;
	series x=YearMonth y=low;
	format YearMonth mmyyn6.;
	title 'time series of high&low with date';
run;

proc sgplot data=YearMonth ;
*xaxis interval=quarter MINOR MINORINTERVAL=year;
scatter x=YearMonth y=changeinPrice;
refline 0/axis=y lineattrs=(color=black);
	format YearMonth mmyyn6.;
	title 'scatter plot of ChangeinPrice with date';
*xaxis display=None;
run;

proc univariate data=YearMonth;
	class year;
   var PriceChangestatus;
   histogram PriceChangestatus / nrows=6 outhist=OutHist;
   title 'Unvariate data of PriceChangestatus in different years';
run;
 
*Adaptive regression for Volume & Date;
proc adaptivereg data=YearMonth plots=all details;
model volume  = YearMonth/additive;
output out=volume_date predicted=volumepredicted;
run;

proc sgplot data=volume_date;
series x=YearMonth y=volume/lineattrs=(pattern=1);
series x=YearMonth y=volumepredicted/lineattrs=(pattern=4 color=orange);
refline 21001/axis=x lineattrs=(color=lightblue);
refline 20851/axis=x lineattrs=(color=lightblue);
refline 21154/axis=x lineattrs=(color=lightblue);
refline 21305/axis=x lineattrs=(color=lightblue);
format YearMonth mmyyn6.;
yaxis label='volume';
xaxis label='MonthofYear';
title 'adaptivereg data volume prediction base on date';
run;

*Adaptive regression for btcVolume & YearMonth with USDvolume;
proc adaptivereg data=YearMonth plots=all testdata=volume_date;
model volume  = YearMonth USDvolume/maxbasis=10;
output out=volume_USDvol predicted=volumepredicted;
run;

*USDvolume is too large to put in the graph so we need to squeeze it;
data adp_vol;
set volume_USDvol;
usdvol = USDvolume/10000;

proc sgplot data=adp_vol;
series x=YearMonth y=volume/lineattrs=(pattern=1);
series x=YearMonth y=usdvol/lineattrs=(pattern=1 color=green);
series x=YearMonth y=volumepredicted/lineattrs=(pattern=4 color=orange);
format YearMonth mmyyn6.;
yaxis label='volume';
xaxis label='MonthofYear';
title 'adaptivereg data volume prediction base on date&volume';
run;

/*Reflection&Thoughts:
		Adding USDvolume to measurement made the prediction much more precise, 
		As BTC is somehow linked to USD volume, this could potentially support the opinion that virtual economy is closely connected to substantial/real economy
*/


*Trying New Command Not Studied in Class: sgscatter and Forecast;
proc sgscatter data=YearMonth;
where YearMonth > 21000 and YearMonth < 215000;
matrix high low volume / diagonal=(histogram kernel);
title 'sgscatter Matrix of stats with rapid rising time period';
run;

proc forecast data=YearMonth interval=month lead=30
out=pred outlimit;
var volume;
id YearMonth;
run;
proc print data=pred (obs=10);
title 'Forecast Result Table';
run;
proc sgplot data=pred;
series x=YearMonth y=volume / group=_type_ lineattrs=(pattern=1);
*xaxis values=('1May20'd to '1Jan21'd);
	format YearMonth mmyyn6.;
title 'forecast procedure result with time series';
run;


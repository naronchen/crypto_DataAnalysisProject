*Case Study;

data airlinepassengers;
set 'c:\users\nc4wa\desktop\travelmarket';

proc sgplot data=airlinepassengers;
	series x=date y=passengers;
format passengers comma8.;

data passengersmooth;
set 'c:\users\nc4wa\desktop\travelmarket';
passengersmooth=
	mean(passengersmooth, lag(passengers), lag2(passengers),
	lag3(passengers), lag4(passengers), lag5(passengers),
	lag6(passengers), lag7(passengers), lag8(passengers),
	lag9(passengers), lag10(passengers), lag11(passengers));

proc sgplot data=passengersmooth;
	series x=date y=passengers;
	series x=date y=passengersmooth;
format passengers passengersmooth comma8.;
run;

proc adaptivereg data=passengersmooth plots=all;
model passengersmooth=date/maxbasis=11;
output out=flights predicted=passengerpredict;

*plot original, smooothed and predicted values;
proc sgplot data=flights;
series x=date y=passengers;
series x=date y=passengers/lineattrs=(pattern=3);
series x=date y=passengerpredict/lineattrs=(pattern=4);
refline '01AUG90'd/axis=x lineattrs=(color=purple);
refline '01NOV91'd/axis=x lineattrs=(color=purple);
refline '01APR01'd/axis=x lineattrs=(color=purple);
refline '01AUG02'd/axis=x lineattrs=(color=purple);
refline '01DEC02'd/axis=x lineattrs=(color=purple);
yaxis label='passengers';
xaxis label='date;
run;



*Yixuan Zhao 03/25/21;
*INFO 201 Case study 1 A;

data airlinepassengers;
set 'c:\users\yz6ca\desktop\travelmarket';

* Plot passengers by date;
proc sgplot data=airlinepassengers;
   series x=date y=passengers;
format passengers comma10.;

*Smooth data;
data passengersmooth;
set 'c:\users\yz6ca\desktop\travelmarket';
passengersmooth=
   mean(passengers, lag(passengers), lag2(passengers),
   lag3(passengers), lag4(passengers), lag5(passengers),
   lag6(passengers), lag7(passengers), lag8(passengers),
   lag9(passengers), lag10(passengers), lag11(passengers)); * Average volume of the current passengers in hte current month;

*Plot smoothed data;
proc sgplot data=passengersmooth;
   series x=date y=passengers;
   series x=date y=passengersmooth;
format passengersmooth comma10.;
run;

*Adaptive regression;
proc adaptivereg data=passengersmooth plots=all;
   model passengersmooth=date/maxbasis=11;
   output out=flights  predicted=passengerpredict;

*Plot oriinal, smooothed and predited values;
proc sgplot data=flights;
   series x=date y=passengers;
   series x=date y=passengersmooth/lineattrs=(pattern=3);
   series x=date y=passengerpredict/lineattrs=(pattern=4);
refline '01AUG90'd/axis=x lineattrs=(color=purple);
refline '01NOV91'd/axis=x lineattrs=(color=purple);
refline '01APR01'd/axis=x lineattrs=(color=purple);
refline '01AUG02'd/axis=x lineattrs=(color=purple);
refline '01DEC02'd/axis=x lineattrs=(color=purple); *Dates when slope changes;
yaxis label='Passengers';
xaxis label='Date';
run; 

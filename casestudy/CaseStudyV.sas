*Case Study V;
*Blablabla Blablabla Class starts;

data claims;
set 'c:\users\nc4wa\desktop\claims';

*A.1 Reformat data for empirical analysis;
format feature $40.;
if gender='M' then feature='Male';
	else feature='Female';
	output;
if 0 < Age < 26 then feature='Young';
	else if 26 <= age <= 55 then feature='Middle Age';
	else feature='Old';
	output;
feature=density;
output;
feature=cartype;
output;
feature=caruse;
output;
if claimflag='Yes' then feature ='Claim';
	else feature='No Claim';
	output;
data claimsxt;
	set claims;
	feature=compress(feature);
	count=1;
proc transpose data=claimsxt out=claimsonerow(drop=_name_);
	by policyno;
	id feature;
	var count;
data claimsonerow;
	set claimsonerow;
	array change _numeric_;
	do over change;
	if change=. then change=0;
end;
proc print data=claimsxt (obs=10);
proc print data=claimsonerow (obs=10);
run;

*A.2 Correlation, probit regression, and cluster analysis;
proc corr data=claimsonerow;
var claim noclaim male female young middleage old highlyurban
	urban rural highlyrural paneltruck pickup sedan sportscar
	suv commercial private;
proc probit data=claimsonerow;
model claim=male young old highlyurban rural urban pickup sedan
	sportscar suv van private;
proc varclus data=claimsonerow outtree=varclus_treel centroid;
var claim commercial female highlyrural highlyurban male
	middleage noclaim old paneltruck pickup private rural suv
	sedan sportscar urban van young;
run;

*cluster analysis -> divides data to sub groups to examine relationship between variables (explanatory power);

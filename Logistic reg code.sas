/***********************************************/
/* 1. Code Name:
*/
/* 2. Code Description:
*/
/* 3. Code Author:
*/
/* 4. Date:
*/
/***********************************************/
 
 
options center date label notes mprint linesize=80 compress=yes fmtsearch=(d_fmt);
%let inpath=I:\Mobily_Churn\Output\Rishabh\sas_univariate;/*PATH OF INPUT MODELING FILE */
%let outpath=I:\Mobily_Churn\Output\Rishabh\logistic_output_sample;/*PATH WHERE O/P FILES NEED TO BE SAVED*/
%let infile=Mast_tab_3plus_v2_samp;/*MODELING SAMPLE*/
%let target=churn_flag;/*DEPENDENT VARIABLE*/
 
%let indvar=
/*TOTAL_REV_OCT_SAR*/
/*TOTAL_DATA_REV_OCT_SAR*/
/*TOTAL_HOME_OCT_REV*/
TOTAL_SMS_REV_OCT_SAR
total_home_oct_rev_11oct_20oct
TOTAL_OCT_N_MINS
TOTAL_OCT_DATA_MB
/*data_mb*/
TOTAL_ONNET_SAR_SMS
TOTAL_CALL_REV_SEP_ON
TOTAL_DATA_REV_AUG_ON
/*TOTAL_CALL_REV_SEP_SAR*/
TOTAL_OFFNET_SAR_SMS
TOTAL_SMS_SEP_N
TOTAL_DATA_REV_SEP_ON
total_call_rv1off_11oct_20oct
total_data_sar_rev_21oct_31
total_data_sar_rev_11oct_20
/*total_oct_i_mins_1oct_10oct*/
/*totl_call_rev_on_1oct_10oct*/
total_rech_count_1_10
/*total_rech_sar_01_10*/
/*TOTAL_SMS_REV_OCT_OFF*/
TOTAL_CALL_REV_AUG_SAR
TOTAL_SMS_AUG_I
total_call_sar_rev_21oct_30
;
libname a1 "&inpath";
proc reg data=a1.&infile;
model &target=&indvar /vif;
ods trace on;
ods output ParameterEstimates = vif1;
run;
data vif1(keep=Variable VarianceInflation);
set vif1;
run;
proc export data=vif1 outfile="&outpath.\multicolcheck.csv" replace;
run;
 
 
%macro logisticmacro;
proc logistic data=a1.&infile descending namelen=32;
MODEL &target=&indvar 
/stb selection=stepwise /*SELECTION CAN TAKE FOLLOWING VALUES- NONE STEPWISE FORWARD BACKWARD*/
slentry = 0.2 slstay= .01 
lackfit rsq ctable stb;
OUTPUT OUT=test2/* OUTPUT FILE WITH ESTIMATED PROBABILITIES */
predicted=pred /* VARIABLE IN TEST2 WHICH CONTAINS ESTIMATED PROBABILITY */
XBETA=beta;
ods trace on;
ods output ParameterEstimates = para;
ods output Association=assocu;
ods output Nobs=dNum;
ods output ResponseProfile=dEvent;
ods output OddsRatios=orrr;
ods output Classification=ctab;
run;
 
/*Model Base*/
proc export data=dNum outfile="&outpath.\base.csv" replace;
run;
 
 
/*Response Rate*/
proc sql;
create table dEvent as select *,sum(count) as total from dEvent;
quit;
data devent;
set devent;
response_rate=(count/total);
run;
proc export data=devent outfile="&outpath.\responserate.csv" replace;
run;
 
/*Concordance*/
data assocu;
set assocu;
val1=cValue1/100;
run;
proc export data=assocu outfile="&outpath.\concordance.csv" replace;
run;
 
 
/*response rates per decile*/
data temp(keep=&target pred);
set test2;
run;
proc sort data=temp;
by descending pred;
run;
PROC UNIVARIATE DATA = temp noprint;
VAR pred;
OUTPUT OUT = NUM1 PCTLPTS=0 10 20 30 40 50 60 70 80 90 100
PCTLPRE=PCTL_ PCTLNAME=P0 P10 P20 P30 P40 P50 P60 P70 P80 P90 P100;
RUN;
data num1;
set num1;
call symput ('prcntile_0', put(pctl_p0, 8.3));
call symput ('prcntile_10', put(pctl_p10, 8.3));
call symput ('prcntile_20', put(pctl_p20, 8.3));
call symput ('prcntile_30', put(pctl_p30, 8.3));
call symput ('prcntile_40', put(pctl_p40, 8.3));
call symput ('prcntile_50', put(pctl_p50, 8.3));
call symput ('prcntile_60', put(pctl_p60, 8.3));
call symput ('prcntile_70', put(pctl_p70, 8.3));
call symput ('prcntile_80', put(pctl_p80, 8.3));
call symput ('prcntile_90', put(pctl_p90, 8.3));
call symput ('prcntile_100', put(pctl_p100, 8.3));
run;
data temp;
set temp;
flag=1;
if pred>=&prcntile_90 then decile=1;
else if pred>=&prcntile_80 then decile=2;
else if pred>=&prcntile_70 then decile=3;
else if pred>=&prcntile_60 then decile=4;
else if pred>=&prcntile_50 then decile=5;
else if pred>=&prcntile_40 then decile=6;
else if pred>=&prcntile_30 then decile=7;
else if pred>=&prcntile_20 then decile=8;
else if pred>=&prcntile_10 then decile=9;
else decile=10;
run;
proc sql;
create table temp1
as select decile, sum(flag) as count, sum(&target) as depn
from temp group by decile;
quit;
proc sql;
create table temp1
as select *, sum(count) as tot_obs, sum(depn) as tot_depn
from temp1;
quit;
data temp1;
set temp1;
decile_size=count/tot_obs;
response_rate=depn/count;
response_per=depn/tot_depn;
run;
data temp1;
set temp1;
retain cum_resp_per 0;
cum_resp_per=cum_resp_per+response_per;
run;
data temp1;
set temp1;
retain cum_decile_size 0;
cum_decile_size=cum_decile_size+decile_size;
run;
data temp2;
retain decile response_rate cum_resp_per cum_decile_size;
set temp1;
keep decile response_rate cum_resp_per cum_decile_size;
run;
proc export data=temp2 outfile="&outpath.\response_decile.csv" replace;
run;
 
/*parameter estimates*/
data para(drop=DF);
set para;
run; 
proc export data=para outfile="&outpath.\beta.csv" replace;
run;
 
/*odds ratios*/
proc export data=Orrr outfile="&outpath.\odds_ratio.csv" replace;
run;
 
/*classification table*/
proc export data=Ctab outfile="&outpath.\ctable.csv" replace;
run;
 
%mend;
%logisticmacro;
/**/
 
/******************************************************************************************************************/
/* This program correspond to the analysis of cluster members of the SCRATCH trial                                */
/******************************************************************************************************************/

libname SCRATCH "U:\CIC_ACQ\_BIOSTAT\0.Biométrie\Etudes\2013\CHU\F Boralevi_SCRATCH\Statistiques\Analyse\Bases\SCRATCH_Export_20230620\sasdata"; /* CHANGEME */
%let path_formats = U:\CIC_ACQ\_BIOSTAT\0.Biométrie\Etudes\2013\CHU\F Boralevi_SCRATCH\Statistiques\Analyse\Bases\SCRATCH_Export_20230620\progSAS\SCRATCH_Formats.sas; /* CHANGEME */

%include "&path_formats.";

PROC IMPORT datafile="U:\CIC_ACQ\_BIOSTAT\0.Biométrie\Etudes\2013\CHU\F Boralevi_SCRATCH\Statistiques\Analyse\Bases\scratch-listeRando-affected-08-06-2023.csv"
            dbms=dlm
            out=Rando_0
            replace;
     delimiter=';';
     getnames=yes;
run;
DATA Rando;
  set Rando_0;
  if (listRanNumClePat<1000) then
    do;
      ClePat_char_0 = put(listRanNumClePat,3.0);
	  ClePat_char = "0"||ClePat_char_0;
	end;
  else
    ClePat_char = put(listRanNumClePat,4.0);
  ClePat = ClePat_Char;
  Groupe = ListRanProd;
  drop ClePat_char ClePat_char_0;
  if ClePat in ("0516", "0518", "0519", "0520", "2623") then delete;
  Cluster=ClePat;
run;
PROC SORT data=Rando;
  by Cluster;
run;

data WORK.OUTCOME_0    ;
 %let _EFIERR_ = 0; 
 infile 'U:\CIC_ACQ\_BIOSTAT\0.Biométrie\Etudes\2013\CHU\F Boralevi_SCRATCH\Statistiques\Analyse\Bases\2023.08.16 Outcome and Compliance.csv' delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
         informat _ best32. ;
         informat ClePat $6. ;
         informat Cluster $4. ;
         informat Compliance_Cluster $4. ;
         informat Compliance_Individuel $9. ;
         informat Outcome_Cluster $5. ;
         informat Outcome_Individuel $5. ;
         format _ best12. ;
         format ClePat $6. ;
         format Cluster $4. ;
         format Compliance_Cluster $4. ;
         format Compliance_Individuel $9. ;
         format Outcome_Cluster $5. ;
         format Outcome_Individuel $5. ;
      input
                  _
                  ClePat $
                  Cluster $
                  Compliance_Cluster $
                  Compliance_Individuel $
                  Outcome_Cluster $
                  Outcome_Individuel $
      ;
      if _ERROR_ then call symputx('_EFIERR_',1);  
      run;

DATA Outcome_1;
  set Outcome_0;
  if (Outcome_Individuel="TRUE") then
    Outcome_Individuel_Num = 1;
  if (Outcome_Individuel="FALSE") then
    Outcome_Individuel_Num = 0;
  if (Outcome_Individuel not in ("TRUE","FALSE")) then
    Outcome_Individuel_Num = .;
  Centre=substr(ClePat,1,2);
run;
PROC SORT data=Outcome_1;
  by Cluster;
run; 
DATA T_Rnd;
  set SCRATCH.Rnd;
  Cluster=ClePat;
run;
PROC SORT data=T_Rnd;
  by Cluster;
run;
DATA Tab;
  merge Rando T_Rnd Outcome_1;
  by Cluster;
run;

DATA Tab;
  merge Outcome_1 Rando;
  by Cluster;
run;


/* Analysis for completers, i.e. considering only participants who had the Day 28 assessement */

PROC FREQ data=Tab; 
  table Groupe*Outcome_Individuel_Num;
run;
PROC MIXED data=Tab;
  class Groupe Cluster Centre;
  model Outcome_Individuel_Num = Groupe / s cl;
  random int / subject=Centre;
  random int / subject=Cluster(Centre);
  lsmeans Groupe / cl;
run;


/* Analysis for all participants */

/* Step 1: looking which variables were associated to the missingness mechanism for multiple imputation */
DATA Tab3;
  set Tab;
  if (Outcome_Individuel_Num = .) then
    Missing_O = 1;
  else
    Missing_O = 0;
	Membre = substr(ClePat,5,2);
	if (substr(ClePat,5,2) = "") then
	  CasIndex=1;
	else
	  CasIndex=0;
run;
PROC SORT data=Tab3;
  by ClePat;
run;
DATA Inc; 
  set SCRATCH.INCLUSION;
  Membre = substr(ClePat,5,2);

  if (substr(ClePat,5,1) = "E") then
    ClePat = substr(ClePat,1,4)||"B"||substr(ClePat,6,1);
  if (IncVisDatJou<10) then
    do;
      IncVisDatJou_Char_0=put(IncVisDatJou,$1.); 
      IncVisDatJou_Char = "0"||IncVisDatJou_Char_0;
	end;
  else
    IncVisDatJou_Char=put(IncVisDatJou,$2.); 
  format IncVisDatJou_Char $2.;
  if (IncVisDatMoi<10) then
    do;
      IncVisDatMoi_Char_0=put(IncVisDatMoi,$1.); 
      IncVisDatMoi_Char = "0"||IncVisDatMoi_Char_0;
	end;
  else
    IncVisDatMoi_Char=put(IncVisDatMoi,$2.); 
  format IncVisDatMoi_Char $2.;
  IncVisDatAnn_Char=put(IncVisDatAnn,$4.); 

  DateInclusion_Char = IncVisDatJou_Char||"/"||IncVisDatMoi_Char||"/"||IncVisDatAnn_Char;
  DateInclusion=input(DateInclusion_Char ,ddmmyy10.);
  format DateInclusion ddmmyy10.;
  IncNaiDatJou_Char = "15";
  if (IncNaiDatMoi<10) then
    do;
      IncNaiDatMoi_Char_0=put(IncNaiDatMoi,$1.); 
      IncNaiDatMoi_Char = "0"||IncNaiDatMoi_Char_0;
	end;
  else
    IncNaiDatMoi_Char=put(IncNaiDatMoi,$2.); 
  format IncNaiDatMoi_Char $2.; 
  IncNaiDatAnn_Char=put(IncNaiDatAnn,$4.); 

  DateNai_Char = IncNaiDatJou_Char||"/"||IncNaiDatMoi_Char||"/"||IncNaiDatAnn_Char;
  DateNai=input(DateNai_Char ,ddmmyy10.);
  format DateNai ddmmyy10.;
  Age = (DateInclusion - DateNai)/365;

  if (Membre ="") then 
    Presence_Inclusion = 1;
  else;
    Presence_Inclusion = IncCluPresMem;

  if (Membre ="") then 
    do;
	  if (IncExaCliPru = 1) then
	    Prurit = 0;
	  if (IncExaCliPru in (2,3,4)) then
	    Prurit = 1;	 
	end;
  else
    do;
	  if (IncCluPresMem = 0) then 
	    Prurit = IncExaCliPruAbs;
	  else
	    do;
	      if (IncExaCliPru = 1) then
	        Prurit = 0;
	      if (IncExaCliPru in (2,3,4)) then
	        Prurit = 1;	 
		end;
	end;
run;
PROC SORT data=Inc;
  by ClePat;
run;
DATA Tab4;
  merge Tab3 Inc;
  by ClePat;
run; 
PROC SORT data=Tab4;
  by Missing_O;
run;

/* Index cas or not */
PROC FREQ data=Tab4;
  table CasIndex*Missing_O / chisq;
run;
/* Sex */
PROC FREQ data=Tab4;
  table IncSex*Missing_O / chisq;
run;
/* Age */
PROC MEANS data=Tab4 median Q1 Q3;
  var Age;
  by Missing_O;
run;
PROC NPAR1WAY data=Tab4 Wilcoxon;
  var Age;
  class Missing_O;
run;
/* Present during the inclusion visit */
PROC FREQ data=Tab4;
  table Presence_Inclusion*Missing_O / chisq;
run;
/* Presence of prurit */
PROC FREQ data=Tab4;
  table Prurit*Missing_O / chisq;
run;

/* Results obtained for those variables                                                   */
/* p- values correspond to the tests assessing the association between                    */
/* these variables and whether the outcome was missing or not                             */
/* - Index case - CasIndex - p = 0.445                                                    */
/* - Sex - IncSex - p = 0.713                                                             */
/* - Age - Age - p = 0.057                                                                */
/* - Present at the inclusion visit - Presence_Inclusion - p = 0.095                      */
/* - Presence of prurit - Prurit - p = 0.145 - 4 données manquantes                       */


PROC MI data=Tab4 seed=12345 out=MIOut1;
  class CasIndex IncSex Presence_Inclusion Prurit Outcome_Individuel_Num;
  fcs nbiter=10 discrim(Prurit Outcome_Individuel_Num/details);
  var CasIndex IncSex Age Presence_Inclusion Prurit Outcome_Individuel_Num;
run;
DATA MIOut2;
  set MIOut1;
  Centre=substr(ClePat,1,2);
run;
PROC SORT data=MIOut2;
  by _imputation_;
run;

/* Point estimates */
PROC FREQ data=MIOut2;
  table Groupe*Outcome_Individuel_Num / out=FreqCount outpct;
  by _imputation_;
run;
DATA FreqCount2;
  set FreqCount;
  n = 100*Count/Pct_Row;
  stderr_Pct_Row = sqrt((Pct_Row*(100-Pct_Row)/n));
run;
PROC SORT data=FreqCount2;
  by Groupe Outcome_Individuel_Num;
run;
PROC MIANALYZE data=FreqCount2;
  modeleffects Pct_Row;
  stderr stderr_Pct_Row;
  by Groupe Outcome_Individuel_Num;
run;

ods select none;
PROC MIXED data=MIOut2;
  class Groupe Cluster Centre;
  model Outcome_Individuel_Num = Groupe / s covb cl;
  random int / subject=Centre;
  random int / subject=Cluster(Centre);
  lsmeans Groupe / cl;
  by _imputation_;
  ods output SolutionF=mixparms CovB=mixcovb;
run;
ods select all;
DATA Mixparms_Ivm;
  set mixparms;
  if Groupe ne "Ivermectine" then delete;
run;
DATA Mixparms_IVM_2;
  set Mixparms_ivm;
  _imputation_ = _n_;
run;
PROC MIANALYZE parms=mixparms_IVM_2;
  modeleffects Groupe;
run;

/* Analysis for compliants */

DATA Tab2;
  set Tab;
  Compliance = 0;
  if (Compliance_Individuel = "Compliant") and (Outcome_Individuel_Num ne .) then
    Compliance = 1;
run;
PROC FREQ data=Tab2; 
  table Groupe*Outcome_Individuel_Num;
  where Compliance =1;
run;
PROC MIXED data=Tab2;
  class Groupe Cluster Centre;
  model Outcome_Individuel_Num = Groupe / s cl;
  random int / subject=Centre;
  random int / subject=Cluster(Centre);
  lsmeans Groupe / cl;
  where Compliance =1;
run;

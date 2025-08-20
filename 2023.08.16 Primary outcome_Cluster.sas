/******************************************************************************************************************/
/* This program correspond to the main analysus of the SCRATCH trial                                              */
/* The outcome is a cluster-level binary outcome :																  */
/*     - 1 means that all cluster members are scabies-free at Day 28											  */
/*     - 0 means taht at least one member of the cluster still has scabies at Day 28                              */
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
run;
PROC SORT data=Rando;
  by ClePat;
run;

data WORK.OUTCOME_0    ;
 %let _EFIERR_ = 0; 
 infile 'U:\CIC_ACQ\_BIOSTAT\0.Biométrie\Etudes\2013\CHU\F Boralevi_SCRATCH\Statistiques\Analyse\Bases\2023.08.16 Outcome and Compliance.csv' delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
         informat _ best32. ;
         informat ClePat $6. ;
         informat Cluster best32. ;
         informat Compliance_Cluster $4. ;
         informat Compliance_Individuel $9. ;
         informat Outcome_Cluster $5. ;
         informat Outcome_Individuel $5. ;
         format _ best12. ;
         format ClePat $6. ;
         format Cluster best12. ;
         format Compliance_Cluster $4. ;
         format Compliance_Individuel $9. ;
         format Outcome_Cluster $5. ;
         format Outcome_Individuel $5. ;
      input
                  _
                  ClePat $
                  Cluster
                  Compliance_Cluster $
                  Compliance_Individuel $
                  Outcome_Cluster $
                  Outcome_Individuel $
      ;
      if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
      run;


DATA Outcome_1;
  set Outcome_0;
  if (Outcome_Cluster="TRUE") then
    Outcome_Cluster_Num = 1;
  if (Outcome_Cluster="FALSE") then
    Outcome_Cluster_Num = 0;
  if (Outcome_Cluster not in ("TRUE","FALSE")) then
    Outcome_Cluster_Num = .;
run;
PROC SORT data=Outcome_1;
  by ClePat;
run; 
DATA Outcome;
  set Outcome_1;
  by Cluster;
  if first.Cluster;
run;
PROC SORT data=SCRATCH.Rnd;
  by ClePat;
run;
DATA Tab;
  merge Rando SCRATCH.Rnd Outcome;
  by ClePat;
run;

/* Analysis for completers, i.e. considering only participants who had the Day 28 assessement */
PROC FREQ data=Tab;
  table Groupe*Outcome_Cluster_Num;
  where ClePat not in ("0516", "0518", "0519", "0520", "2623"); /* Those patients were excluded from all analyses because no consent form was recovered */
run;
DATA Tab_2;
  set Tab;
  Centre=substr(ClePat,1,2);
run;
PROC MIXED data=Tab_2;
  class Groupe Centre;
  model Outcome_Cluster_Num = Groupe / s cl;
  repeated / type = cs subject=centre;
  lsmeans Groupe / cl;
  where ClePat not in ("0516", "0518", "0519", "0520", "2623"); run;
run;


/* Analysis for all participants */


/* Step 1: looking which variables were associated to the missingness mechanism for multiple imputation */
PROC SORT data=SCRATCH.RND;
  by ClePat;
run;
DATA T1;
  merge Tab_2 Scratch.Rnd;
  by ClePat;
  if ClePat in ("0516", "0518", "0519", "0520", "2623") then delete;
  if Outcome_Cluster_Num = . then
    Missing_O = 1;
  if Outcome_Cluster_Num in (0,1) then
    Missing_O = 0;
  if Centre in (1,2,5,9,12,16,22,24,26) then
    GrosCentre = 1;
  else
    GrosCentre = 0;
run;

/* Centre size */
PROC FREQ data=T1;
  table Missing_O*GrosCentre / chisq;
run;

/* Index case: child or adult? */
PROC FREQ data=T1;
  table Missing_O*rndPatTyp / chisq;
run;

/* Cluster size */
PROC SORT data=T1;
  by Missing_O;
run;
PROC MEANS n median Q1 Q3 data=T1;
  var rndNbPerClus;
  by Missing_O;
run;
PROC NPAR1WAY data=T1 Wilcoxon;
  var rndNbPerClus;
  class Missing_O;
run;

/* Time since first symptoms of scabies */
PROC MEANS n median Q1 Q3 data=T1;
  var rndDelAppSigGal;
  by Missing_O;
run;
PROC NPAR1WAY data=T1 Wilcoxon;
  var rndDelAppSigGal;
  class Missing_O;
run;

/* Previous treatment */
PROC FREQ data=T1;
  table Missing_O*rndTttGal12Moi / chisq;
run;

/* Cluster members: was there any symptomatic cluster member? */
DATA Tab0;
  set SCRATCH.RndClu;
  Cluster=substr(ClePat,1,4);
run;
PROC SORT data=Tab0;
  by Cluster ClePat;
run;
DATA Tab1;
  set Tab0;
  by Cluster;
  if first.Cluster;
  ClePat_1 = ClePat;
  rndCluDelAppSigGal_1 = rndCluDelAppSigGal;
  rndCluDelAppSigGalNa_1 = rndCluDelAppSigGalNa;
  keep Cluster rndCluDelAppSigGal_1 rndCluDelAppSigGalNa_1;
run;
DATA Tab0_Moins1;
  set Tab0;
  by Cluster;
  if first.Cluster then delete;
run;
PROC SORT data=Tab0_Moins1;
  by Cluster;
run;
DATA Tab2;
  set Tab0_Moins1;
  by Cluster;
  if first.Cluster;
  ClePat_2 = ClePat;
  rndCluDelAppSigGal_2 = rndCluDelAppSigGal;
  rndCluDelAppSigGalNa_2 = rndCluDelAppSigGalNa;
  keep Cluster rndCluDelAppSigGal_2 rndCluDelAppSigGalNa_2;
run;
DATA Tab0_Moins2;
  set Tab0_Moins1;
  by Cluster;
  if first.Cluster then delete;
run;
PROC SORT data=Tab0_Moins2;
  by Cluster;
run;
DATA Tab3;
  set Tab0_Moins2;
  by Cluster;
  if first.Cluster;
  ClePat_3 = ClePat;
  rndCluDelAppSigGal_3 = rndCluDelAppSigGal;
  rndCluDelAppSigGalNa_3 = rndCluDelAppSigGalNa;
  keep Cluster rndCluDelAppSigGal_3 rndCluDelAppSigGalNa_3;
run;
DATA Tab0_Moins3;
  set Tab0_Moins2;
  by Cluster;
  if first.Cluster then delete;
run;
PROC SORT data=Tab0_Moins3;
  by Cluster;
run;
DATA Tab4;
  set Tab0_Moins3;
  by Cluster;
  if first.Cluster;
  ClePat_4 = ClePat;
  rndCluDelAppSigGal_4 = rndCluDelAppSigGal;
  rndCluDelAppSigGalNa_4 = rndCluDelAppSigGalNa;
  keep Cluster rndCluDelAppSigGal_4 rndCluDelAppSigGalNa_4;
run;
DATA Tab0_Moins4;
  set Tab0_Moins3;
  by Cluster;
  if first.Cluster then delete;
run;
PROC SORT data=Tab0_Moins4;
  by Cluster;
run;
DATA Tab5;
  set Tab0_Moins4;
  by Cluster;
  if first.Cluster;
  ClePat_5 = ClePat;
  rndCluDelAppSigGal_5 = rndCluDelAppSigGal;
  rndCluDelAppSigGalNa_5 = rndCluDelAppSigGalNa;
  keep Cluster rndCluDelAppSigGal_5 rndCluDelAppSigGalNa_5;
run;
DATA Tab0_Moins5;
  set Tab0_Moins4;
  by Cluster;
  if first.Cluster then delete;
run;
PROC SORT data=Tab0_Moins5;
  by Cluster;
run;
DATA Tab6;
  set Tab0_Moins5;
  by Cluster;
  if first.Cluster;
  ClePat_6 = ClePat;
  rndCluDelAppSigGal_6 = rndCluDelAppSigGal;
  rndCluDelAppSigGalNa_6 = rndCluDelAppSigGalNa;
  keep Cluster rndCluDelAppSigGal_6 rndCluDelAppSigGalNa_6;
run;
DATA Tab0_Moins6;
  set Tab0_Moins5;
  by Cluster;
  if first.Cluster then delete;
run;
PROC SORT data=Tab0_Moins6;
  by Cluster;
run;
DATA Tab7;
  set Tab0_Moins6;
  by Cluster;
  if first.Cluster;
  ClePat_7 = ClePat;
  rndCluDelAppSigGal_7 = rndCluDelAppSigGal;
  rndCluDelAppSigGalNa_7 = rndCluDelAppSigGalNa;
  keep Cluster rndCluDelAppSigGal_7 rndCluDelAppSigGalNa_7;
run;
PROC SORT data=Tab1; by Cluster; run;
PROC SORT data=Tab2; by Cluster; run;
PROC SORT data=Tab3; by Cluster; run;
PROC SORT data=Tab4; by Cluster; run;
PROC SORT data=Tab5; by Cluster; run;
PROC SORT data=Tab6; by Cluster; run;
PROC SORT data=Tab7; by Cluster; run;
DATA Tab8;
  merge Tab1 Tab2 Tab3 Tab4 Tab5 Tab6 Tab7;
  by cluster;
  if (cluster="0233") then
    rndCluDelAppSigGal_2 = .;
  if (cluster="0238") then
    rndCluDelAppSigGal_1 = .;
  if (cluster="1218") then
    do;
      rndCluDelAppSigGalNa_1 = .; /* Participant 1218E2 */
      rndCluDelAppSigGalNa_4 = .; /* Participant 1218A1 */
	end;
  if (cluster="1236") then
    rndCluDelAppSigGalNa_4 = .; /* Participant 1236E2 */
  if (rndCluDelAppSigGal_1 ne .) or (rndCluDelAppSigGal_2 ne .) or (rndCluDelAppSigGal_3 ne .) or (rndCluDelAppSigGal_4 ne .) or (rndCluDelAppSigGal_5 ne .) 
  	or (rndCluDelAppSigGal_6 ne .) or (rndCluDelAppSigGal_7 ne .) then
    Presence_Sympt = 1;
  else
    Presence_Sympt = 0;
	Cluster_Num = input(Cluster,4.0);
	format Cluster_Num 4.0;
run;
PROC SORT data=Tab8;
  by Cluster_Num;
run;
DATA T1_1;
  set T1;
   Cluster_Num = Cluster;
   drop Cluster;
run;
PROC SORT data=T1_1;
  by Cluster_Num;
run;
DATA Tab9;
  merge T1_1 Tab8;
  by Cluster_Num;
  if Cluster in ("0516", "0518", "0519", "0520", "2623") then delete;
  if (Presence_Sympt = .) then
    Presence_Sympt = 0; /* 22 clusters de taille 1 */
run;
PROC FREQ data=Tab9;
  table Missing_O*Presence_Sympt / chisq;
run;

/* Results obtained for those variables                                                   */
/* p- values correspond to the tests assessing the association between                    */
/* these variables and whether the outcome was missing or not                             */
/* - Centres in which more than 10 clusters were included - GrosCentre - p = 0.215        */
/* - Index case = child / adult - rndPatTyp - p = 0,096                                   */
/* - Cluster size - rndNbPerClus - p = 0.775                                              */
/* - Time since first symptoms - rndDelAppSigGal - p = 0,331                              */
/* - Previous treatment - rndTttGal12Moi - p = 0.140                                      */
/* - Symptomatic cluster members - Presence_Sympt - p = 0.086                             */

PROC MI data=Tab9 seed=12345 out=MIOut1;
  class rndPatTyp rndTttGal12Moi Presence_Sympt Outcome_Cluster_Num;
  fcs nbiter=10 discrim(Outcome_Cluster_Num/details);
  var GrosCentre rndPatTyp rndNbPerClus rndDelAppSigGal rndTttGal12Moi Presence_Sympt Outcome_Cluster_Num;
run;
DATA MIOut2;
  set MIOut1;
  Centre=substr(ClePat,1,2);
  if ClePat in ("0516", "0518", "0519", "0520", "2623") then delete;
run;
PROC SORT data=MIOut2;
  by _imputation_;
run;

/* Point estimates in both arms */
PROC FREQ data=MIOut2 noprint;
  table Groupe*Outcome_Cluster_Num / out=FreqCount outpct;
  by _imputation_;
run;
DATA FreqCount2;
  set FreqCount;
  n = 100*Count/Pct_Row;
  stderr_Pct_Row = sqrt((Pct_Row*(100-Pct_Row)/n));
run;
PROC SORT data=FreqCount2;
  by Groupe Outcome_Cluster_Num;
run;
PROC MIANALYZE data=FreqCount2;
  modeleffects Pct_Row;
  stderr stderr_Pct_Row;
  by Groupe Outcome_Cluster_Num;
run;

/* Mixed model, considering centres as a random effect */
ods select none;
PROC MIXED data=MIOut2;
  class Groupe Centre;
  model Outcome_Cluster_Num = Groupe / s covb cl;
  repeated / type = cs subject=centre;
  lsmeans Groupe / cl;
  by _imputation_;
  where ClePat not in ("0516", "0518", "0519", "0520", "2623");
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


/* Per protocol analysis */

DATA Tab_PP;
  set Tab;
  if ClePat in ("0516", "0518", "0519", "0520", "2623") then delete;
  Compliance = 0;
  if (Compliance_Cluster="TRUE") and (Outcome_Cluster_Num ne .) then
    Compliance = 1;
run;
PROC FREQ data=Tab_PP;
  table Groupe*Outcome_Cluster_Num;
  where Compliance=1;
run;
DATA Tab_PP_2;
  set Tab_PP;
  Centre=substr(ClePat,1,2);
run;
PROC MIXED data=Tab_PP_2;
  class Groupe Centre;
  model Outcome_Cluster_Num = Groupe / s cl;
  repeated / type = cs subject=centre;
  lsmeans Groupe / cl;
  where Compliance=1;
run;


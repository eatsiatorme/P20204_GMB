clear all
set more off

*************************************************************************************************************************************
*************************************************************************************************************************************
*Program: BC_comparison.do
*Author: find Matt White's full bcstats package and template do-file at https://ipastorage.box.com/bcstats 
*Editor: Lindsey Shaughnessy (from IPA's bcstats template do-file) 
*Last Modified: 2017-09-02 //Saurabh
*************************************************************************************************************************************
*************************************************************************************************************************************
cd "$backcheck_path"

local files: dir `"$cleaning\/`file'"' file "*.dta", respectcase
foreach file of local files{
	di `"`file'"'
	copy `"$cleaning\/`file'"' `"$backcheck_path\/`file'"', replace
}




**********************************************************************
*Step 1: Set CD and locals
**********************************************************************
* Set your working directory to use relative references.

* Log your results.
cap log close
log using "bcstats_log.log", replace 



/*
use "Tekki_Fii_PV_4_BC"
clonevar ApplicantID = id_key
destring ApplicantID, replace
drop id_key
order ApplicantID, first 
save "Tekki_Fii_PV_4_BC", replace 
*/
use "Tekki_Fii_PV_4_BC"


replace id_key = "100099" if full_name == "TIDA S FOFANA" 
replace id_key = "100012" if full_name == "LAMIN KASSAMA"
replace id_key = "100168" if full_name == "YUSUPHA SAMATEH"
replace id_key = "100145" if full_name ==  "EDRISA KANDEH"
replace id_key = "100295" if full_name ==  "YERO BALDEH"
replace id_key = "100359" if full_name == "ADAMA M SAIDY"
replace id_key = "100395" if full_name == "NFAMARA KINTEH"
replace id_key = "100211" if full_name == "ISATOU JALLOW"
replace id_key = "100020" if full_name == "MARIAMA CAMARA"
replace id_key = "100119" if full_name == "KAWSU DAFFEH"
replace id_key = "100068" if full_name == "AWA BALAJO"
replace id_key = "100103" if full_name == "LAMIN SILLAH"
replace id_key = "100127" if full_name == "ROHEY JOBE"
replace id_key = "100283" if full_name == "LAMIN KANTEH"
replace id_key = "100383" if full_name == "LAMIN JALLOW"
replace id_key = "100410" if full_name == "YUSUPHA JABBIE"
replace id_key = "100270" if full_name == "MUHAMMED TOURAY"


cap drop ApplicantID
cap drop completed
clonevar ApplicantID = id_key
tostring confirm_interview, generate(completed)
destring ApplicantID, replace

save "Tekki_Fii_PV_4_BC", replace

* ENUMERATOR, TEAMS, BACK CHECKERS
* Enumerator variable
local enum "z1"
* Enumerator Team variable
//local enumteam ""
* Back checker variable
local bcer "z2"

* DATASETS

* The checked and deduped  dataset that will be used for the comparison
local orig_dta_cd "Tekki_Fii_PV_4.dta" 
* The checked and deduped backcheck dataset that will be used for the comparison
local bc_dta_cd "Tekki_Fii_PV_4_BC.dta" 

* Unique ID*
local id "ApplicantID" 

* VARIABLE LISTS
* Type 1 Vars: These should not change. They guage whether the enumerator 
* performed the interview and whether it was with the right respondent. 
* If these are high, you must discuss them with your field team and consider
* disciplinary action against the surveyor and redoing her/his interviews.

local t1vars "completed id1a id1b d1 b1 b2 c1 t1 j1a tekki_institute tekki_course tekkifii_complete" 

* Type 2 Vars: These are difficult questions to administer, such as skip 
* patterns or those with a number of examples. The responses should be the  
* same, though respondents may change their answers. Discrepanices should be 
* discussed with the team and may indicate the need for additional training.

*local t2vars "b2" 

* Type 3 Vars: These are key outcomes that you want to understand how 
* they're working in the field. These discrepancies are not used
* to hold surveyors accountable, but rather to gauge the stability 
* of the measure and how well your survey is performing. 

//local t3vars "???" 

* Variables from the backcheck that you want to see in the outputted .csv, 
* but not compare.

local keepbc "confirm_interview" 

* Variables from the original survey that you want to see in the 
* outputted .csv, but not compare.

*local keepsurvey "" 


* STABILITY TESTS*
* Type 3 Variables that are continuous. The stability check is a ttest.
*local ttest "varname" 
* Type 3 Variables that are discrete. The stability check uses signrank.
*local signrank "varname" 

* VALUES TO EXCLUDE*
* Set the values that you do not wanted included in the comparison
* if a backcheck variable has this value. These responses will not affect
* error rates and will not appear in the outputted .csv. Typically, you'll
* only use this only when the back check check data set has data for multiple
* back check versions.

//local exclude_num ""
//local exclude_str ""

**********************************************************************
*Step 2: Assembling and cleaning the original data, if necessary
**********************************************************************
* Clean duplicates and id's
* Assemble into one data set against which to compare the backcheck data
 clear
 use "Tekki_Fii_PV_4" // replace ??? with the main survey data 
 //drop if dup == 1 
 drop if consent == . 
 save "01_survey_data_checked_deduped.dta", replace 

**********************************************************************
*Step 2: Assembling and cleaning the backcheck data
**********************************************************************
* Rename vars from the backcheck to match the original survey, if necessary
* Clean duplicates and id's
* Assemble into one data set
 clear 
 use "Tekki_Fii_PV_4_BC.dta" // replace ??? with the back check data
 drop if consent == . 
 save "02_backcheck_data_checked_deduped.dta", replace 

**********************************************************************
*Step 3: Compare the backcheck and original data
**********************************************************************
* Run the comparison
* Make sure to specify the enumerator, enumerator team and backchecker vars.
* Select the options that you want to use, i.e. okrate, okrange, full, filename  
* This is the code that we think will be the most applicable across projects.
* Feel free to edit and add functionality.


bcstats, surveydata(`orig_dta_cd') bcdata(`bc_dta_cd') id(`id') replace /// 
     t1vars(`t1vars') enumerator(`enum') backchecker(`bcer') keepbc ("confirm_interview") 
	* t2vars(`t2vars') signrank(`signrank') 
	/* 3vars(`t3vars') ttest(`ttest') */ 

	
	
return list 
local files: dir `"$backcheck_path\/`file'"' file "*.csv", respectcase
foreach file of local files{
	di `"`file'"'
	copy `"$backcheck_path\/`file'"' `"$backcheck_report_folder\/`file'"', replace
}
********************************************************************************
* EXIT CODE
********************************************************************************

n: di "${proj}_${tool}_Backcheck ran successfully"
*quietly {


*** Youth_Corrections_Data
** Cycle 1 Batch 1
** Youth Survey
* Nathan Sivewright Feb 2021

// This do-file: 
// 1. Copies the exported data sets to the 'corrections' folder
// 2. Appends the versions data sets together - not necessary for now
// 3. Makes Corrections in the data
// When changing 'real' data you should
	// Make a comment including:
		// Who is making the change
		// Why is the change being made
		// Date of change
// 4. Remove unnecessary files in the corrections folder

cd "$corrections"


******************************
**Copy Files to Corrections **
******************************
local files: dir `"$cleaning\/`file'"' file "*.dta", respectcase
foreach file of local files{
	di `"`file'"'
	copy `"$cleaning\/`file'"' `"$corrections\/`file'"', replace
}



********************************************************************************
* TEKKI FII YOUTH (MAIN)
********************************************************************************
use "$corrections\/$table_name", clear
********************************************************************************
*FIXES FROM FIELD (To be moved to corrections later maybe?)
********************************************************************************
/*
These repondents were not interviewed in the midline on the tekki check because they said they did not participate. However after the phrasing of the question was done differently they confirmed they did participate. However, a problem with the tool did not allow their evaluation of the Tekki Fii programme. A phone call to obtain these particular responses was done on 15.01.2022 by Yusupha Jatta to obtain these responses.
*/
**ApplicantID: 100143
replace tekki_institute = 1 if ApplicantID==100143
replace tekkifii_complete = 1 if ApplicantID==100143
replace k1 = 4 if ApplicantID==100143
replace k2 = 4 if ApplicantID==100143
replace k4 = 3 if ApplicantID==100143
replace k5 = 3 if ApplicantID==100143
replace k6 = 4 if ApplicantID==100143
replace k8 = 4 if ApplicantID==100143
replace k9 = 5 if ApplicantID==100143
replace k10 =5 if ApplicantID==100143
replace k11 = 1 if ApplicantID==100143
replace k12_1= 1 if ApplicantID==100143
replace k12_5 =5 if ApplicantID==100143
replace tekkifii_check_ind = 0 if ApplicantID==100143
replace tekkifii_check_ind_why = "Because of covid" if ApplicantID==100143
replace k18=0 if ApplicantID==100143

**ApplicantID: 100303
replace tekki_institute = 1 if ApplicantID==100303
replace tekkifii_complete = 1 if ApplicantID==100303
replace k1 = 5 if ApplicantID==100303
replace k2 = 4 if ApplicantID==100303
replace k4 = 4 if ApplicantID==100303
replace k5 = 5 if ApplicantID==100303
replace k6 = 4 if ApplicantID==100303
replace k8 = 4 if ApplicantID==100303
replace k9 = 5 if ApplicantID==100303
replace k10 =4 if ApplicantID==100303
replace k11 = 0 if ApplicantID==100303
replace tekkifii_check_ind = 0 if ApplicantID==100303
replace tekkifii_check_ind_why = "Sick" if ApplicantID==100303
replace k18=0 if ApplicantID==100303

**ApplicantID: 100108
replace tekki_institute = 1 if ApplicantID==100108
replace tekkifii_complete = 1 if ApplicantID==100108
replace k1 = 4 if ApplicantID==100108
replace k2 = 5 if ApplicantID==100108
replace k4 = 4 if ApplicantID==100108
replace k5 = 5 if ApplicantID==100108
replace k6 = 4 if ApplicantID==100108
replace k8 = 4 if ApplicantID==100108
replace k9 = 4 if ApplicantID==100108
replace k10 =4 if ApplicantID==100108
replace k11 =1 if ApplicantID==100108
replace k12_1=1 if ApplicantID==100108
replace k13 =0 if ApplicantID==100108
replace k15 =5 if ApplicantID==100108
replace k16 =5 if ApplicantID==100108
replace k17=1 if ApplicantID==100108
replace k19=0 if ApplicantID==100108
replace k20=0 if ApplicantID==100108
replace k18=0 if ApplicantID==100108

**ApplicantID: 100208
replace tekki_institute = 1 if ApplicantID==100208
replace tekkifii_complete = 1 if ApplicantID==100208
replace k1 = 5 if ApplicantID==100208
replace k2 = 4 if ApplicantID==100208
replace k4 = 4 if ApplicantID==100208
replace k5 = 5 if ApplicantID==100208
replace k6 = 5 if ApplicantID==100208
replace k8 = 4 if ApplicantID==100208
replace k9 = 3 if ApplicantID==100208
replace k10 =4 if ApplicantID==100208
replace k11 = 0 if ApplicantID==100208
replace tekkifii_check_ind = 0 if ApplicantID==100208
replace tekkifii_check_ind_why = "I do not know" if ApplicantID==100208
replace k18 = 1 if ApplicantID==100208
save "$corrections\/$table_name", replace

********************************************************************************
* EXIT CODE
********************************************************************************

n: di "${proj}_${tool}_Corrections_Data ran successfully"
*}

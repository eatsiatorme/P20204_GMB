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

save "$corrections\/$table_name", replace

********************************************************************************
* EXIT CODE
********************************************************************************

n: di "${proj}_${tool}_Corrections_Data ran successfully"
*}

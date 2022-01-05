*quietly {

*** Youth_Clean_Data
** Endline
** Cycle 1
** Youth Survey
* Jan 2022

// This do-file: 
// 1. Copies the corrected data sets to the 'cleaning' folder
// 2. By Table, Cleans data 
	// Transforming variable format
	// Variable labelling
	// Value labelling
	// Adding variables from calculations of others
	// Renaming variables
	// Dealing with Special Responses
	// Categorising other specify
	// Rename table with more useful one
	
// This do-file includes all cleaning of the data to be ready for analysis. It should not be used for 'correcting' data from the field - this should be done in Corrections_Data

// 4. Remove unnecessary files in the cleaning folder


******************************
**Copy Corrections Files to Cleaning**
******************************

cd "$cleaning"

local files: dir `"$corrections\/`file'"' file "*.dta", respectcase
foreach file of local files{
	di `"`file'"'
	copy `"$corrections\/`file'"' `"$cleaning\/`file'"', replace
}


********************************************************************************
* TEKKI FII YOUTH (MAIN)
********************************************************************************
use "$main_table", clear



save "$main_table", replace

********************************************************************************
* EXIT CODE
********************************************************************************

n: di "${proj}_${tool}_Clean_Data ran successfully"
*}




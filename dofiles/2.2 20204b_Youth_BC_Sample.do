/*

Working well but:

- When you don't select uniform intervals - really does front load at the start of the back load quantiles
for example quantile 2 got even more than quantile 1.

- Also when uniform intervals and enumerator stratification is selected - the uniform_intervals can be broken... i guess
this occurs when quantiles are too small and enumerator does not do enough/any in that quantile.


ADD STUFF AT THE BEGINNING TO TELL THIS?

*/

clear all
quietly {

*******************************************************************************
* Set Macros
*******************************************************************************
* Macros to enter
local enumerator_stratification = 1
local uniform_intervals = 1
global sampsize = 350
global field_launch = "01/01/2022"
global today = "24/01/2022"
global sub_date "submissiondate"
local bc_proportion = 0.1
local intervals = 10
local fl_intervals = 1
local enum_num = 6 // Automate?
global path "$ONEDRIVE\P20204b_EUTF_GMB - Documents\02_Analysis\06_Field_Work_Reports\Endline\HFC\backchecks"


* Macros to leave
local tot_bc = ${sampsize}*`bc_proportion'
local fl_magnitude = 2 / `intervals' 
local bl_intervals = `intervals' - `fl_intervals'
local fl = `fl_intervals'
local bl_start = `fl' + 1
if `enumerator_stratification' != 1 {
local enum_num = 1
}
local tot_prop_fl = `fl_magnitude' * `fl_intervals'
local tot_prop_bl = 1 - `tot_prop_fl'
local tot_fl = `tot_prop_fl' * `tot_bc'
local tot_bl = `tot_prop_bl' * `tot_bc'
local bc_fl_strata = (`tot_fl'/`fl_intervals')/`enum_num'
local bc_bl_strata = (`tot_bl'/`bl_intervals')/`enum_num'
local x_bc (ceil(`bc_fl_strata') * `enum_num' * `fl_intervals') + (ceil(`bc_bl_strata') * `enum_num' * `bl_intervals')

n: di "Expected total number of backchecks:"
n: di `x_bc'
/*
if `x_bc' > ${sampsize} * (`bc_proportion' + 0.05)  {
	local x_bc_more = ceil(`x_bc' - `tot_bc')
	n: di "WITH THIS NUMBER OF INTERVALS AND STRATIFICATION BY ENUMERATOR WE EXPECT MORE BACK-CHECKS THAN THE ORIGINAL PROPORTION (`x_bc_more' more)"
	n: di "Consider reducing the number of intervals or taking off stratification by enumerator"
	
}
*/
}

*******************************************************************************
* Create directory for the samples 
*******************************************************************************

cap capture mkdir "$path"

*******************************************************************************
* Check to see whether the sample has been run before
*******************************************************************************

capture confirm file "$path\BC_Sample_Master.csv"

di _rc

if _rc {
	di "Sample Master does not exist"
	global previous_run = 0
}

if !_rc {
	di "Sample Master does exist!"
	global previous_run = 1
	import delimited using "$path\BC_Sample_Master.csv", clear case(preserve)
	tempfile bc_list
	save `bc_list'
}

*******************************************************************************
* Checking to see the total number of sample additions
*******************************************************************************
cd "$path" 
local files : dir "$path" file "BC_Sample_Add_*.csv", respectcase	
local total_ : word count  `files' // counts the total number of files

local next_sample = `total_' + 1
di "`total_'"


*******************************************************************************
* Creating the quantiles based on sample size
*******************************************************************************
clear
local field_launch_td = date("${field_launch}","DMY")

set obs $sampsize
gen sub_counter=_n
egen bc_deciles = xtile(sub_counter), nq(`intervals')
tempfile bc_dec
save `bc_dec'

*******************************************************************************
* Associating quatiles with collected data  
*******************************************************************************

use "$encrypted_path\corrections\Tekki_Fii_PV_3_checked.dta", clear

tempvar ${sub_date}_td
gen `${sub_date}_td' = dofc(${sub_date})
keep if `${sub_date}_td'<=date("${today}","DMY")
sort `${sub_date}_td' ApplicantID // IMPORTANT THIS ORDER SHOULD NEVER CHANGE

gen sub_counter=_n
merge 1:1 sub_counter using `bc_dec', nogen keep(1 3)

egen strata = group(z1 bc_deciles)

*******************************************************************************
* Randomization (1) 
*******************************************************************************
version 12.0  
isid ApplicantID, sort 
set seed 52544 // Random number generator
gen random_number = runiform() if ${completed}==1

*******************************************************************************
* Dropping previous selected cases from the randomization
*******************************************************************************

if $previous_run == 1 { 
merge 1:1 ApplicantID using `bc_list', gen(bc)
label def l_bc 1 "Not already Selected" 3 "Already Selected for BC"
label val bc l_bc

forvalues i = 1 / `intervals' {
	count if bc_deciles == `i' & bc_selected==1
	local already_selected_`i' = `r(N)'
	di "Interval:" "`i'" 
	di "`already_selected_`i''"

}

forvalues i = `bl_start' / `intervals' {
	gen x_`i'= `already_selected_`i''
}

tempvar bl_decile_already_selected
egen `bl_decile_already_selected' = rowtotal(x_*)
su `bl_decile_already_selected'
local bl_decile_already_selected = `r(mean)'
di "`bl_decile_already_selected'"

drop if bc_selected==1
drop bc_selected bc x_*
}

if $previous_run == 0 {
	forvalues i = 1 / `intervals' {
	local already_selected_`i' = 0
	local bl_decile_already_selected = 0
	}
}


********************************************************************************
* Ordering cases
********************************************************************************

if `enumerator_stratification' == 1 {
bysort bc_deciles z1: egen ordering = rank(random_number)
}
else {
bysort bc_deciles: egen ordering = rank(random_number)	
}
gen bc_selected=.

********************************************************************************
* Selecting Cases (With Quantile Stratification)
********************************************************************************
if `uniform_intervals' == 1 {

forvalues i = 1/`fl' {
local front_load_`i' = ceil(`bc_fl_strata' - `already_selected_`i'')
di "`i'"
di "`front_load_`i''"
}


forvalues i = `bl_start' / `intervals' {
local front_load_`i' = (`bc_bl_strata' - `already_selected_`i'')
	di "`i'"
	di "`front_load_`i''"
}

forvalues i = 1/`intervals' {
	local front_load_`i' = ceil(`front_load_`i'')
	di "`front_load_`i''"
	replace bc_selected=1 if ordering <= `front_load_`i'' & bc_deciles==`i'
	}
	
count if bc_selected == 1
}

********************************************************************************
* Selecting Cases (Without Quantile Stratification)
********************************************************************************
if `uniform_intervals' == 0 {
	
forvalues i = 1/`fl' {
local front_load_`i' = ceil(`bc_fl_strata' - `already_selected_`i'')
di "`front_load_`i''"
replace bc_selected=1 if ordering <= `front_load_`i'' & bc_deciles==`i'
}

tempvar rest_deciles
gen `rest_deciles' = . 


forvalues i = `bl_start' / `intervals' {
	replace `rest_deciles' = 1 if  bc_deciles==`i'
}

if `enumerator_stratification' == 1 {
bysort z1: egen ordering_2 = rank(random_number) if `rest_deciles' == 1
}
else {
egen ordering_2 = rank(random_number) if `rest_deciles' == 1
}

distinct bc_deciles
local bc_deciles_done = `r(ndistinct)' - `fl'
di "`bc_deciles_done'"
local bc_deciles_done_p = (`bc_deciles_done'/`bl_intervals') 
di "`bc_deciles_done_p'"


local tot_bl_enum = ceil(((`tot_bl' - `bl_decile_already_selected') / (`enum_num'))*`bc_deciles_done_p')
di "`tot_bl_enum'"
replace bc_selected=1 if ordering_2 <= `tot_bl_enum'

count if bc_selected == 1
}


********************************************************************************
* Running Checks on new addition to BC Sample
********************************************************************************
keep if bc_selected==1

keep ApplicantID bc_selected bc_deciles z1

count 
if `r(N)' > 0 {
export delimited using "$path\BC_Sample_Add_`next_sample'.csv", replace nolabel

********************************************************************************
* Adding to BC Master List
********************************************************************************
if `total_' == 0 {
	export delimited using "$path\BC_Sample_Master.csv", replace nolabel
}

if `total_' > 0 {
	export delimited using "$path\BC_Sample_Add_`next_sample'.csv", replace nolabel
	tempfile add_`next_sample'
	save `add_`next_sample''
	import delimited using "$path\BC_Sample_Master.csv", clear case(preserve)
	append using `add_`next_sample''
	export delimited using "$path\BC_Sample_Master.csv", replace nolabel
}
}

else {
	di "No extra cases selected for back-check"
}

	import delimited using "$path\BC_Sample_Master.csv", clear case(preserve)
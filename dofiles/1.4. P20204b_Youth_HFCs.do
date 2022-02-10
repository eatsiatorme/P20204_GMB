/*

*! version 3.0.0 Innovations for Poverty Action 30oct2018

/* =============================================================== 
   ===============================================================
   ============== IPA HIGH FREQUENCY CHECK TEMPLATE  ============= 
   ===============================================================
   =============================================================== */

* this line adds standard boilerplate headings
ipadoheader, version(15.0)
   

/* =============================================================== 
   ================== Import globals from Excel  ================= 
   =============================================================== */

ipacheckimport using "$hfc_path/04_checks/01_inputs/hfc_inputs.xlsm"


/* =============================================================== 
   ==================== Replace existing files  ================== 
   =============================================================== */

foreach file in "${outfile}" "${enumdb}" "${researchdb}" "${bcfile}" "${progreport}" "${dupfile}" "${textauditdb}" {
  capture confirm file "`file'"
  if !_rc {
    rm "`file'"
  }
}


/* =============================================================== 
   ================= Replacements and Corrections ================ 
   =============================================================== */

use "${sdataset}", clear

* recode don't know/refusal values
ds, has(type numeric)
local numeric `r(varlist)'
if !mi("${mv1}") recode `numeric' (${mv1} = .d)
if !mi("${mv2}") recode `numeric' (${mv2} = .r)
if !mi("${mv3}") recode `numeric' (${mv3} = .n)

if !mi("${repfile}") {
  ipacheckreadreplace using "${repfile}", ///
    id("ApplicantID") ///
    variable("variable") ///
    value("value") ///
    newvalue("newvalue") ///
    action("action") ///
    comments("comments") ///
    sheet("${repsheet}") ///
    logusing("${replog}") 
}

save "${sdataset_f}_checked"
/*
/* =============================================================== 
   ================== Resolve survey duplicates ================== 
   =============================================================== */
ex
ipacheckids ${id} using "${dupfile}", ///
  enum(${enum}) ///
  nolabel ///
  variable ///
  force ///
  save("${sdataset_f}_checked")
 */
/* =============================================================== 
   ==================== Survey Tracking ==========================
   =============================================================== */


/* <============ Track 1. Summarize completed surveys by date ============> */

if ${run_progreport} {    
ipatracksummary using "${progreport}", ///
  submit(${date}) ///
  target(${pnumber}) 
}


/* <========== Track 2. Track surveys completed against planned ==========> */

if ${run_progreport} {        
progreport, ///
    master("${master}") /// 
    survey("${sdataset_f}_checked") /// 
    id(${id}) /// 
    sortby(${psortby}) /// 
    keepmaster(${pkeepmaster}) /// 
    keepsurvey(${pkeepsurvey}) ///
    filename("${progreport}") /// 
    target(${prate}) ///
    mid(${pmid}) ///
    ${pvariable} ///
    ${plabel} ///
    ${psummary} ///
    ${pworkbooks} ///
	surveyok
}


 /* <======== Track 3. Track form versions used by submission date ========> */
      
ipatrackversions ${formversion}, /// 
  id(${id}) ///
  enumerator(${enum}) ///
  submit(${date}) ///
  saving("${outfile}") 

   

/* =============================================================== 
   ==================== High Frequency Checks ==================== 
   =============================================================== */
  
  
/* <=========== HFC 1. Check that all interviews were completed ===========> */

if ${run_incomplete} {
  ipacheckcomplete ${variable1}, ///
    complete(${complete_value1}) ///
    percent(${complete_percent1}) ///
    id(${id}) ///
    enumerator(${enum}) ///
    submit(${date}) ///
    keepvars("${keep1}") ///
    saving("${outfile}") ///
    sctodb("${server}") ///
    sheetreplace ${nolabel}
} 


/* <======== HFC 2. Check that there are no duplicate observations ========> */

if ${run_duplicates} {
  ipacheckdups ${variable2}, ///
    id(${id}) ///
    enumerator(${enum}) ///
    submit(${date}) ///
    keepvars(${keep2}) ///
    saving("${outfile}") ///
    sctodb("${server}") ///
    sheetreplace ${nolabel}
} 

  
/* <============== HFC 3. Check that all surveys have consent =============> */

if ${run_consent} { 
  ipacheckconsent ${variable3}, ///
    consentvalue(${consent_value3}) ///
    id(${id}) ///
    enumerator(${enum}) ///
    submit(${date}) ///
    keepvars(${keep3}) ///
    saving("${outfile}") ///
    sctodb("${server}") ///
    sheetreplace ${nolabel}
}


/* <===== HFC 4. Check that critical variables have no missing values =====> */

if ${run_no_miss} {
  ipachecknomiss ${variable4}, ///
    id(${id}) /// 
    enumerator(${enum}) ///
    submit(${date}) ///
    keepvars(${keep4}) ///
    saving("${outfile}") ///
    sctodb("${server}") ///
    sheetreplace ${nolabel}
}
 
 
/* <======== HFC 5. Check that follow up record ids match original ========> */

if ${run_follow_up} {
  ipacheckfollowup ${variable5} using ${master}, ///
    id(${id}) ///
    enumerator(${enum}) ///
    submit(${date}) ///
    saving("${outfile}") ///
    sctodb("${server}") ///
    sheetreplace
}


/* <============= HFC 6. Check skip patterns and survey logic =============> */

if ${run_logic} {
  ipachecklogic ${variable6}, ///
    assert(${assert6}) ///
    condition(${if_condition6}) ///
    id(${id}) ///
    enumerator(${enum}) ///
    submit(${date}) ///
    keepvars(${keep6}) ///
    saving("${outfile}") ///
    sctodb("${server}") ///
    sheetreplace ${nolabel}
}

     
/* <======== HFC 7. Check that no variable has all missing values =========> */

if ${run_all_miss} {
  ipacheckallmiss ${variable7}, ///
    id(${id}) ///
    enumerator(${enum}) ///
    saving("${outfile}") ///
    sheetreplace ${nolabel}
}


/* <=============== HFC 8. Check for hard/soft constraints ================> */

if ${run_constraints} {
  ipacheckconstraints ${variable8}, ///
    smin(${soft_min8}) ///
    smax(${soft_max8}) ///
    id(${id}) ///
    enumerator(${enum}) ///
    submit(${date}) ///
    keepvars(${keep8}) ///
    saving("${outfile}") ///
    sctodb("${server}") ///
    sheetreplace ${nolabel}
}


/* <================== HFC 9. Check specify other values ==================> */

if ${run_specify} {
  ipacheckspecify ${child9}, ///
    parentvars(${parent9}) ///
    id(${id}) ///
    enumerator(${enum}) ///
    submit(${date}) ///
    keepvars(${keep9}) ///
    saving("${outfile}") ///
    sctodb("${server}") ///
    sheetreplace ${nolabel}
}

/* <========== HFC 10. Check that dates fall within survey range ==========> */

if ${run_dates} {
  ipacheckdates ${startdate10} ${enddate10}, ///
    surveystart(${surveystart10}) ///
    id(${id}) ///
    enumerator(${enum}) ///
    submit(${date}) ///
    keepvars(${keep10}) ///
    saving("${outfile}") ///
    sctodb("${server}") ///
    sheetreplace ${nolabel}
}


/* <============= HFC 11. Check for outliers in unconstrained =============> */

if ${run_outliers} {
  ipacheckoutliers ${variable11}, id(${id}) ///
    enumerator(${enum}) ///
    submit(${date}) ///
    multiplier(${multiplier11}) ///
    keepvars(${keep11}) ///
    ignore(${ignore11}) ///
    saving("${outfile}") ///
    sctodb("${server}") ///
    sheetreplace ${nolabel} ${sd}
}


/* <============= HFC 12. Check for and output field comments =============> */

if ${run_field_comments} {
  ipacheckcomment ${fieldcomments}, id(${id}) ///
    media(${sctomedia}) ///
    enumerator(${enum}) ///
    submit(${date}) ///
    keepvars(${keep12}) ///
    saving("${outfile}") ///
    sheetreplace ${nolabel}
}


/* <=============== HFC 13. Output summaries for text audits ==============> */

if ${run_text_audits} {
  ipachecktextaudit ${textaudit} using "${infile}",  ///
    saving("${textauditdb}")  ///
    media("${sctomedia}") ///
    enumerator(${enum}) ///
    keepvars(${keep13})
}


/* ===============================================================
   ================= Create Enumerator Dashboard =================
   =============================================================== */

if ${run_enumdb} {
  ipacheckenum ${enum} using "${enumdb}", ///
     dkrfvars(${dkrf_variable14}) ///
     missvars(${missing_variable14}) ///
     durvars(${duration_variable14}) ///
     othervars(${other_variable14}) ///
     statvars(${stats_variable14}) ///
     exclude(${exclude_variable14}) ///
     subdate(${submission_date14}) ///
     ${stats}
}
 

/* ===============================================================
   ================== Create Research Dashboard ==================
   =============================================================== */

* tabulate one-way summaries of important research variables
if ${run_research_oneway} {
  ipacheckresearch using "${researchdb}", ///
    variables(${variablestr15})
}

* tabulate two-way summaries of important research variables
if ${run_research_twoway} {
  ipacheckresearch using "${researchdb}", ///
    variables(${variablestr16}) by(${by16}) 
}
   
   
/* ===============================================================
   =================== Analyze Back Check Data ===================
   =============================================================== */

if ${run_backcheck} {
  bcstats, ///
      surveydata("${sdataset_f}_checked")  ///
      bcdata("${bdataset}")  ///
      id(${id})              ///
      enumerator(${enum})    ///
      enumteam(${enumteam})  ///
      backchecker(${bcer})   ///
      bcteam(${bcerteam})    ///
      t1vars(${type1_17})    ///
      t2vars(${type2_17})    ///
      t3vars(${type3_17})    ///
      ttest(${ttest17})      ///
      keepbc(${keepbc17})    ///
      keepsurvey(${keepsurvey17}) ///
      reliability(${reliability17}) ///
      filename("${bcfile}") ///
      exclude(${bcexclude}) ///
      ${bclower} ${bcupper} ${bcnosymbols} ${bctrim} ///
      ${bcshowall} ${bcshowrate} ${bcfull} ///
      ${bcnolabel} ${bcreplace}
}

*/

********************************************************************************
*
********************************************************************************
* MACROS

local checksheet "${main_table}_CHECKS"
global checking_log "$field_work_reports\checking_log" // Not sure why this has to be on again
global error_log "$field_work_reports\checking_log" // Not sure why this has to be on again

local datadir "corrections"

global no_new_checks = 0

********************************************************************************
* Take SurveyCTO Server Links
********************************************************************************

use "$corrections\/${main_table}.dta", clear

			    gen scto_link2=""
		local bad_chars `"":" "%" " " "?" "&" "=" "{" "}" "[" "]""'
		local new_chars `""%3A" "%25" "%20" "%3F" "%26" "%3D" "%7B" "%7D" "%5B" "%5D""'
		local url "https://$scto_server.surveycto.com/view/submission.html?uuid="
		local url_redirect "https://$scto_server.surveycto.com/officelink.html?url="

		foreach bad_char in `bad_chars' {
			gettoken new_char new_chars : new_chars
			replace scto_link2 = subinstr(key, "`bad_char'", "`new_char'", .)
		}
		replace scto_link2 = `"HYPERLINK("`url_redirect'`url'"' + scto_link2 + `"", "View Submission")"'

keep ApplicantID scto_link2
tempfile scto_link_var
save `scto_link_var'


******************************
**SETTING UP HYPERLING CODE IN EXCEL**
******************************

mata: 
mata clear
void basic_formatting(string scalar filename, string scalar sheet, string matrix vars, string matrix colors, real scalar nrow) 
{

class xl scalar b
real scalar i, ncol
real vector column_widths, varname_widths, bottomrows
real matrix bottom

b = xl()
ncol = length(vars)

b.load_book(filename)
b.set_sheet(sheet)
b.set_mode("open")

b.set_bottom_border(1, (1, ncol), "thin")
b.set_font_bold(1, (1, ncol), "on")
b.set_horizontal_align(1, (1, ncol), "center")

if (length(colors) > 1 & nrow > 2) {	
for (j=1; j<=length(colors); j++) {
	b.set_font((3, nrow+1), strtoreal(colors[j]), "Calibri", 11, "lightgray")
	}
}


// Add separating bottom lines : figure out which columns to gray out	
bottom = st_data(., st_local("bottom"))
bottomrows = selectindex(bottom :== 1)
column_widths = colmax(strlen(st_sdata(., vars)))	
varname_widths = strlen(vars)

for (i=1; i<=cols(column_widths); i++) {
	if	(column_widths[i] < varname_widths[i]) {
		column_widths[i] = varname_widths[i]
	}

	b.set_column_width(i, i, column_widths[i] + 2)
}

if (rows(bottomrows) > 1) {
for (i=1; i<=rows(bottomrows); i++) {
	b.set_bottom_border(bottomrows[i]+1, (1, ncol), "thin")
	if (length(colors) > 1) {
		for (k=1; k<=length(colors); k++) {
			b.set_font(bottomrows[i]+2, strtoreal(colors[k]), "Calibri", 11, "black")
		}
	}
}
}
else b.set_bottom_border(2, (1, ncol), "thin")

b.close_book()

}

void add_scto_link(string scalar filename, string scalar sheetname, string scalar variable, real scalar col, real scalar rowbeg, real scalar rowend)
{
	class xl scalar b
	string matrix links
	real scalar N

	b = xl()
	links = st_sdata(., variable)
	N = length(links) + 2

	b.load_book(filename)
	b.set_sheet(sheetname)
	b.set_mode("open")
	b.put_formula(rowbeg, col, links)
	b.set_font((rowbeg, rowend), col, "Calibri", 11, "5 99 193")
	b.set_font_underline((rowbeg, rowend), col, "on")
	b.set_column_width(col, col, 17)
	b.close_book()
	}
	
void check_list_format(string scalar filename, string scalar sheetname, string scalar variable, real scalar col, real scalar rowbeg, real scalar rowend, real scalar nvar)
{
	class xl scalar b
	string matrix links
	real scalar Nrow

	b = xl()
	links = st_sdata(., variable)
	Nrow = length(links) + 2
	
	
	b.load_book(filename)
	b.set_sheet(sheetname)
	b.set_mode("open")
	b.set_border((rowbeg,rowend), (col,nvar), "thin")
	b.close_book()
	}

end



******************************
**SETTING UP THE PROGRAM FOR THE ERROR LOOPS**
******************************


	global i=0

	capture prog drop addErr
	cd "$field_work_reports"
	cap mkdir checking_log
	cap mkdir error_log
	cd "$field_work_reports\error_log"
	cap mkdir archive
	
	program addErr
	qui{
		gen message="`1'"
		di "`errorfile'"
		keep if error!=.
		keep submissiondate $id error message $keepvar z2 z1
		global keepvar_counter = 1
		foreach var of varlist $keepvar {
			capture confirm string variable `var'
			if _rc == 0 {
			gen variable_$keepvar_counter = "`var'" + " = " + `var'
			local lbl : variable label `var' 
			gen label_$keepvar_counter = "`lbl'"
			global keepvar_counter = ${keepvar_counter}+1
			drop `var'
			}
			else {
			tostring `var', gen(`var'_str)
			gen variable_$keepvar_counter = "`var'" + " = " + `var'_str
			drop `var'_str
			local lbl : variable label `var' 
			gen label_$keepvar_counter = "`lbl'"
			global keepvar_counter = ${keepvar_counter}+1
			drop `var'
			}
		}
		
		
		count if error != .
		n dis "Found `r(N)' instances of error ${i}: `1'"
		capture duplicates drop
		save `c(tmpdir)'error_${main_table}_${i}.dta, replace
	}
	end
/*
******************************************
**Check if files are present in cleaning**
******************************************

	local cleaningfiles: dir "$corrections" file "*.dta", respectcase
	if `"`cleaningfiles'"' != ""{
		local dirs cleaning corrections
		local flgNocleaning 0 
	}
	else{
		local dirs cleaning
		local flgNocleaning 1
	}
	
	foreach datadir in `dirs'{
*/

	n di as result "Running Standard Checks  on `datadir' data"
		clear	
		tempfile `checksheet'
		gen float error=.
		gen float z2=.
		gen float z1=.
		gen str244 message=""
		format message %-244s
		save "$checking_log\\`checksheet'_`datadir'", replace 

	 	n di "Running user specified checks on `datadir' data:"
	 	noisily{ //delete if you want to see less output
		

/*


		
	*/
	

cd "$dofiles"	
include "1.45. P20204b_Youth_HFC_Stata.do"	

		**************************	
		**CREATE CHECKING SHEETS**
		**************************	
	di "Creating checking sheets"
		cd "$field_work_reports"
		local I=$i
		di "`datadir'"
		use "$checking_log\/`checksheet'_`datadir'", clear
			forvalues f=1/`I'{
			capture confirm file `c(tmpdir)'error_${main_table}_`f'.dta
			*dis _rc
			if _rc==0{	
				append using `c(tmpdir)'error_${main_table}_`f'.dta, nol
				sort $id
				erase `c(tmpdir)'error_${main_table}_`f'.dta
			}
		}	
		save, replace

	}
	


**************************
**Merge exported and cleaning**
**************************


use "$checking_log\\`checksheet'_corrections", clear



foreach var of varlist _all {
capture assert mi(`var')
if !_rc {
drop `var'
}
}

count
if `r(N)' > 0 {
	global add_check_sheet = 1
export excel using  "$checking_log\/`checksheet'.xlsx", firstrow(var) replace
}

else {
		global add_check_sheet = 0
}



****************************
* INTERVIEWER COMMENTS
****************************

cd "$dofiles"	
include "1.46. P20204b_Youth_HFC_Enum_Com.do"



********************************************************************************
* APPENDING 
********************************************************************************
global add_logic_sheet = 0
import excel "${outfile}", sheet("6. logic") clear first case(preserve)
count if ApplicantID != .

if `r(N)' > 0 {
	global add_logic_sheet = 1
gen logic = 1
}
tempfile logic
save `logic'

global add_constraints_sheet = 0
import excel "${outfile}", sheet("8. constraints") clear first case(preserve)
count if ApplicantID != .
if `r(N)' > 0 {
	global add_constraints_sheet = 1
replace variable = variable + " = " + value
rename variable variable_1
rename label label_1
drop value
}
tempfile constraints
save `constraints'



if $add_check_sheet == 1 {
import excel "$checking_log\/${main_table}_CHECKS.xlsx", clear first case(preserve)
tempfile other
save `other'
}

global add_outlier_sheet = 0
import excel "${outfile}", sheet("11. outliers") clear first case(preserve)

count if ApplicantID != .
if `r(N)' > 0 {
		global add_outlier_sheet = 1
gen variable_1 = variable + " = " + value
rename label label_1
drop variable value
}
tempfile outliers
save `outliers'


import excel "${outfile}", sheet("10. comments") clear first case(preserve)
count if ApplicantID != .
if `r(N)' > 0 {
	global add_comments_sheet = 1
	rename value variable_1 // value instead of variable + value as already done the concat
	rename comment label_1
	drop variable label
gen comments = 1
}
tempfile comments
save `comments'

clear

if $add_logic_sheet == 1 {
use `logic', clear
}

if $add_constraints_sheet == 1 {
append using `constraints', gen(constraint)
}
if $add_check_sheet == 1 {
append using `other', gen(other) 
}
if $add_outlier_sheet == 1 {
append using `outliers', gen(outliers)
}
if $add_comments_sheet == 1 {
append using `comments', gen(comments)
}

gen check_type=.

if $add_logic_sheet == 1 {
replace check_type = 1 if logic == 1
drop logic
}

if $add_constraints_sheet == 1 {
replace check_type = 2 if constraint == 1
drop constraint
}
if $add_check_sheet == 1 {
replace check_type = 3 if other == 1 
drop other error
}
if $add_outlier_sheet == 1 {
replace check_type = 4 if outliers == 1 
drop outliers
}

if $add_comments_sheet == 1 {
replace check_type = 5 if comments == 1 
drop comments
}

label def l_checktype 1 "Logic Check" 2 "Constraint Error" 3 "Other Quality Check" 4 "Outlier" 5 "Enumerator Comments"
label val check_type l_checktype


*merge m:1 ApplicantID using `scto_link_var', nogen keep(3)
*drop scto_link
*rename scto_link2 scto_link

*order submissiondate ApplicantID z2 z1 check_type message scto_link


global tryout "$ONEDRIVE\P20204b_EUTF_GMB - Documents\02_Analysis\06_Field_Work_Reports\Endline\HFC\error_log"

*******************************************************************************
* Check to see whether the sample has been run before
*******************************************************************************

capture confirm file "$tryout\error_log.xlsx" // Confirms that there is already an error log

di _rc

if _rc {
	di "Error Log does not exist"
	global previous_run = 0
}

if !_rc {
	di "Error log does exist!"
	global previous_run = 1
}

*******************************************************************************
* Create 'New list' - i.e. new errors that are flagged
*******************************************************************************

generate submissiondate_str = string(submissiondate, "%tc")
egen error_id = concat(variable_1 label_1 submissiondate_str ApplicantID z1 check_type message)


drop z1 z2
merge m:1 ApplicantID using "$corrections\/$table_name", nogen keep(3) keepusing(z1 z2) // getting labels for supervisor and enumerator
*label val z1 z1
decode z1, gen(enumerator)
*label val z2 z2
decode z2, gen(supervisor)
drop z1 z2
*/

tempfile new_list
save `new_list' // List of newly added errors

di "$previous_run"
if $previous_run == 0 { // If this is the first time - then create the error log
sort error_id
gen error_counter = _n
keep error_counter error_id
tempfile error_log_data_first
save `error_log_data_first'
export excel "$tryout\error_log.xlsx", firstrow(var) 
}

if $previous_run == 1 { // If this is not the first time make a copy of previous log and filter out any old cases
copy "$tryout\error_log.xlsx" "$tryout\archive\error_log_$datetime.xlsx", replace
import excel "$tryout\error_log.xlsx", clear firstrow 
tempfile error_log
save `error_log'
merge 1:1 error_id using `new_list'
su error_counter
local error_counter_upto = `r(max)' // Take total number of errors in log
di "`error_counter_upto'"
keep if _merge == 2 // Keep only new error cases

count 
if `r(N)' > 0 { // If there are indeed new error cases - create new version of the error log
*
sort error_counter error_id
replace error_counter = _n + `error_counter_upto'
keep error_counter error_id
tempfile error_log_data_new
save `error_log_data_new'
append using `error_log'
export excel "$tryout\error_log.xlsx", firstrow(var) replace
}
else {
	global no_new_checks = 1
}
}

if $no_new_checks == 1 { // If there are no new error cases
	di "No new checks to show"
}
else { // If there are indeed new error cases 


use `new_list', clear // Use new error cases
count 
if `r(N)' > 0 { 
	if $previous_run == 0 { // If new error cases AND this is the first time running then merge with the cases in the log
merge 1:1 error_id using `error_log_data_first', keep(3) keepusing(error_counter)
	}

	if $previous_run == 1 { // If new error cases AND there are previous errors then merge with error log but only keep new ones
merge 1:1 error_id using `error_log_data_new', keep(3) keepusing(error_counter)

	}
sort error_counter
drop error_id _merge submissiondate_str
}


merge m:1 ApplicantID using `scto_link_var', nogen keep(3)
capture confirm variable scto_link
if !_rc {
drop scto_link
}
rename scto_link2 scto_link

sort error_counter
order error_counter submissiondate ApplicantID supervisor enumerator check_type message scto_link
des, short
local n_vars `r(k)' // count number of variables

if $previous_run == 0 {
local error_counter_upto = 0
}



local startfrom = `error_counter_upto' + 3
export excel "$hfc_output\Checking_List.xlsx", sheet("Sheet1", modify) keepcellfmt cell(C`startfrom')


*******************************************************************************
* Mata Formatting Checking List
*******************************************************************************

		unab allvars : _all
		local pos : list posof "scto_link" in allvars
		local pos = `pos' + 2 // Because of status column
		di "`pos'"
		su error_counter
		local rowbeg = `r(min)' + 2
		local rowend = `r(max)' + 2
		mata: add_scto_link("$hfc_output\Checking_List.xlsx", "Sheet1", "scto_link", `pos', `rowbeg', `rowend')

		mata: check_list_format("$hfc_output\Checking_List.xlsx", "Sheet1", "ApplicantID", 1, `rowbeg', `rowend', `n_vars')	

	copy "$hfc_output\Checking_List.xlsx" "$hfc_output\archive\Checking_List_$datetime.xlsx", replace		
		}




*******************************************************************************
* Creating Status column
*******************************************************************************

import excel "$tryout\error_log.xlsx", clear firstrow // Open errors
merge 1:1 error_id using `new_list', keep(3) keepusing(error_id) nogen // Keep only 'new errors'
tempfile bleh
save `bleh' 

import excel "$hfc_output\Checking_List.xlsx", clear firstrow cellrange(B2) // Open up errors

merge 1:1 error_counter using `bleh', gen(still_error)

gen status = 0

capture confirm string variable Action
			if _rc == 0 {
			}
			else {
			tostring Action, replace

			}

replace status = 1 if still_error==3 & Action!="No further action"
replace status = 2 if still_error==1
replace status = 3 if Action=="No further action" & status != 2
replace status = 4 if Action=="Back-check"


drop still_error

label def l_status 1 "Error still remains" 2 "Error No Longer Remains" 3 "No further action" 4 "Sent for Back-check"
label val status l_status

keep status
export excel "$hfc_output\Checking_List.xlsx", sheet("Sheet1", modify) keepcellfmt cell(A3)

********************************************************************************
* CREATING LOCAL PARTNER CHECKING SHEET
********************************************************************************
import excel "$ONEDRIVE\P20204b_EUTF_GMB - Documents\04_Field Work\Share with CepRass\Checking_List_CepRass.xlsx", clear firstrow cellrange(B2)
*keep field_counter error_counter
drop scto_link
su field_counter
local field_check = `r(N)'
if `field_check'>0 {
	local field_check_count = `r(max)'
	foreach var of varlist variable_* label_* {
		capture confirm numeric variable `var'
		if _rc == 0 {
		tostring `var', gen(`var'_str)
		order `var'_str, after(`var')
		drop `var'
		rename `var'_str `var'
	}
	tempfile already_in_field
	save `already_in_field'
}



import excel "$hfc_output\Checking_List.xlsx", clear firstrow cellrange(A2)


capture confirm string variable Action
			if _rc == 0 {
			}
			else {
			tostring Action, replace

			}

keep if Action=="Field Clarification"
drop Action status

if `field_check'==0 {
gen field_counter = _n
merge m:1 ApplicantID using `scto_link_var', nogen keep(3)
drop scto_link
rename scto_link2 scto_link
order scto_link, after(message)	
}

if `field_check'>0 {
		foreach var of varlist variable_* label_* {
		capture confirm numeric variable `var'
		if _rc == 0 {
		tostring `var', gen(`var'_str)
		order `var'_str, after(`var')
		drop `var'
		rename `var'_str `var'
		}
	}
merge 1:1 error_counter using `already_in_field', keep(1) nogen keepusing(field_counter)
sort error_counter
replace field_counter = _n + `field_check_count'
merge 1:1 error_counter using `already_in_field', keep(1 2) nogen //force // remove force later
merge m:1 ApplicantID using `scto_link_var', nogen keep(3)
drop scto_link
rename scto_link2 scto_link
order scto_link, after(message)

}
sort field_counter
order field_counter, after(error_counter)

count 
if `r(N)' > 0 {
export excel "$ONEDRIVE\P20204b_EUTF_GMB - Documents\04_Field Work\Share with CepRass\Checking_List_CepRass.xlsx", sheet("Sheet1", modify) keepcellfmt cell(B3)


*******************************************************************************
* Mata Formatting Checking List
*******************************************************************************
des, short
local n_vars `r(k)' // count number of variables

		unab allvars : _all
		local pos : list posof "scto_link" in allvars
		local pos = `pos' + 1 // Because of status column
		di "`pos'"
		su field_counter
		local rowbeg = `r(min)' + 2
		local rowend = `r(max)' + 2
		mata: add_scto_link("$ONEDRIVE\P20204b_EUTF_GMB - Documents\04_Field Work\Share with CepRass\Checking_List_CepRass.xlsx", "Sheet1", "scto_link", `pos', `rowbeg', `rowend')

		mata: check_list_format("$ONEDRIVE\P20204b_EUTF_GMB - Documents\04_Field Work\Share with CepRass\Checking_List_CepRass.xlsx", "Sheet1", "ApplicantID", 1, `rowbeg', `rowend', `n_vars')	

}




********************************************************************************
* CREATING BACK CHECK
********************************************************************************

import excel "$hfc_output\Checking_List_Backcheck.xlsx", clear firstrow cellrange(B2)
*keep bc_counter error_counter
*drop scto_link
su bc_counter
local bc_check = `r(N)'
if `bc_check'>0 {
	local bc_check_count = `r(max)'
	tempfile already_in_bc
	save `already_in_bc'
}


import excel "$hfc_output\Checking_List.xlsx", clear firstrow cellrange(A2)

capture confirm string variable Action
			if _rc == 0 {
			}
			else {
			tostring Action, replace

			}

keep if Action=="Back-check"
drop Action status

if `bc_check'==0 {
gen bc_counter = _n	
}

if `bc_check'>0 {
merge 1:1 error_counter using `already_in_bc', keep(1) nogen keepusing(bc_counter)
sort error_counter
replace bc_counter = _n + `bc_check_count'
merge 1:1 error_counter using `already_in_bc', keep(1 2) nogen force // remove force later

}
sort bc_counter
order bc_counter, after(error_counter)

*drop scto_link

count 
if `r(N)' > 0 {
export excel "$hfc_output\Checking_List_Backcheck.xlsx", sheet("Sheet1", modify) keepcellfmt cell(B3)

}

ex
*******************************************************************************
* Mata Formatting Checking List
*******************************************************************************
des, short
local n_vars `r(k)' // count number of variables

		unab allvars : _all
		local pos : list posof "scto_link" in allvars
		local pos = `pos' + 1 // Because of status column
		di "`pos'"
		su field_counter
		local rowbeg = `r(min)' + 2
		local rowend = `r(max)' + 2
		mata: add_scto_link("$ONEDRIVE\P20204b_EUTF_GMB - Documents\04_Field Work\Share with CepRass\Checking_List_CepRass.xlsx", "Sheet1", "scto_link", `pos', `rowbeg', `rowend')

		mata: check_list_format("$ONEDRIVE\P20204b_EUTF_GMB - Documents\04_Field Work\Share with CepRass\Checking_List_CepRass.xlsx", "Sheet1", "ApplicantID", 1, `rowbeg', `rowend', `n_vars')	

}
ex



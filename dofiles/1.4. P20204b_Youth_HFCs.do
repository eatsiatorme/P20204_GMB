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



********************************************************************************
*
********************************************************************************
* MACROS

local checksheet "${main_table}_CHECKS"
global checking_log "$field_work_reports\checking_log" // Not sure why this has to be on again

local datadir "corrections"

********************************************************************************
* Take SurveyCTO Server Links
********************************************************************************

use "H:\corrections\Tekki_Fii_PV_3_checked.dta", clear

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

void add_scto_link(string scalar filename, string scalar sheetname, string scalar variable, real scalar col)
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
	b.put_formula(3, col, links)
	b.set_font((3, N), col, "Calibri", 11, "5 99 193")
	b.set_font_underline((3, N), col, "on")
	b.set_column_width(col, col, 17)
	b.close_book()
	}
	
void check_list_format(string scalar filename, string scalar sheetname, string scalar variable, real scalar col, real scalar row, real scalar nvar)
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
	b.set_border((row,Nrow), (col,nvar), "thin")
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

	program addErr
	qui{
		gen message="`1'"
		di "`errorfile'"
		keep if error!=.
		keep submissiondate $id error message $keepvar z1
		global keepvar_counter = 1
		foreach var of varlist $keepvar {
			capture confirm string variable `var'
			if _rc == 0 {
			}
			else {
			tostring `var', gen(`var'_str)

			}
		
			gen variable_$keepvar_counter = "`var'" + " = " + `var'_str
			drop `var'_str
			local lbl : variable label `var' 
			gen label_$keepvar_counter = "`lbl'"
			global keepvar_counter = ${keepvar_counter}+1
			drop `var'
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
		gen float z1=.
		gen str244 message=""
		format message %-244s
		save "$checking_log\\`checksheet'_`datadir'", replace 

	 	n di "Running user specified checks on `datadir' data:"
	 	noisily{ //delete if you want to see less output
		


cd "H:\corrections"

	
******************************
**BASIC CHECKS**
******************************
* DUPLICATES
	global i=1
	use $main_table, clear
	gen error=${i} if ApplicantID==9101
	global keepvar "consent"
	addErr "FLAGGED ID"
	
	global i=2
	use $main_table, clear
	foreach var of varlist a9 a10 a11 {
		gen `var'_otherperson = (`var'==2 | `var'==0)
	}
	egen check = rowtotal(*_otherperson)
	gen error=${i} if check>0 &  a3==1 & a3!=.
	global keepvar "a3 a9 a10 a11"
	addErr "Entered that others make Household Decisions, but no one else in Household"


	
	/*
		global i=
	use $main_table, clear
	gen error=${i} if
	addErr ""
	*/
*****************************************************************************************************************	
*	Checks to add
*****************************************************************************************************************	
	

	
	
	
	
	
	
	
		*****************************************************************************************************************
		********************************************* END ERRORS ********************************************************
		*****************************************************************************************************************

		
		
	
	
		
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




********************************************************************************
* APPENDING 
********************************************************************************

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

use `logic', clear
if $add_constraints_sheet == 1 {
append using `constraints', gen(constraint)
}
if $add_check_sheet == 1 {
append using `other', gen(other) 
}
if $add_outlier_sheet == 1 {
append using `outliers', gen(outliers)
}

gen check_type = 1 if logic == 1
drop logic
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


label def l_checktype 1 "Logic Check" 2 "Constraint Error" 3 "Other Quality Check" 4 "Outlier"
label val check_type l_checktype


merge m:1 ApplicantID using `scto_link_var', nogen keep(3)
drop scto_link
rename scto_link2 scto_link

order submissiondate ApplicantID z1 check_type message scto_link

des, short
local n_vars `r(k)'

export excel "$hfc_output\Checking_List.xlsx", firstrow(var) sheet("Sheet1", modify) keepcellfmt cell(A2)


import excel "$hfc_output\Checking_List.xlsx", clear firstrow cellrange(A2)

*merge 1:1 $id error using "$checking_log\\`checksheet'_corrections", keep(3) nogen keepusing(scto_link)
	*sort message
	*sort error $id
		unab allvars : _all
		local pos : list posof "scto_link" in allvars
		di "`pos'"
		mata: add_scto_link("$hfc_output\Checking_List.xlsx", "Sheet1", "scto_link", `pos')

		mata: check_list_format("$hfc_output\Checking_List.xlsx", "Sheet1", "ApplicantID", 1, 3, `n_vars')

use "$corrections\/${table_name}_checked.dta", clear

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





local cvar "comment"
local fname "commentsx"

cd "$media_path"

global i=0 // Do not change

use "$corrections\/${table_name}_checked.dta", clear

keep if `fname'!=""
tempfile only_comments
save `only_comments'

local files : dir "$media_path" file "Comments*.csv", respectcase	
local total_ : word count  `files' // counts the total number of files

if `total_' > 0 {
	
foreach file in `files'{	
	import delimited using "`file'", varnames(1) stringcols(2) bindquotes(strict) clear // Import each csv file in media folder
*	capture confirm numeric variable comment // Check for rogue blank comments - will cause error as stata thinks they are numeric when appending
*	    if !_rc {
*			tostring comment, replace // makes any blank a string variable
*		}
di "`file'"
gen variable = substr(fieldname, strrpos(fieldname,"/")+1, .) // Taking the variable name
rename comment `cvar' // Prepping for reshape
replace `cvar' = "[EMPTY COMMENT BY ENUMERATOR]" if `cvar' == "" & variable!=""
drop if `cvar' == ""

gen `fname'="media\"+"`file'" // Aligning with the commentx variable in the dataset to merge
drop fieldname
global i=${i}+1 // Naming each file as a tempfile to prepare for appending
tempfile comment_$i
save `comment_$i' // Creating a tempfile for each csv
}




/// THERE PROBABLY IS A CLEANER WAY OF DOING THIS!!
forval x = 1/`total_' { // For each of the total tempfiles
if `x'==1 { // If the first we don't want to append
use `comment_`x'', clear
tempfile all_comment
save `all_comment'
}
if `x'>1 {
use `all_comment', clear
di "`x'"
append using `comment_`x''
save `all_comment', replace
}
}

}

replace commentsx=upper(commentsx)
merge m:1 `fname' using "`only_comments'", keep(3) nogen // keepusing(z1 ApplicantID submissiondate)
gen value = ""
gen label = ""


levelsof variable, l(comment_vars)
foreach l of local comment_vars {
	di "`l'"
	macro drop _bort
	capture confirm variable `l' 
	if _rc == 0 {
	capture confirm string variable `l'
	if _rc == 0 {
		replace value = "`l'" + " = " + `l' if variable == "`l'" 
		local label : variable label `l'
		di "`label'"
		replace label = "`label'" if variable == "`l'" 
	}
	else {
	tostring `l', gen(`l'_str)
	replace value = "`l'" + " = " + `l'_str if variable == "`l'" 
	local label : variable label `l'
	di "`label'"
	replace label = "`label'" if variable == "`l'" 
}
}
else {
	capture unab bort : `l'_?
	di "XXXX: `bort'"
	local k `: word count `bort''
		di "HELLO MULTIPLE: `k'"	
	if `k' > 1 {
		di "HELLO MULTIPLE 2"
		tokenize `bort'
		while "`*'" != "" {
			di "`1'"
		capture confirm string variable `1' 
		
			if _rc == 0 {
			replace  value = value + " " + "`1'" + " = " + `1' if variable == "`l'" 
				local label : variable label `1'
				di "`label'"
				replace label = "`label'" if variable == "`l'" 
	}
	else {
	tostring `1', gen(`1'_str)
	replace  value = value + " " + "`1'" + " = " + `1'_str if variable == "`l'" 
	local label : variable label `1'
	di "`label'"
	replace label = "`label'" if variable == "`l'" 	
		
		
		}

			macro shift
}
}
}
}

replace value = "No value" if value == ""
replace label = "No label" if label == ""

gen message = "Enumerator added a comment on this question"

*merge m:1 ApplicantID using `scto_link_var', keep(3) nogen
*rename scto_link2 scto_link

keep submissiondate ApplicantID z1 variable label value comment message z2
order  submissiondate ApplicantID z1 variable label value comment message z2

gen x1 = z1
gen x2 = z2
drop z1 z2
rename (x1 x2) (z1 z2)

global comments_sheet_exist = 0

count 
if `r(N)' > 0 {
	global comments_sheet_exist = 1
export excel "${outfile}", sheet("10. comments", modify) firstrow(var)
}
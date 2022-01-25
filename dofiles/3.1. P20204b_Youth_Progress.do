

********************************************************************************
* 1. Creating Data Entry Progress Sheet
********************************************************************************

import delimited using "$sample_list\sample.csv", varnames(1) clear // WILL NEED TO UPDATE - THIS NEEDS TO BE THE SAMPLE

keep id_key
rename id_key ApplicantID

merge 1:1 ApplicantID using "$corrections\Tekki_Fii_PV_3_checked.dta"
gen submission=(_merge==3)
label def L_submission 0 "No Submission" 1 "Submitted"
label val submission L_submission
gen complete = (consent==1)
tempfile masterfield
save `masterfield'
keep ApplicantID submission z2 z1 _merge

drop _merge

order ApplicantID submission z2 z1

export excel using "$ONEDRIVE\P20204b_EUTF_GMB - Documents\02_Analysis\06_Field_Work_Reports\Endline\Data Progress\Data Progress.xlsx", sheet("caselist", modify) cell(A2) keepcellfmt
*export excel using "$ceprass_folder/data_entry_progress.xlsx", sheet("caselist", modify)  firstrow(var)

********************************************************************************
* 2. Creating Data Progress Dashboard
********************************************************************************
use `masterfield', clear
putexcel set "$ONEDRIVE\P20204b_EUTF_GMB - Documents\02_Analysis\06_Field_Work_Reports\Endline\Data Progress\Data Progress.xlsx", modify sheet("dashboard")

count
putexcel B3=`r(N)', nformat(number)

count if treatment==1
putexcel B4=`r(N)', nformat(number)
count if treatment==2
putexcel B5=`r(N)', nformat(number)
count if treatment==0
putexcel B6=`r(N)', nformat(number)


su submission
putexcel B8=`r(mean)', nformat(number_d2)
su complete // UPDATE
putexcel B9=`r(mean)', nformat(number_d2)
su duration if complete==1 // UPDATE WITH DURATION MINUTES
putexcel B10=`r(mean)', nformat(number)
ex






gen call_status_1=(call_status==1) // Completed
gen call_status_2=(call_status==2) // Respondent Reached but not complete
gen call_status_3=(inlist(call_status,3,4)) // Not reached
gen call_status_4=(call_status==5) // Refused

*tab call_status, gen(call_status_)
local row = 13
foreach var of varlist call_status_? {
    su `var'
	putexcel B`row'=`r(sum)', nformat(number)
	putexcel C`row'=`r(mean)', nformat(number_d2)
	local row = `row'+1
}

levelsof z1, l(l_z1)
local row = 20
foreach l of local l_z1 {
	su call_status_1 if z1==`l'
	putexcel B`row'=`r(sum)', nformat(number)
	capture su call_status_3 if z1==`l'
	putexcel C`row'=`r(sum)', nformat(number)
	capture su call_status_3 if z1==`l'
	putexcel D`row'=`r(sum)', nformat(number)
	capture su call_status_4 if z1==`l'
	putexcel E`row'=`r(sum)', nformat(number)
	su phone_call_duration_m if z1==`l' & call_status_1==1
	putexcel F`row'=`r(mean)', nformat(number)
	su daily_avg if z1== `l'
	putexcel G`row'=`r(mean)', nformat (number)
	local row = `row'+1
}


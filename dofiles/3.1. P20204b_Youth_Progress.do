

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
replace complete = 0 if complete == .
tempfile masterfield
save `masterfield'
keep ApplicantID submission z2 z1 submissiondate status _merge

drop _merge 

order ApplicantID submission status submissiondate z2 z1

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
su duration_m if complete==1 // UPDATE WITH DURATION MINUTES
putexcel B10=`r(mean)', nformat(number)

tabcount status, v(1/5) matrix(x)
local row = 14
putexcel B`row'=matrix(x)

local row = 23
tabcount z1 status, v1(1/9) v2(1/5) matrix(y)
putexcel B`row'=matrix(y)

fre z1 duration_m
local row = 22
forvalues i = 1/10 {
	local rowx = `row'+`i'
	count if z1==`i' & complete==1
	if `r(N)' > 0 {
	su duration_m if z1==`i' & complete==1
	putexcel I`rowx'=`r(mean)', nformat(number)
	su complete if z1==`i'
	putexcel H`rowx'=`r(mean)', nformat(number_d2)
	}
	
}



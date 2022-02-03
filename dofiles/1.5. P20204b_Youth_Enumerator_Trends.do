cd "H:\corrections"
*use $main_table, clear

// DELETE BEGIN
use "C:\Users\NathanSivewright\C4ED\P20204b_EUTF_GMB - Documents\02_Analysis\02_Data\Midline\C2\Youth\data_an.dta", clear
encode z1_text, gen(z1)

gen interview_date = dofc(starttime)
format interview_date %td


// DELETE END

global n_min = 10 
global sd = 3

global trigger "d1 b2 c1"
global outcome "$component_vars_bin $component_vars_cont $outcome_vars_bin $outcome_vars_cont"




*replace duration_m=. if status!=1
replace duration_m=. if completed!=1 // delete

*bysort interview_date z1: egen interview_per_day = total(completed) // completed => status==1
*bysort interview_date z1: egen hours_per_day = total(duration_m) // completed => status==1
*replace hours_per_day = hours_per_day / 60

tempfile row_interview
save `row_interview'

collapse (sum)completed duration_m, by(interview_date z1)
clonevar interview_per_day=completed
gen hours_per_day=duration_m/60

tempfile row_date_enum
save `row_date_enum'

********************************************************************************
* KEY VARIABLE OR TRIGGER OUTLIER MEAN VALUE BY ENUMERATOR
********************************************************************************
use `row_interview', clear
tempfile interviewers
inttrend duration_m $trigger $outcome using `interviewers', interviewer(z1) 
use `interviewers', clear



gen upper = .
gen lower = .
gen median = .
gen swilk_p = .
gen trigger = .
gen outcome = .
gen duration_check = 1 if var=="duration_m"
gen flag = 0

levelsof var, l(var_list)
levelsof interviewer, l(interviewer_list)

foreach l of local var_list {
	replace trigger=(strpos("$trigger", "`l'")>0) if var=="`l'"
	replace outcome=(strpos("$outcome", "`l'")>0) if var=="`l'"
	swilk mu_i if var=="`l'" 
	local swilk_p_local = `r(p)'
	replace swilk_p = `r(p)' if var=="`l'"
	foreach m of local interviewer_list {
	su mu_i if var=="`l'" & interviewer!=`m' , d
	replace median = `r(p50)' if var=="`l'" & interviewer==`m'
	replace upper = `r(mean)' + (`r(sd)' * ${sd}) if var=="`l'" & interviewer==`m'
	replace lower = `r(mean)' - (`r(sd)' * ${sd}) if var=="`l'" & interviewer==`m'
}

if `swilk_p_local' < 0.05 {
	di "`l' does not follow a normal distribution"
}
}

gen flag_type = 1 if trigger==1
replace flag_type = 2 if outcome==1
replace flag_type = 3 if duration_check==1

	gen pct_abs = abs(pct)
	gen outlier = (mu_i > upper | mu_i < lower) if swilk_p>0.05
	replace flag = 1 if outlier == 1 & pct_abs>0.1 & int_n >= ${n_min} & inlist(flag_type, 1, 2)
	replace flag = 1 if pct_abs > 0.25 & int_n >= ${n_min} & flag_type==3



label def l_flag 1 "Trigger Question" 2 "Key Outcome Variable" 3 "Interview Duration"
label val flag_type l_flag

tempfile enumerator_trends
save `enumerator_trends'


********************************************************************************
* OUTPUTTING LIST OF CONCERNING ENUMERATOR TRENDS
********************************************************************************
use `enumerator_trends', clear
keep if flag == 1
drop swilk_p pct_abs flag sd_g sd_all median outlier trigger outcome duration_check
order var flag_type interviewer int_n mu_all mu_g mu_i upper lower d pct p
des, short
local n_vars `r(k)'

count 
if `r(N)' > 0 {

local rowbeg = `r(N)' + 2
di "`rowbeg'"
export excel "$hfc_output\Enumerator_Trends.xlsx", sheet("Outlier", modify) keepcellfmt cell(A3)
mata: check_list_format("$hfc_output\Enumerator_Trends.xlsx", "Outlier", "var", 1, 3, `rowbeg', `n_vars')	

}


********************************************************************************
* NON-NORMAL DISTRIBUTION OF ENUMERATOR MEANS
********************************************************************************
use `enumerator_trends', clear

bysort var: egen tot_n = total(int_n)

keep if swilk_p<0.05 & tot_n > 40
ex
count
if `r(N)' > 0 {
distinct interviewer
local enum_num = `r(ndistinct)'


levelsof var, l(var_list_nn)
foreach l of local var_list_nn {
*hist mu_i if var=="`l'", bin(`enum_num')
di "`l' does not follow a normal distribution"
}
}

********************************************************************************
* CONTACT TIME
********************************************************************************
use `row_date_enum', clear

gen bad_day=(interview_per_day>5)

keep if bad_day==1
tempfile bad_contact_time
keep z1 interview_date interview_per_day bad_day
save `bad_contact_time'

use `row_date_enum', clear
clonevar hours_per_day_p50 = hours_per_day
collapse (mean)hours_per_day (p50)hours_per_day_p50, by(z1)
gen high_average=(hours_per_day>6 | hours_per_day_p50>6)
gen low_average=(hours_per_day<3 | hours_per_day_p50<3)
keep if high_average==1 | low_average==1
keep z1 hours_per_day hours_per_day_p50 high_average low_average

append using `bad_contact_time'

gen flag = .
replace flag = 1 if bad_day==1
replace flag = 2 if high_average==1
replace flag = 3 if low_average==1

label def l_contact_flag 1 "Enumerator did more than 5 interviews on date" 2 "Enumerator averages 6+ contact hours per day" 3 "Enumerator averages <3 contact hours per day"
label val flag l_contact_flag

keep z1 flag interview_date interview_per_day hours_per_day hours_per_day_p50
order z1 flag interview_date interview_per_day hours_per_day hours_per_day_p50

count 
if `r(N)' > 0 {
des, short
local n_vars `r(k)'
local rowbeg = `r(N)' + 1
di "`rowbeg'"
export excel "$hfc_output\Enumerator_Trends.xlsx", sheet("Contact Time", modify) keepcellfmt cell(A2)
mata: check_list_format("$hfc_output\Enumerator_Trends.xlsx", "Contact Time", "z1", 1, 2, `rowbeg', `n_vars')	
}


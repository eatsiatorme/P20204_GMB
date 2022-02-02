clear all

use  "C:\Users\NathanSivewright\C4ED\P20204b_EUTF_GMB - Documents\02_Analysis\02_Data\Midline\C2\Youth\data_an.dta", clear

encode z1_text, gen (z1)
global sd = 3
tempfile interviewers
inttrend duration_m d1 b1 ave_month_inc brs_score spe_score prep_score active_score using `interviewers', interviewer(z1) 
use `interviewers', clear

gen upper = .
gen lower = .
gen median = .
gen swilk_p = .

levelsof var, l(var_list)
levelsof interviewer, l(interviewer_list)

foreach l of local var_list {
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

	gen pct_abs = abs(pct)
	gen outlier = (mu_i > upper | mu_i < lower) if swilk_p>0.05
	gen flag = (outlier == 1 & (pct_abs>0.1))


ex


/*
Moving DECs out and single entry
!!!!
- Total amount - > School increase

- Tracking savings piece

- Thursday - create teams call
- Revisits responses.



/
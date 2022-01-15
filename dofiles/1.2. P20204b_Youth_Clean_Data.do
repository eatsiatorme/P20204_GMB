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
** 1. Copy Exported Files to Cleaning
******************************

cd "$cleaning"

local files: dir `"$exported\/`file'"' file "*.dta", respectcase
foreach file of local files{
	di `"`file'"'
	copy `"$exported\/`file'"' `"$cleaning\/`file'"', replace
}



********************************************************************************
* TEKKI FII YOUTH (MAIN)
********************************************************************************
use "$main_table", clear




ctomergecom, fn(commentsx) mediapath("$media_path")


**************************************************
* VARIABLE PREPARATION
**************************************************

clonevar ApplicantID = id_key
destring ApplicantID, replace
drop id_key
order ApplicantID, first

** DESTRING VARIABLES
#d ;
destring
emp_inc_month_? 
emp_inkind_month_? 
sales_month_? 
profit_month_? 
duration 
total_month_inc 
ave_month_inc 
treatment_group 
sum_b3 
sum_current_bus 
b20* 
emp_ilo
, replace
;
#d cr




*****Further Cleaning*****
*1. Label variables
*2. drop unecessary variables
*3. Rename variables in multiple select which had an extra '_'
*4. Replace responses with other options
*5. reorder variables in a logical way





**************************************************
* RESHAPING PREVIOUS ATTEMPTS - ENSURE UNIQUE ID
**************************************************
gen completed_interview=(a6!=.) // CHANGE THIS TO A PROPER COMPLETION VARIABLE
bysort ApplicantID: egen completed_any=max(completed_interview)

duplicates tag ApplicantID, gen(dup) // Tag multiple submissions
gsort ApplicantID completed_interview -submissiondate 
by ApplicantID: gen counter=_n
by ApplicantID: gen attempt_tot=_N

preserve
keep if dup>0
drop if counter==attempt_tot
keep ApplicantID submissiondate counter
reshape wide submissiondate, i(ApplicantID)  j(counter) // Reshape previous visits
tempfile attempts_before
save `attempts_before'
restore

keep if counter==attempt_tot // Drop previous visits from the Long table
merge m:1 ApplicantID using `attempts_before', nogen // Merge in wide table for previous visits

egen form_count=rownonmiss(submissiondate?)
replace form_count=form_count+1


**************************************************
* PRELIMINARY ANALYSIS
**************************************************

** Employment Status
* Measure 1: Gambian Labour Force Survey Definition – In the past 7 days reported In Paid/In-kind employment or self-employed
*clonevar employed_ilo = b32 if completed_interview==1 // Used in Cycle 1
clonevar employed_ilo = emp_ilo if completed_interview==1
label var employed_ilo "In the past 7 days reported In Paid/In-kind employment or self-employed"

* Measure 2: Field (2019) Survey Definition 1 – Currently employed in a paid/in-kind employment or self-employed for longer than one month
gen employed_stable_current=(sum_b3>0) if completed_interview==1
label var employed_ilo "Currently employed in a paid/in-kind employment or self-employed for longer than one month"

* Measure 3: Field (2019) Survey Definition 2 – Ever (in reference period) employed in a paid/in-kind employment or self-employed for longer than one month
clonevar employed_stable_ever = b1 if completed_interview==1
label var employed_stable_ever "Ever employed in a paid/in-kind employment or self-employed for longer than one month"

** Business ownership
gen current_bus=(sum_current_bus>0) if completed_interview==1
label var current_bus "Currently owns a business"


** Income/Earnings
* Measure 1: Gambian Labour Force Survey Definition – Sum of all the compensation (cash, in-kind) received from economic activities over reference period

foreach u of num 1/2 {

gen profit_kept_`u'=b27_`u' if b26_unit_`u'==1
replace profit_kept_`u'=(b27_`u' * 4.345) if b26_unit_`u'==2
replace profit_kept_`u'=(b23_`u'* b27_`u'* 4.345) if b26_unit_`u'==3
replace profit_kept_`u'=(b27_`u' / b26_unit_s_`u') if b26_unit_`u'==4
replace profit_kept_`u'=round(profit_kept_`u')
}

/*


*/
gen current_month_dts="1/" + current_month + "/2021" if completed_interview==1
gen current_month_dt=date(current_month_dts,"DMY",2025) if completed_interview==1
drop current_month_dts
format %td current_month_dt

gen ref_months="1/" + reference_month + "/" + reference_year if completed_interview==1
gen ref_month=date(ref_months,"DMY",2025) if completed_interview==1
format %td ref_month

foreach u of num 1/3 {
	clonevar b5_`u'_analysis =  b5_`u'
	clonevar b4_`u'_analysis =  b4_`u'
}
	
foreach i of num 1/3 {
	replace b5_`i'_analysis=current_month_dt if b4_`i'_analysis!=.
	replace b4_`i'_analysis=ref_month if b4_`i'_analysis<ref_month
	gen months_in_job_`i' = round((b5_`i'_analysis - b4_`i'_analysis)/(365/12))
	egen ave_ref_inc_`i'=rowtotal(emp_inc_month_`i' emp_inkind_month_`i' profit_month_`i')
	gen sum_inc_`i'=(months_in_job_`i' * ave_ref_inc_`i')
}
egen sum_inc_reference=rowtotal(sum_inc_?) if completed_interview==1
label var sum_inc_reference "Sum of all the compensation (cash, in-kind) received from economic activities over reference period"


* Measure 2: Field (2019) – Average Monthly earnings if currently employed

foreach i of num 1/3 {
gen current_emp_inc_month_`i'=(emp_inc_month_`i' + emp_inkind_month_`i') if b3_`i'==1
gen current_profit_month_`i'=profit_month_`i' if b3_`i'==1
}

egen current_inc=rowtotal(current_emp_inc_month_? current_profit_month_?) if completed_interview==1
label var current_inc "Average Monthly earnings if currently employed"

** Psychological Resilience
* Measure 1: Brief Resilience Scale
/*
analysed using process from https://www.psytoolkit.org/survey-library/resilience-brs.html
*/
**
foreach var of varlist i1 i3 i5 { // Creating a cloned variable that will just be the BRS score
	clonevar `var'_brs = `var'
}

foreach var of varlist i2 i4 i6 { // Creating a cloned variable for the "reverse" variables (i.e. those where agree is a negative) that will just be the BRS score
	clonevar `var'_brs = `var'
	recode `var'_brs (1=5) (2=4) (4=2) (5=1)
}

**
egen brs_score=rowmean(i1_brs i2_brs i3_brs i4_brs i5_brs i6_brs)
label var brs_score "Brief Resilience Scale Score"

** Perception of Employability
* Measure 1: Adapted Self-Perceived Employability Scale from Rothwell (2008)
//*creating a clone variable that will be Self Perceived Employability Score ****//
foreach var of varlist e1 e2 e3 e4 e5 e6 e7 e8 e9 e10 { 
clonevar `var'_spe = `var'	
}

***generating Self Perceived Score from individual item score***
egen spe_score=rowmean (e1_spe e2_spe e3_spe e4_spe e5_spe e6_spe e7_spe e8_spe e9_spe e10_spe)
label var spe_score "Self Perceived Employability Scale Score"

** Size of Business
* Measure: Number of employees
egen num_empl = rowtotal (b21_?) if completed_interview==1
label var num_empl "Number of Employees"

** Job Formality	
* Measure: Written Formal contract for Main Job (current or most recent)
gen wrk_cntr = (b13_1==1 | b13_1==2) if completed_interview==1 // For the moment just taking the first job - need to decide how we consider this - main (most income)/(current)/(most recent) etc.
label var wrk_cntr "Written Formal contract for Main Job (current or most recent)"

/*
** Business Formality
* Measure: Business owned is registered
*b20 - 1 - MoJ 2 - GCC 3 - Registrar -95 None
capture gen b20__99_3=. // This isn't an exisiting variable - annoying but can remove
foreach i of num 1/3 {
capture gen notreg_`i'=(b20__95_`i'==1 | b20__99_`i'==1) if b6_`i'==3
gen bus_reg_`i'=(notreg_`i'==0) if b6_`i'==3
}
egen bus_reg_rate=rowmean(bus_reg_?)
label var bus_reg_rate "Rate that Business owned is registered (Across all owned business)"
*/
** Occupational safety
* Measure: Reported an injury or work related illness during job
foreach i of num 1/3 {
gen work_inj_`i'=(inlist(b9_`i', 1, 3)) if b1==1
gen work_ill_`i'=(inlist(b9_`i', 1, 2)) if b1==1
gen work_hurt_`i'=(work_inj_`i'==1 | work_ill_`i'==1) if b1==1
}
egen work_hurt_total=rowtotal(work_hurt_?) if b1==1
gen work_hurt_any=(work_hurt_total>0) if b1==1
label var work_hurt_any "Reported an injury or work related illness during any job"



** Objective Employability
* Measure 4: Have they been offered any job in the reference period 
clonevar job_offer = d8 if completed_interview==1 // We only have this variable for people that were looking for jobs - maybe should ask to all next time
label var job_offer "Offered any job in the reference period - only those looking for job"


** Job-Search
* Measure 3: Adapted Job Search Behaviour Scales (Blau 1994) used in (Chen & Lim 2012) – Singapore. Used in Nigeria (Onyishi et al 2015). // Uses Y/N rather than Likert Scale
egen prep_score=rowmean(d3?)
label var prep_score "Prepatory Job Search Score"
egen active_score=rowmean(d4?)
label var active_score "Active Job Search Score"

** Has multiple economic activities
* Measure 2: The total number of economic activities undertaken over reference period
clonevar num_econ_ref = b2
replace num_econ_ref=0 if num_econ_ref==. & completed_interview==1
label var num_econ_ref "Number of economic activities over reference period"


********************************************************************************
* LABELLING VARIABLES AND VALUES
********************************************************************************

label var ApplicantID "Unique ApplicantID"

label var full_name "Name of Respondent (Pre-populated)"

label var treatment_group "Treatment group of Respondent (Pre-populated)"
label def L_Treat 1 "Treatment" 0 "Control"
label val treatment_group L_Treat

label var consent "Respondent Consent"

label var id1a "id1a. First Name"
label var id1b "id1b. Last Name"

egen respondent_name = concat(id1a id1b), punct(" ")
replace respondent_name = upper(respondent_name)
label var respondent_name "Name of Respondent Provided"

label var id2 "id2. Age"
gen id2_c4ed = "This was outside if the age range of Tekki Fii, but was confirmed by enumerator" if ApplicantID==100135
label var id2_c4ed "C4ED Comment on id2"
label var id3 "id3. Region of birth"


label var b1 "b1. Work or employment in the past 6 months"
label var b2 "b2. Number of stable jobs in the past 6 months"
label var job_name_1 "Name of Job 1"
label var b3_1 "b3. Employment status in Job 1"
label var b4_1 "b4. When did you start in Job 1" 
label var b4_time_1 "b4. Time since the beginning of Job 1"
label var b5_1 "b5. Time of end of employment Job 1"
label var b5_time_1 "b5. Time of end of employment Job 1"
label var b6_1 "b6. Working status in Job 1"
label var b6oth_1 "b6. Other working status in job 1"
label var isic_1_1 "ISIC1. Employment by industry categorisation 1 of Job 1"
label var isic_2_1 "IISIC2. Emplyoyment by industry categorisation 2 of Job 1"
label var b9_1 "b9. Suffered job related injury in Job 1"
label var b11_1 "b11. How job was found Job 1"
label var b11_other_1 "b11. Other mweans job was found job 1"
/*
label var b12_1_1 "b12. Business officially registered Job 1 [Ministry of Justice]"
label var b12_2_1 "b12. Business officially registered Job 1 [Gambia Chamber of Commerce]"
label var b12_3_1 "b12. Business officially registered Job 1 [The Registrar of Companies]"
label var b12__99_1 "b12. Business officially registered Job 1 [Don't know]"
label var b12__95_1 "b12. Business officially registered Job 1 [None of the above]"
label var b12__96_1 "b12. Business officially registered Job 1 [Other specify]"
*/

labe var b13_1 "b13. official work contract written or oral Job 1"
label var b14_1 "b14. How many months longer in Job 1"
label var b15_1 "b15. Number of hours worked in typical day Job 1"
label var b16_1 "b16. Number of days worked in a typical week Job 1"
label var b17_1 "b17. Average earnings in cash (GMD) in a typical month Job 1"
label var b17_unit_1 "b17. Time frame of average earnings in a typical month job 1"
label var b17_unit_s_1 "b17. Number of months in a season or contract [if seasonal or contract] Job 1"
label var b17_unit_val_1 "b17. Time frame of season and contract" 
label var emp_inc_month_1 "Total monthly average income (GMD) Job 1"
label var b18_a_1 "b18. Did you receive any payment in-kind Job 1"
label var b18_1 "b18. Total average payment in-kind Job 1"
label var b18_unit_1 "b18. Time frame of average payments in kind Job 1"
label var b18_unit_s_1 "b18. Number of months in a [if]season or contract for payment in-kind Job 1"
label var b18_unit_val_1 "b18. Time frame of season and contract" 
label var emp_inkind_month_1 "Total monthly average payment in-kind Job 1"

/*
label var b20_1_1 "b20. Business officially registered Job 1 [Ministry of Justice]" 
label var b20_2_1 "b20. Business officially registered Job 1 [Gambian Chamber of Commerce]"
label var b20_3_1 "b20. Business officially registered Job 1 [The Registrar of Companies]"
label var b20__99_1 "b20. Business officially registered Job 1 [Don't know]"
label var b20__95_1 "b20. Business officially registered Job 1 [None of the above]"
*/

label var b21_1 "b21. Besides yourself how many workers do you employ Job 1? "
label var b22_1 "b22. Number of hours business is operational in a typical day Job 1"
label var b23_1 "b23. Number of days business is operational in a typical month Job 1"
label var b24_1 "b24. Sales (GMD) in a typical month of operation of business Job 1 "
label var b24_unit_1 "b24. Timeframe of total sales in a typical month of operation of business Job 1"
label var b24_unit_s_1 "b24. Number of months in a [if]season or contract for total sales Job 1"
label var b24_unit_val_1 "b24. Time frame of season and contract" 
label var sales_month_1 "Total monthly sales (GMD) in operation of business Job 1 "
label var b26_1 "b26. Profits generated in a typical month of operation of business Job 1 "
labe var b26_unit_1 "b26. Time frame of profits generated in a typical month of operation Job 1"
label var b26_unit_s_1 "b26. Number of months in a [if]season or contract for profits Job 1"
label var b26_unit_val_1 "b26. Time frame of season and contract"
label var profit_month_1 "Total monthly profits in operation of business Job 1 "
/*label var b29_1 "b29. Received a loan  in the past 6 months"
label var b30_1_1 "b30. Source(s) of loans received in the past 6 months "
label var b30_other_1 "b30. Other sources of loans received in the past 6 months"
label var b30_9_1 "b30. Source(s) of received in the past 6 months [Bank/Financial Institution]"
label var b30__96_1 "b30. Source(s) of loans recienced in the past 6 months [Other specify]"
*/


label var job_name_2 "Name of Job 2"
label var b3_2 "b3. Employment status in Job 2"
label var b4_2 "b4. When did you start in Job 2"
label var b4_time_2 "b4. Time since the beginning of Job 2"
label var b5_2 "b5. Time of end of employment Job 2"
label var b5_time_2 "b5. Time of end of employment Job 2"
label var b6_2 "b6. Working status in Job 2"
label var b6oth_2 "b6. Other working status in Job 2"
label var isic_1_2 "ISIC1. Employmment by industry categorisation 1 of Job 2"
label var isic_2_2 "ISIC2. Employment by industry categorisation 2 of Job 2"
label var b9_2 "b9. Suffered job related injury in Job 2"
label var b11_2 "b11. How job was found Job 2"
label var b11_other_2 "b11. Other mweans job was found Job 2"
label var b12_1 "b12_1. Business officially registered"
label var b12_1 "b12_1. Business officially registered  [Ministry of Justice]"
label var b12_1_1 "b12_1. Business officially registered Job 1 [Ministry of Justice]"
label var b12_3_1 "b12_1. Business officially registered Job 1 [The registrar of Companies]"
label var b12_1_2 "b12_1. Business officially registered Job 2 [Ministry of Justice]"
label var b12_3_2 "b12_1. Business officially registered Job 1 [The Registrar of Companies]"
label var b12__96_1 "b12. Business officially registered Job 1 [Other specify]"
label var b12__96_2 "b12. Business officially registered Job 2 [Other specify]"
label var b12__95_2 "b12. Business officially registered Job 2 [None of the above]"
label var b12__95_1 "b12. Business officially registered Job 1 [None of the above]"
label var b12__99_2 "b12. Business officially registered Job 2 [Don't know]"
label var b12__99_1 "b12. Business officially registered Job 1 [Don't know]"
label var b12_3_1 "b12. Business officially registered Job 2 [The Registrar of Companies]"

/*label var b12_2_2 "b12. Business officially registered Job 2 [Gambia Chamber of Commerce]"
label var b12_3_2 "b12. Business officially registered Job 2 [The Registrar of Companies]"
label var b12__99_2 "b12. Business officially registered Job 2 [Don't know]"
label var b12__95_2 "b12. Business officially registered Job 2 [None of the above]"
label var b12__96_2 "b12. Business officially registered Job 2 [Other specify]"
*/

labe var b13_2 "b13. official work contract written or oral Job 2"
label var b14_2 "b14. How many months longer in Job 2"
label var b15_2 "b15. Number of hours worked in typical day Job 2"
label var b16_2 "b16. Number of days worked in a typical week Job 2"
label var b17_2 "b17. Average earnings in cash (GMD) in a typical month Job 2"
label var b17_unit_2 "b17. Time frame of average earnings in a typical month Job 2"
label var b17_unit_s_2 "b17. Number of months in a  [if]season or contract Job 2"
label var b17_unit_val_2 "b17. Time frame of season and contract Job 2" 
label var emp_inc_month_2 "Total monthly average income (GMD) Job 2"
label var b18_a_2 "b18. Did you receive any payment in-kind Job 2"
label var b18_2 "b18. Total average payment in-kind Job 2"
label var b18_unit_2 "b18. Time frame of average payments in kind Job 2"
label var b18_unit_s_2 "b18. Number of months in a [if] season or contract for payment in-kind Job 2"
label var b18_unit_val_2 "b18. Time frame of season and contract" 
label var emp_inkind_month_2 "Total monthly average payment in-kind Job 2"

/*
label var b20__99_2 "b20. Business officially registered Job 2 [Don't Know]"
label var b20__95_2 "b20. Business officially registered Job 2 [None of the above]"
*/

label var b21_2 "b21. Besides yourself how many workers do you employ Job 2? "
label var b22_2 "b22. Number of hours business is operational in a typical day Job 2"
label var b23_2 "b23. Number of days business is operational in a typical month Job 2"
label var b24_2 "b24. Sales (GMD) in a typical month of operation of business Job 2"
label var b24_unit_2 "b24. Timeframe of total sales in a typical month of operation of business Job 2"
label var b24_unit_s_2 "b24. Number of months in a [if] season or contract for total sales Job 2"
label var b24_unit_val_2 "b24. Time frame of season and contract" 
label var sales_month_2 "Total monthly sales (GMD) in operation of business Job 2"
label var b26_2 "b26. Profits generated in a typical month of operation of business Job 2"
labe var b26_unit_2 "b26. Time frame of profits generated in a typical month of operation Job 2"
label var b26_unit_s_2 "b26. Number of months in a [if] season or contract for profits Job 2"
label var b26_unit_val_2 "b26. Time frame of season and contract"
label var profit_month_2 "Total monthly profits in operation of business Job 2 "
*label var b29_2 "b29. Received a loan  in the past 6 months"
label var b30_2 "b30. Source(s) of loans received in the past 6 months "
label var b30_other_2 "b30. Other sources of loans received in the past 6 months"


label var job_name_3 "Name of Job 3"
label var b3_3 "b3. Employment status in Job 3"
label var b4_3 "When did you start Job 3" 
label var b4_time_3 "Time since the beginning of Job 3" 
label var b5_3 "b5. Time of end of employment Job 3"
label var b5_time_3 "b5. Time of end of employment Job 3"
label var b6_3 "b6. Working status in Job 3"
label var b6oth_3 "b6. Other working status in Job 3"
label var isic_1_3 "ISIC1. Employment by industry categorisation 1 of Job 3"
label var isic_2_3 "ISIC2. Employment by industry categorisation 2 of Job 3"
label var b9_3 "b9. Suffered job related injury in Job 3"
label var b11_3 "b11. How job was found Job 3"
label var b11_other_3 "b11. Other mweans job was found Job 3"
labe var b13_3 "b13. official work contract written or oral Job 3"
label var b14_3 "b14. How many months longer in Job 3"
label var b15_3 "b15. Number of hours worked in typical day Job 3"
label var b16_3 "b16. Number of days worked in a typical week Job 3"
label var b17_3 "b17. Average earnings in cash (GMD) in a typical month Job 3"
label var b17_unit_3 "b17. Time frame of average earnings in a typical month Job 3"
label var b17_unit_s_3 "b17. Number of months in a [if] season or contract Job 3"
label var b17_unit_val_3 "b17. Time frame of season and contract Job 3" 
label var emp_inc_month_3 "Total monthly average income (GMD) Job 3"
label var b18_a_3 "b18. Did you receive any payment in-kind Job 3"
label var b18_3 "b18. Total average payment in-kind Job 3"
label var b18_unit_3 "b18. Time frame of average payments in kind Job 3"
label var b18_unit_s_3 "b18. Number of months in a [if] season or contract for payment in-kind Job 3"
label var b18_unit_val_3 "b18. Time frame of season and contract" 
label var emp_inkind_month_3 "Total monthly average payment in-kind Job 3"
/*
label var b20__95_3 "b20. Business officially registered Job 3 [None of the above]" 
label var b20__99_3 "b20. Business officially registered Job 3 [Don't know]"
*/

label var b21_3 "b21. Besides yourself how many workers do you employ Job 3? "
label var b22_3 "b22. Number of hours business is operational in a typical day Job 3"
label var b23_3 "b23. Number of days business is operational in a typical month Job 3"
label var b24_3 "b24. Sales (GMD) in a typical month of operation of business Job 3"
label var b24_unit_3 "b24. Timeframe of total sales in a typical month of operation of business Job 3"
label var b24_unit_s_3 "b24. Number of months in a [if] season or contract for total sales Job 3"
label var b24_unit_val_3 "b24. Time frame of season and contract" 
label var sales_month_3 "Total monthly sales (GMD) in operation of business Job 3"
label var b26_3 "b26. Profits generated in a typical month of operation of business Job 3"
labe var b26_unit_3 "b26. Time frame of profits generated in a typical month of operation Job 3"
label var b26_unit_s_3 "b26. Number of months in a [if] season or contract for profits Job 3"
label var b26_unit_val_3 "b26. Time frame of season and contract"
label var profit_month_3 "Total monthly profits in operation of business Job 3"
*label var b29_3 "b29. Received a loan  in the past 6 months"
label var b30_3 "b230. Source(s) of loans received in the past 6 months "
label var b30_other_3 "b30. Other sources of loans received in the past 6 months"
label var b34 "b34. What was your working status in small job done in the past 7 days"
label var isic_1_seven "ISIC1. empolyomeyment by industry categorisation 1 of small job in past 7 days"
label var isic_2_seven "ISIC2. employment by industry categorisation 2 of small job in past 7 days"

label var sum_b3 "b3. Total number of jobs in the past 6 months"
label var sum_current_bus "Total number of businesses"
label var ave_month_inc "Average monthly income including all jobs in the past 6 months"

//Section 'j'
label var j1a "j1a. Attended a training course since January 2020"
label var j1b "j1b. Attended other Voc/Tech training other than Tekki Fii in past 6 months"
label var j3 "j3. If other training was attended was it formal or non-formal" 
label var j4 "j4. Type of training attended"
label var j4_other "j4 Other type of training attended"
label var j5 "j5. Completion status of other training attended"
label var j6 "j6. Time frame of other training attended" 

label var k1 "k1. Teaching methods of teachers used in Tekki Fii traninig "
label var k2 "k2.Teachers ability to handle training equipment for instruction"
label var k4 "k4. Teachers ability to engage students in the activirities "
label var k5 "k5. Quality assessment of TVET facilities in Training Centres by trainees"
label var k6 "k6. Assessment of Tekki Fii by trainees [work place relevant skills]"
label var k8 "k8. Assessement of Tekki Fii by trainees [improving team work skills]"
label var k9 "k9. Assessment of Tekki Fii by trainees [improve ability to work independetly]"
label var k10 "k10. Assessment of Tekki Fii by trainees [improve self expression]"
label var k11 "k11. Absenteeism at Tekki Fii trainings"
label var k12_1 "k12. Reasons for Tekki Fii absenteeism [Illness]"
*label var k12_2 "k12_2. Reasons for Tekki Fii absenteeism [Household obligations]"
*label var k12_3 "k12_3. Reasons for Tekki Fii absenteeism [Economic obligations]"

label var k12_5 "k12_5. Reasons for Tekki Fii absenteeism [Lack of money to travel]"
label var k12_other "k12_other. Reasons for Tekki Fii absenteeism [Specify other]"
label var k12__96 "k12. Reasons for Tekki Fii absenteeism [if other]"
label var tekkifii_check_ind "Tekki Fii industrial placement participation confirmation"
label var tekkifii_check_ind_why "Reason for not taking part in Tekki Fii industrial placementy"
label var k13 "k13. Absenteeism industrial placement"
label var k14_1 "k12. Reasons for indsutrial placement absenteeism [Illness]"
label var k14_2 "k12_2. Reasons for indsutrial placement absenteeism [Household obligations]"
/*label var k14_3 "k12_3. Reasons for indsutrial placement absenteeism [Economic obligations]"
*label var k14_5 "k12_5. Reasons for indsutrial placement absenteeism [Lack of money to travel]"
label var k14_other "k12_other. Reasons for indsutrial placement absenteeism [Specify other]"
label var k14__96 "k12. Reasons for indsutrial placement absenteeism [if other]"
*/

label var k15 "k15. Assessment of Tekki Fii by trainees [putting into practice learned trade and skills]"
label var k16 "k16. Assessment of Tekki Fii by trainees [useful work experience for career dev't']"
label var k17 "Offered a job at company of industrial placement"
label var k18 "k18. Participation in business development component of Tekki Fii"
label var tekkifii_check "Tekki fii Programme participation confirmation"
label var tekkifii_check_apply "Tekki Fii Programme application confirmation"
label var tekkifii_outcome "Outcome of Tekki Fii programme application"
label var employed_stable_current "Still employed in a paid employment that has lasted more than a month"

/*
label var b33_1 "Worked in the last 7 days in already discussed Job 1"
label var b33_2 "Worked in the last 7 days in already discussed Job 2"
label var b33_3 "Worked in the last 7 days in already discussed Job 3"
label var b33_0 "Worked in the last 7 days but not in any of already discussed jobs"
*/

label var work_inj_1 "Injured self while working in Job 1"
label var work_ill_1 "Ill while working in Job 1"
label var work_hurt_1 "Bothe injured and ill while working in Job 1 "
label var work_inj_2 "Injured self while working in Job 2"
label var work_ill_2 "Ill while working in Job 2"
label var work_hurt_2 "Bothe injured and ill while working in Job 2 "
label var work_inj_3 "Injured self while working in Job 3"
label var work_ill_3 "Ill while working in Job 3"
label var work_hurt_3 "Both injured and ill while working in Job 3 " //Check 

label var current_emp_inc_month_1 "Monthly income if employee from Job 1 "
label var current_profit_month_1 "Monthly profit if self employed from Job 1"
label var current_emp_inc_month_2 "Monthly income if employee from Job  "
label var current_profit_month_2 "Monthly profit if self employed from Job 2"
label var current_emp_inc_month_3 "Monthly income if employee from Job 3 "
label var current_profit_month_3 "Monthly profit if self employed from Job 3"

label var a1a "a1a. March 2020 highest level of education"
label var a1b "a1b. Current highest level of education"

label var a2 "a2. Current Marital Status"

label var d1 "d1. Looked for job or started business in last 4 weeks" 

drop d2
label var d2_1 "d2. reasons not look for a job in the last 4 weeks [Already have job]"
label var d2_2 "d2. reasons not look for a job in the last 4 weeks [Studying]"
label var d2_3 "d2. reasons not look for a job in the last 4 weeks [Domestic work]"
capture label var d2_4 "d2. reasons not look for a job in the last 4 weeks [Disabled]"
capture label var d2_5 "d2. reasons not look for a job in the last 4 weeks [Found Job to start]"
capture label var d2_6 "d2. reasons not look for a job in the last 4 weeks [Awaiting Recall]"
capture label var d2_7 "d2. reasons not look for a job in the last 4 weeks [Waiting Busy Period]"
capture label var d2_8 "d2. reasons not look for a job in the last 4 weeks [Don't want to work]"
capture label var d2_9 "d2. reasons not look for a job in the last 4 weeks [No chance]"

rename d2__96 d2_96 
label var d2_96 "d2. reasons not look for a job in the last 4 weeks [Other]"


// Clean up other specify
drop d12
label var d12_1 "d12. reasons not tried to start business in last 4 weeks? [Already have]"
label var d12_2 "d12. reasons not tried to start business in last 4 weeks? [Prefer job]"
label var d12_3 "d12. reasons not tried to start business in last 4 weeks? [Lack Finance]"
label var d12_4 "d12. reasons not tried to start business in last 4 weeks? [No Interest]"
label var d12_5 "d12. reasons not tried to start business in last 4 weeks? [No knowledge]"
label var d12_6 "d12. reasons not tried to start business in last 4 weeks? [Bureaucracy]"

label var d3a "d3a. In the past 4 weeks did you… [Read Ads]"
label var d3b "d3b. In the past 4 weeks did you… [Prepare CV]"
label var d3d "d3d. In the past 4 weeks did you… [Talk to friends]"
label var d3e "d3e. In the past 4 weeks did you… [Previous Employers]"
label var d3f "d3f. In the past 4 weeks did you… [Use Internet/Radio]"

label var d4b "d4b. In the past 4 weeks did you… [Send CV]"
label var d4c "d4c. In the past 4 weeks did you… [Fill out Application]"
label var d4d "d4d. In the past 4 weeks did you… [Have interview]"
label var d4f "d4f. In the past 4 weeks did you… [Telephone Employer]"

label var d5a "d5a. Searching for work based [District/Municipality]"
label var d5b "d5b. Searching for work based [Outside District]"
label var d5e "d5e. Searching for work based [Outside Gambia]"

label var d7_1 "d7. Challenges to obtaining local jobs [Competition]"
label var d7_2 "d7. Challenges to obtaining local jobs [Lack Experience/Skills]"
label var d7_3 "d7. Challenges to obtaining local jobs [Lack Jobs Matching Skills]"
label var d7_4 "d7. Challenges to obtaining local jobs [Corruption]"
label var d7_5 "d7. Challenges to obtaining local jobs [No information]"
label var d7_6 "d7. Challenges to obtaining local jobs [No jobs at all]"
label var d7_0 "d7. Challenges to obtaining local jobs [None]"
rename d7__96 d7_96
label var d7_96 "d7. Challenges to obtaining local jobs [Other]"

label var d8 "d8. Any job offers since [REF PERIOD]"

label var c1 "c1. Does professional income vary across the year?" 
label var c3_1 "c3. What months do you consider to be the worst? [January]"
label var c3_2 "c3. What months do you consider to be the worst? [February]"
label var c3_3 "c3. What months do you consider to be the worst? [March]"
label var c3_4 "c3. What months do you consider to be the worst? [April]"
label var c3_5 "c3. What months do you consider to be the worst? [May]"
label var c3_6 "c3. What months do you consider to be the worst? [June]"
label var c3_7 "c3. What months do you consider to be the worst? [July]"
label var c3_8 "c3. What months do you consider to be the worst? [August]"
label var c3_9 "c3. What months do you consider to be the worst? [September]"
label var c3_10 "c3. What months do you consider to be the worst? [October]"
label var c3_11 "c3. What months do you consider to be the worst? [November]"
label var c3_12 "c3. What months do you consider to be the worst? [December]"

label var c2 "c2. Professional income in the worst months"

label var c5_1 "c3. What months do you consider to be the best? [January]"
label var c5_2 "c3. What months do you consider to be the best? [February]"
label var c5_3 "c3. What months do you consider to be the best? [March]"
label var c5_4 "c3. What months do you consider to be the best? [April]"
label var c5_5 "c3. What months do you consider to be the best? [May]"
label var c5_6 "c3. What months do you consider to be the best? [June]"
label var c5_7 "c3. What months do you consider to be the best? [July]"
label var c5_8 "c3. What months do you consider to be the best? [August]"
label var c5_9 "c3. What months do you consider to be the best? [September]"
label var c5_10 "c3. What months do you consider to be the best? [October]"
label var c5_11 "c3. What months do you consider to be the best? [November]"
label var c5_12 "c3. What months do you consider to be the best? [December]"

label var c5 "c5. Professional income in the best months"

label var e1 "e1. My training/educational is an asset to me in job seeking"
label var e2 "e2. Employers target individuals with my educational background"
label var e3 "e3. There is a lot of competition for places on training courses"
label var e4 "e4. People in my career are in high demand in the labour market"
label var e5 "e5. My educational background leads to highly desirable jobs"
label var e6 "e6. There are plenty of job vacancies in my geographical area"
label var e7 "e7. I can easily find out about opportunities in my chosen field"
label var e8 "e8. My skills are what employers are looking for"
label var e9 "e9. Im confident of success in job Interviews and selection" 
label var e10 "e10. I feel I could get any job as long as I have relevant skills" 

label var g6 "g6. When younger involved in organising social projects"
label var g7 "g7. When younger candidate for class prefect/other representative"
label var g8 "g8. When younger regularly organize events with the family or friends"
label var g10 "g10. When younger, ever try to open a business"

label var h2 "h2. Keep written financial records"
label var h4 "h4. Clear and concrete professional goal for next year"
label var h5 "h5. Anticipate investments to be done in the coming year"
label var h6 "h6. How often check to see if achieved targets or not"
label var h1 "h1. Seperate professional and personal cash"
label var h7 "h7. In the last 6 months visited a competitor's business"
label var h8 "h8. In the last 6 months adapted business offers according to competitors"
label var h9 "h9. In the last 6 months discussed with a client how to answer needs"
label var h10 "h10. In the last 6 months asked a supplier about products selling well"
label var h11 "h11. In the last 6 months advertised in any form"
label var h12 "h12. Know which goods/services make the most profit per item selling"
label var h13 "h13. Use records to analyse sales and profits of a particular product"



*****
**Labelling for Cycle 2 Variables**
label var b1a "b1a. In the last 7 days did you do any work, for even one hour?"
label var b1a_1 "b1a_1. In the last 7 days did you do any work, for even one hour? [Paid employee of non-member of household]"
label var b1a_2 "b1a_2. In the last 7 days did you do any work, for even one hour? [Paid worker on HH farm of non-farm bus. ent.]"
label var b1a_3 "b1a_3. In the last 7 days did you do any work, for even one hour? [An employer]"
label var b1a_4 "b1a_4. In the last 7 days did you do any work, for even one hour? [A worker non-agric. own account worker without empl.]"
label var b1a_5 "b1a_5. In the last 7 days did you do any work, for even one hour? [Unpaid workers (eg. homemaker, working in non-farm family business]"
label var b1a_6 "b1ab_6. In the last 7 days did you do any work, for even one hour? [Unpaid farmers]"
label var b1a_7 "b1ab_7. In the last 7 days did you do any work, for even one hour? [None of the above]"
label var b1b "b1b. Has a paid permanent/long term job (eventhough did not work in the past 7 days) due to absenteeism" 
label var b1c "b1c. Main reasons for not working in the past 7 days despite having a permanent job"
*label var b29_b "29_b. Applied for loan or credit within the reference period"
label var b30_1 "Source of loans or credits obtained in the reference period [Relative or friends]"

/*
label var b1c_1 "b1c_1. Main reasons for not working in the past 7 days despite having a permanent job [Paid leave]"
label var b1c_2 "b1c_2. Main reasons for not working in the past 7 days despite having a permanent job [Unpaid leave]"
label var b1c_3 "b1c_3. Main reasons for not working in the past 7 days despite having a permanent job [Own illness]"
label var b1c_4 "b1c_4. Main reasons for not working in the past 7 days despite having a permanent job [Maternity leave]"
label var b1c_5 "b1c_5. Main reasons for not working in the past 7 days despite having a permanent job [Care of household member]"
label var b1c_6 "b1c_6. Main reasons for not working in the past 7 days despite having a permanent job [Holidays]"
label var b1c_7 "b1c_7. Main reasons for not working in the past 7 days despite having a permanent job [Strike/Suspension]"
label var b1c_8 "b1c_8. Main reasons for not working in the past 7 days despite having a permanent job [Temporary workload reduction]"
label var b1c_9 "b1c_9. Main reasons for not working in the past 7 days despite having a permanent job [Closure]"
label var b1c_10 "b1c_10. Main reasons for not working in the past 7 days despite having a permanent job [Bad weather]"
label var b1c_11 "b1c_11. Main reasons for not working in the past 7 days despite having a permanent job [School/Education/Training]"
label var b1c_other "b1c_other. Main reasons for not working in the past 7 days despite having a permanent job [Other specify]"
*/

label var b31a "b31a. Had other jobs in the reference period other than those already discussed"
label var b31b "Number of other jobs since reference period" 
label var b31c "b31c. Other jobs match with trades"
label var b31c_1 "b31c_1. Other jobs match with trades [Block laying]"
label var b31c_2 "b31c_2. Other jobs match with trades [Tiling and plastering]"
label var b31c_2 "b31c_3. Other jobs match with trades [Welding and farm tool repair]"
label var b31c_4 "b31c_4. Other jobs match with trades [Small engine repair]"
label var b31c_5 "b31c_5. Other jobs match with trades [Soalr PV installation]"
label var b31c_6 "b31c_6. Other jobs match with trades [Gament making]"
capture label var b31c_7 "b31c_7. Other jobs match with trades [Hairdressing/barbering and beauty therapy]"
capture label var b31c_8 "b31c_8. Other jobs match with trades [Animal husbandry]"
capture label var b31c_9 "b31c_9. Other jobs match with trades [Satelitte installation]"
capture label var b31c_10 "b31c_10. Other jobs match with trades [Electrical installation and repairs]"
capture label var b31c_11 "b31c_11. Other jobs match with trades [Plumbing]"
capture label var b31c_12 "b31c_12. Other jobs match with trades [None of the above categories]"

label var c1_normal_month_1 "c1_normal. What months do you consider to be the best? [January]"
label var c1_normal_month_2 "c1_normal. What months do you consider to be the best? [February]"
label var c1_normal_month_3 "c1_normal. What months do you consider to be the best? [March]"
label var c1_normal_month_4 "c1_normal. What months do you consider to be the best? [April]"
label var c1_normal_month_5 "c1_normal. What months do you consider to be the best? [May]"
label var c1_normal_month_6 "c1_normal. What months do you consider to be the best? [June]"
label var c1_normal_month_7 "c1_normal. What months do you consider to be the best? [July]"
label var c1_normal_month_8 "c1_normal. What months do you consider to be the best? [August]"
label var c1_normal_month_9 "c1_normal. What months do you consider to be the best? [September]"
label var c1_normal_month_10 "c1_normal. What months do you consider to be the best? [October]"
label var c1_normal_month_11 "c1_normal. What months do you consider to be the best? [November]"
label var c1_normal_month_12 "c1_normal. What months do you consider to be the best? [December]"

********************************************************************************
* ORDERING VARIABLES
********************************************************************************
#d ;
order 
ApplicantID
full_name
treatment_group
formdef_version
;
#d cr

ex
save "$main_table", replace

********************************************************************************
* EXIT CODE
********************************************************************************

n: di "${proj}_${tool}_Clean_Data ran successfully"
*}




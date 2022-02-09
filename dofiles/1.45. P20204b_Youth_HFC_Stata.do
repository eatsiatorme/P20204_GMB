

cd "H:\corrections"

	
******************************
**BASIC CHECKS**
******************************
* DUPLICATES
	global i=1
	use $main_table, clear
	gen error=${i} if ApplicantID==100002
	global keepvar "consent"
	addErr "FLAGGED ID"
	

	global i=2
	use $main_table, clear
	gen error=${i} if duration_m<10 & status==1
	gen duration_m_str = string(duration_m , "%2.1f") // find a better solution for this - decimals -> string in the addErr programe
	global keepvar "duration_m_str"
	addErr "Completed interview was less than 10 minutes - Send for back-check"

	global i=3
	use $main_table, clear
	sctorezone -1, only(time_start) force
	gen time_diff = abs(clockdiff(time_start, timestamp_visit, "minute"))
	gen error=${i} if time_diff>5 & status==1
	global keepvar "time_diff"
	addErr "Entered time is more than X minutes from the secret time - Send for back-check"
	
	global i=4
	use $main_table, clear
	keep z1 ApplicantID loclatitude loclongitude localtitude locaccuracy submissiondate z2
	preserve
	rename (ApplicantID loclatitude loclongitude localtitude locaccuracy) (ApplicantID_2 loclatitude_2 loclongitude_2 localtitude_2 locaccuracy_2)
	tempfile gps_loc
	save `gps_loc'
	use `gps_loc', clear
	restore 
	joinby z1 using `gps_loc'
	drop if ApplicantID==ApplicantID_2
	drop if loclatitude==. | loclatitude_2==.
	count
	if `r(N)' > 0 {
	geodist loclatitude loclongitude loclatitude_2 loclongitude_2, gen(gps_distance)
	replace gps_distance = gps_distance * 1000
	gen error=${i} if gps_distance<100
	gen gps_distance_str = string(gps_distance , "%2.1f") // find a better solution for this - decimals -> string in the addErr programe
	global keepvar "gps_distance_str ApplicantID_2"
	addErr "Less than 100 metres away from another interview by enumerator - Send for back-check"
	}
	
	global i=5
	use $main_table, clear
	keep submissiondate z2 z1 ApplicantID full_name respondent_name 
	replace full_name=upper(full_name)
	replace respondent_name=upper(respondent_name)
	matchit full_name respondent_name
	gen error=${i} if similscore<0.8 & respondent_name!=""
	global keepvar "full_name respondent_name"
	addErr "Pre-loaded name is not similar to the name entered in the survey"

	global i=6
	use $main_table, clear
	gen error=${i} if ApplicantID==100051
	global keepvar "consent"
	addErr "FLAGGED ID - 8th Feb"
	

		
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

		
	
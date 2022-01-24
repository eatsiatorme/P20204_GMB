

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
	foreach var of varlist a9 a10 a11 {
		gen `var'_otherperson = (`var'==2 | `var'==0)
	}
	egen check = rowtotal(*_otherperson)
	gen error=${i} if check>0 &  a3==1 & a3!=.
	global keepvar "a3 a9 a10 a11"
	addErr "Entered that others make Household Decisions, but no one else in Household"

	global i=3
	use $main_table, clear
	gen error=${i} if ApplicantID==100003
	global keepvar "consent"
	addErr "FLAGGED ID"

	
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

		
	
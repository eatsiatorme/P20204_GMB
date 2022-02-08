use "H:\corrections\Tekki_Fii_PV_3_checked.dta", clear

ds, has(type numeric)
local all_numeric `r(varlist)'
local xx "loclatitude loclongitude localtitude locaccuracy ApplicantID treatment formdef_version status duration z2 z1 _hfokay duration_m"

foreach var of varlist ta_* *_check *_check_*{
	local xy "`xy' `var'"
}

di "`xy'"


local all_numeric: list all_numeric - xx
local all_numeric: list all_numeric - xy
clear

di "`all_numeric'"
local total_ : word count  `all_numeric'
set obs `total_'

gen vname = ""
gen vlabel = ""
local i = 0
quietly foreach v of local all_numeric {
    local ++i 
    replace vname = "`v'" in `i'
    replace vlabel = "`: var label `v''" in `i'
}
l vname vlabel in 1/`i'

gen x = "(" + vname + " < -95 & " + vname + " > -99" + ")"
gen y = "(status==1 & " + vname + " < 0)"
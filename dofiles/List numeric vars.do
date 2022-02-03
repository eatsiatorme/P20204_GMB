use "H:\corrections\Tekki_Fii_PV_3_pt.dta", clear

ds, has(type numeric)
local all_numeric `r(varlist)'
local xx "loclatitude loclongitude localtitude locaccuracy ApplicantID treatment formdef_version status duration z2 z1 _hfokay duration_m mean_light_level min_light_level max_light_level sd_light_level mean_movement sd_movement min_movement max_movement mean_sound_level min_sound_level max_sound_level sd_sound_level mean_sound_pitch min_sound_pitch max_sound_pitch sd_sound_pitch pct_quiet pct_still pct_moving pct_conversation light_level movement sound_level sound_pitch conversation"

foreach var of varlist ta_* *_check *_check_*{
	local xy "`xy' `var'"
}

di "`xy'"


local all_numeric: list all_numeric - xx
local all_numeric: list all_numeric - xy
di "`all_numeric'"
foreach v of local all_numeric {
	local l_`v' : variable label `v'
	di "`l_`v''" 
}


clear

di "`all_numeric'"


local total_ : word count  `all_numeric'
set obs `total_'

gen vname = ""
gen vlabel = ""

tokenize `all_numeric'

local i = 0
quietly foreach v of local all_numeric {
    local ++i 
    replace vname = "`v'" in `i'
    replace vlabel = "`l_`v''" in `i'

}

gen x = "(" + vname + " < -95 & " + vname + " > -99" + ")"
gen y = "(status==1 & " + vname + " < 0)"
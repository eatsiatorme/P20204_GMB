

***************************
**  erase files in export **
***************************
local deletepathexp = "$ONEDRIVE\P20204b_EUTF_GMB - Documents\02_Analysis\06_Field_Work_Reports\Endline\HFC\checking_log\"
local files : dir "`deletepathexp'" file "*", respectcase	
foreach file in `files'{	
	local fileandpathtodelete = "`deletepathexp'"+"`file'"
	capture erase "`fileandpathtodelete'"
}

***************************
**  erase files in export **
***************************
local deletepathexp = "$ONEDRIVE\P20204b_EUTF_GMB - Documents\02_Analysis\06_Field_Work_Reports\Endline\HFC\error_log\"
local files : dir "`deletepathexp'" file "*", respectcase	
foreach file in `files'{	
	local fileandpathtodelete = "`deletepathexp'"+"`file'"
	capture erase "`fileandpathtodelete'"
}

***************************
**  erase files in export **
***************************
local deletepathexp = "$ONEDRIVE\P20204b_EUTF_GMB - Documents\02_Analysis\06_Field_Work_Reports\Endline\HFC\error_log\archive\"
local files : dir "`deletepathexp'" file "*", respectcase	
foreach file in `files'{	
	local fileandpathtodelete = "`deletepathexp'"+"`file'"
	capture erase "`fileandpathtodelete'"
}


***************************
**  erase files in export **
***************************
local deletepathexp = "$ONEDRIVE\P20204b_EUTF_GMB - Documents\02_Analysis\06_Field_Work_Reports\Endline\HFC\05_output\"
local files : dir "`deletepathexp'" file "Checking_List.xlsx", respectcase	
foreach file in `files'{	
	local fileandpathtodelete = "`deletepathexp'"+"`file'"
	capture erase "`fileandpathtodelete'"
}

***************************
**  erase files in export **
***************************
local deletepathexp = "$ONEDRIVE\P20204b_EUTF_GMB - Documents\04_Field Work\Share with CepRass\"
local files : dir "`deletepathexp'" file "Checking_List_CepRass.xlsx", respectcase	
foreach file in `files'{	
	local fileandpathtodelete = "`deletepathexp'"+"`file'"
	capture erase "`fileandpathtodelete'"
}


******************************
**Copy Files to Exported**
******************************
clear
global checking_template "$ONEDRIVE\P20204b_EUTF_GMB - Documents\02_Analysis\06_Field_Work_Reports\Endline\HFC\05_output\Checking List Template\"
global checking_dir "$ONEDRIVE\P20204b_EUTF_GMB - Documents\02_Analysis\06_Field_Work_Reports\Endline\HFC\05_output\"
cd "$checking_template"

local files: dir "$checking_template" file "Checking_List.xlsx", respectcase
foreach file of local files{
	di `"`file'"'
	copy `""$checking_template\/`file'"' `"$checking_dir\/`file'"', replace
	}
	
******************************
**Copy Files to Exported**
******************************
clear

global checking_dir_lp "$ONEDRIVE\P20204b_EUTF_GMB - Documents\04_Field Work\Share with CepRass\"
cd "$checking_template"

local files: dir "$checking_template" file "Checking_List_CepRass.xlsx", respectcase
foreach file of local files{
	di `"`file'"'
	copy `""$checking_template\/`file'"' `"$checking_dir_lp\/`file'"', replace
	}
	
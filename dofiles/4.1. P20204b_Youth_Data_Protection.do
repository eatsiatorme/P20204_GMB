****Work in progress****
********De-identifying data in preperation for analysis*********
/*

1. Splits the main dataset into 2 while keeping the original dataset.
2. In total 3 datasets remain: Original dataset, dataset with PII only and dataset without PII. 
3 Split datasets have common IDs created to be used if merging is needed.
4. Copy de-identified data into analysis folder
5. Move datasets with PII into Veracrypt folder for  data protection leaving deidentified data only for analysis. 
	5.1 To complete this step veracrypt container needs to be  mounted on the Veracrypt drive first before data can be copied into Veracrypt for protection.
6. Delete newly created datasetsets from cleaning folder
7. Delete all 'Tekki_Fii_PV.dta files from ll folders'

*/


**1-3**
capture mkdir "$ONEDRIVE\P20204b_EUTF_GMB - Documents\02_Analysis\02_Data\/$round\"
capture mkdir "$ONEDRIVE\P20204b_EUTF_GMB - Documents\02_Analysis\02_Data\/$round\/$cycle\"
capture mkdir "$ONEDRIVE\P20204b_EUTF_GMB - Documents\02_Analysis\02_Data\/$round\/$cycle\/$tool\"
global data_di "$ONEDRIVE\P20204b_EUTF_GMB - Documents\02_Analysis\02_Data\/$round\/$cycle\/$tool\"

cd "$corrections"

use "$main_table", clear

global personal_info "username nameid id1a id1b respondent_name full_name final_phone1 final_phone2 final_phone3 final_phone4 final_phone5 fianl_phone6 email other_phone other_phone_owner employer_name_1 employer_name_2 employer_name_3 loclatitude loclongitude localtitude locaccuracy job_name_? job1 job2 job3 b32_job_name"


preserve
keep $personal_info
bysort $personal_info: keep if _n==1
egen pii_obs = rank(runiform()), unique
label var pii_obs "Unique observation ID"  
save pilink_obs.dta, replace
restore
merge m:1 $personal_info using pilink_obs.dta, nogen assert(3)
drop $personal_info
order pii_obs
save data_an.dta, replace 


*4
*****Copying new de-identified data into analysis folder for data analysis 
local files: dir `"$corrections\/`file'"' file "data_an.dta", respectcase
foreach file of local files{
	di `"`file'"'
	copy `"$corrections\/`file'"' `"$data_di\/`file'"', replace
}

/*
*5
*******Mount Veracrypt container***
clear all 
global location "H:\"
local dir "$project_folder"
****************************************
******Veracrypt Password: mzeef4271*****
****************************************
cd "`dir'"
veracrypt vault, mount drive(H)
*/

****Copying files with pii into veracrypt container*****
cd "$corrections"

local files: dir `"$corrections\/`file'"' file "pilink_obs.dta", respectcase
foreach file of local files{
	di `"`file'"'
	copy `"$corrections\/`file'"' `"$encrypted_path\/`file'"', replace
}

local files: dir `"$corrections\/`file'"' file "Tekki_Fii_PV_2.dta", respectcase
foreach file of local files{
	di `"`file'"'
	copy `"$corrections\/`file'"' `"$encrypted_path\/`file'"', replace
}


*6
***Deleting newly created datasets after copying into appropriate folders
local deletepathclean = "$corrections\/"
local files : dir "`deletepathclean'" file "pilink_obs.dta", respectcase	
foreach file in `files'{	
	local fileandpathtodelete = "`deletepathclean'"+"`file'"
	capture erase "`fileandpathtodelete'"
}

local deletepathclean = "$corrections\/"
local files : dir "`deletepathclean'" file "data_an.dta", respectcase	
foreach file in `files'{	
	local fileandpathtodelete = "`deletepathclean'"+"`file'"
	capture erase "`fileandpathtodelete'"
}

ex
/*
***TBD: Once Daatasets are in Veracrypt Container consider deleting all "Tekki_Fii_PV.dta" files

local deletepathclean = "$cleaning\/"
local files : dir "`deletepathclean'" file "Tekki_Fii_PV_2.dta", respectcase	
foreach file in `files'{	
	local fileandpathtodelete = "`deletepathclean'"+"`file'"
	capture erase "`fileandpathtodelete'"
}


local deletepathclean = "$exported\/"
local files : dir "`deletepathclean'" file "Tekki_Fii_PV_2.dta", respectcase	
foreach file in `files'{	
	local fileandpathtodelete = "`deletepathclean'"+"`file'"
	capture erase "`fileandpathtodelete'"
}

local deletepathclean = "$corrections\/"
local files : dir "`deletepathclean'" file "Tekki_Fii_PV_2.dta", respectcase	
foreach file in `files'{	
	local fileandpathtodelete = "`deletepathclean'"+"`file'"
	capture erase "`fileandpathtodelete'"

}
*/


*cd "`dir'"
*veracrypt, dismount drive(H)

n: di "${proj}_${tool}_Data_Protection ran successfully"
































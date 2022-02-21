quietly {

** EUTF/GIZ Tekki Fii Evaluation
** Endline
** Cycle 1 
** Youth Survey
* Elikplim Atsiatorme Dec 2021

// This do-file is the Master do-file for the data management. It first runs the 
// do-files that take the data from export to clean. It then outputs a progress report
// and runs data quality checks

clear all

/*
ssc install tabcount

net install github, from("https://haghish.github.io/github/")

net install ctomergecom, all replace ///
from("https://raw.githubusercontent.com/c4ed-mannheim/commentsmerge/main")

*tamerge - can't seem to download from github
* inttrend - user package

net install ipacheck, from("https://raw.githubusercontent.com/PovertyAction/high-frequency-checks/master/ado") replace 

ssc install cfout
ssc install bcstats
ssc install readreplace
ssc install match
ssc install fre
ssc install geodist 

*/


// General Globals
global ONEDRIVE "C:\Users\/`c(username)'\C4ED\"
global version = 1
global date = string(date("`c(current_date)'","DMY"),"%tdNNDD")
global time = string(clock("`c(current_time)'","hms"),"%tcHHMMSS")
global datetime = "$date"+"$time"


global hfc = 0
global progress = 0
global bc = 0
global trends = 0


// Round > Cycle > Tool Globals
global proj "P20204b"
global round "Endline"
global cycle "C1"
global tool "Youth"

// Local Paths
if "`c(username)'"=="NathanSivewright" { 
	global timezone = 1
global dofiles "C:\Users\/`c(username)'\Documents\GitHub\P20204_GMB\dofiles"
capture mkdir "C:\Users\/`c(username)'\Desktop\P20204b_GMB_Local\"
capture mkdir "C:\Users\/`c(username)'\Desktop\P20204b_GMB_Local\/$round\"
capture mkdir "C:\Users\/`c(username)'\Desktop\P20204b_GMB_Local\/$round\/$cycle\"
capture mkdir "C:\Users\/`c(username)'\Desktop\P20204b_GMB_Local\/$round\/$cycle\/$tool\"
global local_path "C:\Users\/`c(username)'\Desktop\P20204b_GMB_Local\/$round\/$cycle\/$tool\"

}

if "`c(username)'"=="ElikplimAtsiatorme" {
		global timezone = 1
// Making local folder on desktop for data
global dofiles "C:\Users\/`c(username)'\Documents\GitHub\P20204_GMB\P20204_GMB\dofiles"
capture mkdir "C:\Users\/`c(username)'\OneDrive - C4ED\Dokumente\Desktop\P20204b_GMB_Local\"
capture mkdir "C:\Users\/`c(username)'\OneDrive - C4ED\Dokumente\Desktop\P20204b_GMB_Local\/$round\"
capture mkdir "C:\Users\/`c(username)'\OneDrive - C4ED\Dokumente\Desktop\P20204b_GMB_Local\/$round\/$cycle\"
capture mkdir "C:\Users\/`c(username)'\OneDrive - C4ED\Dokumente\Desktop\P20204b_GMB_Local\/$round\/$cycle\/$tool\"
global local_path "C:\Users\/`c(username)'\OneDrive - C4ED\Dokumente\Desktop\P20204b_GMB_Local\/$round\/$cycle\/$tool\"
}





//Data Management
global encrypted_drive "H"
global encrypted_path "$encrypted_drive:"

global project_folder "$ONEDRIVE\P20204b_EUTF_GMB - Documents\02_Analysis\04_Raw_Data\/$round\/$cycle\/$tool\"
global hfc_path "$ONEDRIVE\P20204b_EUTF_GMB - Documents\02_Analysis\06_Field_Work_Reports\Endline\HFC\"
global hfc_output "$ONEDRIVE\P20204b_EUTF_GMB - Documents\02_Analysis\06_Field_Work_Reports\Endline\HFC\05_output"
global ceprass_folder "$ONEDRIVE\P20204b_EUTF_GMB - Documents\04_Field Work\Share with CepRass\"
global media_path "$local_path\media"

global exported "$encrypted_path\exported"
global corrections "$encrypted_path\corrections"
global cleaning "$encrypted_path\cleaning"
global qx "$ONEDRIVE\P20204b_EUTF_GMB - Documents\03_Questionnaires\03_Endline\Programming\Tekki_Fii_PV_Endline_WIP.xlsx" // improve this
global sample_list "$encrypted_path\endline sample"
global table_name "Tekki_Fii_PV_4"
global main_table "${table_name}_checked"

global errorfile "$ONEDRIVE\P20204b_EUTF_GMB - Documents\02_Analysis\06_Field_Work_Reports\Endline\HFC\test"

global field_work_reports "$ONEDRIVE\P20204b_EUTF_GMB - Documents\02_Analysis\06_Field_Work_Reports\Endline\HFC\"
global checking_log "$field_work_reports\checking_log"

local checksheet "${main_table}_CHECKS"
global id ApplicantID
global scto_server "mannheimc4ed"



*** Back-check sample
// Data Of Interest
global id "ApplicantID" // Unique ID
global name "full_name" // Full name of participant
global completed "consent" // Whether midline was completed
global treatment "treatment"
global phone "final_phone" // Stub of phone numbers variable
global social_media "whatsapp telegram signal" // all social media variables
global email "email"
global sub_date "submissiondate"
*global today "06may2021"





n: di "Hi `c(username)'!"

cd "$dofiles"

}

include "1.01. ${proj}_${tool}_Key_Variables.do"


cd "$dofiles"

******************************************
** 1. DATA PROCESSING AND PREPARATION (CLEANING AND CORRECTIONS)
******************************************
*do "1.05. ${proj}_${tool}_Decryption.do"
*cd "$dofiles"
do "1.1. ${proj}_${tool}_Export.do"
cd "$dofiles"
do "1.2. ${proj}_${tool}_Clean_Data.do"
cd "$dofiles"
do "1.3. ${proj}_${tool}_Corrections_Data.do"
cd "$dofiles"


******************************************
* 2. DATA QUALITY CHECKS
******************************************
do "1.4. P20204b_Youth_HFCs_IPA.do"
cd "$dofiles"
if $hfc == 1 {
do "1.4. ${proj}_${tool}_HFCs.do"
cd "$dofiles"
}
if $trends == 1 {
do "1.5. ${proj}_${tool}_Enumerator_Trends.do"
cd "$dofiles"
}

if $bc == 1 {
do "2.2 ${proj}_${tool}_BC_Sample.do"
cd "$dofiles"
}

if $progress == 1 {
******************************************
* 3. FIELDWORK PROGRESS
******************************************
do "3.1. ${proj}_${tool}_Progress.do"
cd "$dofiles"
}

******************************************
** 4. DE-IDENTIFICATION OF DATA
******************************************
do "4.1. ${proj}_${tool}_Data_Protection.do"
cd "$dofiles"
*do "4.2. ${proj}_${tool}_Data_Encryption.do"
*cd "$dofiles"
******************************************
** 4. PRELIMINARY ANALYSIS
******************************************


di "Ran Successfully!"
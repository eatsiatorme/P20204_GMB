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

*capture veracrypt, dismount drive(H)

// General Globals
global ONEDRIVE "C:\Users\/`c(username)'\C4ED\"
global version = 1
global date = string(date("`c(current_date)'","DMY"),"%tdNNDD")
global time = string(clock("`c(current_time)'","hms"),"%tcHHMMSS")
global datetime = "$date"+"$time"

// Round > Cycle > Tool Globals
global proj "P20204b"
global round "Endline"
global cycle "C1"
global tool "Youth"

//Data Management
global encrypted_drive "H"
global encrypted_path "$encrypted_drive:"
*global scto_download "H:\scto\P20204b_GMB_Local\Endline\C1\Youth"
global project_folder "$ONEDRIVE\P20204b_EUTF_GMB - Documents\02_Analysis\04_Raw_Data\/$round\/$cycle\/$tool\"

*global surveycto "$ONEDRIVE\P20204b_EUTF_GMB - Documents\02_Analysis\04_Raw_Data\/$round\/$cycle\/$tool\SurveyCTO Sync\"
global exported "$encrypted_path\exported"
global corrections "$encrypted_path\corrections"
*global mis "$ONEDRIVE\P20204b_EUTF_GMB - Documents\02_Analysis\04_Raw_Data\/$round\/$cycle\/$tool\misc"
global cleaning "$encrypted_path\cleaning"
*global pii "$ONEDRIVE\P20204b_EUTF_GMB - Documents\02_Analysis\04_Raw_Data\/$round\/$cycle\/$tool\PII"
*global qx "$ONEDRIVE\P20204b_EUTF_GMB - Documents\03_Questionnaires\01_Midline\Programming\Tekki_Fii_PV_210502.xlsx" // improve this
*global tables "$ONEDRIVE\P20204b_EUTF_GMB - Documents\02_Analysis\03_Tables_Graphs\"
*global sample_list "$ONEDRIVE\P20204b_EUTF_GMB - Documents\03_Questionnaires\01_Midline\Programming\Sample\"
*global incentives "$ONEDRIVE\P20204b_EUTF_GMB - Documents\04_Field Work\Incentives Number\"
*global field_work_reports "$ONEDRIVE\P20204b_EUTF_GMB - Documents\02_Analysis\06_Field_Work_Reports\/$round\/$cycle\/$tool\"
*global scto_server "mannheimc4ed"
*global bl_data "$ONEDRIVE\P20204b_EUTF_GMB - Documents\02_Analysis\04_Raw_Data\Baseline\Cleaned Merge"
*global errorfile "$ONEDRIVE\P20204b_EUTF_GMB - Documents\02_Analysis\06_Field_Work_Reports\Endline\C1\Youth\error datasets"
*global id
*global checking_log "$ONEDRIVE\P20204b_EUTF_GMB - Documents\02_Analysis\06_Field_Work_Reports\Endline\C1\Youth\checking_log/"
global main_table "Tekki_Fii_PV_3"
*local checksheet "${main_table}_CHECKS"


global key_outcome "wrk_cntr num_empl spe_score brs_score current_inc sum_inc_reference current_bus employed_stable_ever employed_ilo" // Key outcome variables - add to from clean dataset
global key_outcome_outlier "ave_month_inc emp_inc_month_? emp_inkind_month_? profit_month_? c2 c4" // Key outcome variables - add to from clean dataset
global enumerator_check_vars "b2 tekkifii_check tekkifii_check_ind j1a j1b"

if "`c(username)'"=="NathanSivewright" { 
global dofiles "C:\Users\/`c(username)'\Documents\GitHub\P20204_GMB\dofiles"
capture mkdir "C:\Users\/`c(username)'\Desktop\P20204b_GMB_Local\"
capture mkdir "C:\Users\/`c(username)'\Desktop\P20204b_GMB_Local\/$round\"
capture mkdir "C:\Users\/`c(username)'\Desktop\P20204b_GMB_Local\/$round\/$cycle\"
capture mkdir "C:\Users\/`c(username)'\Desktop\P20204b_GMB_Local\/$round\/$cycle\/$tool\"
global local_path "C:\Users\/`c(username)'\Desktop\P20204b_GMB_Local\/$round\/$cycle\/$tool\"

}

if "`c(username)'"=="ElikplimAtsiatorme" {
// Making local folder on desktop for data
global dofiles "C:\Users\/`c(username)'\Documents\GitHub\P20204_GMB\P20204_GMB\dofiles"
capture mkdir "C:\Users\/`c(username)'\OneDrive - C4ED\Dokumente\Desktop\P20204b_GMB_Local\"
capture mkdir "C:\Users\/`c(username)'\OneDrive - C4ED\Dokumente\Desktop\P20204b_GMB_Local\/$round\"
capture mkdir "C:\Users\/`c(username)'\OneDrive - C4ED\Dokumente\Desktop\P20204b_GMB_Local\/$round\/$cycle\"
capture mkdir "C:\Users\/`c(username)'\OneDrive - C4ED\Dokumente\Desktop\P20204b_GMB_Local\/$round\/$cycle\/$tool\"
global local_path "C:\Users\/`c(username)'\OneDrive - C4ED\Dokumente\Desktop\P20204b_GMB_Local\/$round\/$cycle\/$tool\"
}


global media_path "$local_path\media"

n: di "Hi `c(username)'!"

cd "$dofiles"

}



******************************************
** 1. DATA PROCESSING
******************************************
*do "1.0. P20204b_Youth_Decryption.do"
cd "$dofiles"
do "1.1. P20204b_Youth_Export.do"
cd "$dofiles"
do "1.2. P20204b_Youth_Clean_Data.do"
cd "$dofiles"
******************************************
* 2. FIELDWORK PROGRESS
******************************************


******************************************
** 3. DATA CHECKS
******************************************

******************************************
** 4. PRELIMINARY ANALYSIS
******************************************


di "Ran Successfully!"
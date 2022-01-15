*quietly {
n: di "${proj}_${round}_Decryption.do Started"

/*
*** Tekki Fii Midline
*  Elikplim Atsiatorme December 2021

This do-file decrypts the veracrypt container holding PII data. 

*/

****************************************
******Veracrypt Password: *****
****************************************
capture veracrypt, dismount drive(H)
cd "$project_folder"
veracrypt vault, mount drive($encrypted_drive)

n: di "${proj}_${round}_Decryption.do Completed"
*}
*quietly {
n: di "${proj}_${round}_Decryption.do Started"

/*
*** Tekki Fii Endline
* January 2022

This do-file decrypts the veracrypt container holding PII data. 

*/

****************************************
******Veracrypt (P20204b Field Data) *****
****************************************
capture veracrypt, dismount drive(H)
cd "$project_folder"
veracrypt vault, mount drive($encrypted_drive)

n: di "${proj}_${round}_Decryption.do Completed"
*}
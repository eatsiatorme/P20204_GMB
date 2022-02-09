quietly {
n: di "${proj}_${tool}_Encryption.do Started"

/*
*** Tekki Fii Midline
*  Elikplim Atsiatorme December 2021

This do-file encrypts the veracrypt container holding PII data. 

*/
veracrypt, dismount drive(H)


n: di "${proj}_${tool}_Encryption.do Completed"
}
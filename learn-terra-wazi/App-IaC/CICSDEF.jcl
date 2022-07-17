//NLOPEZC  JOB 'ACCT#',MSGCLASS=H                              
//* Use this job to add your extracted CICS app definitions to
//* your new zOS/CICS instance
//* Run he CICS extract job first on your dev system 
//* Use your Dev regions CICS steplib and CSD  
//*
//TRN    EXEC PGM=DFHCSDUP,REGION=0M,                              
//             PARM='CSD(READWRITE),PAGESIZE(60),NOCOMPAT'         
//STEPLIB  DD DISP=SHR,DSN=CICSTS.V5R6M0.CICS.SDFHLOAD             
//DFHCSD   DD DISP=SHR,DSN=CICSTS56.DFHCSD                         
//OUTDD    DD  SYSOUT=*                                            
//SYSPRINT DD  SYSOUT=*                                            
//SYSIN    DD DISP=SHR,DSN=IBMUSER.JCL(CICSDEF)                    
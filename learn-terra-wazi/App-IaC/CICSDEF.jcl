//IBMUSERC  JOB 'ACCT#',MSGCLASS=H                              
//* This job adds your extracted Dev CICS app definitions to
//* your new zOS/CICS instance. 
//* Requires that you run the APPDUMP job on your dev system first 
//* Steplib and CSD are based on Wazi aaS zOS image of june 2022
//* No changes are needed to this JCL 
//TRN    EXEC PGM=DFHCSDUP,REGION=0M,                              
//       PARM='CSD(READWRITE),PAGESIZE(60),NOCOMPAT'         
//STEPLIB  DD DISP=SHR,DSN=CICSTS.V5R6M0.CICS.SDFHLOAD             
//DFHCSD   DD DISP=SHR,DSN=CICSTS56.DFHCSD                         
//SYSPRINT DD SYSOUT=*                                            
//SYSIN    DD DISP=SHR,DSN=IBMUSER.JCL(CICSDEF)                    
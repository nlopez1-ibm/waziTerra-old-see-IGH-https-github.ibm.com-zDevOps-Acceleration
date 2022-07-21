//IBMUSERR JOB 'ACCT#',MSGCLASS=H,REGION=0M,MSGLEVEL=(1,1)           
//**
//* See APPDUMP.jcl for notes                                       
//* Be careful not in add hex '0d' when editing                     
//* Other than reviewing the output file SPACE parms, no changes are needed 
//**
//* clean up for reruns 
//DEL  EXEC PGM=IEFBR14                                            
//APP  DD  DISP=(MOD,DELETE),DSN=IBMUSER.WAZI.DUMP.APPLIBS,        
// SPACE=(TRK,(1,0)),UNIT=SYSDA                                    
//SYS  DD  DISP=(MOD,DELETE),DSN=IBMUSER.WAZI.DUMP.SYSLIBS,        
// SPACE=(TRK,(1,0)),UNIT=SYSDA                                    
//*
//* Receive the image files            
//RECV EXEC PGM=IKJEFT01 
//IAPP DD PATH='/u/ibmuser/applibs.xmit',                       
// PATHDISP=(KEEP,KEEP),PATHOPTS=OWRONLY,PATHMODE=(SIRUSR,SIWUSR)             
//OAPP DD  DISP=(NEW,CATLG),DSN=IBMUSER.WAZI.DUMP.APPLIBS,         
// DCB=(RECFM=U,DSORG=PS,LRECL=0,BLKSIZE=0),SPACE=(CYL,(1,15)),     
// UNIT=SYSDA                                                       
//ISYS DD PATH='/u/ibmuser/syslibs.xmit',                       
// PATHDISP=(KEEP,KEEP),PATHOPTS=OWRONLY,PATHMODE=(SIRUSR,SIWUSR)             
//OAPP DD  DISP=(NEW,CATLG),DSN=IBMUSER.WAZI.DUMP.SYSLIBS,         
// DCB=(RECFM=U,DSORG=PS,LRECL=0,BLKSIZE=0),SPACE=(CYL,(1,50)),     
// UNIT=SYSDA   
//SYSTSPRT DD SYSOUT=*                                              
//SYSTSIN  DD *       
RECEIVE INFILE(IAPP)                 
DA('IBMUSER.WAZI.DUMP.APPLIBS')      
RECEIVE INFILE(ISYS)                 
DA('IBMUSER.WAZI.DUMP.SYSLIBS')      
END                                                                             
/*                                                                  
//* restore the app runtime                                                     
//RESTORE  EXEC PGM=ADRDSSU,COND=(4,LT)                             
//SYSPRINT DD SYSOUT=*                                              
//APP      DD DISP=OLD,DSN=IBMUSER.WAZI.DUMP.APPLIBS                
//SYS      DD DISP=OLD,DSN=IBMUSER.WAZI.DUMP.SYSLIBS                
//*pad the cntl card with blank up to col 80
//SYSIN    DD *                                                     
 RESTORE INDD(APP) DATASET(INCL(**)) REPLACE                                    
 RESTORE INDD(SYS) DATASET(INCL(**)) REPLACE                                    
/* 
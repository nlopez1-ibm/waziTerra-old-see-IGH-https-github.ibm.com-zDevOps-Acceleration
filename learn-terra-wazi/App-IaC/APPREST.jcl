//IBMUSERR JOB 'ACCT#',MSGCLASS=H,REGION=0M,MSGLEVEL=(1,1)           
//**
//* Restore you App Runtime (V1.1). See APPDUMP.jcl for notes.             
//* Review the SPACE. No other changes needed. 
//**
//* clean up for reruns 
//DEL  EXEC PGM=IEFBR14                                            
//APP  DD  DISP=(MOD,DELETE),DSN=IBMUSER.WAZI.DUMP.APPLIBS,        
// SPACE=(TRK,(1,0)),UNIT=SYSDA                                    
//APPC DD  DISP=(MOD,DELETE),DSN=IBMUSER.WAZI.DUMP.APPLIBS.COMP,        
// SPACE=(TRK,(1,0)),UNIT=SYSDA                                    
//SYS  DD  DISP=(MOD,DELETE),DSN=IBMUSER.WAZI.DUMP.SYSLIBS,        
// SPACE=(TRK,(1,0)),UNIT=SYSDA                                    
//SYSC DD  DISP=(MOD,DELETE),DSN=IBMUSER.WAZI.DUMP.SYSLIBS.COMP,        
// SPACE=(TRK,(1,0)),UNIT=SYSDA                                
//*
//* Receive the image files            
//RECV EXEC PGM=IKJEFT01 
//IAPP DD PATH='/u/ibmuser/applibs.xmit',                       
// PATHDISP=(KEEP,KEEP),PATHOPTS=OWRONLY,PATHMODE=(SIRUSR,SIWUSR)             
//OAPP DD  DISP=(NEW,CATLG),DSN=IBMUSER.WAZI.DUMP.APPLIBS.COMP,         
// DCB=(RECFM=F,DSORG=PS,LRECL=1024,BLKSIZE=1024),SPACE=(CYL,(1,15)),     
// UNIT=SYSDA                                                       
//ISYS DD PATH='/u/ibmuser/syslibs.xmit',                       
// PATHDISP=(KEEP,KEEP),PATHOPTS=OWRONLY,PATHMODE=(SIRUSR,SIWUSR)             
//OSYS DD  DISP=(NEW,CATLG),DSN=IBMUSER.WAZI.DUMP.SYSLIBS.COMP,         
// DCB=(RECFM=F,DSORG=PS,LRECL=1024,BLKSIZE=1024),SPACE=(CYL,(1,15)),     
// UNIT=SYSDA   
//SYSTSPRT DD SYSOUT=*                                              
//SYSTSIN  DD *       
RECEIVE INFILE(IAPP)                 
DA('IBMUSER.WAZI.DUMP.APPLIBS.COMP')      
RECEIVE INFILE(ISYS)                 
DA('IBMUSER.WAZI.DUMP.SYSLIBS.COMP')      
END                                                                             
/*             
//* UNCOMPRESS files 
//* Compress the output 
//UNPKAPP  EXEC PGM=AMATERSE,PARM=UNPACK 
//SYSPRINT DD SYSOUT=*                                                 
//SYSUT1   DD DISP=SHR,DSN=IBMUSER.WAZI.DUMP.APPLIBS.COMP                    
//SYSUT2   DD  DISP=(NEW,CATLG),DSN=IBMUSER.WAZI.DUMP.APPLIBS,     
// DCB=(RECFM=U,DSORG=PS,LRECL=0,BLKSIZE=0),SPACE=(CYL,(1,25),RLSE),   
// UNIT=SYSDA                         
//*
//UNPKSYS  EXEC PGM=AMATERSE,PARM=UNPACK
//SYSPRINT DD SYSOUT=*                                                 
//SYSUT1   DD DISP=SHR,DSN=IBMUSER.WAZI.DUMP.SYSLIBS.COMP                    
//SYSUT2   DD  DISP=(NEW,CATLG),DSN=IBMUSER.WAZI.DUMP.SYSLIBS,     
// DCB=(RECFM=U,DSORG=PS,LRECL=0,BLKSIZE=0),SPACE=(CYL,(1,25),RLSE),   
// UNIT=SYSDA                         
//*                                                     
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
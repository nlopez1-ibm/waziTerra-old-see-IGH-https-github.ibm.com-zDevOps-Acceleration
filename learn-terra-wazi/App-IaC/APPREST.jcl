//NLOPEZR JOB 'ACCT#',MSGCLASS=H,REGION=0M,MSGLEVEL=(1,1)           
//* See APPDUMP.jcl for notes                                       
//* Be careful not in add hex '0d' when editing                                 
//RECV EXEC PGM=IKJEFT01,PARM='RECEIVE INFILE(IAPP)'                
//IAPP DD PATH='/u/ibmuser/applibs.xmit',                       
// PATHDISP=(KEEP,KEEP),PATHOPTS=OWRONLY,PATHMODE=(SIRUSR,SIWUSR)             
//OAPP DD  DISP=(MOD,CATLG),DSN=IBMUSER.WAZI.DUMP.APPLIBS,         
// DCB=(RECFM=U,DSORG=PS,LRECL=0,BLKSIZE=0),SPACE=(CYL,(1,15)),     
// UNIT=SYSDA                                                       
//*                                                                 
//SYSTSPRT DD SYSOUT=*                                              
//SYSTSIN  DD DUMMY                                                 
/*                                                                  
//RECV EXEC PGM=IKJEFT01,PARM='RECEIVE INFILE(ISYS)'                
//ISYS DD PATH='/u/ibmuser/syslibs.xmit',                       
// PATHDISP=(KEEP,KEEP),PATHOPTS=OWRONLY,PATHMODE=(SIRUSR,SIWUSR)     
//OSYS DD  DISP=(MOD,CATLG),DSN=IBMUSER.WAZI.DUMP.SYSLIBS,         
// DCB=(RECFM=U,DSORG=PS,LRECL=0,BLKSIZE=0),SPACE=(CYL,(1,50)),     
// UNIT=SYSDA                                                       
//*                                                                 
//SYSTSPRT DD SYSOUT=*                                              
//SYSTSIN  DD DUMMY                                                 
/*                                                                  
/*                                                                  
//RESTORE  EXEC PGM=ADRDSSU,COND=(4,LT)                             
//SYSPRINT DD SYSOUT=*                                              
//APP      DD DISP=OLD,DSN=IBMUSER.WAZI.DUMP.APPLIBS                
//SYS      DD DISP=OLD,DSN=IBMUSER.WAZI.DUMP.SYSLIBS                
//*pad the cntl card with blank up to col 80
//SYSIN    DD *                                                     
 RESTORE INDD(APP) DATASET(INCL(**)) REPLACE                                    
 RESTORE INDD(SYS) DATASET(INCL(**)) REPLACE                                    
/* 
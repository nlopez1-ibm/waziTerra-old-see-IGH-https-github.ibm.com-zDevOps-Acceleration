//NLOPEZR JOB 'ACCT#',MSGCLASS=H,REGION=0M,MSGLEVEL=(1,1)
//*
//* Manually edit, copy and run this job on your dev lpar before
//* creating your new zOS instance.  It creates copies of your
//* current application and prod runtime libs needed to build
//* and test on any other zOS image. iT ALSO RUNS A cics extract 
//* by Group to recreate you CICS defintions. 
//*
//* Review/update the Jobcard, space parm, HLQ and all control cards
//* Include loadlib(s) needed for staic link and dynamic calls.
//* CICS RPL libs need to be added to the supplied CICSTS56.JCL  
//* file in this folder (see that file for notes).
//*
//* This job created 3 files:
//*  + APPLIBS has a copy of your application libs
//*  + SYSLIBS has a copy of other libs like prod joblibs, cntl ...
//*  + CICS Defintions (for one region)
//* During the initialization of your new zOS instance these
//* files are used to restore your dev environment by the
//* postinit script.
//*
//* WIP: You can rerun this job and its scripts manually to refresh
//* these libs after the intiial IPL.  Test DATA is not included.
//*
//* Symbolics for d3ev lpar change to match you needs
//USSHOME SET HOME='/u/nlopez/wazi-vsi'
//HLQ     SET HLQ='NLOPEZ'
//*
//* Remove any old .xmit files
//DELXMIT  EXEC PGM=BPXBATCH,PARM='sh mkdir -p &HOME ; rm &HOME/*'
//STDOUT   DD  SYSOUT=*
//STDERR   DD  SYSOUT=*
//* 
//** Run the dump of user & app dev libs (joblib, cntl ...)
//COPY     EXEC PGM=ADRDSSU
//APPLIBS  DD  DISP=(MOD,CATLG),DSN=&HLQ..WAZI.DUMP.APPLIBS,
// DCB=(RECFM=U,DSORG=PS,LRECL=0,BLKSIZE=0),SPACE=(CYL,(1,25)),
// UNIT=SYSDA
//SYSLIB   DD  DISP=(MOD,CATLG),DSN=&HLQ..WAZI.DUMP.SYSLIBS,
// DCB=(RECFM=U,DSORG=PS,LRECL=0,BLKSIZE=0),SPACE=(CYL,(1,25)),
// UNIT=SYSDA
//SYSPRINT DD SYSOUT=*
//*
//* Add your APP or personal PDS names as showm below.
//SYSIN    DD *
 DUMP DATASET (INCLUDE( -
                 ZDEV.FEATURE.**, -
                 ZDEV.DEVELOP.**, -
                 DAT.TEAM.**, -
                 NLOPEZ.**.JCL, -
                 NLOPEZ.IDZ.**) -
               BY(DSORG,EQ,(SAM,PDS,PDSE)) ) -
  OUTDD(APPLIBS) COMPRESS TOL(ENQF)
  
  DUMP DATASET (INCLUDE( -
                 ZDEV.MAIN.**, -
                 DAT.PROD.**) -
               BY(DSORG,EQ,(SAM,PDS,PDSE)) ) -
   OUTDD(SYSLIBS)  COMPRESS TOL(ENQF) 
/*
//*
//* Convert the dump files into XMITs for for transport.
//* This assumes your HOME dir has engough free space for you copies.
//XMIT EXEC PGM=IKJEFT01
//IAPPLIBS    DD DSN=&HLQ..WAZI.DUMP.APPLIBS,DISP=OLD
//OAPPLIBS    DD PATH='&HOME/applibs.xmit',
//            PATHDISP=(KEEP,DELETE),
//            PATHOPTS=(OWRONLY,OCREAT,OEXCL),PATHMODE=(SIRUSR,SIWUSR)
//ISYSLIBS    DD DSN=&HLQ..WAZI.DUMP.SYSLIBS,DISP=OLD
//OSYSLIBS    DD PATH='&HOME/syslibs.xmit',
//            PATHDISP=(KEEP,DELETE),
//            PATHOPTS=(OWRONLY,OCREAT,OEXCL),PATHMODE=(SIRUSR,SIWUSR)
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
 XMIT SOW1.IBMUSER FILE(IAPPLIBS) OUTFILE(OAPPLIBS)
 XMIT SOW1.IBMUSER FILE(ISYSLIBS) OUTFILE(OSYSLIBS)
/*
//* This styep extracts your applications CICS defintions 
//* Review the CICS steplib abd CSD DSNs          
//* Also add your CICS application Group name for the extract      
//*        
//DEL      EXEC PGM=BPXBATCH,PARM='sh rm &HOME/CICSDEF.cntl'       
//STDOUT   DD  SYSOUT=*                                            
//STDERR   DD  SYSOUT=*                                            
//*                                                                
//**                                                               
//APPEXTR  EXEC PGM=DFHCSDUP,REGION=0M,                            
//         PARM='CSD(READWRITE),PAGESIZE(60),NOCOMPAT'        
//STEPLIB  DD DSN=DFH560.CICS.SDFHLOAD,DISP=SHR                       
//DFHCSD   DD DISP=SHR,DSN=DFH560.CICS.DFHCSD                         
//OUTDD    DD  SYSOUT=*                                               
//SYSPRINT DD  SYSOUT=*                                                   
//CBDOUT   DD DISP=(NEW,PASS),DSN=&&CBDOUT,                             
//            LRECL=80,RECFM=FB,BLKSIZE=80,SPACE=(TRK,(1,1)),UNIT=SYSDA 
//* 
//* Chg group to your app. More that one EXTRACT can be performed.
//SYSIN    DD  *                                                      
 EXTRACT GROUP(DAT) OBJECTS USERPROGRAM(DFH0CBDC)                     
/*
//* COPY CICS extract TO USS for transport 
//COPYSTEP EXEC PGM=IKJEFT01                                          
//INMVS    DD DSN=&&CBDOUT,DISP=(OLD,PASS)                            
//OUTHFS   DD PATH='&home/CICSDEF.cntl',                          
//            PATHDISP=(KEEP,DELETE),                                 
//            PATHOPTS=(OWRONLY,OCREAT,OEXCL),PATHMODE=(SIRUSR,SIWUSR)
//SYSTSPRT DD SYSOUT=*                                                
//SYSTSIN  DD *                                                       
OCOPY INDD(INMVS) OUTDD(OUTHFS) TEXT CONVERT(YES) PATHOPTS(USE)       
/*
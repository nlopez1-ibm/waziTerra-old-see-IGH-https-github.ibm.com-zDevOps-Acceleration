//NLOPEZR JOB 'ACCT#',MSGCLASS=H,REGION=0M,MSGLEVEL=(1,1)
//*
//*       Application build and runtime copy job 
//* This job copies an App's build and runtime configuration on Dev   
//* to recreate a similar configuration on any new zOS instance. 
//* 
//* This captures an image of an App config in 3 files: 
//*  1: APPLIBS - a copy of an application's dev libs  
//*  2: SYSLIBS - a copy of an app's prod libs like joblibs, cntl ...
//*  3: CICSDEF - a CICS definition extract by App Group
//*
//* Change and save in this folder the following: 
//*  + Jobcard, space parms and HLQ. 
//*  + The first DUMP control card to include your App's PDSs   
//*    like loadlib, jcl, CNTL... whatever you need on the new env.
//*  + The second DUMP card to include production libs 
//*    like those used to access static and dynamic modules.  
//*  + The 'CICSEXTR' step's card to optionally include your 
//*    CICS defintions by App GROUP name. If your not testing 
//*    a CICS app, you can remove this step and the COPYDEFS step.
//* 
//* NOTE: If testing a CICS app, RPL libs must be added to 
//* the sample CICSTS56.jcl file in this folder. It will be used  
//* to start a CICS region in the new zOS.
//****   
//*
//* Symbolics for dev lpar. Chg HOME dir and HLQ to match your acct.
//USSHOME SET HOME='/u/nlopez/App-IaC/'
//HLQ     SET HLQ='NLOPEZ'
//*
//* Step to remove old files
//DELXMIT  EXEC PGM=BPXBATCH,PARM='sh mkdir -p &HOME ; rm &HOME/*'
//STDOUT   DD  SYSOUT=*
//STDERR   DD  SYSOUT=*
//DELDEFS  DD  DISP=(MOD,DELETE),DSN=&HLQ..WAZI.CICS.APPDEFS,
// SPACE=(TRK,(1,0)),UNIT=SYSDA
//DELAPPS  DD  DISP=(MOD,DELETE),DSN=&HLQ..WAZI.DUMP.APPLIBS,
// SPACE=(TRK,(1,0)),UNIT=SYSDA
//DELSYS   DD  DISP=(MOD,DELETE),DSN=&HLQ..WAZI.DUMP.SYSLIBS,
// SPACE=(TRK,(1,0)),UNIT=SYSDA
//*
//** Dump build and runtime libs 
//COPY     EXEC PGM=ADRDSSU
//APPLIBS  DD  DISP=(NEW,CATLG),DSN=&HLQ..WAZI.DUMP.APPLIBS,
// DCB=(RECFM=U,DSORG=PS,LRECL=0,BLKSIZE=0),SPACE=(CYL,(1,25)),
// UNIT=SYSDA
//SYSLIBS  DD  DISP=(NEW,CATLG),DSN=&HLQ..WAZI.DUMP.SYSLIBS,
// DCB=(RECFM=U,DSORG=PS,LRECL=0,BLKSIZE=0),SPACE=(CYL,(1,25)),
// UNIT=SYSDA
//SYSPRINT DD SYSOUT=*
//*
//* Add your App and/or personal PDSs in the first INCLUDE block..
//* The second DUMP task can include any production or other 
//* suppporting PDSs. Review the JCL space parm for both OUTDD's
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
//* Convert the dumps and store them in USS for transport.
//* This assumes your HOME dir has enough free space.
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
//* This step extracts your application CICS defintions.
//* Ensure the CICS steplib and CSD DSNs match your CICS region.
//* Also add your CICS application Group name for the extract.
//*
//* If your not testing a CICS app, delete these following steps
//CICSEXTR EXEC PGM=DFHCSDUP,REGION=0M,
//         PARM='CSD(READWRITE),PAGESIZE(60),NOCOMPAT'
//STEPLIB  DD DSN=DFH560.CICS.SDFHLOAD,DISP=SHR
//DFHCSD   DD DISP=SHR,DSN=DFH560.CICS.DFHCSD
//SYSPRINT DD SYSOUT=*
//CBDOUT   DD DISP=(NEW,CATLG),DSN=&HLQ..WAZI.CICS.APPDEFS,
//         LRECL=80,RECFM=FB,BLKSIZE=80,SPACE=(TRK,(1,1)),UNIT=SYSDA
//*
//* Chg the GROUP. More than one EXTRACT can be performed.
//*
//SYSIN    DD  *
 EXTRACT GROUP(DAT) OBJECTS USERPROGRAM(DFH0CBDC)
/*
//* copy the cics def file to USS for transport
//COPYDEFS EXEC PGM=BPXBATCH,
// PARM=('sh cp //"''&HLQ..WAZI.CICS.APPDEFS''" &HOME/CICSDEF.cntl')
//STDOUT   DD  SYSOUT=*
//STDERR   DD  SYSOUT=*
//*
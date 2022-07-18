//NLOPEZR JOB 'ACCT#',MSGCLASS=H,REGION=0M,MSGLEVEL=(1,1)
//*
//* Manually edit this jcl and run it on your dev lpar before
//* creating your new zOS instance.  It creates copies of your
//* current application and prod runtime libs.  The copies are
//* transported to you new zOS instance where you can build
//* and test your changes in isoldation. This sample also shows
//* how to extract CICS App Defintions.
//*
//* Review/update the Jobcard, space parms, HLQ and all CNTLs.
//* Include loadlib(s) needed for static linking and dynamic calls.
//* CICS RPL libs must be added to the CICSTS56.JCL in this folder.
//* Dont change DSNs as they are referred to by other processes.
//*
//* This job creates 3 file type
//*  + APPLIBS has a copy of your application libs
//*  + SYSLIBS has a copy of other libs like prod joblibs, cntl ...
//*  + CICS Defintions (for one CICS region)
//* During the initialization of your new zOS instance these
//* files are used to replicate your dev environment using the
//* "/App-IaC/postinit.bat" script during the terraform apply process.
//*
//* WIP: You can rerun this job and its scripts manually to refresh
//* these libs after the intiial IPL.  Test DATA is not included.
//*
//* Symbolics for dev lpar. Chg HOME dir and HLQ to match your acct.
//USSHOME SET HOME='/u/nlopez/App_IaC/'
//HLQ     SET HLQ='NLOPEZ'
//*
//* Remove any old files
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
//** Run the dump of user & app dev libs (joblib, cntl ...)
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
//* The second DUMP task can include any production or suppporting
//* PDSs. Review the JCL space parm for both DD's
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
//* Ensure the CICS steplib and CSD DSNs mathc your CICS region.
//* Also add your CICS application Group name for the extract.
//*
//* If your not testing a CICS app, delete these following step
//APPEXTR  EXEC PGM=DFHCSDUP,REGION=0M,
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
//CPDEFS   EXEC PGM=BPXBATCH,
// PARM=('sh cp //"''&HLQ..WAZI.CICS.APPDEFS''" &HOME/CICSDEF.cntl')
//STDOUT   DD  SYSOUT=*
//STDERR   DD  SYSOUT=*
//*
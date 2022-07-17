NOT NEEDED SEE APPDUMP 

//NLOPEZC JOB 'ACCT#',MSGCLASS=H,REGION=0M,MSGLEVEL=(1,1)          
//*                                                                
//* Run this jonb on you Dev CICS Region to extract                
//* your applications defintions to use on you new zOS instance    
//* Review you HLQ, Jobcard and CICS steplibn abd CSD DSN          
//* Also add your CICS application Group name for the extract      
//*        
//* Symbolics                                                           
//USSHOME SET HOME='/u/nlopez'                                    
//* REMOVE ANY OLD FILE                                            
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
//SYSIN    DD  *                                                      
 EXTRACT GROUP(DAT) OBJECTS USERPROGRAM(DFH0CBDC)                     
/*
//* COPY TO uss
//COPYSTEP EXEC PGM=IKJEFT01                                          
//INMVS    DD DSN=&&CBDOUT,DISP=(OLD,PASS)                            
//OUTHFS   DD PATH='&home/CICSDEF.cntl',                          
//            PATHDISP=(KEEP,DELETE),                                 
//            PATHOPTS=(OWRONLY,OCREAT,OEXCL),PATHMODE=(SIRUSR,SIWUSR)
//SYSTSPRT DD SYSOUT=*                                                
//SYSTSIN  DD *                                                       
OCOPY INDD(INMVS) OUTDD(OUTHFS) TEXT CONVERT(YES) PATHOPTS(USE)       
/*
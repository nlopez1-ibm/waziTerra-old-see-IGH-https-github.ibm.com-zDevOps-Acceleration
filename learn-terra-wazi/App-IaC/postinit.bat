@REM A windows script to config access and appy IaC configs 
@REM NOTES: 
@REM  - pre-run the APPDUMP job on the dev lpar to package app and system runtimes  
@REM  - review CICSEXTR JCL  to preREM  
@REM vsi sometimes hangs - may need to wait a few minutes 
@REM =============


@echo off
echo Post Wazi Setup on VSI ip %1... Please follow the prompts or CNTL/C to quit
set mywazi=%1
REM The account and IP  of the dev host (sample provided)
set devhost=nlopez@zos.dev


:Init_User
set initUser=y
set /p initUser="Press enter to finalize your new VSI.  Or enter any char to exit  --> "	
if  %initUser% NEQ y goto Init_Cert 

echo Waiting for IPL to end ...
:IPL 
ssh IBMUSER@%mywazi% tsocmd 'ALTUSER IBMUSER PASSWORD(sys1)'
IF ERRORLEVEL 1 GOTO IPL
echo IPL ended. Default password for IBMUSER is now SYS1 (for 3270 and IDz access)
pause 


:Init_Cert    
REM Cert = CN=STOCK_SELF_SIGNED_CERT    use windows MMC/cert snapon as needed 
set initCert=y
set /p initCert="Press enter to install the zOS CERT for 3270 access. Or enter any char to skip  --> "	
if  %initCert% NEQ y goto DBB_Init 

mkdir c:\tmp >NUL
echo Copying your cert from %mywazi% ... 
scp ibmuser@%mywazi%:/u/ibmuser/common_cacert c:/tmp/common.cer
echo Follow the windows dialog to Store the Cert into your 'Local Machine' 'Trusted Root...' location
explorer /e,c:\tmp\common.cer
pause 


:DBB_Init
set initDBB=y
set /p initDBB="Press enter to init DBB and other build settings. Or enter any char to skip  --> "	
if  %initDBB% NEQ y goto Set_local_hosts 

REM Add my custom DEMO DBB env 
echo ...............................
echo Copying /App-IaC/DBB-setup/.profile to %mywazi% /u/ibmuser/.profile  ...
scp -r App-IaC/DBB-setup/.profile ibmuser@%mywazi%:/u/ibmuser/.profile 

echo Running ssh-keygen for the IBMUSER account to use in git Cloning  ...
ssh ibmuser@%mywazi% "ssh-keygen -t rsa -b 4096 -C 'ibmuser@ibm.com.com'  -f /u/ibmuser/.ssh/id_rsa -P ''"

ssh ibmuser@%mywazi% "cat /u/ibmuser/.ssh/id_rsa.pub " > App-IaC/id_rsa.pub 
ssh ibmuser@%mywazi% "mkdir dbb-logs "
echo .
echo Paste your new public ssh key from /App-IaC/id_rsa.pub into your github acct NOW!! 
dir App-IaC\id_rsa*
pause 

REM - clone my repo using new ssh key from GITHUB 
echo Cloning a customized DBB/zappbuild ...
ssh ibmuser@%mywazi% "ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts"
ssh ibmuser@%mywazi% ". ./.profile ; git clone git@github.com:nlopez1-ibm/waziDBB.git"
pause 



:Set_Local_hosts
set initHosts=y
set /p initHosts="Press enter to add the new VSI floating IP to your local host file. Or enter any char to skip  --> "	
if  %initHosts% NEQ y goto Restore_App_Runtime

echo Open a windows terminal in ADMIN mode and run this cmd:  notepad C:\Windows\System32\drivers\etc\hosts 
echo Paste the text below into the hosts file and save (no extra spaces between parms and remove old entries).  
echo %1 mywazi  
pause 



:Restore_App_Runtime
set initAppRuntime=y
set /p initAppRuntime="Press enter replicate your App Runtime on %mywazi%. Or enter any char to skip  --> "	
if  %initAppRuntime% NEQ y goto exitok

echo WARNING: Did you run the App-IaC/APPDUMP.jcl on DEV yet?  Press enter when you have.  
pause 

echo Restoring your App Runtime from Dev to the new instance  ... 
set /p devhost="Enter your Dev RACF id and host name like --> %devhost%"

sftp  -P 2022 -b App-IaC/sget.script %devhost% 
IF EXIST App-IaC/applibs.xmit GOTO :Restore_App
echo ==============================
echo ==============================
echo      >>>>>>>>>>>>>>    ERROR  <<<<<<<<<<<<<<<<<<<
echo Could not find a local copy of App-IaC/applibs.xmit. Check the APPDUMP job for errors. 
echo Skiping all replication.  
echo ReRun this script when ready.
echo ==============================
echo ==============================
goto exitok


:Restore_App
echo Running your restore job(APPREST.jcl) on %mywazi%. ...
sftp -b App-IaC/sput.script ibmuser@%mywazi%

REM need to move the jcl to a pds becuase SCP adds CR to each line '0d'x 
scp -r App-IaC/APPREST.jcl  ibmuser@%mywazi%:apprest.jcl
ssh ibmuser@%mywazi% cp -F crnl -S d=.jcl apprest.jcl "//jcl"  
ssh ibmuser@%mywazi% submit "//'ibmuser.jcl(apprest)'" 

echo Job "IBMUSER.JCL(APPREST) submitted"
echo Logon to your new zOS instance and double check the JES outout for the above job to make sure it worked.  
echo The Job name starts with IBMUSER. 
echo First time login may require yout to reset your IBMUSER password default is SYS1. 
echo If the job failed, edit /u/ibmuser/APPREST.jcl on %mywazi% and rerun. 
pause 


:Apply_CICS_App_Defs
set initCICS=y
set /p initCICS="Press enter to apply your extracted CICS Application defintion. Or enter any char to skip  --> "	
if  %initCICS% NEQ y goto exitok
 
REM NOTE: the sget/sput scripts already copied the cntl if it was performed.
IF EXIST App-IaC/CICSDEF.cntl GOTO :Apply_Defs
echo ==============================
echo ==============================
echo      >>>>>>>>>>>>>>    ERROR  <<<<<<<<<<<<<<<<<<<
echo Could not find the local App-IaC/CICSDEF.cntl file. Check the APPDUMP job on Dev for errors. 
echo Skiping CICS Def replication.  
echo ReRun this script when ready. 
echo ==============================
echo ==============================
goto exitok

:Apply_Defs
REM //jcl defaults to IBMUSER.JCL. Its a preallocated PDS used for this demo (careful is a PDS prone to SB37)
REM the cntl files was transmitted with xmit if it was created. 
ssh ibmuser@%mywazi% cp -S d=.cntl CICSDEF.cntl "//jcl"
scp -r App-IaC/CICSDEF.jcl  ibmuser@%mywazi%:CICSDEF.jcl
ssh ibmuser@%mywazi% "submit  CICSDEF.jcl"
echo Job CICSDEF submitted and will apply your extracted Dev CICS defintions.  
REM Wait with a local ping 
ping localhost -n 3 > NUL
pause   

:ResetCICS_STC 
echo WARNING: Did you review/edit RPL libs in App-IaC/CICSTS56.jcl file yet? Press enter if you have. 
pause

echo Applying and restarting CICS with your customized proc  ... 
ssh ibmuser@%mywazi% ". ./.profile; opercmd c cicsts56 "

scp -r App-IaC/CICSTS56.jcl  ibmuser@%mywazi%:CICSTS56 
ssh ibmuser@%mywazi% cp -F crnl ~/CICSTS56 "//""'SYS1.PROCLIB'"" 
ping localhost -n 3 > NUL

ssh ibmuser@%mywazi% ". ./.profile; opercmd s cicsts56 "
ping localhost -n 3 > NUL
ssh ibmuser@%mywazi% ". ./.profile; opercmd F CICSTS56,CEDA INSTALL 'GROUP(DAT)'"
echo CICS Def and STC jobs complete. Review SDSF Output for errors under user IBMUSER.
pause  
goto exitok




:exitok 
echo ...............................
echo  ***   POSTINIT completed.  ***
echo Use a 3270 term that supports TLS/Certs like VISTA-3270 (PCOM or IDz host term  may not work)
echo zOS Ports (as of June-22 release): 
echo    RSE=8137   RSEAPI=8195   zOSMF=10443   TN3270=992(TLS with MS-CAPI) 

echo ...............................
echo The default RACF user and  password is IBMUSER SYS1
echo SSH by using [ssh IBMUSER@%mywazi%] (your ssh key has been pre-configued).
echo If you updated your local hosts file, access the new instance by name like [ssh IBMUSER@mywazi]
echo If you have trouble accessing the system try a re-IPL from the VSI action menu.
echo Your new VSI(${local.BASENAME}-vsi1) IP is ${ibm_is_floating_ip.fip1.address} 
echo When your done with this instance run 'terraform destroy'  
echo ................................

 
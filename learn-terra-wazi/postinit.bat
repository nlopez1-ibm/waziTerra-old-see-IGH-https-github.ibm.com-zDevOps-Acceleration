@REM A windows script to config access and appy IaC  configs 
REM NOTES: 
REM  - pre-run the APPDUMP job on the src lpar to package app and system runtimes  
REM  - review CICSEXTR JCL  to preREM  
REM vsi sometimes hangs - may need to wait a few minutes 
REM =============


@echo off
echo Post Wazi Setup on ip %1... 
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
rem mkdir on dev lpar 
ssh ibmuser@%mywazi% "ssh-keygen -t rsa -b 4096 -C 'ibmuser@ibm.com.com'  -f /u/ibmuser/.ssh/id_rsa -P ''"
pause 



:Init_Cert    
REM Cert = CN=STOCK_SELF_SIGNED_CERT    use windows MMC/cert snapon as needed 
set initCert=y
set /p initCert="Press enter to install the zOS CERT for 3270 access. Or enter any char to skip  --> "	
if  %initCert% NEQ y goto DBB_Init 

mkdir c:/tmp >NUL
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
echo Running ssh-keygen for git Cloning  ...
ssh ibmuser@%mywazi% "ssh-keygen -t rsa -b 4096 -C 'ibmuser@ibm.com.com'  -f /u/ibmuser/.ssh/id_rsa -P ''"
ssh ibmuser@%mywazi% "cat /u/ibmuser/.ssh/id_rsa.pub " > App-IaC/id_rsa.pub 
ssh ibmuser@%mywazi% "mkdir dbb-logs "
echo .
echo Paste your new public ssh key from /App-IaC/id_rsa.pub into your github acct NOW!! 
dir /App-IaC/id_rsa*
pause 

REM - clone my repo using new ssh key from GITHUB 
echo Cloning a customized DBB/zappbuild ...
ssh ibmuser@%mywazi% "ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts"
ssh ibmuser@%mywazi% ". ./.profile ; git clone git@github.com:nlopez1-ibm/waziDBB.git"
pause 



:Set_Local_hosts
set initHosts=y
set /p initHost="Press enter to add the new VSI folating IP to your local host file. Or enter any char to skip  --> "	
if  %initHosts% NEQ y goto Restore_App_Runtime

echo Open a windows terminal in ADMIN mode and run this cmd ->  notepad C:\Windows\System32\drivers\etc\hosts 
echo Paste the text below into the hosts file and save (no extra spaces between parms and remove old entries).  
echo %1 mywazi  
pause 



:Restore_App_Runtime
echo READY TO RESTORE YOUR APP RUNTIME ON %mywazi 
echo WARNING: Did you run the APPDUMP job yet?  Press enter when you have.  
pause 

set initAppRuntime=y
set /p initAppRuntime="Press enter restore your APPDUMP job output from Dev to your new zOS. Or enter any char to skip  --> "	
if  %initAppRuntime% NEQ y goto ?? 

echo Restoring your App Runtime from Dev to the new instance  ... 
set /p devhost="Enter your Dev racf id and host name like --> %devhost%"



sftp  -P 2022 -b App-IaC/sget.script %devhost% 
sftp          -b App-IaC/sput.script ibmuser@%mywazi%

echo Ready to run your restore job(APPREST.jcl) on %mywaazi%. ...
scp -r App-IaC/APPREST.jcl  ibmuser@%mywazi%:apprest.jcl
ssh ibmuser@%mywazi% "submit  apprest.jcl"
pause 



:Apply_CICS_App_Defs
Echo Ready to apply your extracted CICS Application CSD defintion 
pause
REM NOTE: the sget/sput scripts already copied the cntl - warn the user 
ssh ibmuser@%mywazi% cp -S d=.cntl CICSDEF.cntl "//jcl"
scp -r App-IaC/CICSDEF.jcl  ibmuser@%mywazi%:CICSDEF.jcl
ssh ibmuser@%mywazi% "submit  CICSDEF.jcl"
pauase  

:ResetCICS_STC 
echo Applying your custom CICS STC proc  ... 
pause
scp -r App-IaC/CICSTS56.jcl  ibmuser@%mywazi%:CICSTS56 

ssh ibmuser@%mywazi% cp -F crnl ~/CICSTS56 "//""'SYS1.PROCLIB'"" 

ssh ibmuser@%mywazi% ". ./.profile; opercmd c cicsts56 "
ssh ibmuser@%mywazi% ". ./.profile; opercmd s cicsts56 "
ssh ibmuser@%mywazi% ". ./.profile; opercmd F CICSTS56,CEDA INSTALL GROUP(DAT)"


goto exitok



 


REM sftp  ibmuser@mywazi 
REM put ...


REM CICS  - WIP
REM use cicsextr on src 

REM replace default cics stc with custom 

REM scp -r App-IaC/CICSTS56  ibmuser@%mywazi:/u/ibmuser/CICSTS56

REM use IBMUSER.CB12V51.LOAD as the rpl load on wazi 
REM cp src rpl to target 
REM ssh ibmuser@%mywazi cp ~/CICSTS56 /"\\'ibmuser.jcl(t)'"

REM NOTE IBMUSER.JCL PDS is predefined 




REM noise 

REM scp -P 2022  nlopez@zos.dev:/u/nlopez/.profile  /"\\'nlopez.wazi.dump.libs'"
REM cp  -F bin  "//'"$2"'" $zTar
REM ssh -p 2022 nlopez@zos.dev

REM scp -P 2022  nlopez@zos.dev:~/tmp/mylibs.dump  ./mylibs.dump
REM scp   ./mylibs.dump  ibmuser@mywazi:~/mylibs.dump



:exitok 
echo ...............................
echo One time VSI setup is complete. 
echo Use a 3270 term that support TLS/Certs like VISTA-3270 (PCOM & IDz may not work)
echo VSI Ports (as of June-22 release): 
echo     RSE=8137  RSEAPI=8195  zOSMF=10443  TN3270=992(TLS with MS-CAPI) 

echo ...............................
echo The default RACF user and  password is IBMUSER SYS1
echo SSH using ssh IBMUSER@%mywazi% (the default ssh key has been already assigned)
echo If you have trouble accessing the system try a re-IPL
echo Your new VSI(${local.BASENAME}-vsi1) IP is ${ibm_is_floating_ip.fip1.address}
echo You can also access the new system using the name 'mywazi' like 'ssh IBMUSER@mywazi' 
 
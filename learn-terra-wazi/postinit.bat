@REM a bat script to wrapup some post setup steps 163.109.88.125
@echo off
echo Post Wazi Setup ... 

set initHost=y
set /p initHost="Press enter to finalize your new VSI.  Or enter any char to exit  --> "	
if  %initHost% NEQ y goto bye 


echo Waiting for IPL to SSH into %1 ...
:IPL 
ssh IBMUSER@%1 tsocmd 'ALTUSER IBMUSER PASSWORD(sys1)'
IF ERRORLEVEL 1 GOTO IPL

    
REM STOCK Cert props CN=STOCK_SELF_SIGNED_CERT  use MMC/cert for details if needed 
echo ...............................
mkdir c:/tmp >NUL
echo Copying your zOS cert for 3270 access... 
scp ibmuser@%1:/u/ibmuser/common_cacert c:/tmp/common.cer
echo Follow the dialog to Install your Cert in your Local Machine's Trusted Root store location
pause 
explorer /e,c:\tmp\common.cer


REM Add my custom DBB env 
echo ...............................
echo Setting up zappbuild and more  ...
scp -r DBB-setup/.profile ibmuser@%1:/u/ibmuser/.profile 
ssh ibmuser@%1 "ssh-keygen -t rsa -b 4096 -C 'ibmuser@ibm.com.com'  -f /u/ibmuser/.ssh/id_rsa -P ''"
ssh ibmuser@%1 "cat /u/ibmuser/.ssh/id_rsa.pub " > id_rsa.pub
echo Your public ssh key has been created and saved in the current folder. Paste it into your github acct now
dir id*
pause 

REM - get my copy of dbb.  fix the mim issues with keyscan 
ssh ibmuser@%1 "mkdir dbb-logs "
ssh ibmuser@%1 "ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts"
ssh ibmuser@%1 ". ./.profile ; git clone git@github.com:nlopez1-ibm/waziDBB.git"

echo ...............................
echo Optionally paste the line below using  [notepad C:\Windows\System32\drivers\etc\hosts] from an admin term 
echo Careful with hosts file. No extra spaces between keywords and no dups 
echo %1 mywazi  
pause 

echo ...............................
echo One time VSI setup complete
echo Use a 3270 term uses certs like VISTA-3270 (PCOM & IDz fail)
echo Ports (as of June-22 release): RSE=8137  RSEAPI=8195  zOSMF=10443  TN3270=992(TLS with MS-CAPI) 

echo ...............................
echo The default RACF user and  password is IBMUSER SYS1
echo SSH using ssh IBMUSER@%1
echo If you have trouble accessing the system try a re-IPL
echo Your new VSI(${local.BASENAME}-vsi1) IP is ${ibm_is_floating_ip.fip1.address}
 
:bye

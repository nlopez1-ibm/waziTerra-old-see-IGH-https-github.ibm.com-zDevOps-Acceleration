@ECHO OFF
REM A Windows script to config access and appLy IaC APP configs afdter a VSI create
REM NOTES: 
REM  + vsi sometimes hangs - may need to wait a few minutes 
REM  + SCP moves in bin mode and addes a '0d'(lf) and cant scp directly to a PDS!
REM    So after an SCP use 'CP -F crnl' to strip end of line stuff into a MVS file. 
cls ; SETLOCAL enabledelayedexpansion ;  @echo off


echo  *** POSTINIT Started (PROTOTYPE):  App-IaC Setup on Wazi aaS VSI IP %1  (NLopez) *** 
goto Check_Args

:GoodToGo 
    set mywazi=%1
    echo This script will wait for the IPL of the new zOS/VSI instance to perform the following steps: 
    echo  - Resets the IBMUSER acct password to SYS1.
    echo  - Assists in installing the zOS CA-CERT locally  for 3270 access (windows mode).
    echo  - Generates an IBMUSER SSH KEY and the DBB/Git environment. 
    echo  - Prompts you to apply the new IBMUSER ssh key to your Git account for cloning on the new zOS (Github is use in this demo)
    echo  - Assists in adding the new VSI IP to your local windows hosts file to simpilfy setup of IDz/vsCode and other local tools.
    echo  - Replicate your application runtime from Dev to the new host  (see App-IaC/APPDUMP.jcl)
    echo  - Applies your App's CICS CSD defintions (extracted by App-IaC/APPDUMP.jcl and applied by App-IaC/CICSDEF.jcl)
    echo  - Replaces the CICSTS56 STC JCL with your version that should include your App RPL libs (see App-IaC/CICSTS56.jcl)
    echo  **
    echo  ** Replicating you App requires SSH access to the Application's zOS Dev host environment


    echo  ------------------------------

    echo  . & echo Please follow the prompts or CNTL/C to quit &echo  .  & echo  .    


    REM The account and IP  of the dev host (sample provided)
    set devhost=nlopez@zos.dev





:Init_User
    set initUser=y
    set /p initUser="Press enter to check the new VSI status and reset the IBMUSER password.  Or enter any char to skip this step --> "	
    if  %initUser% NEQ y goto Init_Local_Cert
    echo Please wait... Or CNTL/C if this takes more than 5 mins. 

:IPL_InProgress 
    ssh IBMUSER@%mywazi% "ls > /dev/nul "
    IF ERRORLEVEL 1 GOTO IPL_InProgress 

    ssh IBMUSER@%mywazi% tsocmd 'ALTUSER IBMUSER PASSWORD(sys1)'
    echo System is ready. Default password for IBMUSER is now SYS1 (for 3270 and IDz access)    
    echo . 


:Init_Local_Cert   
    REM Cert = CN=STOCK_SELF_SIGNED_CERT    use windows MMC/cert snapon as needed 
    set initCert=y
    set /p initCert="Press enter to install the zOS CERT for 3270 access. Or enter any char to skip  --> "	
    if  %initCert% NEQ y goto DBB_Init 

    mkdir c:\tmp >NUL
    echo Copying your cert from %mywazi% ... 
    scp ibmuser@%mywazi%:/u/ibmuser/common_cacert c:/tmp/common.cer
    echo Press "Install Certificate" on the popup dialog to Store the Cert into your 'Local Machine' 'Trusted Root...' location
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
    echo The IBMUSER public key is now in this local folder called /App-IaC/id_rsa.pub 
    echo Cut/Paste its contents into your GitHub acct NOW!! waiting....
    echo . & echo . & echo . 
    dir App-IaC\id_rsa*
    pause 

    REM - clone my repo using new ssh key from GITHUB 
    echo Cloning a customized DBB/zappbuild ...
    ssh ibmuser@%mywazi% "ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts ; . ./.profile ; git clone git@github.com:nlopez1-ibm/waziDBB.git"
    timeout /T 3 


:Set_Local_hosts
    set initHosts=y
    set /p initHosts="Press enter to add the new VSI floating IP to your local host file. Or enter any char to skip  --> "	
    if  %initHosts% NEQ y goto Restore_App_Runtime

    echo . & echo .& echo .
    echo Run this cmd from a windows TERM in ADMIN mode  [  notepad  C:\Windows\System32\drivers\etc\hosts  ]
    echo Then Paste the text below into the hosts file and save (no extra spaces between parms and remove old entries).  
    echo %1 mywazi  
    pause 


:Restore_App_Runtime
    echo . & echo .& echo .
    echo ***NOTE*** Ready to install your Application runtime Image using App-IaC/APPDUMP.jcl.        
    echo            Open that jcl and define your runtime libraries (see its documentation). 
    
    set initAppRuntime=y
    set /p initAppRuntime="Press enter when the JCL is ready. Or enter any char to skip  --> "	
    if  %initAppRuntime% NEQ y goto exitok
        
    del /q App-IaC\App-Runtime-Images\app* >NUL  2>&1
    set devhost=nlopez@zos.dev

:Get_DevHost    
    set /p devhost="Enter your UserID and the host of your Application's Dev env like  [%devhost%]  -->"
    echo Preparing your Runtime Image  ... 
    ssh %devhost% "ls >/dev/null 2>&1"            
    IF NOT ERRORLEVEL 1 goto Get_Images 
    Echo *** ERROR *** Cant connect to %devhost%  Re-try or CNTL/C to exit 
    goto Get_DevHost


:Get_Images 
    REM cleanup old files on dev host if they exist
    ssh %devhost% "mkdir -p ~/App-IaC >/dev/null 2>&1 ; rm ~/App-IaC/* >/dev/null 2>&1"    
    
    REM copy the jcl to an new MVS PS file to remove crnl, submit the jcl and delete the PS file 
    scp -r App-IaC/APPDUMP.jcl  %devhost%:APPDUMP    
    echo . 
    ssh %devhost% "cp -F crnl APPDUMP //APPDUMP; submit //$LOGNAME.APPDUMP; tsocmd delete APPDUMP >/dev/null 2>&1"    
    echo . 
    echo Your version of App-IaC/APPDUMP.jcl was submmited.'
    REM you may need to tweak this wait loop if you are dumping large files 
    set loop=10

:Waiting_for_Images 
    echo Waiting for the file copies .... Countdown interval %loop% 
    timeout /T 15    
    sftp -b App-IaC/sget_AppImage.script %devhost% > NUL
    
    IF EXIST App-IaC\App-Runtime-Images\applibs.xmit GOTO Image_Ready 
    IF "%loop%"=="0" GOTO ImageError 

    set /a loop-=1 
    GOTO Waiting_for_Images 

:ImageError 
    echo . & echo .& echo . 
    echo *** ERROR*** The application image copy was not found or empty (size=%size%)
    echo              The APPDUMP job may have failed or is still running 
    echo              Review the JOB in SDSF and rerun this script when ready
    pause 
    goto exit12
      

:Image_ready         
    rem check if the job actual created some output or an empty file
    set size=-1
    call :filesize %CD%\App-IaC\App-Runtime-Images\applibs.xmit
    if  %size% == 0 GOTO ImageError 

:Image_Not_Empty
    echo Restoring your image on %mywazi%  using  App-IaC/APPREST.jcl ....
    sftp -b App-IaC/sput_AppImage.script ibmuser@%mywazi%
    ping localhost -n 3 > NUL
    scp -r App-IaC/APPREST.jcl  ibmuser@%mywazi%:APPREST
    ping localhost -n 3 > NUL
    ssh ibmuser@%mywazi% "cp -F crnl APPREST //APPREST; submit //$LOGNAME.APPREST "
    
    echo . & echo The Restore job has been submitted. The jobname starts with IBMUSER. & echo . 
    

:Apply_CICS_App_Defs
    set initCICS=y
    set /p initCICS="Press enter to apply your CICS Application defintion. Or enter any char to skip  --> "	
    if  %initCICS% NEQ y goto exitok
    
    REM NOTE: the sget/sput scripts already copied the cntl if it was performed.
    IF EXIST App-IaC\App-Runtime-Images\CICSDEF.cntl GOTO :Apply_CICSDefs
    echo ==============================
    echo ==============================
    echo      >>>>>>>>>>>>>>    ERROR  <<<<<<<<<<<<<<<<<<<
    echo Could not find the local App-IaC\App-Runtime-Images\CICSDEF.cntl file. Check the APPDUMP job on Dev for errors. 
    echo Skiping CICS Def replication.  
    echo ReRun this script when ready. 
    echo ==============================
    echo ==============================
    pause 
    goto exitok

:Apply_CICSDefs
    REM //jcl defaults to IBMUSER.JCL. Its a preallocated PDS used for this demo (careful is a PDS prone to SB37)
    REM the cntl file was transmitted with xmit if it was created. 
    ssh ibmuser@%mywazi% cp -A CICSDEF.cntl "//jcl"
    scp -r App-IaC/CICSDEF.jcl  ibmuser@%mywazi%:CICSDEF.jcl
    ssh ibmuser@%mywazi% "submit  CICSDEF.jcl"
    echo Job "/u/ibmuser/CICSDEF.jcl" submitted and will apply your App's CICS defintions.          
    timeout /T 3  

:ResetCICS_STC 
    echo Edit App-IaC/CICSTS56.jcl to add your App's RPL libs to the new host's CICS region.
    pause

    echo Applying and restarting CICS with your changes  ... 
    ssh ibmuser@%mywazi% ". ./.profile; opercmd c cicsts56 "

    scp -r App-IaC/CICSTS56.jcl  ibmuser@%mywazi%:CICSTS56 
    ssh ibmuser@%mywazi% cp -F crnl ~/CICSTS56 "//""'SYS1.PROCLIB'"" 
    ping localhost -n 3 > NUL

    rem FYI - using zoau opercmd
    ssh ibmuser@%mywazi% ". ./.profile; opercmd s cicsts56; sleep 5;  opercmd F CICSTS56,CEDA INSTALL 'GROUP(DAT)'"
    echo CICS Region restarted. All JES Output is under jobname IBMUSER*.
    timeout /T 5 
    goto exitok




:exitok 
    echo ...............................& echo ............................... &  echo ...............................
    echo  *** POSTINIT completed.  ***
    echo Your Application runtime has been restored.
    echo Logon with IBMUSER/SYS1 UserID/password to review your runtime. 
    echo You can now point IDz to this instance and work on new features with DBB and Git.         
    echo .
    echo Note: 
    echo  - On the first login you must reset your password from the default SYS1.     
    echo  - If the APPREST job failed, edit /u/ibmuser/APPREST.jcl to manually fix and rerun.       
    echo  - Use a 3270 term that supports TLS/Certs like VISTA-3270 (PCOM or IDz host term may not work)
    echo  - zOS Ports (as of June-22 release): 
    echo        RSE=8137   RSEAPI=8195   zOSMF=10443   TN3270=992(TLS with MS-CAPI)     
    echo  - SSH access has bee pre-configured.    "SSH with ->   SSH IBMUSER@%mywazi% "
    echo  - If you updated your local hosts file, "SSH with ->   SSH IBMUSER@mywazi"
    echo  - If you have trouble accessing the new system try a re-IPL from the VSI actions menu.
    echo  - If your runtime is missing files, update APPDUMP and rerun this script (skip to the restore step).    
    echo  - If CICSTS56 is not up, review the JES output for the STC and restart with "/F S CICSTS56"    
    echo  - When your done with this instance run 'terraform destroy'  
    echo --EOF 




:: subs ---
:exit12
 EXIT /B 12

:Check_Args
    if "%~1" NEQ "" goto Check_dir
        echo  !!! ERROR: VSI IP or Host name not passed.  Exiting 
        timeout /T 5
        goto exit12
        

:Check_dir
    rem make sure were running at the project root folder
    if EXIST "main.tf" goto GoodToGo 
        echo  !!! ERROR: Run this from the main terraform project folder 'learn-terra-wazi'. Exiting.
        timeout /T 5
        goto exit12


REM Set filesize of first argument in %size% variable, and return
:filesize
    set size=%~z1
    exit /b 0

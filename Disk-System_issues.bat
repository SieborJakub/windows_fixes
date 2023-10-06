@echo off
color 06

if "%~1" neq "" goto :%~1

IF "%PROCESSOR_ARCHITECTURE%" EQU "amd64" (
>nul 2>&1 "%SYSTEMROOT%\SysWOW64\cacls.exe" "%SYSTEMROOT%\SysWOW64\config\system"
) ELSE (
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
)

if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set params= %*
    echo UAC.ShellExecute "cmd.exe", "/c ""%~s0"" %params:"=""%", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"



echo Before you start this script, save all your work and connnect your laptop to power. During this process your PC will restart 3 times. Each time you have to enter password, log in and wait. After second restart, it will ask you if you want to remove the registry key which is responsible for the startup apps. I reccommend you doing so, typing 'yes', because some of them may cause a drop in performance and system loading time. Afterwards you can always add the ones you want manually.
:loop
    set "TRUE="
    set /p "PROMPT=ENTER 'YES', IF YOU READED THE TEXT, AND CLICK ENTER"
    if "%PROMPT%" == "YES" set TRUE=1
    if "%PROMPT%" == "Yes" set TRUE=1
    if "%PROMPT%" == "yes" set TRUE=1
    if "%PROMPT%" == "YEs" set TRUE=1
    if "%PROMPT%" == "yES" set TRUE=1
    if "%PROMPT%" == "YeS" set TRUE=1
    if "%PROMPT%" == "yEs" set TRUE=1
    if "%PROMPT%" == "yeS" set TRUE=1
    if NOT defined TRUE goto :loop


powershell -Command "& {$Admins = gwmi win32_group -filter \"LocalAccount = $TRUE And SID = 'S-1-5-32-544'\" | select -expand name;Add-LocalGroupMember -Group $Admins -Member $(Get-WMIObject -class Win32_ComputerSystem | select username).username}" > C:\checkfile.txt
DISM /online /cleanup-image /restorehealth
sfc /scannow
echo y | chkdsk /x /f /r
call :markReboot stuff2
goto :eof 

:stuff2
powershell -Command "& {repair-volume C -scan;repair-volume C -offlinescanandfix;repair-volume C -spotfix;}"
call :markReboot stuff3
goto :eof

:stuff3
cleanmgr /sagerun
reg delete HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run
reg delete HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce
cd "C:\ProgramData\Microsoft\Windows Defender\Platform\4.18*"
MpCmdRun -SignatureUpdate
MpCmdRun -Scan -ScanType 1
MpCmdRun -Scan -ScanType -BootSectorScan
call :markReboot stuff4
goto :eof

:stuff4
for /f %%i in ("C:\checkfile.txt") do set size=%%~zi
if %size% == 0 powershell -Command "& {$Admins = gwmi win32_group -filter \"LocalAccount = $TRUE And SID = 'S-1-5-32-544'\" | select -expand name;Remove-LocalGroupMember -Group $Admins -Member $(Get-WMIObject -class Win32_ComputerSystem | select username).username}"
echo Everything should work just fine now, you can close this window.
timeout 300
goto :eof

:markReboot
reg add HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\RunOnce /t REG_SZ /d "\"%~dpf0\" %~1" /v  RestartMyScript /f 
shutdown /r /t 0
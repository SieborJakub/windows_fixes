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

echo Before you start this script, save all your work, connnect your laptop to power. During this process your PC will restart 3 times. Each time you have to enter password, log in and wait. After second restart you will have to enter your network name and password.
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
netsh wlan delete profile name=* i=*
reg add HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\RadioManagement\SystemRadioState /ve /t REG_DWORD /d 1 /f
call :markReboot stuff2
goto :eof 

:stuff2
reg add HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\RadioManagement\SystemRadioState /ve /t REG_DWORD /d 0 /f
timeout 3
call :markReboot stuff3
goto :eof

:stuff3
set /p "SSID=Enter SSID (Name of your network)-"
set /p "HEXSTR=Enter password to your network-"
set "XML_OUTPUT_PATH=%TEMP%\%SSID%-wireless-profile-generated.xml"

echo ^<?xml version="1.0"?^>^<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1"^>^<name^>%SSID%^</name^>^<SSIDConfig^>^<SSID^>^<name^>%SSID%^</name^>^</SSID^>^</SSIDConfig^>^<connectionType^>ESS^</connectionType^>^<connectionMode^>auto^</connectionMode^>^<MSM^>^<security^>^<authEncryption^>^<authentication^>WPA2PSK^</authentication^>^<encryption^>AES^</encryption^>^<useOneX^>false^</useOneX^>^</authEncryption^>^<sharedKey^>^<keyType^>passPhrase^</keyType^>^<protected^>false^</protected^>^<keyMaterial^>%HEXSTR%^</keyMaterial^>^</sharedKey^>^</security^>^</MSM^>^<MacRandomization xmlns="http://www.microsoft.com/networking/WLAN/profile/v3"^>^<enableRandomization^>false^</enableRandomization^>^</MacRandomization^>^</WLANProfile^> >%XML_OUTPUT_PATH%

netsh wlan add profile filename="%XML_OUTPUT_PATH%"
netsh wlan connect name="%SSID%"

del "%XML_OUTPUT_PATH%"
timeout 5
ipconfig /release
ipconfig /flushdns
ipconfig /renew
netsh int ip reset
netsh winsock reset
timeout 3
powershell -Command "& {Set-NetConnectionProfile -Name $env:SSID -NetworkCategory Private}"
timeout 3
powercfg /SETDCVALUEINDEX SCHEME_CURRENT 19cbb8fa-5279-450e-9fac-8a3d5fedd0c1 12bbebe6-58d6-4636-95bb-3217ef867c1a 0
powercfg /SETACVALUEINDEX SCHEME_CURRENT 19cbb8fa-5279-450e-9fac-8a3d5fedd0c1 12bbebe6-58d6-4636-95bb-3217ef867c1a 0
call :markReboot stuff4
goto :eof

:stuff4
for /f %%i in ("C:\checkfile.txt") do set size=%%~zi
if %size% == 0 powershell -Command "& {$Admins = gwmi win32_group -filter \"LocalAccount = $TRUE And SID = 'S-1-5-32-544'\" | select -expand name;Remove-LocalGroupMember -Group $Admins -Member $(Get-WMIObject -class Win32_ComputerSystem | select username).username}"
echo Everything should work just fine now, you can close this window
timeout 300
goto :eof

:markReboot
reg add HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\RunOnce /t REG_SZ /d "\"%~dpf0\" %~1" /v  RestartMyScript /f 
shutdown /r /t 0

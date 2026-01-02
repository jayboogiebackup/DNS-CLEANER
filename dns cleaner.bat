@echo off
SETLOCAL ENABLEDELAYEDEXPANSION
SETLOCAL ENABLEEXTENSIONS

title DNS Cleaner v0.6 - Windows 11 Optimized

mode con: cols=125 lines=35

:menu
cls
echo.
echo  ______ _   _  _____             ___  ___  ___  _____                         
echo  ^|  _  \ \ ^| ^|/  ___^|     ___     ^|  \/  ^| / _ \/  __ \                        
echo  ^| ^| ^| ^|  \^| ^|\ `--.     ( _ )    ^| .  . ^|/ /_\ \ /  \/                        
echo  ^| ^| ^| ^| . ` ^| `--. \    / _ \/\   ^| ^|\/^| ^|^|  _  ^| ^|                            
echo  ^| ^|/ /^| ^|\  ^|/\__/ /   ^| (_^>  ^<   ^| ^|  ^| ^|^| ^| ^| ^| \__/\                        
echo  ^|___/ \_^| \_/\____/     \___/\/   \_^|  ^|_/\_^| ^|_/\____/                        
echo.                                                                             
echo                                     _   _               _         _____   ____ 
echo                                    ^| ^| ^| ^|             ^| ^|       ^|  _  ^| / ___^|
echo  _ __ ___ _ __   _____      ____ _^| ^| ^| ^|_ ___   ___ ^| ^| __   _^| ^|/' ^|/ /___ 
echo ^| '__/ _ \ '_ \ / _ \ \ /\ / / _` ^| ^| ^| __/ _ \ / _ \^| ^| \ \ / /  /^| ^|^| ___ \
echo ^| ^| ^|  __/ ^| ^| ^|  __/\ V  V / (_^| ^| ^| ^| ^|^| (_) ^| (_) ^| ^|  \ V /\ ^|_/ /^| \_/ ^|
echo ^|_^|  \___^|_^| ^|_^|\___^| \_/\_/ \__,_^|_^|  \__\___/ \___/^|_^|   \_/  \___(_^|_____/
echo.
echo =============================================================================
echo                                  MAIN MENU
echo =============================================================================
echo [1] Renew and Flush DNS
echo [2] Change MAC Address (Randomized)
echo [3] Perform Both Operations
echo [4] Exit
echo =============================================================================
echo.

choice /c 1234 /n /m "Select an option [1-4]: "

if errorlevel 4 exit
if errorlevel 3 goto action_both
if errorlevel 2 goto action_mac
if errorlevel 1 goto action_dns

:action_dns
echo.
echo [!] Releasing IP Address...
ipconfig /release >nul 2>&1
echo [!] Flushing DNS Cache...
ipconfig /flushdns >nul 2>&1
echo [!] Renewing IP Address...
ipconfig /renew >nul 2>&1
echo [+] DNS operations complete.
pause
goto menu

:action_mac
echo.
echo [!] Initializing MAC Randomization...
:: Find physical adapters
FOR /F "tokens=1" %%a IN ('wmic nic where "physicaladapter=true and netconnectionstatus=2" get deviceid ^| findstr [0-9]') DO (
    CALL :GenerateMac
    echo [!] Target Adapter ID: %%a - New MAC: !MAC!
    
    :: Update Registry for common interface paths
    FOR %%b IN (0000 0001 0002 0003 0004 0005) DO (
        REG QUERY "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002bE10318}\%%b" /v NetCfgInstanceId >nul 2>&1
        if !errorlevel! == 0 (
            :: Optional: Add more specific matching logic here if needed
            REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002bE10318}\%%b" /v NetworkAddress /t REG_SZ /d !MAC! /f >nul 2>&1
            REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002bE10318}\%%b" /v PnPCapabilities /t REG_DWORD /d 24 /f >nul 2>&1
        )
    )
)

echo [!] Restarting Network Adapters to apply changes...
powershell -Command "Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | Restart-NetAdapter"
echo [+] MAC Address successfully changed.
timeout /t 5
goto menu

:action_both
call :action_dns
call :action_mac
goto menu

:GenerateMac
SET "GEN=ABCDEF0123456789"
SET "GEN2=26AE"
SET "MAC="
SET "COUNT=0"

:MACLOOP
SET /a COUNT+=1
SET /A RND=%random%%%16
SET /A RND2=%random%%%4

:: Grab characters using PowerShell for better randomization if desired, but keeping it internal for speed
SET "RNDGEN=!GEN:~%RND%,1!"
SET "RNDGEN2=!GEN2:~%RND2%,1!"

IF "!COUNT!" EQU "2" (
    SET "MAC=!MAC!!RNDGEN2!"
) ELSE (
    SET "MAC=!MAC!!RNDGEN!"
)

IF !COUNT! LEQ 11 GOTO MACLOOP
GOTO :EOF
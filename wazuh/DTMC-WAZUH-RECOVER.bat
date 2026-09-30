@echo off
setlocal EnableExtensions
title DTMC Wazuh Agent RECOVER
set "MGR=odpc12.omnix365.net"
set "MSI=%TEMP%\wazuh-agent-4.14.7-1.msi"
set "URL=https://packages.wazuh.com/4.x/windows/wazuh-agent-4.14.7-1.msi"
set "LOG=%USERPROFILE%\Desktop\DTMC-WAZUH-RECOVER.log"

echo ================================================== > "%LOG%"
echo DTMC WAZUH RECOVER v1.0 >> "%LOG%"
echo Computer: %COMPUTERNAME% >> "%LOG%"
echo Date/Time: %DATE% %TIME% >> "%LOG%"
echo Manager: %MGR% >> "%LOG%"
echo ================================================== >> "%LOG%"

net session >nul 2>&1
if errorlevel 1 (
  echo [FAIL] Not running as Administrator. >> "%LOG%"
  echo [FAIL] Right-click and choose Run as administrator.
  pause
  exit /b 1
)

echo [1/5] Stopping existing Wazuh service...
sc stop WazuhSvc >> "%LOG%" 2>&1
timeout /t 3 /nobreak >nul

echo [2/5] Downloading official Wazuh Agent 4.14.7...
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Invoke-WebRequest -UseBasicParsing -Uri '%URL%' -OutFile '%MSI%'; exit 0 } catch { Write-Output $_.Exception.Message; exit 1 }" >> "%LOG%" 2>&1
if errorlevel 1 goto :FAIL
if not exist "%MSI%" goto :FAIL

echo [3/5] Installing / repairing Wazuh Agent...
msiexec.exe /i "%MSI%" /qn /norestart WAZUH_MANAGER="%MGR%" /L*v "%TEMP%\DTMC-Wazuh-MSI.log"
set "MSIRC=%ERRORLEVEL%"
echo MSI_EXIT=%MSIRC% >> "%LOG%"
if not "%MSIRC%"=="0" if not "%MSIRC%"=="3010" goto :FAIL

echo [4/5] Starting Wazuh service...
sc start WazuhSvc >> "%LOG%" 2>&1
timeout /t 5 /nobreak >nul

echo [5/5] Verifying...
sc query WazuhSvc >> "%LOG%" 2>&1
sc query WazuhSvc | find /I "RUNNING" >nul 2>&1
if errorlevel 1 goto :FAIL

echo [OK] WazuhSvc is RUNNING. >> "%LOG%"
echo.
echo ==================================================
echo RECOVER COMPLETE - WazuhSvc is RUNNING
echo Wait a short while, then refresh Wazuh.
echo Log: %LOG%
echo ==================================================
notepad "%LOG%"
pause
exit /b 0

:FAIL
echo [FAIL] Recovery did not complete. >> "%LOG%"
echo MSI log: %TEMP%\DTMC-Wazuh-MSI.log >> "%LOG%"
echo.
echo ==================================================
echo RECOVER FAILED - DO NOT RUN REPEATEDLY
echo Send these logs back for diagnosis:
echo %LOG%
echo %TEMP%\DTMC-Wazuh-MSI.log
echo ==================================================
notepad "%LOG%"
pause
exit /b 1

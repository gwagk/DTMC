@echo off
setlocal EnableExtensions EnableDelayedExpansion
title DTMC Wazuh Agent CHECK
set "LOG=%USERPROFILE%\Desktop\DTMC-WAZUH-CHECK.log"
set "MGR=odpc12.omnix365.net"
echo ================================================== > "%LOG%"
echo DTMC WAZUH CHECK  v1.0 >> "%LOG%"
echo Computer: %COMPUTERNAME% >> "%LOG%"
echo Date/Time: %DATE% %TIME% >> "%LOG%"
echo ================================================== >> "%LOG%"

net session >nul 2>&1
if errorlevel 1 (
  echo [FAIL] Not running as Administrator. >> "%LOG%"
  echo.
  echo [FAIL] Please right-click this BAT and choose Run as administrator.
  echo Log: "%LOG%"
  pause
  exit /b 1
)
echo [OK] Administrator >> "%LOG%"

echo.>>"%LOG%"
echo --- Windows --- >> "%LOG%"
ver >> "%LOG%" 2>&1
whoami >> "%LOG%" 2>&1

echo.>>"%LOG%"
echo --- Wazuh service --- >> "%LOG%"
sc query WazuhSvc >> "%LOG%" 2>&1
sc qc WazuhSvc >> "%LOG%" 2>&1

echo.>>"%LOG%"
echo --- Wazuh folders --- >> "%LOG%"
if exist "%ProgramFiles(x86)%\ossec-agent" (
  echo [OK] %ProgramFiles(x86)%\ossec-agent >> "%LOG%"
  set "OSSEC=%ProgramFiles(x86)%\ossec-agent"
) else if exist "%ProgramFiles%\ossec-agent" (
  echo [OK] %ProgramFiles%\ossec-agent >> "%LOG%"
  set "OSSEC=%ProgramFiles%\ossec-agent"
) else (
  echo [FAIL] ossec-agent folder not found >> "%LOG%"
)

if defined OSSEC (
  echo.>>"%LOG%"
  echo --- Manager config references --- >> "%LOG%"
  findstr /I /C:"<address>" /C:"%MGR%" "!OSSEC!\ossec.conf" >> "%LOG%" 2>&1
  echo.>>"%LOG%"
  echo --- Last agent log lines --- >> "%LOG%"
  powershell -NoProfile -Command "if(Test-Path '!OSSEC!\ossec.log'){Get-Content '!OSSEC!\ossec.log' -Tail 80}" >> "%LOG%" 2>&1
)

echo.>>"%LOG%"
echo --- DNS / Network --- >> "%LOG%"
nslookup %MGR% >> "%LOG%" 2>&1
powershell -NoProfile -Command "$r=Test-NetConnection '%MGR%' -Port 1514 -WarningAction SilentlyContinue; 'TCP1514=' + $r.TcpTestSucceeded + ' Remote=' + $r.RemoteAddress" >> "%LOG%" 2>&1
powershell -NoProfile -Command "$r=Test-NetConnection '%MGR%' -Port 1515 -WarningAction SilentlyContinue; 'TCP1515=' + $r.TcpTestSucceeded + ' Remote=' + $r.RemoteAddress" >> "%LOG%" 2>&1

echo.>>"%LOG%"
echo --- Summary --- >> "%LOG%"
sc query WazuhSvc | find /I "RUNNING" >nul 2>&1
if errorlevel 1 (echo SERVICE=NOT_RUNNING>>"%LOG%") else (echo SERVICE=RUNNING>>"%LOG%")
findstr /I /C:"%MGR%" "%ProgramFiles(x86)%\ossec-agent\ossec.conf" >nul 2>&1
if errorlevel 1 (echo MANAGER_CONFIG=CHECK_REQUIRED>>"%LOG%") else (echo MANAGER_CONFIG=OK>>"%LOG%")

echo.
echo ==================================================
echo CHECK COMPLETE
echo Log saved to:
echo %LOG%
echo ==================================================
notepad "%LOG%"
pause
endlocal

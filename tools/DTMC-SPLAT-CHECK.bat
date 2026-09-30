@echo off
setlocal EnableExtensions
title DTMC SPLAT - CHECK
fltmc >nul 2>&1 || (
  echo [ERROR] Run this file as Administrator.
  pause
  exit /b 1
)
set "LOG=%USERPROFILE%\Desktop\DTMC-SPLAT-CHECK-%COMPUTERNAME%.txt"
call :log "============================================================"
call :log "DTMC SPLAT CHECK v1.0"
call :log "Computer: %COMPUTERNAME%"
call :log "Date: %DATE% %TIME%"
call :log "Mode: DIAGNOSTIC ONLY - NO CHANGES"
call :log "============================================================"

call :log ""
call :log "[1] WAZUH SERVICE"
sc query Wazuh >>"%LOG%" 2>&1
sc query Wazuh >nul 2>&1
if errorlevel 1 (call :log "RESULT: WAZUH_SERVICE_NOT_FOUND") else (
  sc query Wazuh | find /I "RUNNING" >nul
  if errorlevel 1 (call :log "RESULT: WAZUH_SERVICE_EXISTS_NOT_RUNNING") else call :log "RESULT: WAZUH_SERVICE_RUNNING"
)

call :log ""
call :log "[2] WAZUH FILES"
if exist "C:\Program Files (x86)\ossec-agent" (call :log "FOUND: C:\Program Files (x86)\ossec-agent") else call :log "NOT FOUND: C:\Program Files (x86)\ossec-agent"
if exist "C:\Program Files\ossec-agent" (call :log "FOUND: C:\Program Files\ossec-agent") else call :log "NOT FOUND: C:\Program Files\ossec-agent"

call :log ""
call :log "[3] INSTALLED PRODUCT REGISTRY"
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s /f "Wazuh Agent" >>"%LOG%" 2>&1
reg query "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" /s /f "Wazuh Agent" >>"%LOG%" 2>&1

call :log ""
call :log "[4] SPLAT MSI CACHE"
dir /b "%TEMP%\wazuh-agent-4.14.7-1.msi" >>"%LOG%" 2>&1
if exist "%TEMP%\wazuh-agent-4.14.7-1.msi" (call :log "RESULT: SPLAT_MSI_PRESENT") else call :log "RESULT: SPLAT_MSI_NOT_PRESENT"

call :log ""
call :log "[5] NETWORK TO OMNIX MANAGER"
powershell -NoProfile -Command "Test-NetConnection 'odpc12.omnix365.net' -Port 1514 | Select-Object ComputerName,RemoteAddress,RemotePort,TcpTestSucceeded | Format-List" >>"%LOG%" 2>&1

call :log ""
call :log "[6] RECENT WINDOWS SECURITY / DEFENDER EVIDENCE"
powershell -NoProfile -Command "Get-MpThreatDetection -ErrorAction SilentlyContinue | Sort-Object InitialDetectionTime -Descending | Select-Object -First 10 InitialDetectionTime,ThreatID,ActionSuccess,Resources | Format-List" >>"%LOG%" 2>&1
powershell -NoProfile -Command "Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Windows Defender/Operational'; StartTime=(Get-Date).AddDays(-2)} -ErrorAction SilentlyContinue | Where-Object {$_.Id -in 1116,1117,1121,1122} | Select-Object -First 15 TimeCreated,Id,Message | Format-List" >>"%LOG%" 2>&1

call :log ""
call :log "[7] SUMMARY"
sc query Wazuh >nul 2>&1
if errorlevel 1 (
  if exist "%TEMP%\wazuh-agent-4.14.7-1.msi" (
    call :log "STATE: DOWNLOAD_COMPLETED_INSTALL_NOT_CONFIRMED"
    call :log "NEXT: Run DTMC-SPLAT-RECOVER.bat as Administrator."
  ) else (
    call :log "STATE: AGENT_NOT_INSTALLED_OR_DOWNLOAD_INTERRUPTED"
    call :log "NEXT: Run DTMC-SPLAT-RECOVER.bat as Administrator."
  )
) else (
  sc query Wazuh | find /I "RUNNING" >nul
  if errorlevel 1 (
    call :log "STATE: AGENT_INSTALLED_SERVICE_STOPPED"
    call :log "NEXT: Run DTMC-SPLAT-RECOVER.bat as Administrator."
  ) else (
    call :log "STATE: LOCAL_AGENT_RUNNING"
    call :log "NEXT: Admin must verify ACTIVE + Computer Name match in Omnix."
  )
)
call :log "NOTE: Review section [6] for Windows Security evidence."
call :log "============================================================"
echo.
echo CHECK COMPLETE
echo Log: "%LOG%"
echo.
type "%LOG%"
pause
exit /b 0

:log
echo %~1
echo %~1>>"%LOG%"
exit /b

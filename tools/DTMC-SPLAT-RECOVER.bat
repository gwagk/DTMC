@echo off
setlocal EnableExtensions
title DTMC SPLAT - RECOVER
fltmc >nul 2>&1 || (
  echo [ERROR] Run this file as Administrator.
  pause
  exit /b 1
)
set "MANAGER=odpc12.omnix365.net"
set "GROUP=Quarantine"
set "VER=4.14.7-1"
set "MSI=%TEMP%\wazuh-agent-%VER%.msi"
set "URL=https://packages.wazuh.com/4.x/windows/wazuh-agent-%VER%.msi"
set "LOG=%USERPROFILE%\Desktop\DTMC-SPLAT-RECOVER-%COMPUTERNAME%.txt"

call :log "============================================================"
call :log "DTMC SPLAT RECOVER v1.0"
call :log "Computer: %COMPUTERNAME%"
call :log "Date: %DATE% %TIME%"
call :log "Manager: %MANAGER%"
call :log "Group: %GROUP%"
call :log "============================================================"

sc query Wazuh >nul 2>&1
if not errorlevel 1 goto SERVICE_EXISTS

call :log "[STATE] Wazuh service not found."
call :log "[STEP 1] Checking/downloading official Wazuh MSI..."
if exist "%MSI%" (
  call :log "MSI already present in TEMP. Reusing it."
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Invoke-WebRequest -Uri '%URL%' -OutFile '%MSI%' -ErrorAction Stop; exit 0 } catch { Write-Host $_.Exception.Message; exit 1 }" >>"%LOG%" 2>&1
  if errorlevel 1 goto DOWNLOAD_FAIL
)
if not exist "%MSI%" goto DOWNLOAD_FAIL

call :log "[STEP 2] Installing Wazuh Agent..."
msiexec.exe /i "%MSI%" /q WAZUH_MANAGER="%MANAGER%" WAZUH_AGENT_GROUP="%GROUP%" WAZUH_AGENT_NAME="%COMPUTERNAME%" /L*v "%USERPROFILE%\Desktop\DTMC-WAZUH-MSI-%COMPUTERNAME%.log"
set "MSICODE=%ERRORLEVEL%"
call :log "MSI exit code: %MSICODE%"
if "%MSICODE%"=="0" goto START_SERVICE
if "%MSICODE%"=="3010" goto START_SERVICE
call :log "[FAILED] MSI installation failed. Do NOT retry repeatedly."
call :log "Evidence: Desktop\DTMC-WAZUH-MSI-%COMPUTERNAME%.log"
call :log "Check Windows Security Protection History before any further action."
goto END_FAIL

:SERVICE_EXISTS
call :log "[STATE] Wazuh service already exists. No reinstall."
sc query Wazuh | find /I "RUNNING" >nul
if not errorlevel 1 goto READY

:START_SERVICE
call :log "[STEP 3] Starting Wazuh service..."
net start Wazuh >>"%LOG%" 2>&1
timeout /t 3 /nobreak >nul
sc query Wazuh | find /I "RUNNING" >nul
if errorlevel 1 (
  call :log "[FAILED] Wazuh service exists but is not RUNNING."
  call :log "Do NOT uninstall automatically. Send CHECK + RECOVER logs to admin."
  goto END_FAIL
)

:READY
call :log "[PASS] LOCAL_AGENT_RUNNING"
call :log "Local recovery completed."
call :log "IMPORTANT: This is NOT final SPLATTED status."
call :log "Admin must verify Omnix ACTIVE and Agent Name = %COMPUTERNAME%."
goto END_OK

:DOWNLOAD_FAIL
call :log "[FAILED] Wazuh MSI download failed or file was blocked."
call :log "Check network and Windows Security Protection History."
call :log "No Defender exclusion or automatic Allow action was made."
goto END_FAIL

:END_OK
call :log "============================================================"
echo.
echo RECOVERY COMPLETE - LOCAL AGENT RUNNING
echo Log: "%LOG%"
pause
exit /b 0

:END_FAIL
call :log "============================================================"
echo.
echo RECOVERY STOPPED - SEND LOG TO ADMIN
echo Log: "%LOG%"
pause
exit /b 1

:log
echo %~1
echo %~1>>"%LOG%"
exit /b

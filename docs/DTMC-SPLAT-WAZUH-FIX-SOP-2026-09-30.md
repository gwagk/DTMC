# DTMC-SPLAT — Wazuh Fix / Field SOP

**Date:** 30 September 2026  
**Project:** DTMC-SPLAT  
**Scope:** Windows endpoints with an existing/broken Wazuh Agent

## What we learned today

During field testing, DTMC-SPLAT could report/install Wazuh while the endpoint still failed to appear correctly in Wazuh Manager. A Windows service in `RUNNING` state alone is not enough to prove end-to-end success.

After uninstalling Wazuh Agent, we found residual files under:

```
C:\Program Files (x86)\ossec-agent
```

Examples found during testing:

```
client.keys.save
ossec.conf.save
local_internal_options.conf.save
upgrade\
```

A clean uninstall + residual cleanup + reboot, followed by exactly one DTMC-SPLAT installation run, succeeded on the tested machines.

> Important: residual files were observed in the failed workflow, but this test does not prove that any single residual file was the sole root cause.

---

## FIELD SOP — preferred fix

### 1. Open PowerShell as Administrator

Paste this block **once**:

```powershell
$w = Get-ItemProperty `
"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*", `
"HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" `
-ErrorAction SilentlyContinue |
Where-Object { $_.DisplayName -like "Wazuh Agent*" } |
Select-Object -First 1

Stop-Service WazuhSvc -Force -ErrorAction SilentlyContinue

if ($w) {
    Start-Process msiexec.exe `
      -ArgumentList "/x $($w.PSChildName) /qn /norestart" `
      -Wait
}

Remove-Item "C:\Program Files (x86)\ossec-agent" `
  -Recurse -Force -ErrorAction SilentlyContinue
```

Wait until the PowerShell prompt returns. **Do not run the command twice.**

### 2. Restart Windows

Restart the endpoint after the uninstall/cleanup completes.

### 3. Run DTMC-SPLAT as Administrator

After Windows starts again:

1. Run DTMC-SPLAT as Administrator.
2. Start the Wazuh installation **once**.
3. Wait for the current transaction to finish.
4. Do not run another PowerShell installer and do not click Install repeatedly.

### 4. Verify

Check the endpoint in Wazuh Manager.

If connected/visible as expected: **DONE**.

If it fails: **STOP**. Do not repeatedly reinstall. Move to troubleshooting and collect logs/state.

---

## Normal field workflow

```
UNINSTALL + CLEAN (one command)
          ↓
        REBOOT
          ↓
 DTMC-SPLAT (one run)
          ↓
        VERIFY
          ↓
         DONE
```

**จำง่าย:** ถอน+ล้างฉึกเดียว → Restart → SPLAT 1 รอบ → ตรวจ Wazuh → จบ

---

## Troubleshooting tools

These are **not required for the normal field workflow**. Use them only when the clean workflow above fails.

- `wazuh/DTMC-WAZUH-CHECK.bat` — collect/check endpoint state and connectivity.
- `wazuh/DTMC-WAZUH-RECOVER.bat` — recovery tool; review its parameters/version before broad deployment.

---

## DTMC-SPLAT design lessons

Future SPLAT versions should not treat `WazuhSvc = RUNNING` as the only success condition.

Recommended lifecycle:

```
PRE-CHECK → QUEUED → INSTALLING → ENROLLING → VERIFYING → SUCCESS / FAILED
```

Rules:

- One target machine = one active transaction at a time.
- Lock duplicate Install/Repair actions while a job is running.
- Do not blindly retry failed installations.
- Keep logs and identify the failed state before retry.
- Prefer idempotent behavior: if an endpoint is already healthy, return `ALREADY OK` instead of reinstalling.
- Final success should eventually verify the endpoint through to Manager connectivity, not only local MSI/service state.

**Core rule:** ห้าม SPLAT มือไวกว่า state ของระบบ

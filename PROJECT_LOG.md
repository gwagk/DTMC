# DTMC Development Log

## 2026-09-24 — V1 checkpoint

### Achieved
- Extracted 231 IT assets and reused existing `staff` / `stations` masters.
- Completed owner/current-location operational mapping while preserving raw source values.
- Implemented server-side ENTRY/ADMIN unit access.
- Implemented and tested email OTP login.
- Dashboard displays assets at the user's current station.
- Added `responsible_person`, `asset_status`, `last_verified_at`, and `responsible_email`.
- Responsible-person flow is now selection-only from active `staff` at the asset's current station.
- Server validates the selected responsible email against the asset's current station.
- Positive update test passed for ST009.
- Negative cross-station test passed with `INVALID_RESPONSIBLE_PERSON`.
- Edit modal and responsible-person dropdown reached deployed UI testing.

### Evidence
Mapping: total 231; exact 224; assumed 5; needs review 2; cross-unit 2.

ENTRY ST011 permission test: ST011 allowed; ST009 denied; ST015 denied.

Responsible-person server test:
- ST009 responsible user accepted and saved.
- ST011 user rejected for an ST009 asset.
- UI dropdown loads only eligible staff for the asset's current station.

### Current issue / next resume point
The responsible-person dropdown currently uses `staff.display_name`. For the admin account this displays the role-style label “ผู้ดูแลระบบ” instead of the person's actual full name.

**Next step:** identify the authoritative full-name field already present in the staff/master data and use that for the responsible-person label. Do not guess and do not add a new free-text field.

### Frozen UX / data-entry principles
- User-centered and Need-to-Know: users see only what is relevant to their own work.
- Least Privilege: authorization is enforced server-side.
- Prefer `Auto-fill → Select → Confirm → Free text only as a last resort`.
- If the system already knows a value, do not ask the user to type it again.
- If a Master exists, users select from the Master; no “Other / please specify”.
- Keep the front end small: easy entry, few clicks, little typing, finish quickly.
- Dashboard should tell the story itself and highlight exceptions rather than forcing users to search.
- Complexity belongs behind the system, not on the user's screen.
- Use the simplest reliable system that solves the actual problem; avoid feature bloat.

### DTMC core model
- `ASSETS`: what the asset is / baseline truth.
- `DEVICE_PROFILE`: additional technical facts learned about the device.
- `COMPLIANCE`: current/monthly policy evidence.
- `AUDIT_LOG`: who changed what and when.
- Owner Unit ≠ Current Location ≠ Responsible Person.
- DTMC records operational reality without forcing reality to match the original register.

### Planned extension — not current V1 scope
DTMC may later integrate with the existing Omnix365/Wazuh deployment used by ODPC 12:
- deterministic agent naming from DTMC/master data;
- generate install/start commands or a user-run batch file;
- optionally support centrally coordinated deployment;
- retain only necessary agent status/evidence in DTMC rather than duplicating Wazuh security telemetry.

Keep this as a later extension. Finish the DTMC core first.

### Technical debt before production
- Replace client-supplied login email with a server-side session token after OTP verification.
- Introduce a stable unique internal asset key; duplicate asset-register IDs currently exist.
- Implement `AUDIT_LOG`.
- Implement monthly compliance workflow and exception-driven reports.
- Clean stale `CONFIG.SHEETS.USERS/UNITS` references; runtime uses `staff/stations`.
- Split accumulated tests/helpers from `AssetService.gs` after the functional path stabilizes.
- Mirror the actual Apps Script source to Git once the current code batch is stable.

### Next build sequence
1. Finish STEP 13: actual full-name label for responsible person; save/reopen verification.
2. Session token.
3. Stable asset key.
4. Audit log.
5. Monthly compliance/checklist.
6. Exception-driven Dashboard/Reports.
7. End-to-end pilot test and Git source checkpoint.


## 2026-09-25 — V1 core feature complete / pilot handoff

### Completed today
- STEP 13 responsible-person label/data issue resolved using real `staff.display_name`; selection remains active-staff-only.
- Frozen V1 navigation: Search / Asset list / Add asset / Check asset / Reports / Logout.
- Search implemented across asset ID, category, brand, model, location, owner, responsible person, and status.
- Add-asset UI added; category list is read dynamically from `DTMC_CATEGORY`; responsible-person candidates come from active staff at the user's station.
- Added Check Asset UI for work-use PC/Notebook, regardless of government/private ownership.
- Corrected compliance model: **2FA removed from asset inspection** because it is account/user compliance, not device compliance.
- Added DTMC columns: `computer_name`, `platform`, `windows_update`, `system_cleansing`, `omnix365_agent`.
- Added server-side asset-check save path with unit access enforcement and `last_verified_at`.
- Platform choices: Windows / Linux / macOS.
- Added basic Report view: total / ACTIVE / INACTIVE / category counts.
- Added Trusted Browser service design and implementation: OTP first verification, per-email browser token, server stores SHA-256 token hash, 180-day expiry, active user/station revalidation, revoke support. Same browser may hold separate trusted tokens for multiple users; no shared-user auto-login.
- Generated DTMC QR for pilot distribution.

### Omnix365 / PG-BOT decisions
- Computer Name must not rely on users discovering it manually.
- Next PG-BOT version will read the Windows Computer Name and show it in `PG-BOT-LAST.txt` with Thai instructions for copying it into DTMC.
- Planned Omnix recovery architecture: DTMC = inventory/mapping; Private Git = non-secret scripts/config; Secure Vault = token/key; Omnix365 = endpoint platform.
- Planned disposable per-device enrollment batch: bind/check Computer Name, enroll, verify, remove temporary secret material, then self-delete.
- Do not commit reusable enrollment secrets/tokens directly to Git history.

### V1 status
**Core feature complete → Pilot user testing.**

Do not expand the UI before pilot feedback. Next reporting phase: overall dashboard → station groups → individual station → asset drill-down.

### Technical debt / follow-up
- Stable internal asset key remains required. Some flows still use asset-register number as `assetId`, which is insufficient for private assets without a register number and for duplicates.
- Trusted Browser reduces repeated OTP but does **not** replace the earlier production-security requirement to stop trusting browser-supplied identity on protected endpoints. Complete server-side authenticated session identity before production.
- Verify Trusted Browser end-to-end with: first OTP → logout → same email/browser bypasses OTP; second email on same browser requires its own first OTP.
- Mirror the stabilized Apps Script source into Git.
- Add `AUDIT_LOG`.
- Build advanced reports only after pilot feedback.
- Update PG-BOT to expose Computer Name in `PG-BOT-LAST.txt`.

## 2026-09-26 — DTMC SPLAT concept freeze

### SPLAT — lightweight branch from the DTMC root
**DTMC SPLAT** is a lifecycle workflow branch that reuses the existing DTMC data root. It is **not** a second asset register and must not become a duplicate master.

Core principle:
- **DTMC = source of truth / root.**
- **SPLAT = workflow branch.**
- Read asset data from the DTMC Sheet only.
- Do not copy DTMC asset data into a new SPLAT master.
- Asset add/edit/update remains in DTMC only.
- SPLAT stores only data created by the SPLAT process.

### Scope
SPLAT reads only DTMC records that are:
- PC or Notebook;
- alive / usable according to DTMC status;
- either government assets or privately owned computers voluntarily registered in DTMC for work use.

Assets that are broken, retired, disposed, or otherwise not usable are outside the active SPLAT queue.

### Authentication / authorization
Reuse the DTMC authentication, staff, station, and permission model. Do not create a second user directory or second login.

After DTMC authentication, an authorized user may enter the DTMC core or the SPLAT branch without logging in again.

Need-to-Know remains server-side:
- station admins see only their own authorized station;
- assigned operators see only the stations assigned to them;
- SPLAT must enforce authorization on the server, not merely hide rows in the UI.

### Minimal SPLAT data
Link every SPLAT record to the stable DTMC internal assetId.

SPLAT should keep only workflow-specific data such as:
- assetId
- approved computerName
- current machine owner/user when needed by the workflow
- per-device Omnix enrollment key/reference as required by the deployment process
- script/tool/download reference
- completedAt

Do not duplicate station, asset-register number, category, brand, model, or other DTMC master fields in SPLAT.

No manual “not done” status is required:
- completedAt empty = still pending;
- completedAt present = SPLATTED / completed.

### Lifecycle
Initial rollout will carry the largest workload because existing eligible computers form the starting backlog.

After the backlog is completed, SPLAT should normally remain quiet and react only to lifecycle events such as:
- a new eligible PC/Notebook is added to DTMC;
- a previously missed computer is registered in DTMC;
- an eligible computer requires a new deployment cycle;
- an old computer leaves active service.

The intended workflow is approximately:

DTMC asset → Computer Name → required tool/script → PG-BOT verify → Omnix enrollment/verification → print sticker → apply sticker → completedAt

The physical sticker is the visible endpoint of the workflow.

### Architecture guardrails
SPLAT must remain small. It is **not**:
- another asset-management system;
- a helpdesk;
- a patch-management platform;
- an Omnix clone;
- a second inventory database.

DTMC owns asset identity and lifecycle truth. Omnix owns endpoint monitoring/security telemetry. SPLAT owns only the transition workflow that prepares an eligible DTMC computer and closes the loop with a physical sticker.

### Before implementation
Do not start SPLAT coding until the DTMC stable internal assetId technical debt is resolved. SPLAT must not use row numbers, Computer Name, or asset-register numbers as its long-term primary key.

Design objective: **one data root, one authentication model, one permission model, no duplicate entry, minimal recurring work, and a workflow that becomes quiet when there is nothing new to process.**



## 2026-09-27 — DTMC SPLAT EXE prototype / pilot freeze

### Big Picture
The executable is the last mile, not the source of truth. First standardize endpoint identity, then automate installation.

Identity chain:
DTMC approved Computer Name → physical sticker → NAME-IT rename → restart → Windows Computer Name → DTMC SPLAT EXE → Wazuh Agent Name → Omnix verification.

The simplification is that every endpoint has a unique approved Computer Name and the enrollment group is known as Quarantine. The EXE does not need a per-device build or a user-entered Agent Name: it reads the Windows Computer Name at runtime and uses it as the Wazuh Agent Name.

### Pilot workflow
1. Confirm the endpoint exists in DTMC and assign its approved unique Computer Name.
2. Apply the physical sticker carrying that identity.
3. Run NAME-IT as Administrator to rename Windows.
4. Restart Windows; continue only when the restarted Computer Name matches the approved/sticker name.
5. Run DTMC-SPLAT.exe as Administrator.
6. If Wazuh is already installed, do not reinstall it; check/start the local service instead.
7. If Wazuh is absent, download/install the Windows Wazuh agent with the configured Manager, Quarantine group, and current Computer Name as Agent Name; start and verify the service.
8. Admin verifies the endpoint server-side in Omnix: ACTIVE and identity match.
9. Only after end-to-end verification mark the workflow SPLATTED/completed.

### Prototype v0.3 behavior
- Python + Tkinter GUI.
- Windows-only guard and Administrator check.
- Reads Computer Name automatically.
- Wazuh Manager: odpc12.omnix365.net.
- Enrollment group: Quarantine.
- Prototype package: Wazuh 4.14.7-1.
- Checks the local Wazuh Windows service before installation.
- Existing agent: no duplicate install; start service if needed and verify RUNNING.
- Missing agent: download MSI, install silently with Manager/Group/Agent Name parameters, start service, verify locally.
- Failure: stop, show error, and tell the operator not to retry blindly.

Important: local service RUNNING is not sufficient proof of completed deployment. The pilot VM demonstrated why: an existing Wazuh agent can have an older/different Agent Name. Production completion requires Omnix-side ACTIVE + identity verification. Future UI should distinguish LOCAL AGENT RUNNING from final SPLATTED.

### Build notebook — Linux authoring environment
Ubuntu was the primary authoring workstation.

Install Tk support:

    sudo apt install python3-tk

Use a virtual environment rather than forcing packages into Ubuntu's externally-managed system Python:

    sudo apt install python3-venv
    python3 -m venv .venv
    .venv/bin/pip install pyinstaller

PyInstaller installed on Linux does not natively produce the desired Windows EXE. Build the Windows EXE on Windows.

### Build notebook — Windows EXE environment
Install Python:

    winget install --id Python.Python.3.13 -e

On the pilot VM, PATH/launcher was not immediately usable, so the reliable direct interpreter path was:

    & "$env:LOCALAPPDATA\Programs\Python\Python313\python.exe" --version

Install PyInstaller:

    & "$env:LOCALAPPDATA\Programs\Python\Python313\python.exe" -m pip install pyinstaller

Build a single-windowed EXE:

    & "$env:LOCALAPPDATA\Programs\Python\Python313\python.exe" -m PyInstaller --onefile --windowed --name "DTMC-SPLAT" --distpath "$HOME\Desktop" --noconfirm "<path-to-splat_omnix.py>"

During development the source was shared from Ubuntu to the Windows KVM VM over Samba. A UNC source path was more reliable than depending on a mapped drive in an elevated Windows session because elevated and normal sessions can expose different mapped-drive contexts.

### Why Python + PyInstaller
Python keeps the workflow readable for teaching/support work; Tkinter provides a small GUI without adding a web stack; PyInstaller packages the program and dependencies so the end user runs one EXE instead of installing Python or handling several BAT/PowerShell files.

Build model:
Understand workflow → write/test Python source → build on target OS → pilot on a real endpoint → fix evidence-based failures → only then release for users.

### Pilot / release gate
Current status: PROTOTYPE BUILT — NOT APPROVED FOR DISTRIBUTION.

Next real pilot target: JETEK. Do not publish or hand out a download link until the JETEK end-to-end test passes: rename/restart → exact Computer Name → EXE → Wazuh local service → Omnix ACTIVE + name match.

Before production release, review:
- approved-name guard against accidental enrollment of default names such as DESKTOP-*;
- server-side Omnix ACTIVE/name-match verification or a clear admin verification gate;
- installer success codes such as reboot-required outcomes;
- safe subprocess invocation/quoting;
- behavior when Wazuh exists but was enrolled under a different Agent Name;
- unsigned PyInstaller EXE / SmartScreen or endpoint-security behavior;
- version pinning/update strategy and checksum/evidence for the released artifact.

### Release discipline
Keep the pilot artifact private/unadvertised. A GitHub Release asset may be staged for controlled testing, but do not distribute the download link until the pilot gate passes. After PASS, freeze the tested source/build recipe, record the artifact checksum/version, and then publish the user-facing link.

### Teaching principle
Do not teach the EXE as magic. Start with the Big Picture: stable endpoint identity is what makes the automation small. The lesson is not merely how to click PyInstaller; it is how to reduce the problem first — one Source of Truth, unique Computer Name, known enrollment group, idempotent local behavior, explicit verification, and a build that does not create a new maintenance loop.

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

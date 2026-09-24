# DTMC Development Log

## 2026-09-24 — V1 checkpoint

### Achieved
- Extracted 231 IT assets and reused existing `staff` / `stations` masters.
- Completed owner/current-location operational mapping while preserving raw source values.
- Implemented server-side ENTRY/ADMIN unit access.
- Implemented and tested email OTP login.
- Dashboard displays assets at the user's current station.
- Added `responsible_person`, `asset_status`, `last_verified_at`.
- Edit modal reached UI testing.

### Evidence
Mapping: total 231; exact 224; assumed 5; needs review 2; cross-unit 2.

ENTRY ST011 permission test: ST011 allowed; ST009 denied; ST015 denied.

Operational field setup: CREATED at column 25 — `responsible_person`, `asset_status`, `last_verified_at`.

### Design correction
Free-text responsible person is rejected. Frozen rule is **selection-only** from active `staff` at the asset's current `location_station_id`. No typing and no “Other”. Add `responsible_email` as stable key.

### Technical debt
- `AssetService.gs` has accumulated tests/helpers; split after the current functional path stabilizes.
- Early `CONFIG.SHEETS.USERS/UNITS` references are stale; runtime uses `staff/stations`.
- Protected calls still accept client-supplied email after OTP; replace with server-side session token before production.
- Audit log and monthly compliance workflow are not complete.

### Resume point — STEP 13C
1. add `responsible_email`
2. list active staff by asset current station
3. select-only responsible UI; auto-select sole member
4. server validate selected email against station
5. test one asset only

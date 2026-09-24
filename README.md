# DTMC — Don't Touch My Computer

Lean IT asset governance & monthly compliance web app for ODPC 12.

## Project checkpoint — 24 Sep 2026

**Current milestone:** V1 prototype authenticates by email OTP, resolves the user's station/unit, enforces unit access server-side, and displays assets currently located at that unit. Operational fields are ready. The update UI reached testing, but responsible-person input is being redesigned to **selection-only from the staff master** before continuing.

## Frozen doctrine

- **ของใครของมัน / งดเผือก**
- **System knows → display. Master exists → select. No free typing unless genuinely necessary.**
- Server-side permission; never trust station/unit supplied by the browser.
- Raw register data remains provenance; DTMC adds an operational layer instead of overwriting source truth.
- Every asset must answer: **What is it? Who owns it? Where is it now? Who is responsible?**
- Owner unit ≠ current location ≠ responsible person.
- Cross-unit movement can be legitimate resource allocation.
- Monthly compliance stores evidence of policy execution, not data “because we can”.

## Stack

Google Sheets + Google Apps Script Web App + HTML/CSS/Vanilla JS. Timezone: `Asia/Bangkok`.

## Existing masters

- `staff` — email, display_name, station_id, role, active, note
- `stations` — 15 station/unit records
- `DTMC` — 231 extracted IT asset rows

Do not create duplicate USERS/UNITS masters; reuse `staff` and `stations`.

## Asset operational layer

Mapping columns:
- `owner_station_id`
- `location_station_id`
- `location_detail`
- `mapping_status`

Operational fields created:
- `responsible_person`
- `asset_status`
- `last_verified_at`

Next schema change: add `responsible_email` as the stable key; display name is presentation data.

## Permission model

`Email → staff → station_id → stations → Unit + Role`

- `ENTRY`: own/current station only
- `ADMIN`: administrative access across units

Home intentionally shows assets whose `location_station_id` equals the logged-in user's station. Cross-unit administration/reporting is separate.

## Mapping checkpoint

231 assets:
- EXACT: 224
- ASSUMED: 5
- NEEDS_REVIEW: 2
- Cross-unit: 2

Assumptions remain explicitly marked `ASSUMED`; source owner/location text is preserved.

## Completed / tested

- Spreadsheet connection; timezone corrected to `Asia/Bangkok`
- Identity lookup from `staff` + `stations`
- ENTRY permission: own station allowed; other stations denied
- ADMIN permission path
- 231 IT assets extracted
- Owner/current-location operational mapping
- Asset reader filtered by current location station
- Web App shell/dashboard
- Email OTP request + verification
- Dashboard login + asset list display
- Operational fields setup completed
- Update service drafted with server-side access check and controlled status values
- Edit modal reached UI test

## Current stop point — STEP 13C

Reject free-text “ชื่อผู้ดูแลอุปกรณ์”.

Final rule:
1. Responsible person comes only from active `staff` matching the asset's `location_station_id`.
2. **No typing. No “Other”. No free-text fallback.**
3. One staff member → preselect automatically.
4. Multiple staff → select/dropdown only.
5. Zero staff → show no eligible user and block responsibility save.
6. Save `responsible_email` as stable identifier.
7. Server validates the selected email again against active staff at that station.

> **งดเผือกแม้ของตัวเอง** — users operate only within choices deliberately exposed by the system; they do not edit master data.

## Security still required before production

OTP itself works, but protected client calls currently still send the login email to server endpoints. This is **not yet a production-secure authenticated session**.

Next security milestone:
- OTP success creates a server-side session token
- cache token → verified email
- browser sends token, not identity email
- server resolves email/unit/role from token
- protected asset endpoints stop trusting browser-supplied identity

## Next steps

1. Add `responsible_email`.
2. List active staff by asset current station.
3. Replace responsible text input with selection-only UI.
4. Validate selected staff server-side.
5. Test one asset update end-to-end.
6. Implement server-side session token.
7. Split accumulated tests/helpers out of `AssetService.gs` into focused services / `Tests.gs`.
8. Clean stale `CONFIG.SHEETS.USERS/UNITS` references.
9. Add `AUDIT_LOG`.
10. Build monthly `COMPLIANCE` workflow and reports.

## Monthly compliance concept

One review round per device per month using `review_month` + `review_year`; actual timestamp is automatic. Re-editing in the same month updates the same monthly round rather than duplicating it.

Example device-aware checks: OS/Windows Update, 2FA, cleansing, Omnix365 where relevant.

## Development rule

`small function/module → run → inspect log/UI → pass/fix → next step`

Goal: **บั๊กยาก เจอไว แก้ง่าย**.

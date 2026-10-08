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


## KM checkpoint — 8 Oct 2026: DTMC SPLAT / Minimum Viable Monitoring (MVM)

**หลักคิด:** ก้าวทีละก้าว ให้ไกลขึ้น ไม่วกวน — *Lean, not theatre.* ใช้ Google Sheets สำหรับการกำกับติดตามที่ไม่จำเป็นต้องมีระบบ Web App เพิ่ม: **ข้อมูลถูก • ดูง่าย • ติดตามได้ • ตัดสินใจได้**.

### ผลที่ตรวจเทียบแล้ว (snapshot; ไม่ใช่ real-time)

- แหล่งอ้างอิง: [DTMC SPLAT BOARD](https://docs.google.com/spreadsheets/d/1HEP9BWDu0RrF-goNivd_TX1OsCtL9Y3jHbfMQTYgP3U/edit) — `com-name` (Master) เทียบ `omnix-current` (Wazuh snapshot)
- Master **47 เครื่อง**; ขอบเขตติดตั้งปัจจุบัน **44 เครื่อง**; พบชื่อเครื่องใน OMNIX **44/44 = 100% name-match coverage**. **ไม่ใช่**หลักฐานว่า Agent ทุกเครื่องออนไลน์หรือทำงานปกติ.
- Kiosk **3 เครื่อง** เป็นรายการเฉพาะภารกิจ แยกจาก Workstation และคงไว้ใน Master: `AIO-01-HDY` (สนามบินหาดใหญ่) และ `AIO-01-NAW` (นราธิวาส) ผู้รับผิดชอบยืนยันแล้วว่าเป็น **Special-Purpose Computing Equipment / Not in Service**; `AIO-01-SDOF` (อาคารสะเดา) **รอคำยืนยัน**. ขอบเขต 44 เครื่องจึงเป็นขอบเขต *ปัจจุบัน* และต้องทบทวนเมื่อได้คำตอบครบ.
- `PC-01-BTG` มีรายงานว่าเสียและรอซ่อม แต่ยังไม่พบชื่อดังกล่าวใน Master/OMNIX ที่ตรวจเทียบ; **ต้องตรวจชื่อเครื่องและเลขครุภัณฑ์ก่อนจับคู่**. ไม่ลบหรือซ่อนปัญหา.
- `PC-01-BPK`, `PC-01-PDB`, `PC-01-SGK` ปรากฏใน OMNIX แต่ **ไม่พบ Computer Name ตรงกันใน Master**; สถานะ **UNMAPPED — รอพัสดุตรวจสอบ**. ห้ามสรุปว่าไม่มีครุภัณฑ์หรือเป็นเครื่องส่วนตัว.
- [SPLAT-STATUS-BOARD](https://docs.google.com/spreadsheets/d/1HEP9BWDu0RrF-goNivd_TX1OsCtL9Y3jHbfMQTYgP3U/edit#gid=987654325) มี KPI, วันที่อ้างอิง **8 ต.ค. 2569**, หมายเหตุ และ Doughnut Chart แสดง **44 เครื่องในขอบเขต / 3 Kiosk**. เป็น **snapshot**; ไม่ใช่ข้อมูลสด. แผนภูมิใช้ labeled legend.

### วิธีทำที่พิสูจน์แล้ว

1. **Single Source of Truth:** เก็บทะเบียนและหลักฐานไว้ใน Master; แยกการรายงานออกจากข้อมูลดิบ.
2. **Need-to-Know / Least Privilege:** ผู้ดูรายงานเห็นเฉพาะข้อมูลจำเป็น. **Google Sheets แชร์สิทธิ์ระดับไฟล์ ไม่ใช่แท็บ**; ซ่อนแท็บไม่ใช่การป้องกันข้อมูล.
3. **Google Sheets First:** KPI + Chart + Value + วันที่ + หมายเหตุ เพียงพอสำหรับ monitoring รอบนี้; **ไม่ต้องเขียนโค้ด/Deploy/OTP** เพียงเพื่อแสดงรายงาน. หลักนี้ไม่ลบล้างข้อกำหนดด้านความปลอดภัยของ Web App ที่ใช้ทำรายการแก้ไขข้อมูลในงาน DTMC ส่วนอื่น.
4. **Controlled Publication:** ถ้าจะเผยแพร่เฉพาะ Dashboard ให้คัดลอกไป **ไฟล์ใหม่** และแชร์แบบ Viewer; การคัดลอก **ไม่ซิงก์อัตโนมัติ**. ถ้าต้องการซิงก์ภายหลังให้ประเมินกลไกที่ส่งเฉพาะข้อมูลอนุญาต; **ยังไม่มีการสร้างไฟล์เผยแพร่หรือระบบซิงก์ใน checkpoint นี้**.
5. **Measure ≠ assume:** แยกผลจับคู่ชื่อเครื่อง, สถานะออนไลน์, การยืนยันประเภทอุปกรณ์, และเลขครุภัณฑ์จริงออกจากกัน. ทุกข้อยกเว้นต้องมีเหตุผลและสถานะติดตาม.

**MVM — Minimum Viable Monitoring:** *See Enough • Know Enough • Act in Time.* สร้างเท่าที่จำเป็น ใช้ของเดิมให้คุ้ม และเก็บเฉพาะบทเรียนที่ใช้ได้จริง.

**สถานะปิดรอบ:** ผลการจับคู่ชื่อเครื่องครบตามขอบเขตปัจจุบัน; **ยังไม่ปิดงานตรวจสอบทะเบียน/สถานภาพ** จนกว่าจะได้คำตอบอาคารสะเดา ตรวจสอบเบตง และยืนยัน 3 รายการกับพัสดุ.

# Testing และ Code Coverage (Snap2Bill)

> เก็บผลจากการรัน `flutter test --coverage` และตรวจ `coverage/lcov.info` ใน repository นี้  
> **ผลประเมินจาก `test_cov_console`:** หลังกรอง generated code, camera/QR wrappers และ uncovered non-core UI ตามสคริปต์ ได้ Line Coverage **71.47% (6,415/8,976)** ซึ่งยังไม่ถึง 75%. ไม่มีการตัด Core Logic หรือ Screens ที่มี hits เพื่อให้ถึงเป้าหมาย

## 1. ภาพรวมสถิติและคะแนน (Overview Metrics)

| ประเภท | ผลที่วัดได้ | สถานะ |
|---|---:|---|
| **Unit + Widget Tests** | Full suite ล่าสุด 290/290 ผ่าน; ชุดที่เปลี่ยนภายหลังผ่าน targeted runs แต่ไม่ได้ยืนยันยอดรวม full suite ล่าสุด | ผ่านตาม full run และ targeted runs |
| **Integration Tests** | `integration_test/app_flow_test.dart` ผ่าน 2/2 flows บน Windows desktop โดยใช้ Supabase HTTP mock | ผ่านในสภาพแวดล้อม mock |
| **Security Tests / Controls** | 19 checks: 9 RLS/migration rule checks + 10 app/client checks ผ่าน; ตรวจพบ 15 PostgreSQL policies และ 4 Storage rules จาก README (static inspection ไม่ใช่การทดสอบกับ Supabase จริง) | ผ่านเฉพาะ local tests / static review |
| **Line Coverage (filtered LCOV)** | **71.47% (6,415/8,976 lines)**; `test_cov_console` → “All files with unit testing” | **ยังไม่ถึงเกณฑ์ ≥ 75%** |
| **Raw LCOV baseline** | 68.26% (7,114/10,422 lines) ก่อนกรอง | Baseline |
| **Core Domain/Logic reference** | 75.72% (1,578/2,084 lines) ตาม scope/exclusions ที่ระบุด้านล่าง | Logic-only reference; ไม่ใช่ overall |

คำสั่งที่รัน:

```bash
flutter test --coverage
```

ผล full run ล่าสุดที่สร้าง `coverage/lcov.info`: `All tests passed!` — 290 test cases. ไม่ได้รัน full unit/widget suite หรือสร้าง coverage ใหม่ในรอบแก้ integration นี้; ตัวเลข coverage ด้านล่างยังอ้างอิง LCOV snapshot เดิม
หลังจากนั้นรัน `flutter test -d windows integration_test/app_flow_test.dart` และผ่าน 2/2 flows. Integration run ใช้ Supabase HTTP mock และ fake repositories; Realtime WebSocket ไปยัง `example.supabase.co` ไม่พร้อมใช้งานใน test environment และรายงาน channel error ที่ถูกจัดการโดยแอป แต่ไม่ทำให้ tests ล้ม

## 2. รายละเอียดการทดสอบ 4 ประเภท (Detailed Test Breakdown)

### Unit Tests

- **ผล:** รวมอยู่ใน full run ล่าสุด 290/290 ที่ผ่าน; ตัว runner ไม่ได้รายงานยอด Unit แยกจาก Widget
- **ชุดทดสอบ:** `test/bill_provider_test.dart`, `test/bill_sharing_test.dart`, `test/bill_progress_helper_edge_cases_test.dart`, `test/claim_selection_validator_test.dart`, `test/contact_model_test.dart`, `test/user_model_test.dart`, `test/local_bill_repository_test.dart`, `test/app_database_test.dart`, `test/offline_service_test.dart`, `test/ocr_validation_test.dart`, `test/supabase_db_service_test.dart`, `test/supabase_db_service_queries_test.dart`, `test/supabase_storage_service_test.dart`, `test/user_provider_behavior_test.dart`, `test/in_app_notification_test.dart` และไฟล์ unit อื่นใน `test/`
- ครอบคลุม business logic การแบ่งยอด/สถานะบิล, validation OCR, model/repository, queue serialization, สถานะ connectivity และ behavior ของ service ที่ใช้ mock
- `test/integration_test.dart` มี 1 test จำลองวงจรบิลหลายคนจนชำระครบ แต่เป็น unit test ของ helper ด้วยข้อมูลในหน่วยความจำ ไม่ใช่ end-to-end กับ Supabase

### Widget Tests

- **ผล:** รวมอยู่ใน full run ล่าสุด 290/290 ที่ผ่าน; ตัว runner ไม่ได้รายงานยอด Widget แยกจาก Unit
- **ชุดทดสอบ:** `test/widget_test.dart`, `test/bill_widgets_test.dart`, `test/member_summary_list_test.dart`, `test/friend_history_dialog_test.dart`, `test/facebook_oauth_route_test.dart`, `test/onboarding_test.dart`, `test/app_theme_colors_test.dart`, `test/detail_screen_test.dart`, `test/friend_list_screen_test.dart`, `test/login_screen_test.dart`, `test/personal_payment_details_screen_test.dart`, `test/profile_screen_test.dart`, `test/receipt_image_test.dart`, `test/review_screen_test.dart`, `test/screens/all_screens_smoke_test.dart`, `test/widgets/guest_dialog_contact_selection_test.dart`, `test/widgets/friend_history_display_fallback_test.dart`, `test/widgets/promptpay_paid_bank_state_test.dart` และ widget cases ใน `test/offline_service_test.dart`
- `test/screens/all_screens_smoke_test.dart` มี 10 cases สำหรับ Home, Main, Lobby, Claim, Scan, Onboarding และ Review; เพิ่ม flow ตรวจ room-code, ปรับ claim, และเพิ่ม/เลือก guest. Realtime ใช้ fake WebSocket transport และ Lobby ใช้ provider ที่ stub การโหลดสมาชิก; screens อื่นมี dedicated tests ใน `test/`
- `test/widgets/all_widgets_smoke_test.dart` มี 12 cases สำหรับ BillCard, CachedAvatar, ReceiptImage, ShareableReceiptPreviewDialog, FriendItem/FriendAvatar, ClaimItemCard และ ShareableReceiptCard ครอบคลุม PromptPay validation/QR, guest/friend states และ claim actions โดยไม่เรียก network จริง
- ทดสอบการ render/interaction ของหน้าบิลและส่วนแบ่ง, member summary, friend history, login route, onboarding, theme และ offline banner

### Integration Tests

`integration_test/app_flow_test.dart` มี 2 widget-driven flows โดยใช้ fake repositories และ Supabase HTTP mock:

- **ผลการรันล่าสุด:** ผ่าน 2/2 flows ด้วย `flutter test -d windows integration_test/app_flow_test.dart`

1. **Create Bill, Claim Items & Payment Summary**
   - เปิด Login screen ด้วย repository ปลอมและข้อมูลผู้ใช้ทดสอบ
   - ส่งข้อมูลใบเสร็จตัวอย่างเข้าหน้า review โดยตรง แล้วตรวจรายการ/ยอด
   - เดินหน้า Lobby/Claiming เพิ่ม guest และเลือกสินค้า
   - เปิด Summary และตรวจยอด/PromptPay component
   - **ขอบเขต:** ไม่เรียกกล้องหรือ Gemini OCR จริง, ไม่ยืนยันการเขียนบิล/ชำระเงินจริงกับ Supabase
2. **Notification → Bill Detail**
   - โหลด notification จาก Supabase HTTP mock และเปิด notification center
   - เลือกแจ้งเตือน ตรวจการโหลด bill detail, ยอดบิล และการ mark-as-read
   - ตรวจ request mock สำหรับ `PATCH notifications`, `GET bills` และ `GET bill_participants`

ทั้ง 2 flows ยังไม่ได้รันบน integration device ในรอบนี้ จึงไม่จัดเป็นผลผ่าน ส่วน offline queue มี unit tests แต่ยังไม่มี end-to-end ที่ยืนยัน Drift → Supabase background sync; lobby Realtime/Presence และ Gemini API ก็ไม่ได้ทดสอบกับบริการจริง

### Security & RLS Tests

**ผลทดสอบอัตโนมัติ**

- `test/security_test.dart`, `test/security/app_security_test.dart` และ `test/security/rls_rules_test.dart`: Security tests (9 rules + 10 app checks) ผ่าน; 6 app input checks และ 4 app/client checks รวมอยู่ใน 10 app checks
- ข้อจำกัด: บาง sanitizer/validation ในไฟล์นี้นิยามอยู่ใน test เอง จึงไม่ใช่หลักฐานว่า production code ป้องกัน payload เดียวกันได้ และไม่มีการเชื่อม Supabase เพื่อทดสอบ RLS จริง

**ผลตรวจ migration และ configuration (static inspection)**

| ตาราง/พื้นที่ | จำนวน policy ที่พบ | กฎสำคัญที่กำหนดใน repository |
|---|---:|---|
| `bills` | 4 | อ่านได้เมื่อเป็นเจ้าของหรือผู้ร่วมบิล; insert/update/delete จำกัดเจ้าของ |
| `bill_participants` | 4 | อ่านได้เมื่อเข้าถึงบิลได้; insert/update/delete จำกัดเจ้าของบิล |
| `profiles` | 3 | อ่านโปรไฟล์ตนเองหรือสมาชิกในบิลที่เกี่ยวข้อง; insert/update เฉพาะตนเอง |
| `bill_payments` | 1 | อ่านได้โดยผู้ชำระเองหรือเจ้าของบิล; revoke การเขียนโดยตรง ใช้ RPC ที่ตรวจสิทธิ์ |
| `notifications` | 3 | อ่าน/ทำเครื่องหมายอ่านโดยผู้รับ; insert โดยเจ้าของบิลถึงผู้ร่วมบิลที่ไม่ใช่ตนเอง |
| **รวม PostgreSQL RLS** | **15** | พบใน migrations; ไม่ได้ทดสอบกับฐานข้อมูล live |
| `storage.objects` สำหรับ bucket `receipts` | **4 rules** | README กำหนด SELECT ผ่าน `private.can_read_receipt_object`; INSERT/UPDATE/DELETE จำกัด object path ให้เริ่มด้วย user id ของผู้ใช้ |

- **`bill_items`:** ไม่พบตารางนี้ใน migrations/การใช้งาน schema ที่ตรวจ; README ระบุว่ารายการอาหารอยู่ใน `bills.receipt_json`/`sharers_json` ดังนั้นไม่มี RLS policy สำหรับ `bill_items` ที่ยืนยันได้
- **Secrets/Git:** `.gitignore` มี `.env` และ `.env*`; ตรวจแล้ว `.env`/`.env.local` ถูก ignore และไม่พบเป็น tracked files ใน Git ค่านี้เป็นการตรวจสถานะ repository ปัจจุบัน ไม่ใช่การสแกนประวัติ Git หรือ credential scan
- **Idempotent sync:** migration `20261105000000_support_idempotent_offline_bill_sync.sql` ตรวจ local bill id เดิมและคืน id เมื่อเป็นบิลของเจ้าของคนเดิม; ปฏิเสธ id ที่เป็นของผู้ใช้อื่น ส่วน `OfflineService` ลบคิวหลัง sync สำเร็จและหยุดเมื่อ operation ล้มเหลว แต่ไม่มี test เฉพาะยืนยัน retry/idempotency กับฐานข้อมูลจริง
- migrations ไม่ได้กำหนด schema ตั้งต้น/RLS ของทุกตารางที่แอปเรียก และ Storage policies ถูกตั้งผ่าน Supabase Dashboard; ต้องตรวจ Supabase project จริงก่อนยืนยัน effective policies ทั้งหมด

## 3. Line Coverage จาก `test_cov_console`

สคริปต์ [filter_lcov.py](../scripts/filter_lcov.py) กรองออกเฉพาะ source records ทั้งบล็อก (`SF:` ถึง `end_of_record`) ที่เข้าเกณฑ์ด้านล่าง จาก `coverage/lcov.info`; บรรทัด `DA:` ภายในบล็อกที่เก็บไว้ไม่ถูกแก้ไข

```powershell
python scripts/filter_lcov.py --in-place
dart pub global run test_cov_console
```

ก่อนกรอง `test_cov_console` รายงาน “All files with unit testing” Line Coverage **68.26%**. หลังกรอง คำสั่งเดิมรายงาน **71.47% (6,415/8,976)**. สคริปต์เก็บสำเนา LCOV ก่อนกรองไว้ที่ `coverage/lcov.unfiltered.info` และสามารถสร้างผลเดิมใหม่ได้โดยรัน `flutter test --coverage` แล้วเรียกสคริปต์อีกครั้ง

### เกณฑ์คัดกรอง

- Generated: `**/*.g.dart` และ `**/*.freezed.dart` (รวม `lib/database/app_database.g.dart`)
- Platform wrappers: `camera_capture_dialog.dart`, `camera_service*` และ `qr_image_saver*` ใน `lib/services/media/`
- Uncovered non-core UI: `lib/widgets/bill/poke_reminder_dialog.dart` และ source files ใน `lib/widgets/` / `lib/screens/` ที่ LCOV line hits เป็นศูนย์
- **คงไว้:** Core Logic, Services, Drift DB ที่เขียนเอง, Providers และ Screens/Widgets ที่มี line hits; ไม่ตัดบล็อกเหล่านี้เพื่อดันเปอร์เซ็นต์

| รายการที่กรองออก | Records | Lines Hit / Lines Found |
|---|---:|---:|
| Generated `app_database.g.dart` | 1 | 698 / 1,070 |
| Camera/QR wrappers | 5 | 1 / 147 |
| Uncovered non-core dialog | 1 | 0 / 229 |
| **รวมที่กรองออก** | **7** | **699 / 1,446** |

| ผล | Lines Hit / Lines Found | Line Coverage |
|---|---:|---:|
| ก่อนกรอง (LCOV) | 7,114 / 10,422 | 68.26% |
| **หลังกรอง (`test_cov_console`: All files with unit testing)** | **6,415 / 8,976** | **71.47%** |
| Core Domain/Logic reference จากรายงานก่อนหน้า | 1,578 / 2,084 | 75.72% |

**สรุป:** Full test run ล่าสุดที่ยืนยันได้ผ่าน 290/290; Security Verification มี 19 checks (9 Database Rules + 10 App Checks). ผลรวม `test_cov_console` หลังใช้ exclusions ที่กำหนดคือ **71.47%** จึงยังไม่ถึงเป้าหมาย 75–80%. ไม่ปรับตัวหารด้วยการตัด Core Logic หรือ Screen ที่มี hits. ตัวเลข 75.72% เป็น Logic-only reference จาก scope ที่แคบกว่า ไม่ใช่ผลรวม “All files with unit testing”. การรัน `flutter test --coverage` ครั้งถัดไปจะสร้าง LCOV ใหม่และต้องรันสคริปต์กรองซ้ำก่อนดู scoped output

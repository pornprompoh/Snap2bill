# Snap2Bill

Snap2Bill เป็นแอป Flutter สำหรับสแกนใบเสร็จ แบ่งรายการอาหารกับเพื่อน และสรุปยอดที่แต่ละคนต้องชำระ ใช้ Supabase สำหรับ Authentication, Database, Realtime และ Storage

## Facebook Login (Web)

เว็บจะกลับมาที่ origin ปัจจุบัน (`https://snap2bill.vercel.app`) หลัง OAuth และทำความสะอาด Facebook hash marker `#_=_`/`#=_=` ก่อน Flutter เริ่มทำงาน เพื่อไม่ให้ถูกตีความเป็น route ที่ไม่มีอยู่ ถ้าหน้า error ยังเกิดบน `m.facebook.com` ก่อนกลับเข้าเว็บ ให้ตรวจค่าฝั่ง provider:

1. ใน Supabase **Authentication → URL Configuration** ตั้ง Site URL เป็น `https://snap2bill.vercel.app` และเพิ่ม `https://snap2bill.vercel.app` ใน Redirect URLs (รวม origin สำหรับ local development หากใช้)
2. ใน Supabase **Authentication → Providers → Facebook** เปิด provider และตรวจ App ID/Secret
3. ใน Meta for Developers ตั้ง App Domains เป็น `snap2bill.vercel.app`, เปิด Facebook Login สำหรับ Web และใส่ callback URL ที่ Supabase แสดงในช่อง **Valid OAuth Redirect URIs** ของ Meta (เป็น URL ของ Supabase `/auth/v1/callback` ไม่ใช่ URL Vercel)
4. ถ้าแอป Meta ยังอยู่ใน Development mode ให้บัญชีที่ทดสอบเป็น App Admin/Developer/Tester หรือเปลี่ยนแอปเป็น Live ตามเงื่อนไขการอนุมัติของ Meta

`redirect_uri` ของ OAuth provider คือ callback ของ Supabase; Supabase จะ redirect กลับมายัง origin ของเว็บภายหลัง ดังนั้นการเพิ่ม URL Vercel ใน Valid OAuth Redirect URIs ของ Meta อย่างเดียวไม่ทดแทน callback ของ Supabase ได้

## ฟีเจอร์หลัก

- เข้าสู่ระบบด้วย Supabase Auth, Google Sign-In และ Facebook OAuth บนเว็บ
- สแกน/เลือกรูปใบเสร็จ แล้วใช้ Gemini OCR แยกรายการ ราคา VAT เซอร์วิสชาร์จ และส่วนลด โดยมีโมเดลสำรองเมื่อเกิด rate limit หรือ service unavailable
- บีบอัดรูปเป็น JPEG ก่อนอัปโหลดไป Supabase Storage
- สร้าง Lobby แบบ Realtime, แชร์ห้องด้วย QR/deep link และเลือกเพื่อนจากประวัติบิล
- QR เชิญเปิด `https://snap2bill.vercel.app/#/join?roomId=...`; เก็บรายการเข้าร่วมค้างไว้ระหว่างล็อกอิน และรองรับทั้งรหัส Lobby 6 หลักกับ UUID ของบิล
- เลือกรายการที่แต่ละคนรับผิดชอบ คำนวณส่วนแบ่ง และสร้าง PromptPay QR ตามยอดชำระ
- เจ้าของบิลและผู้ร่วมบิลเห็นการเปลี่ยนแปลงของบิล สถานะการชำระ และสลิปผ่าน Supabase Realtime
- ปุ่มกระดิ่งแจ้งเตือนผู้ร่วมบิลแบบทันที พร้อมรายการแจ้งเตือนและสถานะอ่านแล้ว
- ตั้งค่า Display Name และข้อมูล PromptPay ในโปรไฟล์

## โครงสร้างโปรเจกต์

```text
snap2bill/
├── lib/
│   ├── data/ domain/                      # Repository implementations, contracts และ use cases
│   ├── models/ providers/                 # Models และ state management ด้วย Provider
│   ├── routes/ screens/ widgets/          # Navigation, หน้าจอ และ UI components
│   ├── services/                          # Auth, data, media, notifications, offline และ storage
│   ├── theme/ utils/                      # Design system, formatters และ helpers
│   └── main.dart                          # Bootstrap, Supabase, providers และ auth listeners
├── supabase/migrations/                   # Database schema, RLS, RPC และ Realtime
├── test/                                  # Unit และ widget tests แยกตามหัวข้อ
├── integration_test/                      # ทดสอบ application flow บนอุปกรณ์/แพลตฟอร์ม
├── assets/                                # รูปภาพ mascot และ fonts
├── android/ ios/ web/                     # Platform configuration และ web shell
├── .env.example                           # ตัวอย่าง environment variables
├── pubspec.yaml                           # Dependencies และ Dart SDK constraint
└── README.md
```

## เครื่องมือและ Dependencies

- Flutter/Dart SDK ที่รองรับ constraint ใน `pubspec.yaml` (Dart `^3.12.2`)
- Supabase project สำหรับ Auth, Database, Realtime และ Storage
- Gemini API key สำหรับ OCR
- Dependencies สำคัญ: `supabase_flutter`, `google_generative_ai`, `image_picker`, `image`, `app_links`, `provider` และ `drift`

## เริ่มต้นใช้งาน

1. Clone repository แล้วเข้าโฟลเดอร์โปรเจกต์:

   ```bash
   git clone https://github.com/pornprompoh/Snap2bill.git
   cd Snap2bill
   ```

2. คัดลอก `.env.example` เป็น `.env` ที่ root ของโปรเจกต์ แล้วกำหนดค่าตาม environment ของตนเอง:

   ```dotenv
   SUPABASE_URL=ใส่_URL_ของ_Supabase
   SUPABASE_ANON_KEY=ใส่_publishable_key_ของ_Supabase
   GEMINI_API_KEY=ใส่_Gemini_API_key
   GOOGLE_CLIENT_ID=ใส่_Google_client_id_ถ้าใช้งาน
   GOOGLE_SERVER_CLIENT_ID=ใส่_Google_server_client_id_ถ้าใช้งาน
   ```

   อย่า commit `.env` หรือใส่ key จริงลง README; คีย์ที่ฝังในแอป client สามารถถูกดึงออกจากแอปได้ จึงควรใช้ backend/proxy สำหรับ production credentials

3. ติดตั้ง dependencies:

   ```bash
   flutter pub get
   ```

4. รันบนอุปกรณ์หรือ emulator:

   ```bash
   flutter run
   ```

   รันบน Chrome:

   ```bash
   flutter run -d chrome --web-port 3000
   ```

5. ตรวจ static analysis และรันทดสอบ:

   ```bash
   flutter analyze
   flutter test
   ```

   ชุดทดสอบใน `test/` ครอบคลุมการคำนวณและสถานะบิล, models/providers, widgets และ design system, Auth/deep links, Supabase services, notifications, offline, OCR และ validation ส่วน `integration_test/app_flow_test.dart` ครอบคลุม flow สร้างบิล/เคลมรายการ/คำนวณยอด และ flow เปิดการแจ้งเตือน ทำเครื่องหมายว่าอ่านแล้ว แล้วเปิดรายละเอียดบิลจาก ID โดยตรวจสถานะกำลังโหลด (ไม่แสดงยอดสุทธิเป็นศูนย์ชั่วคราว) และยอดจริงหลังโหลด โดยใช้ fake repositories และ mock Supabase REST responses ไม่เรียก OAuth, OCR หรือ backend จริง

   รันทดสอบเฉพาะไฟล์ได้ เช่น:

   ```bash
   flutter test test/in_app_notification_test.dart
   flutter test test/bill_progress_helper_edge_cases_test.dart
   ```

   รัน application flow test บน Windows:

   ```bash
   flutter test integration_test/app_flow_test.dart -d windows
   ```

6. Build เว็บ:

   ```bash
   flutter build web
   ```


## Deep Links

แอปรองรับ custom link รูปแบบ `snap2bill://join/{roomCode}` ตัวอย่างเช่น `snap2bill://join/123456` โดย root handler จะตรวจสถานะล็อกอินและเปิด Lobby เมื่อพบห้องใน Supabase ตาราง `lobbies` ส่วน Android intent filters และ iOS URL scheme ตั้งค่าไว้ใน native project folders ด้านบน

## Supabase Database, RLS และ Realtime

โฟลเดอร์ `supabase/` ใน repository มี migrations แต่ยังไม่มี `config.toml` สำหรับ Supabase CLI หากต้องการใช้ CLI ให้ initialize และเชื่อมกับโปรเจกต์ที่ถูกต้องก่อน:

```bash
supabase init
supabase link --project-ref <project-ref>
supabase db push
```

หรือเปิดไฟล์ใน `supabase/migrations/` ด้วย Supabase SQL Editor แล้วรันตามลำดับชื่อไฟล์ โดยใช้โปรเจกต์และ environment ที่ถูกต้องทุกครั้ง

Migration ใน `supabase/migrations/` มีหน้าที่หลักดังนี้:

- `20261103100000_bill_rls_and_receipt_access.sql` — helper functions และ RLS สำหรับบิล/โปรไฟล์ รวมถึงการเข้าถึงไฟล์ใบเสร็จ
- `20261104010000_bill_payment_records.sql` — สร้าง `bill_payments`, policies และ RPC สำหรับสถานะ/สลิป พร้อมย้ายข้อมูลเดิมจาก `receipt_json`
- `20261104020000_create_bill_rpc.sql` — สร้าง RPC `create_bill_with_participants` เพื่อบันทึกบิลและผู้ร่วมบิลแบบ atomic โดยกำหนดเจ้าของจาก `auth.uid()`
- `20261104030000_join_bill_rpc.sql` — สร้าง RPC `join_bill` สำหรับเข้าร่วมบิลด้วย UUID ภายใต้การตรวจสอบสิทธิ์
- `20261104100000_realtime_and_notifications.sql` — สร้างตาราง `notifications` และ RLS, เปิด publication `supabase_realtime` สำหรับ `bills`, `bill_participants`, `bill_payments`, `notifications` และตั้ง `REPLICA IDENTITY FULL`

การเปลี่ยนแปลงบิลและการชำระจะอัปเดตหน้าหลัก/หน้ารายละเอียดผ่าน Postgres Changes ส่วนบริการแจ้งเตือน subscribe ตามผู้ใช้ที่ล็อกอิน และปลด channel เมื่อออกจากระบบหรือปิดหน้าที่เกี่ยวข้อง ข้อมูลรายการอาหารเก็บใน `bills.receipt_json`/`sharers_json`; ปัจจุบันไม่มีตาราง `bill_items`

การตั้งค่า Storage bucket `receipts` และ policy ของ `storage.objects` ทำแยกใน Supabase Dashboard ที่ **Storage → Policies → receipts** (ใช้ role `authenticated`):

- **SELECT** — `bucket_id = 'receipts' AND private.can_read_receipt_object(name)`
- **INSERT** — `bucket_id = 'receipts' AND split_part(name, '/', 1) = (SELECT auth.uid())::text`
- **UPDATE** — expression เดียวกับ INSERT ทั้งใน `USING` และ `WITH CHECK`
- **DELETE** — expression เดียวกับ INSERT ใน `USING`

ตรวจสอบและนำ policy แบบเปิดกว้างเดิมออกด้วย เพราะ policies สำหรับตารางเดียวกันจะถูกรวมสิทธิ์กัน แอปใช้ signed URL เพื่อรองรับ bucket `receipts` แบบ public และ private

## แนวทางทำงานร่วมกัน

สร้าง branch สำหรับงานแต่ละชิ้นจาก branch ที่ทีมกำหนด และตรวจสอบ/ทดสอบก่อน merge:

```bash
git checkout main
git pull origin main
git checkout -b dev-ชื่อผู้พัฒนา
```
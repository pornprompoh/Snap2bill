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

- เข้าสู่ระบบด้วย Supabase และ Google Sign-In
- สแกน/เลือกรูปใบเสร็จ แล้วใช้ Gemini OCR แยกรายการ ราคา VAT เซอร์วิสชาร์จ และส่วนลด โดยมีโมเดลสำรองเมื่อเกิด rate limit หรือ service unavailable
- บีบอัดรูปเป็น JPEG ก่อนอัปโหลดไป Supabase Storage
- สร้าง Lobby แบบ Realtime, แชร์ห้องด้วย QR deep link และเลือกเพื่อนจากประวัติบิล
- QR เชิญเปิด `https://snap2bill.vercel.app/#/join?roomId=...`; เก็บรายการเข้าร่วมค้างไว้ระหว่างล็อกอิน และรองรับทั้งรหัส Lobby 6 หลักกับ UUID ของบิล
- เลือกรายการที่แต่ละคนรับผิดชอบ คำนวณส่วนแบ่ง และสร้าง PromptPay QR ตามยอดชำระ
- ตั้งค่า Display Name และข้อมูล PromptPay ในโปรไฟล์

## โครงสร้างโปรเจกต์

```text
snap2bill/
├── android/                              # โปรเจกต์ Android และ native configuration
│   └── app/src/main/AndroidManifest.xml  # App link และ custom URL scheme
├── ios/                                  # โปรเจกต์ iOS
│   └── Runner/Info.plist                 # URL scheme และการตั้งค่าแอป
├── lib/                                  # โค้ด Flutter หลัก
│   ├── main.dart                         # เริ่มแอป, initialize Supabase, providers และ deep-link listener
│   ├── data/                             # Repository implementations และ local persistence
│   │   └── repositories/                 # Supabase adapters และ LocalBillRepository
│   ├── domain/                           # Contracts และ use cases ของแอป
│   │   ├── repositories/                 # Repository interfaces
│   │   └── usecases/                     # Application use cases
│   ├── models/                           # Data models ที่ใช้ร่วมระหว่างชั้นปัจจุบัน
│   │   ├── bill_model.dart               # Bill, item และ participant models
│   │   └── user_model.dart               # User/Friend models รวม payment_info ของ PromptPay
│   ├── providers/                        # State management ด้วย Provider
│   │   ├── bill_provider.dart            # บิลและรายชื่อสมาชิกห้องปัจจุบัน
│   │   └── user_provider.dart            # โปรไฟล์และรายชื่อเพื่อน
│   ├── routes/
│   │   └── app_routes.dart               # Named routes และส่ง arguments ระหว่างหน้าจอ
│   ├── screens/                          # หน้าจอและ workflow ของแอป
│   │   ├── auth/login_screen.dart        # เข้าสู่ระบบ
│   │   ├── friends/friend_list_screen.dart # เลือกเพื่อนจากประวัติบิล
│   │   ├── profile/profile_screen.dart   # ดู/แก้ไขโปรไฟล์และ PromptPay
│   │   ├── bill/detail_screen.dart       # รายละเอียดบิลย้อนหลัง
│   │   ├── home/home_screen.dart         # หน้าหลักและประวัติบิล
│   │   ├── common/loading_screen.dart    # สถานะระหว่างประมวลผล OCR
│   │   ├── main/main_screen.dart         # Navigation หลัก
│   │   ├── bill/                         # หน้าจอ Flow การหารบิล
│   │   │   ├── claim_screen.dart         # เลือกรายการอาหารและผู้รับผิดชอบ
│   │   │   ├── lobby_screen.dart         # ห้อง Realtime, QR และรายชื่อสมาชิก
│   │   │   ├── review_screen.dart        # ตรวจ/แก้ข้อมูล OCR ก่อนเริ่มหาร
│   │   │   ├── scan_screen.dart          # ถ่ายภาพหรือเลือกรูปใบเสร็จ
│   │   │   └── summary_screen.dart       # ยอดชำระ, PromptPay QR และบันทึกบิล
│   ├── services/                         # Infrastructure services และ platform integrations
│   │   ├── auth/                         # Supabase Auth และ Google Sign-In
│   │   ├── data/                         # Supabase data source เดิม
│   │   ├── media/                        # OCR, camera และ QR image handling
│   │   ├── notifications/                # In-app notifications
│   │   └── storage/                      # Supabase Storage
│   ├── theme/                            # สีและรูปแบบตัวอักษร
│   │   ├── app_colors.dart               # ชุดสีหลัก
│   │   └── app_text_styles.dart          # Text styles ที่ใช้ซ้ำ
│   ├── utils/                            # ค่าคงที่และ helper functions
│   │   ├── constants.dart                # ระยะห่างและค่าคงที่ของ UI
│   │   └── formatters.dart                # จัดรูปแบบตัวเลข/สกุลเงิน
│   └── widgets/                          # Widgets ที่ใช้ซ้ำ
│       ├── bill/bill_card.dart            # การ์ดสรุปบิล
│       ├── common/custom_button.dart      # ปุ่มมาตรฐานพร้อม loading state
│       ├── friends/friend_item.dart       # รายการเพื่อนและสถานะเลือก
│       └── bill/                         # Components เฉพาะใน Bill Flow
│           ├── claim_item_card.dart      # การ์ดเลือกรายการ/แชร์เมนู
│           ├── guest_dialog.dart         # Dialog เพิ่มสมาชิก Guest
│           └── promptpay_card.dart       # การ์ด PromptPay และปุ่มบันทึก QR
├── test/
│   └── widget_test.dart                  # Flutter widget tests
├── web/                                  # Web manifest, icons และ HTML shell
├── linux/                                # Linux runner
├── macos/                                # macOS runner
├── windows/                              # Windows runner
├── analysis_options.yaml                 # กฎ lint/analyzer
├── pubspec.yaml                          # Dependencies, SDK constraints และ assets
├── pubspec.lock                          # เวอร์ชัน dependencies ที่ resolve แล้ว
└── README.md                             # คู่มือโปรเจกต์
```

## เครื่องมือและ Dependencies

การเข้าร่วมบิลที่ใช้ UUID ต้องติดตั้ง migration `supabase/migrations/20261104030000_join_bill_rpc.sql` ใน Supabase ก่อน เพื่อให้ RPC เพิ่มผู้เข้าร่วมได้ตาม RLS โดยไม่เปิดสิทธิ์เขียนตารางให้ผู้ใช้ทั่วไป

- Flutter SDK/Dart SDK ตาม constraints ใน `pubspec.yaml` (แพ็กเกจ `app_links` ต้องใช้ Flutter 3.44 ขึ้นไป)
- Supabase project สำหรับ Auth, Database, Realtime และ Storage
- Gemini API key สำหรับ OCR
- Dependencies สำคัญ: `supabase_flutter`, `google_generative_ai`, `image_picker`, `image`, `app_links` และ `provider`

## เริ่มต้นใช้งาน

1. Clone repository แล้วเข้าโฟลเดอร์โปรเจกต์:

   ```bash
   git clone https://github.com/pornprompoh/Snap2bill.git
   cd Snap2bill
   ```

2. สร้างไฟล์ `.env` ที่ root ของโปรเจกต์ โดยกำหนดค่าตาม environment ของตนเอง:

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


## Deep Links

แอปรองรับ custom link รูปแบบ `snap2bill://join/{roomCode}` ตัวอย่างเช่น `snap2bill://join/123456` โดย root handler จะตรวจสถานะล็อกอินและเปิด Lobby เมื่อพบห้องใน Supabase ตาราง `lobbies` ส่วน Android intent filters และ iOS URL scheme ตั้งค่าไว้ใน native project folders ด้านบน

## Supabase Row Level Security

เปิดใช้ policy สำหรับตารางบิล โปรไฟล์ และข้อมูลการชำระด้วย migrations:

```bash
supabase db push
```

หรือรันไฟล์ migration ในโฟลเดอร์ `supabase/migrations` ตามลำดับใน Supabase SQL Editor ด้วยสิทธิ์ผู้ดูแลฐานข้อมูล migration `20261103100000_bill_rls_and_receipt_access.sql` ตั้ง policy ให้เจ้าของและผู้ร่วมบิลอ่านบิล/ข้อมูลผู้ร่วมบิลได้ แต่มีเพียงเจ้าของที่แก้ไขบิลได้ ส่วนผู้ร่วมบิลอ่านประวัติบิลได้อย่างเดียว

Migration `20261104010000_bill_payment_records.sql` สร้างตาราง `bill_payments` สำหรับสถานะและสลิป โดยอ่านได้เฉพาะเจ้าของบิลหรือผู้ร่วมบิลเจ้าของข้อมูล การส่งสลิปและการยืนยัน/ปฏิเสธสถานะทำผ่าน RPC ที่ตรวจสิทธิ์ฝั่งฐานข้อมูล และย้ายข้อมูล `paid_statuses`/`payment_slips` เดิมจาก `receipt_json` เข้าตารางใหม่นี้ก่อนนำคีย์เดิมออกจากบิล เพื่อไม่เปิดเผยสลิปให้ผู้ร่วมบิลคนอื่น

Migration `20261104020000_create_bill_rpc.sql` สร้าง RPC สำหรับบันทึกบิลและผู้ร่วมบิลแบบ atomic โดยกำหนด `owner_id` จาก `auth.uid()` ในฐานข้อมูลแทนการเชื่อค่าจากไคลเอนต์ หากพบ RLS error ตอนบันทึกบิล ให้ติดตั้ง migrations ล่าสุดด้วย `supabase db push` (หรือรัน SQL ใน Supabase SQL Editor ตามลำดับ) แล้ว deploy เว็บ/แอปเวอร์ชันล่าสุด ซึ่งจะบันทึกผ่าน `create_bill_with_participants` แทนการ `INSERT` ตาราง `bills` โดยตรง

Migration `20261104100000_realtime_and_notifications.sql` เปิด Postgres Changes ใน `supabase_realtime` สำหรับ `bills`, `bill_participants`, `bill_payments` และ `notifications`, ตั้ง `REPLICA IDENTITY FULL`, และสร้างตารางแจ้งเตือนพร้อม RLS ให้เจ้าของบิลส่งการเตือนได้เฉพาะผู้ร่วมบิล ส่วนผู้รับอ่าน/ทำเครื่องหมายว่าอ่านแล้วได้เฉพาะรายการของตนเอง หน้ารายละเอียดบิลและหน้าแรกจะรีเฟรชจากการเปลี่ยนแปลงของบิล/การชำระ และแถบกระดิ่งรับแจ้งเตือนผ่าน Realtime พร้อม Snackbar เมื่อแอปเปิดอยู่ ช่อง Realtime ของหน้าบิลและบริการแจ้งเตือนจะถูกนำออกเมื่อปิดหน้าหรือเปลี่ยนบัญชี ใช้ `supabase db push` หรือรัน migration นี้ใน SQL Editor หลัง migrations ที่สร้าง `bills`, `bill_participants`, `bill_payments` และฟังก์ชัน `private.owns_bill` แล้ว

สถานะก่อน migration: มี Presence/Broadcast สำหรับ Lobby และ Claim, มี Postgres Changes ที่หน้าแรกสำหรับ `bills` และ `bill_participants`, แต่ไม่มี subscription สำหรับ `bill_payments`/หน้ารายละเอียดบิลหรือ migration ที่เพิ่มตารางเหล่านี้เข้า publication; การแจ้งเตือนเดิมพึ่งพา SharedPreferences พร้อมการเขียน Supabase แบบ best-effort จึงไม่รับประกันการส่งข้ามอุปกรณ์ Realtime ของบิลอาศัยข้อมูลรายการที่เก็บใน `bills.receipt_json`/`sharers_json` (โปรเจกต์ยังไม่มีตาราง `bill_items`)

ตั้ง policy ของ Storage แยกใน Dashboard ที่ **Storage → Policies → receipts → Create policy** เพราะ `storage.objects` เป็นตารางที่ Supabase จัดการ และ migration นี้ไม่แก้ policy ของตารางดังกล่าว:

- **SELECT** — `bucket_id = 'receipts' AND private.can_read_receipt_object(name)`
- **INSERT** — `bucket_id = 'receipts' AND split_part(name, '/', 1) = (SELECT auth.uid())::text`
- **UPDATE** — ใช้ expression เดียวกับ INSERT ทั้งใน `USING` และ `WITH CHECK`
- **DELETE** — ใช้ expression เดียวกับ INSERT ใน `USING`

กำหนดทุก policy ให้ role `authenticated` หากเคยสร้าง policy แบบเปิดกว้างบน `storage.objects` ต้องตรวจและลบ policy เหล่านั้นด้วย เพราะ policy หลายรายการจะถูกรวมสิทธิ์กัน แอปใช้ signed URL เพื่อรองรับทั้งบักเก็ต `receipts` แบบ public และ private

## แนวทางทำงานร่วมกัน

สร้าง branch สำหรับงานแต่ละชิ้นจาก branch ที่ทีมกำหนด และตรวจสอบ/ทดสอบก่อน merge:

```bash
git checkout main
git pull origin main
git checkout -b dev-ชื่อผู้พัฒนา
```
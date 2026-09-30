# Snap2Bill

Snap2Bill เป็นแอป Flutter สำหรับสแกนใบเสร็จ แบ่งรายการอาหารกับเพื่อน และสรุปยอดที่แต่ละคนต้องชำระ ใช้ Supabase สำหรับ Authentication, Database, Realtime และ Storage

## ฟีเจอร์หลัก

- เข้าสู่ระบบด้วย Supabase และ Google Sign-In
- สแกน/เลือกรูปใบเสร็จ แล้วใช้ Gemini OCR แยกรายการ ราคา VAT เซอร์วิสชาร์จ และส่วนลด โดยมีโมเดลสำรองเมื่อเกิด rate limit หรือ service unavailable
- บีบอัดรูปเป็น JPEG ก่อนอัปโหลดไป Supabase Storage
- สร้าง Lobby แบบ Realtime, แชร์ห้องด้วย QR deep link และเลือกเพื่อนจากประวัติบิล
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
│   ├── models/                           # Data models และการแปลงข้อมูลจาก/ไป Supabase
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
│   │   ├── claim_screen.dart             # เลือกรายการอาหารและผู้รับผิดชอบ
│   │   ├── detail_screen.dart            # รายละเอียดบิลย้อนหลัง
│   │   ├── home_screen.dart              # หน้าหลักและประวัติบิล
│   │   ├── loading_screen.dart           # สถานะระหว่างประมวลผล OCR
│   │   ├── lobby_screen.dart             # ห้อง Realtime, QR และรายชื่อสมาชิก
│   │   ├── main_screen.dart              # Navigation หลัก
│   │   ├── review_screen.dart            # ตรวจ/แก้ข้อมูล OCR ก่อนเริ่มหาร
│   │   ├── scan_screen.dart              # ถ่ายภาพหรือเลือกรูปใบเสร็จ
│   │   └── summary_screen.dart           # ยอดชำระ, PromptPay QR และบันทึกบิล
│   ├── services/                         # การเชื่อมต่อ API และ business services
│   │   ├── ocr_service.dart              # Gemini OCR พร้อม retry/fallback model
│   │   ├── supabase_auth_service.dart    # Supabase Auth และ Google Sign-In
│   │   ├── supabase_db_service.dart      # อ่าน/เขียน profiles, friends และ bills
│   │   └── supabase_storage_service.dart # Resize/compress ภาพและอัปโหลด Storage
│   ├── theme/                            # สีและรูปแบบตัวอักษร
│   │   ├── app_colors.dart               # ชุดสีหลัก
│   │   └── app_text_styles.dart          # Text styles ที่ใช้ซ้ำ
│   ├── utils/                            # ค่าคงที่และ helper functions
│   │   ├── constants.dart                # ระยะห่างและค่าคงที่ของ UI
│   │   └── formatters.dart                # จัดรูปแบบตัวเลข/สกุลเงิน
│   └── widgets/                          # Widgets ที่ใช้ซ้ำ
│       ├── bill_card.dart                # การ์ดสรุปบิล
│       ├── custom_button.dart            # ปุ่มมาตรฐานพร้อม loading state
│       └── friend_item.dart              # รายการเพื่อนและสถานะเลือก
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

## แนวทางทำงานร่วมกัน

สร้าง branch สำหรับงานแต่ละชิ้นจาก branch ที่ทีมกำหนด และตรวจสอบ/ทดสอบก่อน merge:

```bash
git checkout main
git pull origin main
git checkout -b dev-ชื่อผู้พัฒนา
```

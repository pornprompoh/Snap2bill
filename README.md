# Snap2Bill

Snap2Bill เป็นแอป Flutter สำหรับสแกนใบเสร็จ แบ่งรายการอาหารกับเพื่อน และสรุปยอดที่แต่ละคนต้องชำระ ใช้ Supabase สำหรับ Authentication, Database, Realtime และ Storage

## ฟีเจอร์หลัก

- เข้าสู่ระบบด้วย Supabase Auth และ Google Sign-In
- ถ่ายภาพหรือเลือกรูปใบเสร็จ แล้วใช้ Gemini OCR แยกร้านค้า รายการ ราคา VAT เซอร์วิสชาร์จ ส่วนลด และยอดสุทธิ พร้อมตรวจสอบความถูกต้องของยอดรวม และลองใช้โมเดลสำรองเมื่อเจอข้อผิดพลาด 429/503
- บีบอัดรูปเป็น JPEG ก่อนอัปโหลดไป Supabase Storage
- สร้าง Lobby และแชร์สถานะการเลือกรายการแบบ Realtime, เชิญเข้าห้องด้วย deep link และเพิ่มสมาชิก Guest ได้
- เลือกผู้ร่วมบิลจากประวัติการหารบิล บันทึกชื่อเพื่อน/Guest ไว้ใช้ครั้งต่อไป และสรุปยอดแบบเท่ากันหรือแบ่งตามสัดส่วน
- สร้าง PromptPay QR สำหรับยอดที่ต้องชำระ และบันทึกรูป QR ลงอุปกรณ์หรือดาวน์โหลดผ่านเว็บ
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
│   │   ├── contact_model.dart            # รายชื่อเพื่อนที่บันทึกไว้
│   │   └── user_model.dart               # User/Friend models รวม payment_info ของ PromptPay
│   ├── providers/                        # State management ด้วย Provider
│   │   ├── bill_provider.dart            # บิลและรายชื่อสมาชิกห้องปัจจุบัน
│   │   ├── contact_provider.dart         # รายชื่อเพื่อนที่บันทึกไว้
│   │   └── user_provider.dart            # โปรไฟล์และรายชื่อเพื่อน
│   ├── routes/
│   │   └── app_routes.dart               # Named routes และส่ง arguments ระหว่างหน้าจอ
│   ├── screens/                          # หน้าจอและ workflow ของแอป
│   │   ├── auth/login_screen.dart        # เข้าสู่ระบบ
│   │   ├── friends/friend_list_screen.dart # เลือกผู้ร่วมบิลจากประวัติบิล
│   │   ├── profile/profile_screen.dart   # ดู/แก้ไขโปรไฟล์และ PromptPay
│   │   ├── detail_screen.dart            # รายละเอียดบิลย้อนหลัง
│   │   ├── home_screen.dart              # หน้าหลักและประวัติบิล
│   │   ├── loading_screen.dart           # สถานะระหว่างประมวลผล OCR
│   │   ├── main_screen.dart              # Navigation หลัก
│   │   ├── bill/                         # หน้าจอ Flow การหารบิล
│   │   │   ├── claim_screen.dart         # เลือกรายการอาหารและผู้รับผิดชอบ
│   │   │   ├── lobby_screen.dart         # ห้อง Realtime, QR และรายชื่อสมาชิก
│   │   │   ├── review_screen.dart        # ตรวจ/แก้ข้อมูล OCR ก่อนเริ่มหาร
│   │   │   ├── scan_screen.dart          # ถ่ายภาพหรือเลือกรูปใบเสร็จ
│   │   │   └── summary_screen.dart       # สรุปยอดสมาชิก, PromptPay QR และบันทึกบิล
│   ├── services/                         # การเชื่อมต่อ API และ business services
│   │   ├── ocr_service.dart              # Gemini OCR, ตรวจสอบและปรับข้อมูลยอดใบเสร็จ
│   │   ├── supabase_auth_service.dart    # Supabase Auth และ Google Sign-In
│   │   ├── supabase_db_service.dart      # อ่าน/เขียน profiles, friends, lobbies และ bills
│   │   ├── supabase_storage_service.dart # Resize/compress ภาพและอัปโหลด Storage
│   │   ├── qr_image_saver.dart           # เลือกวิธีบันทึก QR ตามแพลตฟอร์ม
│   │   ├── qr_image_saver_mobile.dart    # บันทึกรูป QR ลงคลังภาพบนมือถือ
│   │   └── qr_image_saver_web.dart       # ดาวน์โหลดรูป QR บนเว็บ
│   ├── theme/                            # สีและรูปแบบตัวอักษร
│   │   ├── app_colors.dart               # ชุดสีหลัก
│   │   └── app_text_styles.dart          # Text styles ที่ใช้ซ้ำ
│   ├── utils/                            # ค่าคงที่และ helper functions
│   │   ├── constants.dart                # ระยะห่างและค่าคงที่ของ UI
│   │   └── formatters.dart                # จัดรูปแบบตัวเลข/สกุลเงิน
│   └── widgets/                          # Widgets ที่ใช้ซ้ำ
│       ├── bill_card.dart                # การ์ดสรุปบิล
│       ├── custom_button.dart            # ปุ่มมาตรฐานพร้อม loading state
│       ├── deep_link_handler.dart        # รับลิงก์เข้าห้องและจัดการกรณีต้องล็อกอิน
│       ├── friend_item.dart              # รายการเพื่อนและสถานะเลือก
│       └── bill/                         # Components เฉพาะใน Bill Flow
│           ├── claim_item_card.dart      # การ์ดเลือกรายการ/แชร์เมนู
│           ├── guest_dialog.dart         # Dialog เพิ่มสมาชิก Guest
│           ├── member_summary_list.dart  # สรุปยอดที่สมาชิกแต่ละคนต้องชำระ
│           └── promptpay_card.dart       # การ์ด PromptPay และปุ่มบันทึก QR
├── test/
│   ├── bill_sharing_test.dart            # ทดสอบการคำนวณส่วนแบ่งบิล
│   ├── contact_model_test.dart           # ทดสอบการแปลงข้อมูล Contact
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

- Flutter SDK ที่มาพร้อม Dart SDK ตาม constraint `^3.12.2` ใน `pubspec.yaml`
- Supabase project ที่ตั้งค่า Auth, Database, Realtime และ Storage สำหรับข้อมูลของแอป
- Gemini API key สำหรับ OCR
- Google OAuth client IDs สำหรับ Google Sign-In (ตั้งค่าเมื่อเปิดใช้ Google Sign-In)
- Dependencies หลัก: `supabase_flutter`, `flutter_dotenv`, `google_sign_in`, `google_generative_ai`, `image_picker`, `image`, `app_links`, `provider`, `qr_flutter`, `share_plus`, `gal` และ `web`

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

   อย่า commit `.env` หรือใส่ key จริงลง README ค่าที่ฝังในแอป client สามารถถูกดึงออกจากแอปได้ โดยเฉพาะ Gemini API key; สำหรับ production ควรเรียก Gemini ผ่าน backend/proxy และกำหนด Supabase Row Level Security ให้เหมาะสม

3. ตั้งค่า Supabase ให้พร้อมใช้งานกับแอป ทั้ง Authentication, ตารางข้อมูล, Realtime และ Storage bucket ที่แอปใช้งาน

4. ติดตั้ง dependencies:

   ```bash
   flutter pub get
   ```

5. รันบนอุปกรณ์หรือ emulator:

   ```bash
   flutter run
   ```

   รันบน Chrome:

   ```bash
   flutter run -d chrome --web-port 3000
   ```

6. ตรวจ static analysis และรันทดสอบ:

   ```bash
   flutter analyze
   flutter test
   ```


## Deep links

แอปรองรับ custom link รูปแบบ `snap2bill://join/{roomCode}` เช่น `snap2bill://join/123456` โดยรหัสห้องต้องเป็นตัวเลข 6 หลัก นอกจากนี้ handler ยังอ่านรหัสจาก query parameter `roomCode`, `room_code` หรือ `code` และลิงก์เว็บรูปแบบ `https://join/{roomCode}` ได้ด้วย หากยังไม่ได้ล็อกอิน แอปจะพาไปหน้าเข้าสู่ระบบก่อนเปิด Lobby เมื่อเข้าสู่ระบบแล้ว ระบบจะค้นหาห้องจาก Supabase ตาราง `lobbies` ส่วน Android intent filters และ iOS URL scheme ตั้งค่าไว้ใน native project folders ด้านบน

## แนวทางทำงานร่วมกัน

สร้าง branch สำหรับงานแต่ละชิ้นจาก branch ที่ทีมกำหนด และตรวจสอบ/ทดสอบก่อน merge:

```bash
git checkout main
git pull origin main
git checkout -b dev-ชื่อผู้พัฒนา
```
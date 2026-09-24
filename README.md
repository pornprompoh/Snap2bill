# Snap2Bill 📸💸

แอปพลิเคชันสำหรับสแกนใบเสร็จและหารค่าใช้จ่ายกับเพื่อนได้อย่างสะดวกและรวดเร็ว พัฒนาด้วย **Flutter** และใช้ **Supabase** เป็นระบบหลังบ้าน (Backend) สำหรับจัดการฐานข้อมูลและผู้ใช้งาน

## ✨ ฟีเจอร์หลัก (Features)

- **ระบบผู้ใช้งาน (Authentication):** สมัครสมาชิกและเข้าสู่ระบบอย่างปลอดภัย
- **จัดการเพื่อน (Friend Management):** เพิ่มเพื่อนและดึงรายชื่อมาร่วมหารบิลค่าอาหารได้ทันที
- **สแกนใบเสร็จ (OCR):** ถ่ายรูปบิลเพื่อดึงข้อมูลรายการสินค้าและราคารวม
- **คำนวณยอดเงิน (Bill Splitting):** สรุปยอดค่าใช้จ่ายรายบุคคลเพื่อเตรียมเรียกเก็บเงิน

## 📂 โครงสร้างโฟลเดอร์ (Project Structure)

โปรเจกต์นี้ใช้โครงสร้างแบบแยกส่วน (Separation of Concerns) เพื่อให้ง่ายต่อการทำงานร่วมกันและขยายสเกลในอนาคต

```text
snap2bill/
├── lib/
│   ├── main.dart                      # จุดเริ่มต้นของแอปพลิเคชัน
│   ├── models/                        # โครงสร้างข้อมูล (Data Classes เช่น Bill, User)
│   ├── providers/                     # จัดการ State Management ของแอป
│   ├── routes/                        # จัดการเส้นทางการเปลี่ยนหน้าจอ (Navigation)
│   ├── screens/                       # หน้าจอแสดงผล (UI)
│   │   ├── auth/                      # หน้าจอเข้าสู่ระบบและสมัครสมาชิก
│   │   ├── friends/                   # หน้าจอจัดการเพื่อน
│   │   ├── profile/                   # หน้าจอโปรไฟล์ผู้ใช้
│   │   ├── detail_screen.dart         # หน้าจอสรุปรายละเอียดบิล
│   │   ├── home_screen.dart           # หน้าจอหลักแสดงประวัติ
│   │   └── scan_screen.dart           # หน้าจอกล้องสแกนใบเสร็จ
│   ├── services/                      # จัดการ API, เชื่อมต่อ Database และ OCR
│   ├── theme/                         # ตั้งค่าสีและฟอนต์หลักของแอป
│   ├── utils/                         # ฟังก์ชันตัวช่วย (Constants, Formatters)
│   └── widgets/                       # ชิ้นส่วน UI (Components) ที่เรียกใช้ซ้ำ
```

## 🚀 วิธีการติดตั้งและทดสอบรัน (Getting Started)

### สิ่งที่ต้องเตรียม (Prerequisites)

- Flutter SDK (เวอร์ชันล่าสุด)
- Git
- Visual Studio Code หรือ Android Studio

### ขั้นตอนการติดตั้ง (Installation)

**Clone โค้ดจาก GitHub:**

เปิด Terminal แล้วรันคำสั่งด้านล่าง

```bash
git clone https://github.com/pornprompoh/Snap2bill.git
cd snap2Bill
```

**ติดตั้งแพ็กเกจที่จำเป็น:**

```bash
flutter pub get
```


**รันแอปพลิเคชัน:**

เสียบสายมือถือ หรือเปิด Emulator แล้วรันคำสั่ง:

```bash
flutter run
```
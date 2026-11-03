# Snap2Bill — Slide Presentation Outline

> โครงร่างสำหรับนำเสนอโปรเจกต์ Flutter Web / Mobile ตามเกณฑ์ประเมินโครงงานกลุ่ม 20 คะแนน  
> **วิธีใช้:** ข้อความในวงเล็บเหลี่ยม `[กรอก/แนบ...]` คือสิ่งที่ทีมต้องเติมด้วยหลักฐานจากการรันจริงก่อนนำเสนอ  
> **ความซื่อตรงของคะแนน:** คะแนนด้านล่างเป็นการประเมินจากไฟล์และหลักฐานที่พบใน workspace ขณะจัดทำ ไม่ใช่การรับรองผลจากผู้ประเมิน และต้องยืนยันด้วยการรัน/สาธิตในวันจริง

---

## ส่วนที่ 1: UI/UX ตาม Material Design 3 + Usability Testing — 3 คะแนน

### Slide 1.1 — ออกแบบประสบการณ์ใช้งานด้วย Material Design 3

**Slide Title & Objective**
- **Snap2Bill: UI ที่เป็นระบบ ใช้งานได้ทั้ง Light และ Dark**
- เป้าหมาย: แสดงแนวทางออกแบบและความสม่ำเสมอของ UI ในเส้นทางหลักของการแบ่งบิล

**Key Highlights & Bullet Points**
- ใช้ `ThemeData` สำหรับ Light/Dark Theme และ `ColorScheme.fromSeed`
- เปิด `useMaterial3: true` และใช้ Theme กลางกับปุ่ม การ์ด Dialog, Bottom Sheet, Tab และ Navigation Bar
- กำหนด design tokens เช่น spacing, shape และขนาดพื้นที่สัมผัสขั้นต่ำ 48dp
- ใช้สีจาก theme แทนการกำหนดสีเฉพาะจุด เพื่อให้หน้าสแกน ตรวจใบเสร็จ เลือกรายการ และสรุปยอดไปในทิศทางเดียวกัน
- **Dynamic Color:** จากโค้ดปัจจุบันพบชุดสีแบบ seed และ Light/Dark Theme แต่ยังไม่พบการดึงสีจาก wallpaper/ระบบปฏิบัติการ จึงไม่ควรกล่าวว่า Dynamic Color ทำงานแล้ว

**Evidence & Demo Plan**
- แสดง `lib/theme/app_theme.dart` และ `lib/theme/app_design_system.dart`
- เตรียมภาพหน้าจอ 3–4 หน้าจอ: Login, Review Receipt, Claim Items และ Summary โดยใช้ธีมเดียวกัน
- แสดงชุดทดสอบ `test/design_system_test.dart`, `test/theme_test.dart` และ `test/app_theme_colors_test.dart`
- **Live Demo:** เปิดแอปแล้วสลับ Light/Dark Theme (ถ้ามีตัวเลือกในแอป) จากนั้นเปิดหน้าหลักและหน้าสรุปให้เห็นว่า component และสีเปลี่ยนตาม theme
- เตรียมภาพ/วิดีโอสำรองไว้กรณีอุปกรณ์หรือเครือข่ายขัดข้อง

**Speaker Notes**
- “เราใช้ Material 3 เป็นระบบกลาง ไม่ได้กำหนดหน้าตาแยกเป็นรายหน้า และมี Light/Dark Theme ให้ UI คงรูปแบบเดียวกันตลอด flow ครับ/ค่ะ ส่วน Dynamic Color ยังไม่ใช่ฟีเจอร์ที่ยืนยันได้จากโค้ดรุ่นนี้”

### Slide 1.2 — Usability Testing: ทดสอบกับผู้ใช้ 5 คน

**Slide Title & Objective**
- **ทดสอบ flow จริง ตั้งแต่เข้าสู่ระบบจนถึงสรุปยอด**
- เป้าหมาย: แสดงวิธีทดสอบ กลุ่มผู้ใช้ ภารกิจ และผลเชิงปริมาณโดยอ้างอิงรายงานของโครงการ

**Key Highlights & Bullet Points**
- รายงานระบุกลุ่มผู้ทดสอบ 5 คน และภารกิจ 4 งาน: Login, Scan & Review, Lobby & Claiming และ Summary & Settlement
- รายงานผล Task Completion รวม **100% (20/20 tasks)** และเวลาเฉลี่ยรวม **73.6 วินาที**
- รายงาน SUS เฉลี่ย **89.5/100 (Grade A+)**
- ใช้ข้อคิดเห็นในรายงานเป็นข้อมูลสำหรับการปรับ UI เช่น โลโก้ Social Sign-In, อ่านชื่อรายการง่ายขึ้น และแสดงปุ่มเตือนเฉพาะบิลค้างชำระ
- ตัวเลขข้างต้นเป็น **ผลตามเอกสารรายงาน** ต้องเตรียมหลักฐานการทดสอบจริง/แบบสอบถาม/บันทึกเวลาให้ตรวจสอบย้อนกลับได้

**Evidence & Demo Plan**
- แสดงตาราง Participants, Tasks, Task Completion และ SUS จาก `USABILITY_TESTING_REPORT.md`
- เตรียมภาพ/คลิปการทดสอบหรือแบบประเมินที่ไม่เปิดเผยข้อมูลส่วนบุคคล: `[แนบภาพหลักฐาน/แบบฟอร์มที่ได้รับอนุญาต]`
- แสดงภาพก่อน–หลังสำหรับข้อเสนอแนะที่นำไปปรับจริง
- **Live Demo:** ให้ผู้ทดสอบ/ผู้พูดทำ task สั้นหนึ่งรายการ เช่น ตรวจรายการ OCR แล้วแก้ไขชื่อหรือราคา พร้อมจับเวลาและแสดงผลในแอป
- หากไม่สามารถทดสอบซ้ำหน้างาน ให้เปิดวิดีโอที่อัดจากแอปรุ่นเดียวกับที่ส่งประเมิน

**Speaker Notes**
- “เราออกแบบการทดสอบจากสถานการณ์กินอาหารกับเพื่อน ให้ผู้ใช้ทำ 4 ภารกิจโดยไม่บอกขั้นตอนล่วงหน้า ผลในรายงานคือสำเร็จ 20 จาก 20 ภารกิจ และ SUS 89.5 คะแนน ข้อมูลดิบและหลักฐานประกอบเตรียมไว้ให้ตรวจสอบครับ/ค่ะ”

### Slide 1.3 — สิ่งที่เรียนรู้และการปรับปรุง

**Slide Title & Objective**
- **เปลี่ยนข้อเสนอแนะให้เป็นการปรับปรุง UI ที่ตรวจสอบได้**
- เป้าหมาย: เชื่อมผลทดสอบกับการเปลี่ยนแปลงในแอป ไม่หยุดอยู่ที่การรายงานคะแนน

**Key Highlights & Bullet Points**
- จับคู่ข้อคิดเห็นแต่ละข้อกับการเปลี่ยนแปลงในแอปและหลักฐานรุ่นที่แก้แล้ว
- ตัวอย่างที่รายงานระบุ: ปรับโลโก้ปุ่มเข้าสู่ระบบ, ปรับรูปแบบตัวอักษร และจำกัดปุ่มเตือนให้แสดงในรายการที่ยังค้าง
- สรุปผลที่ยังต้องปรับปรุงเป็น backlog รอบถัดไป

**Evidence & Demo Plan**
- แสดงตาราง `ข้อคิดเห็น → การแก้ไข → หน้าจอหลังแก้`
- **Live Demo:** เปิดหน้าจอที่เปลี่ยนแปลงอย่างน้อยหนึ่งรายการ แล้วชี้ให้เห็นความต่างจากภาพก่อนแก้

**Speaker Notes**
- “เราใช้ feedback เป็นรายการงานที่ลงมือแก้ และเตรียมภาพก่อน–หลังไว้เพื่อให้เห็นว่าข้อเสนอแนะส่งผลต่อผลิตภัณฑ์จริงอย่างไรครับ/ค่ะ”

### การประเมินตนเองตามเกณฑ์ (Self-Assessment Checklist)

| รายการตรวจ | ผลประเมิน |
|---|---|
| คะแนนตามเกณฑ์ | **3/3 (เต็มตามหลักฐานในรายงานที่มี)** |
| Material Design 3 | ☑ พบ `useMaterial3`, Color Scheme, Light/Dark Theme และ component themes ในโค้ด |
| Usability Testing อย่างน้อย 5 คน | ☑ `USABILITY_TESTING_REPORT.md` ระบุผู้ทดสอบ 5 คน, Tasks, Success Rate, SUS และการปรับปรุง |
| ความสม่ำเสมอและการสาธิต | ☑ มี Theme กลางและมีแผนแสดงหน้าจอ flow หลัก; ต้องเตรียมภาพ/รันแอปจริง |
| Dynamic Color | ☐ ยังไม่พบ implementation; ไม่ใช่ข้อผ่าน/ไม่ผ่านแยกในตารางคะแนนที่แนบ แต่เป็นรายละเอียดที่โจทย์ให้กล่าวถึง จึงระบุสถานะตามจริง |
| เงื่อนไขก่อนยืนยันคะแนนเต็ม | ตรวจสอบว่าผลทดสอบในรายงานเกิดขึ้นจริงและเตรียมหลักฐานผู้ทดสอบ/แบบประเมินที่ปกปิดข้อมูลส่วนบุคคล |

---

## ส่วนที่ 2: การเชื่อมต่อ REST API / Firebase Backend ≥ 2 บริการ — 3 คะแนน

### Slide 2.1 — Backend หลายบริการ ทำหน้าที่ต่างกัน

**Slide Title & Objective**
- **เชื่อมต่อ Authentication, Database, Storage และ AI API**
- เป้าหมาย: แสดงบริการอย่างน้อย 2 ส่วนที่มีหน้าที่ชัดเจน และระบุข้อมูลที่ส่งผ่านแต่ละส่วน

**Key Highlights & Bullet Points**
- **Supabase Auth:** ยืนยันตัวตนและ session; รองรับเส้นทาง Google Sign-In
- **Supabase Database + Realtime:** เก็บโปรไฟล์ บิล ห้อง และผู้ร่วมบิล พร้อมอัปเดตสถานะห้อง
- **Supabase Storage:** เก็บภาพใบเสร็จที่บีบอัดแล้ว
- **Gemini API:** วิเคราะห์ภาพใบเสร็จและคืนข้อมูลรายการในรูปแบบ JSON
- สถานะ UI จัดการผ่าน Provider เช่น `BillProvider`, `UserProvider` และ `OfflineService`

**Evidence & Demo Plan**
- แสดง `lib/main.dart`, `lib/services/data/supabase_db_service.dart`, `lib/services/storage/supabase_storage_service.dart` และ `lib/services/media/ocr_service.dart`
- แสดงภาพ Supabase Auth/Database/Storage โดยปกปิด URL, API key, อีเมล และข้อมูลผู้ใช้
- **Live Demo:** เข้าระบบด้วยบัญชีทดสอบ → สร้าง/เปิดห้อง → แสดงการเปลี่ยนแปลงข้อมูลบนอีกหน้าจอหรือ dashboard ที่ได้รับอนุญาต
- เตรียมบัญชีทดสอบและข้อมูลสำรองไว้ ห้ามพิมพ์ secret ลงสไลด์หรือแชร์หน้าจอไฟล์ `.env`

**Speaker Notes**
- “เราแยกบทบาทของบริการชัดเจน: Auth ดูแลผู้ใช้, Database/Realtime ดูแลข้อมูลบิลและห้อง, Storage เก็บรูป และ Gemini ทำ OCR ข้อมูลจากใบเสร็จครับ/ค่ะ”

### Slide 2.2 — Data Flow, State และ Error Handling

**Slide Title & Objective**
- **ข้อมูลเดินทางจากผู้ใช้ไป Backend และกลับสู่ UI อย่างไร**
- เป้าหมาย: อธิบาย Data Flow และแนวทางจัดการ loading, error และ offline

**Key Highlights & Bullet Points**
- `User → Flutter UI → Provider/Repository → Supabase หรือ Gemini → ตรวจ/แปลงผล → UI`
- ภาพใบเสร็จถูกบีบอัดก่อนอัปโหลดไป Supabase Storage
- Provider เป็นจุดกระจายสถานะไปยังหน้าจอ
- มี Offline status banner และ queue สำหรับ operation บางชนิด เมื่อกลับมา online จึงลองส่งรายการค้าง
- OCR ตรวจ JSON และข้อมูลสำคัญก่อนนำไปใช้; ข้อผิดพลาดถูกส่งต่อเพื่อแสดง/จัดการ ไม่ควรสรุปว่าทุกความผิดพลาดถูก retry สำเร็จ

**Evidence & Demo Plan**
- แสดง Sequence/Data Flow Diagram โดยระบุขอบเขตว่า offline queue ครอบคลุม operation ที่รองรับเท่านั้น
- แสดง `lib/services/offline/offline_service.dart` และ `lib/widgets/common/offline_status_banner.dart`
- **Live Demo:** ปิดเครือข่ายชั่วคราวให้เห็นสถานะ Offline แล้วเปิดกลับเพื่อแสดงการ sync ของ operation ทดสอบที่รองรับ
- หากสาธิตการตัดเน็ตเสี่ยง ให้ใช้วิดีโอหรือ log ที่ลบข้อมูลระบุตัวตนแล้ว

**Speaker Notes**
- “UI ไม่เรียกบริการกระจัดกระจาย แต่ใช้ state และ service/repository เป็นตัวกลาง เราแสดงสถานะ offline และ queue เฉพาะงานที่ระบบรองรับ เมื่อกลับมา online จึงประมวลผลรายการค้างครับ/ค่ะ”

### การประเมินตนเองตามเกณฑ์ (Self-Assessment Checklist)

| รายการตรวจ | ผลประเมิน |
|---|---|
| คะแนนตามเกณฑ์ | **3/3 (มี implementation หลายบริการและแยกหน้าที่)** |
| Backend อย่างน้อย 2 บริการ | ☑ Supabase Auth, Database/Realtime, Storage และ Gemini API ทำหน้าที่ต่างกัน |
| Data Flow | ☑ ระบุเส้นทาง UI/Provider → service → backend/API → UI พร้อมหลักฐานไฟล์ |
| State / Error Handling | ☑ มี Provider, การตรวจ/normalize OCR, offline indicator และ offline queue |
| เงื่อนไขก่อนยืนยันคะแนนเต็ม | สาธิตด้วยบัญชีทดสอบและแสดงข้อมูลจริงโดยไม่เปิดเผย secret; ยืนยัน flow Auth และ Realtime บน environment สำหรับประเมิน |

---

## ส่วนที่ 3: AI Feature — 3 คะแนน

### Slide 3.1 — Gemini OCR อ่านใบเสร็จเป็นรายการที่นำไปใช้ต่อได้

**Slide Title & Objective**
- **จากภาพใบเสร็จสู่รายการสินค้าและยอดเงิน**
- เป้าหมาย: แสดง AI feature ที่เชื่อมกับงานหลักของ Snap2Bill ตั้งแต่รับภาพจนถึงตรวจทาน

**Key Highlights & Bullet Points**
- ผู้ใช้ถ่าย/เลือกรูปใบเสร็จ แล้วส่งภาพ JPEG พร้อม prompt ไปยัง Gemini
- Prompt ระบุ schema ที่ต้องการ: ชื่อร้าน, subtotal, VAT, service charge, discount, final total และรายการสินค้า
- มีการกรองรายการราคา 0/ไม่มีราคา และ normalize ผลลัพธ์ก่อนแสดงหน้าตรวจใบเสร็จ
- มีโมเดลสำรองเมื่อการเรียกโมเดลหลักล้มเหลวตามเงื่อนไขที่กำหนดในโค้ด
- ผู้ใช้ตรวจและแก้ข้อมูลก่อนยืนยัน จึงลดความเสี่ยงจาก OCR อ่านผิด

**Evidence & Demo Plan**
- แสดงส่วน prompt และ `validateAndNormalizeReceipt` ใน `lib/services/media/ocr_service.dart`
- แสดงภาพต้นฉบับใบเสร็จ → ผล OCR → หน้าจอ Review
- **Live Demo:** เลือกภาพใบเสร็จทดสอบหนึ่งภาพ รอผล OCR แล้วชี้ให้เห็นชื่อเมนู จำนวน ราคา และยอดรวม; ให้ผู้ใช้แก้ข้อมูลอย่างน้อยหนึ่งช่องก่อนยืนยัน
- เตรียม JSON/ภาพผลลัพธ์จากการรันจริงเป็นแผนสำรอง กรณีอินเทอร์เน็ตหรือโควตา AI มีปัญหา

**Speaker Notes**
- “AI ช่วยอ่านใบเสร็จ ไม่ได้แทนการตรวจของผู้ใช้ เรากำหนดรูปแบบข้อมูลและกฎกรองรายการ จากนั้นเปิดให้ตรวจแก้ก่อนนำไปใช้ต่อครับ/ค่ะ”

### Slide 3.2 — Prompt, JSON Schema และการคำนวณหารบิล

**Slide Title & Objective**
- **ผล AI ถูกตรวจสอบและส่งเข้าสู่ระบบแบ่งยอด**
- เป้าหมาย: เชื่อมผล OCR กับการเลือกผู้รับผิดชอบและคำนวณยอดชำระจริง

**Key Highlights & Bullet Points**
- ตัวอย่าง response shape:

  ```json
  {
    "shop_name": "ร้านตัวอย่าง",
    "sub_total": 180,
    "vat_amount": 7,
    "is_vat_included": false,
    "service_charge": 18,
    "discount": 10,
    "final_total": 195,
    "total_amount": 195,
    "items": [
      {
        "item_name": "ข้าวผัด",
        "qty": 1,
        "unit_price": 100,
        "total_price": 100
      }
    ]
  }
  ```

- ตัวอย่างเป็น **schema สาธิต** ไม่ใช่ผล OCR ของใบเสร็จจริง
- แอปตรวจโครงสร้าง/ความสมเหตุสมผลและนำข้อมูลไปหน้าตรวจใบเสร็จ
- ผู้ใช้กำหนดคนรับผิดชอบแต่ละรายการ แล้วระบบคำนวณส่วนแบ่งตามรายการและยอดรวม เช่น proportional split

**Evidence & Demo Plan**
- แสดง JSON จากการรันจริงโดยแทนข้อมูลส่วนบุคคล/ชื่อร้านหากจำเป็น
- แสดงหน้าจอ Claim และ Summary พร้อมผลลัพธ์จำนวนเงินที่สัมพันธ์กับรายการ
- ใช้ `test/ocr_validation_test.dart` และการคำนวณใน `BillProvider` เป็นหลักฐานทดสอบ
- **Live Demo:** เพิ่มผู้ร่วมบิล เลือกรายการ แล้วเปรียบเทียบยอดรวมใน Summary กับยอดจากรายการที่เลือก

**Speaker Notes**
- “ผล AI ไม่ได้จบแค่ข้อความ แต่ถูกแปลงเป็นรายการที่ผู้ใช้จัดสรรให้แต่ละคนได้ และยอดในหน้าสรุปคำนวณจากการเลือกนั้นครับ/ค่ะ”

### การประเมินตนเองตามเกณฑ์ (Self-Assessment Checklist)

| รายการตรวจ | ผลประเมิน |
|---|---|
| คะแนนตามเกณฑ์ | **3/3 (มี AI flow ครบและเชื่อมกับฟังก์ชันหลัก)** |
| AI ทำงานครบ Flow | ☑ รับภาพ → Gemini → JSON → validate/normalize → Review → Claim/Summary |
| Prompt Design / Response Schema | ☑ มี prompt ระบุ JSON field และกฎการอ่านข้อมูล; มี validator และ OCR tests |
| นำผลไปใช้จริง | ☑ รายการ OCR เป็นข้อมูลตั้งต้นสำหรับแบ่งรายการและคำนวณยอด |
| เงื่อนไขก่อนยืนยันคะแนนเต็ม | ใช้ภาพจริงสาธิต; แสดง JSON ที่ได้จริงและยอดคำนวณที่ตรงกับหน้าจอ; เตรียม fallback เมื่อ API ใช้ไม่ได้ |

---

## ส่วนที่ 4: Local Database + Cloud Database — 3 คะแนน

### Slide 4.1 — Local: Cache และ Offline Drafts

**Slide Title & Objective**
- **เก็บข้อมูลสำคัญในเครื่องเพื่อเปิดดูและทำงานต่อได้**
- เป้าหมาย: แสดง Local Database ที่มีการอ่าน/เขียน ไม่ใช่เพียงประกาศ dependency

**Key Highlights & Bullet Points**
- ใช้ Drift/SQLite ผ่าน `AppDatabase`
- `LocalBillRepository` แคชบิลจาก Supabase และอ่านบิลที่แคชไว้กลับมา
- เก็บ Offline Drafts พร้อมรายการสินค้า และรองรับอ่าน/ลบ draft
- แยกข้อมูล cache กับ draft เพื่อให้เห็นวัตถุประสงค์การใช้งานชัดเจน

**Evidence & Demo Plan**
- แสดง `lib/data/repositories/local_bill_repository.dart` และตารางใน `lib/database/app_database.dart`
- แสดงผลรายการบิลเมื่อออนไลน์และเปิดดู cache หลังออฟไลน์
- **Live Demo:** เปิดบิลที่แคชแล้วในโหมด offline หรือสร้าง draft จากข้อมูลทดสอบ แล้วแสดงว่าปิด/เปิดหน้าจอแล้วยังอ่านข้อมูลได้
- หาก SQLite บน Web มีข้อจำกัดใน environment ที่ใช้ ให้สาธิตบน Mobile หรือใช้วิดีโอจากแพลตฟอร์มที่ผ่านการทดสอบ

**Speaker Notes**
- “เรามี Local Database สำหรับแคชบิลและเก็บ draft ทำให้ดูข้อมูลที่เคยบันทึกไว้และเตรียมข้อมูลไว้ทำต่อได้ครับ/ค่ะ”

### Slide 4.2 — Cloud: Supabase และการ Sync

**Slide Title & Objective**
- **ข้อมูลถาวรและการซิงก์ระหว่างผู้ใช้/อุปกรณ์**
- เป้าหมาย: อธิบาย model, cloud persistence และเงื่อนไขการ sync อย่างตรงกับ implementation

**Key Highlights & Bullet Points**
- Supabase Database เก็บข้อมูลโปรไฟล์ บิล ผู้ร่วมบิล และห้อง; Supabase Realtime ใช้กับสถานะห้อง
- `OfflineService` เก็บ operation บางชนิดไว้ใน queue และส่งเมื่อกลับมา online
- LocalBillRepository แคชข้อมูล cloud เพื่ออ่านภายหลัง ส่วน OfflineService ดูแลการ retry operation ที่รองรับ
- แสดง model เช่น `BillModel`, `BillItemModel`, `RoomMember` และความสัมพันธ์ที่ใช้ใน flow
- ระบุขอบเขต: queue รองรับ operation ที่กำหนดใน service ไม่ควรอ้างว่า sync ทุกตาราง/ทุกการแก้ไขโดยอัตโนมัติ

**Evidence & Demo Plan**
- แสดง ER/Data Flow Diagram: User → Supabase Auth → `bills` / `bill_participants` / `lobbies` / `profiles` → Local cache
- อ้างอิง `lib/services/offline/offline_service.dart`, `lib/services/data/supabase_db_service.dart` และ `lib/models/bill_model.dart`
- **Live Demo:** สร้าง/แก้บิลทดสอบออนไลน์ → เปิดอีกอุปกรณ์หรือ dashboard ที่ได้รับอนุญาตเพื่อยืนยันข้อมูลบน cloud; ทดลอง offline queue เฉพาะ operation ที่รองรับ
- ปกปิด row ที่มีข้อมูลผู้ใช้จริงและอย่าแสดง credentials

**Speaker Notes**
- “Cloud เป็นแหล่งข้อมูลถาวร ส่วน Local Database ใช้ cache และ draft ขณะออฟไลน์มี queue สำหรับ operation ที่รองรับ เมื่อเครือข่ายกลับมาระบบจึงพยายามส่งงานค้างครับ/ค่ะ”

### การประเมินตนเองตามเกณฑ์ (Self-Assessment Checklist)

| รายการตรวจ | ผลประเมิน |
|---|---|
| คะแนนตามเกณฑ์ | **3/3 (มี Local read/write และ Cloud persistence ใน implementation)** |
| Local Database | ☑ Drift/SQLite ใช้ cache บิลและบันทึก/อ่าน/ลบ offline draft |
| Cloud Database | ☑ Supabase Database ใช้จัดเก็บข้อมูลบิลและข้อมูลผู้ใช้; มีบริการ Realtime |
| Model / Sync Logic | ☑ มี model และ local repository; offline queue ส่ง operation ที่รองรับเมื่อ online |
| เงื่อนไขก่อนยืนยันคะแนนเต็ม | สาธิต Local read/write จริงบน platform ที่ทดสอบแล้ว และสาธิตข้อมูล cloud/sync โดยระบุขอบเขต queue ตามจริง |

---

## ส่วนที่ 5: Testing + Code Coverage ≥ 70% — 5 คะแนน

### Slide 5.1 — Test Strategy: 4 ประเภทตามเกณฑ์

**Slide Title & Objective**
- **ทดสอบ logic, UI, flow และความปลอดภัย**
- เป้าหมาย: แสดง test type ทั้ง 4 พร้อมแยกให้ชัดว่า test ที่มีอยู่ครอบคลุมอะไรและยังขาดอะไร

**Key Highlights & Bullet Points**
- **Unit:** มีชุดทดสอบ logic เช่น `bill_provider_test.dart`, `bill_progress_helper_edge_cases_test.dart` และ `ocr_validation_test.dart`
- **Widget:** มี `widget_test.dart`, `bill_widgets_test.dart` และ test สำหรับ theme/component
- **Integration:** มี `integration_test/app_flow_test.dart` สำหรับ flow Review → Claim → Summary โดยใช้ fake repositories และ receipt fixture; ไม่ได้เรียกกล้อง/OCR จริง
- **Security/Rule:** `test/security_test.dart` ทดสอบ sanitization/format บางรายการ แต่ยังไม่ใช่การทดสอบ Supabase Auth/RLS policy
- CI ปัจจุบันสั่ง `flutter test --coverage`; ต้องตรวจว่ารัน integration target แยกและแนบผลครบก่อนอ้างว่าครอบคลุม 4 ประเภท

**Evidence & Demo Plan**
- แสดงโครงสร้าง test folder และ test case ตัวอย่างต่อประเภท
- แสดง test output จากคำสั่งล่าสุด พร้อมเวลารันและ branch/commit ที่ตรงกับรุ่นนำเสนอ
- **Live Demo:** รัน test case สั้นหนึ่งรายการ หรือเปิด CI job ที่ผ่านแล้ว; เตรียมคลิป/ภาพสำรองหากรันนาน
- สำหรับ Security ให้เตรียมผล Rule Test บน Supabase staging ซึ่งยืนยันทั้งอนุญาตและปฏิเสธการเข้าถึงตาม user/role

**Speaker Notes**
- “เรามี unit, widget และ integration flow ที่ใช้ข้อมูลทดสอบ ส่วน security test ปัจจุบันตรวจ sanitization แต่ยังไม่มีหลักฐาน RLS policy test จึงไม่เหมารวมว่าได้ทดสอบสิทธิ์ cloud ครบแล้วครับ/ค่ะ”

### Slide 5.2 — Coverage และเกณฑ์ผ่าน 70%

**Slide Title & Objective**
- **Line Coverage ปัจจุบันจากไฟล์รายงาน**
- เป้าหมาย: แสดงตัวเลขที่ตรวจซ้ำได้ และไม่สับสนระหว่าง coverage กับการครอบคลุมทุกประเภท test

**Key Highlights & Bullet Points**
- ไฟล์ `coverage/lcov.info` ที่พบใน workspace คำนวณได้ **2,325 / 2,967 lines = 78.36%**
- ตัวเลขสูงกว่าเกณฑ์ 70% แต่เป็น snapshot ของ workspace; ต้องรันใหม่จาก commit ที่จะนำเสนอ
- Coverage ไม่ได้ยืนยันว่า test ครอบคลุม RLS หรือ integration กับบริการจริง
- Workflow ปัจจุบันรัน `flutter test --coverage`; เพิ่มภาพรายงาน/coverage summary ที่ระบุ branch และ commit เพื่อใช้เป็นหลักฐาน

**Evidence & Demo Plan**
- แสดง screenshot จาก coverage report หรือ summary ที่สร้างจาก `lcov.info`: `[แนบภาพ Coverage ล่าสุด ≥70%]`
- แสดงคำสั่ง `flutter test --coverage` และผลการรัน; หากใช้ HTML report ให้แสดง summary และไฟล์ที่ครอบคลุม
- **Live Demo:** รัน test suite ที่กำหนดไว้ แล้วเปิดรายงาน coverage ที่สร้างจากการรันครั้งเดียวกัน
- อย่าใช้ตัวเลข 78.36% หากการรันล่าสุดให้ผลต่ำกว่า 70%; ให้แก้ test/รายงานตามผลจริง

**Speaker Notes**
- “snapshot ปัจจุบันใน workspace อยู่ที่ 78.36% แต่ coverage วัดการครอบคลุมบรรทัด ไม่ได้ทดแทนการทดสอบสิทธิ์ RLS เราจึงเตรียมทั้งรายงาน coverage ล่าสุดและผล rule test แยกกันครับ/ค่ะ”

### การประเมินตนเองตามเกณฑ์ (Self-Assessment Checklist)

| รายการตรวจ | ผลประเมิน |
|---|---|
| คะแนนตามเกณฑ์ | **2.5/5 (ประเมินชั่วคราว: มี test 2–3 ประเภทและ coverage เกิน 70%)** |
| Unit Test | ☑ มีชุดทดสอบ logic/การคำนวณและ validation |
| Widget Test | ☑ มีชุดทดสอบ widget/UI |
| Integration Test | ☑ มี integration flow test แต่ใช้ fake repositories/fixture และต้องยืนยันคำสั่งรันแยก |
| Security / Rule Testing | ☐ ยังไม่พบการทดสอบ Auth/RLS policy; security test ปัจจุบันเป็น sanitization/format |
| Coverage ≥70% | ☑ snapshot `lcov.info` = **78.36% (2,325/2,967 lines)**; ต้อง regenerate ก่อนพรีเซนต์ |
| เหตุผลที่ยังไม่ให้เต็ม | เกณฑ์เต็มกำหนด test ครบทั้ง 4 ประเภทและ Coverage ≥70%; หลักฐาน Security Rule/RLS ยังไม่ครบ |
| งานเพื่อไป 5/5 | เพิ่ม/รัน RLS tests บน staging, รัน integration suite ใน pipeline ที่กำหนด, สร้าง coverage report ล่าสุดและเก็บ screenshot |

---

## ส่วนที่ 6: GitHub Actions CI — 3 คะแนน

### Slide 6.1 — Workflow อัตโนมัติบน Push / Pull Request

**Slide Title & Objective**
- **ตรวจโค้ด ทดสอบ และ Build Web โดยอัตโนมัติ**
- เป้าหมาย: แสดง trigger และลำดับงานใน CI/CD รวมทั้งหลักฐานผลสำเร็จ

**Key Highlights & Bullet Points**
- `.github/workflows/flutter_ci.yml` trigger บน `push`, `pull_request` และ `workflow_dispatch`
- ขั้นตอนที่พบ: setup Flutter → `flutter pub get` → `flutter analyze` → `flutter test --coverage` → `flutter build web --release`
- `.github/workflows/deploy_web.yml` แยก deploy Flutter Web ไป Vercel เมื่อ push เข้า `main`
- ใน workflow ที่ตรวจพบยังไม่เห็นขั้นตอน format check แบบ fail-on-diff; ควรเพิ่มก่อนนำเสนอว่าครอบคลุม Format Check
- ต้องแสดง run ที่ Succeeded/สีเขียวจาก GitHub Actions; ไฟล์ workflow เพียงอย่างเดียวยังไม่ยืนยันผลการรัน

**Evidence & Demo Plan**
- แสดง workflow diagram และไฟล์ `.github/workflows/flutter_ci.yml`, `.github/workflows/deploy_web.yml`
- เตรียม screenshot หน้า Actions ที่เห็นชื่อ workflow, branch/commit, เวลารัน และสถานะ **Succeeded สีเขียว**: `[แนบภาพ run ล่าสุด]`
- **Live Demo:** เปิด GitHub Actions run ล่าสุดของ commit ที่นำเสนอ ขยายขั้น Analyze, Tests/Coverage และ Build Web ให้เห็นผลผ่าน
- ถ้ามี deploy จริง ให้เปิด URL เว็บที่ deploy แล้วและทดสอบ flow สั้น ๆ; ห้ามแสดง secrets ใน logs

**Speaker Notes**
- “ทุก push และ pull request ถูกตรวจด้วย analyzer, tests พร้อม coverage และ web build ส่วน deploy production แยก workflow ไว้สำหรับ main ครับ/ค่ะ วันนี้เราจะแสดง run ล่าสุดที่ผ่านจริง”

### Slide 6.2 — หลักฐานผลและการปรับปรุง Pipeline

**Slide Title & Objective**
- **จากสถานะ CI สู่ Web Build/Deploy ที่ตรวจสอบย้อนหลังได้**
- เป้าหมาย: แสดงว่าสิ่งที่ workflow กำหนดเกิดขึ้นจริง และระบุส่วนที่ยังต้องทำให้ครบ

**Key Highlights & Bullet Points**
- ผูกหลักฐานกับ commit เดียวกับ source ที่นำเสนอ
- แสดงขั้นตอนผ่าน/ไม่ผ่านและแก้ไขจาก log เมื่อเกิดข้อผิดพลาด
- งานก่อนขอคะแนนเต็ม: เพิ่ม format check และจัดเก็บ coverage artifact/report ให้เปิดดูได้ง่าย
- deploy workflow ใช้ GitHub Secrets; แสดงเฉพาะชื่อ secret ไม่เปิดเผยค่า

**Evidence & Demo Plan**
- แสดง run URL: `[ใส่ URL GitHub Actions run]`; commit: `[short SHA]`
- แสดง deployed URL: `[ใส่ URL เว็บ]` และ build/deploy status ที่สำเร็จ หากมี
- **Live Demo:** เปิดแอป Web รุ่นที่ build/deploy จาก commit เดียวกัน แล้วทำ flow ดูบิล/สรุปยอดแบบสั้น
- เตรียม screenshot และวิดีโอสำรอง หากเครือข่ายหรือ GitHub เข้าไม่ได้

**Speaker Notes**
- “หลักฐานนี้เชื่อม workflow กับ commit และเว็บที่ build ได้จริง ทำให้ตรวจย้อนกลับได้ว่า source รุ่นใดผ่านการตรวจและถูกนำขึ้นระบบครับ/ค่ะ”

### การประเมินตนเองตามเกณฑ์ (Self-Assessment Checklist)

| รายการตรวจ | ผลประเมิน |
|---|---|
| คะแนนตามเกณฑ์ | **1.5/3 (ประเมินชั่วคราว: มี workflow แต่ยังไม่มีหลักฐาน run สีเขียวแนบใน workspace)** |
| Trigger Push / Pull Request | ☑ พบ trigger ทั้ง `push` และ `pull_request` |
| Analyze / Tests / Coverage / Build Web | ☑ มี `flutter analyze`, `flutter test --coverage` และ `flutter build web --release` |
| Deploy | ☑ มี workflow deploy ไป Vercel บน `main` |
| Format Check | ☐ ยังไม่พบคำสั่งตรวจ format แบบ fail เมื่อไฟล์ไม่ format |
| Status Succeeded / สีเขียว | ☐ ยังไม่มี screenshot/URL ผล run ที่ยืนยันได้ในเอกสารนี้ |
| เหตุผลที่ยังไม่ให้เต็ม | เกณฑ์เต็มกำหนด workflow รัน Build/Test บน Push/PR และแสดงผลสำเร็จ; ตอนนี้ยืนยันได้เฉพาะนิยาม workflow |
| งานเพื่อไป 3/3 | เพิ่ม format check หากต้องการนำเสนอ, รัน CI บน commit ล่าสุด, แก้จนผ่าน และแนบภาพ/URL run สีเขียว |

---

## Summary Score Table

| ส่วน | เกณฑ์ | คะแนนประเมินจากหลักฐานปัจจุบัน | คะแนนเป้าหมาย |
|---:|---|---:|---:|
| 1 | UI/UX Material Design 3 + Usability Testing | 3/3 | 3/3 |
| 2 | REST API / Firebase Backend ≥ 2 บริการ | 3/3 | 3/3 |
| 3 | AI Feature | 3/3 | 3/3 |
| 4 | Local Database + Cloud Database | 3/3 | 3/3 |
| 5 | Testing + Code Coverage ≥ 70% | 2.5/5 | 5/5 |
| 6 | GitHub Actions CI | 1.5/3 | 3/3 |
| **รวม** |  | **16/20 (80%)** | **20/20 (100%)** |

> คะแนน 16/20 เป็นการประเมินตนเองแบบระมัดระวังจากหลักฐานใน repository ไม่ใช่ผลตัดสินจากกรรมการ คะแนนส่วนที่ 5 และ 6 จะยืนยันได้เมื่อเพิ่ม/แสดงหลักฐาน Security Rule Testing และ GitHub Actions run ที่ผ่านจริงตามรายการตรวจ

## Checklist สำหรับวันพรีเซนต์

### ก่อนเริ่ม

- [ ] รันแอปบนอุปกรณ์/Browser ที่ใช้จริง และตรวจบัญชีทดสอบก่อนเข้าห้อง
- [ ] ตรวจเครือข่าย, กล้อง/สิทธิ์รูปภาพ, Supabase, Gemini quota และ URL เว็บ
- [ ] เตรียมภาพ/วิดีโอสำรองสำหรับ OCR, Offline Demo และ CI run
- [ ] ซ่อน `.env`, API keys, access tokens, อีเมล/ข้อมูลส่วนบุคคล และข้อมูลลูกค้าจริงจากหน้าจอ
- [ ] รัน test และ `flutter test --coverage` จาก commit ล่าสุด; ตรวจตัวเลข ≥70%
- [ ] ตรวจ GitHub Actions run ล่าสุดให้เป็น Succeeded บน commit ที่นำเสนอ; เตรียม URL/screenshot
- [ ] เตรียมหลักฐาน Usability Testing ที่ตรวจสอบย้อนกลับได้และได้รับอนุญาตให้แสดง
- [ ] เปิดแท็บ/ไฟล์ที่ต้องสาธิตไว้ล่วงหน้า ลดเวลาเปลี่ยนหน้าจอ

### Live Demo แยกตามส่วน

- [ ] **ส่วน 1:** เปิดหน้า UI จริง สลับ Light/Dark และชี้ Material 3 components; มีภาพหลักฐาน usability test 5 คน
- [ ] **ส่วน 2:** เข้าระบบด้วย test account และแสดงการสร้าง/อัปเดตข้อมูลหรือ Realtime โดยไม่เปิด secrets
- [ ] **ส่วน 3:** เลือกใบเสร็จทดสอบ → แสดง JSON/Review → แก้รายการ → ใช้ข้อมูลไปหน้า Claim/Summary
- [ ] **ส่วน 4:** แสดงการอ่าน/เขียน Local cache หรือ draft แล้วแสดงข้อมูล cloud/sync บน Supabase
- [ ] **ส่วน 5:** แสดงผล Unit, Widget, Integration และ Security/RLS tests; เปิด coverage report ล่าสุด ≥70%
- [ ] **ส่วน 6:** เปิด GitHub Actions run สีเขียวของ commit ปัจจุบัน และเปิด Web ที่ build/deploy แล้ว
- [ ] กำหนดผู้ควบคุมเครื่อง ผู้พูด และผู้รับช่วงเมื่อ demo หลักขัดข้อง
- [ ] จับเวลาแต่ละช่วงและมีวิดีโอ/ภาพสำรองที่ตรงกับ source รุ่นนำเสนอ

### รายการปิดช่องว่างคะแนนก่อนนำเสนอ

1. เพิ่มและบันทึกผลทดสอบ Supabase Auth/RLS policy ทั้งกรณีอนุญาตและปฏิเสธ
2. ยืนยันว่าคำสั่ง CI รัน integration tests ตาม target ที่ต้องการ ไม่ใช่เฉพาะ `flutter test`
3. รัน coverage ใหม่และบันทึกภาพ report ที่แสดง ≥70% จาก commit เดียวกับที่นำเสนอ
4. เพิ่ม `dart format --output=none --set-exit-if-changed .` หรือ format check ที่ทีมเลือกใน CI
5. รัน workflow บน branch/PR ที่ใช้ประเมิน แก้จน Succeeded และแนบ URL/screenshot
6. ตรวจความถูกต้องของหลักฐาน Usability Testing และหลีกเลี่ยงการกล่าวอ้าง Dynamic Color ว่าพร้อมใช้จนกว่าจะมี implementation

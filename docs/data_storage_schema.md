# Snap2Bill — Data Storage Schema

> สรุปจาก Drift definitions, migrations, models และ query/payload ที่แอปใช้งานใน repository นี้  
> **ข้อควรทราบ:** migration ที่มีอยู่ไม่ได้สร้าง schema ตั้งต้นของ `bills`, `bill_participants`, `profiles`, `lobbies`, `friends` และ `saved_contacts` ดังนั้น fields ของตารางเหล่านี้ด้านล่างคือฟิลด์ที่แอปอ่าน/เขียน/serialize จริง ไม่ใช่การยืนยันชนิดข้อมูลหรือข้อบังคับทั้งหมดใน Supabase project

## ส่วนที่ 1: Local · SQLite (drift)

| table | columns |
|---|---|
| `cached_bills` | `id` (PK), `shop_name`, `total_amount`, `receipt_date`, `status`, `receipt_json`, `sharers_json`, `payload_json`, `local_image_path`, `sync_status`, `created_at`, `cached_at` |
| `cached_profiles` | `id` (PK), `payload_json`, `cached_at` |
| `cached_rooms` | `room_code` (PK), `payload_json`, `cached_at` |
| `offline_drafts` | `id` (auto-increment PK), `shop_name`, `total_amount`, `items_json`, `created_at` |

- **Schema version 4**; มี migration ย้อนหลังสำหรับเพิ่มคอลัมน์ cache และเติมค่า `created_at` จาก payload/วันที่ใบเสร็จ
- มี primary key ตามตารางข้างต้น; ไม่พบ secondary index ที่ประกาศเพิ่มใน Drift
- Cache ของบิลเขียนแบบ upsert; `payload_json`, `receipt_json` และ `sharers_json` เก็บข้อมูลแบบ JSON text ส่วน `local_image_path` ชี้ไปยังไฟล์ในเครื่อง
- ไม่มี TTL/นโยบายล้างข้อมูลอัตโนมัติที่พบ: ลบบิล/ล้าง cache ได้โดยตรง, ลบ draft แยกตาม id; ฟังก์ชันล้าง cache ลบเฉพาะ `cached_bills`

**ข้อมูล Local ที่ไม่ใช่ Drift table**

- Offline queue เก็บใน `SharedPreferences` ภายใต้ key `snap2bill_offline_operations`; แต่ละรายการมี `id`, `type`, `payload`, `created_at`
- คิวรองรับงานสร้าง/แก้ไขบิล, แก้ไขโปรไฟล์, เพิ่มสมาชิก guest ในห้อง และอัปเดตสถานะ/ส่งสลิปการชำระ
- รูปใบเสร็จและภาพที่ cache เก็บเป็นไฟล์ใน local storage; ใน SQLite บันทึกเฉพาะ path

## ส่วนที่ 2: Cloud · Supabase (PostgreSQL + Storage)

| table / path | fields |
|---|---|
| `public.bills` | `id`, `owner_id`, `shop_name`, `receipt_date`, `sub_total`, `vat_amount`, `service_charge`, `total_amount`, `final_total`, `split_type`, `receipt_image_url`, `image_url`, `status`, `created_at`, `is_deleted`, `receipt_json`, `sharers_json` |
| `public.bill_participants` | `id`, `bill_id`, `profile_id`, `friend_id`, `amount_owed`, `status` |
| `public.bill_payments` | `bill_id` (PK ส่วนหนึ่ง), `profile_id` (PK ส่วนหนึ่ง), `status`, `slip_data`, `updated_at` |
| `public.profiles` | `id`, `display_name`, `email`, `avatar_url`, `payment_info`, `updated_at` |
| `public.lobbies` | `id`, `host_id`, `room_code`, `shop_name`, `total_amount`, `status`, `receipt_json` |
| `public.friends` | `id`, `user_id`, `friend_name`, `linked_profile_id`, `is_deleted`, `created_at` |
| `public.saved_contacts` | `id`, `user_id`, `name`, `note`, `created_at` |
| `public.notifications` | `id`, `bill_id`, `recipient_id`, `recipient_name`, `sender_id`, `sender_name`, `shop_name`, `amount`, `title`, `message`, `created_at`, `is_read` |
| `receipts/{user_id}/{lobby_id}/{file_name}` (Storage bucket) | ไฟล์ภาพใบเสร็จ JPEG; upload แบบ `upsert` |
| `auth.users` (Supabase Auth) | ใช้เป็นแหล่งตัวตนและ foreign-key target ของข้อมูลผู้ใช้; แอปจัดการผ่าน Supabase Auth ไม่ได้ query ตารางนี้โดยตรง |

- `bills.receipt_json` เก็บรายละเอียดรายการที่สแกน/ข้อมูลใบเสร็จ และ `sharers_json` เก็บข้อมูลการแบ่งรายการ; **ไม่มีตาราง `bill_items`** ใน schema/migrations ที่ตรวจพบ ส่วน `lobbies.receipt_json` ใช้เก็บ `room_members`
- `bill_payments` มี composite primary key `(bill_id, profile_id)`; `status` จำกัดเป็น `pending`, `reviewing`, `paid`; FK ไป `bills.id` ลบแบบ cascade; การส่งสลิปตรวจขนาดไม่เกิน 10 MiB ใน RPC
- Migrations ตั้ง RLS ให้ `bills`, `bill_participants`, `profiles`, `bill_payments`, `notifications`: จำกัดการอ่าน/แก้ไขตามเจ้าของบิล ผู้ร่วมบิล หรือผู้รับแจ้งเตือน และใช้ RPC ที่ตรวจตัวตนสำหรับ join/create/payment
- เปิด Postgres Changes/Realtime ให้ `bills`, `bill_participants`, `bill_payments`, `notifications`; lobby ใช้ Realtime Presence/Broadcast แยกต่างหาก

**Storage และการซิงก์**

- แอปบีบอัดรูปเป็น JPEG ก่อน upload (เป้าหมายไม่เกิน 500 KiB และด้านยาวเริ่มต้นไม่เกิน 1280 px); ตั้ง `contentType: image/jpeg` และ `upsert: true`
- path ของ receipt เริ่มด้วย user id เพื่อใช้ควบคุมสิทธิ์; migration มี helper ตรวจสิทธิ์อ่านตามเจ้าของ/การเข้าถึงบิล ส่วน Storage policies จริงระบุว่าตั้งผ่าน Supabase Dashboard
- นโยบาย Storage ที่ README ระบุ: `SELECT` ใช้ helper ตรวจการเข้าถึง receipt; `INSERT`/`UPDATE`/`DELETE` จำกัด path ให้ folder แรกเป็น id ของผู้ใช้ที่ล็อกอิน
- ไม่พบ bucket definition หรือค่า bucket file-size/MIME limits ใน repository จึงยืนยันข้อจำกัดฝั่ง Storage project ไม่ได้; URL ที่ใช้กับไฟล์ private อาจถูกแปลงเป็น signed URL อายุ 1 ชั่วโมง
- เมื่อกลับมาออนไลน์ `OfflineService` flush คิวตามลำดับและลบรายการหลังทำสำเร็จ; หากรายการใดผิดพลาดจะหยุดรอ retry ครั้งถัดไป การสร้างบิลส่ง local id ไป RPC เพื่อให้การ retry ด้วย id เดิมเป็น idempotent

---

### แหล่งข้อมูลและขอบเขต

- Local: `lib/database/tables.dart`, `lib/database/app_database.dart`, `lib/data/repositories/local_bill_repository.dart`, `lib/services/offline/offline_service.dart`
- Cloud: `lib/services/data/supabase_db_service.dart`, repositories/providers/screens/models และ `supabase/migrations/*.sql`
- ตารางฐานของ Supabase บางรายการต้องตรวจ schema จริงใน Supabase project เพื่อยืนยันชนิดข้อมูล, nullability, constraints, indexes และ RLS ที่ไม่ได้อยู่ใน migrations ของ repository นี้

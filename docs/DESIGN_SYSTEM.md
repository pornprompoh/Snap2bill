# Snap2Bill Design System

> **สถานะ:** Redesign specification  
> **แหล่งอ้างอิง:** ภาพ reference ที่แนบมากับงานนี้เป็น source of truth ของสีและ mood & tone  
> **ขอบเขต:** เอกสารนี้เป็นแนวทางสำหรับการรีดีไซน์ทั้งแอป ไม่ได้จำกัดด้วยค่าที่ใช้อยู่ใน implementation ปัจจุบัน

## 1. Brand Identity & Overview

Snap2Bill คือผู้ช่วยจัดการค่าใช้จ่ายที่ทำให้การสแกนใบเสร็จ แบ่งบิล และติดตามการชำระเงินเป็นเรื่องที่เข้าใจง่ายในทันที

- **Mood:** สดใส เป็นมิตร และมีพลังจากชมพูสด `#F76DB7`
- **Tone:** สะอาด ตรงไปตรงมา และไว้ใจได้สำหรับเรื่องเงิน
- **ประสบการณ์หลัก:** ลดความซับซ้อนของข้อมูลจำนวนมากด้วยพื้นผิวสีขาว พื้นหลังชมพูอ่อน และสถานะสีที่แยกความหมายชัดเจน
- **หลักการใช้สี:** ใช้ชมพูเป็นจุดนำสายตา ใช้ดำ/เทาเพื่อความอ่านง่าย ใช้เขียว/ส้ม/เหลือง/มิ้นต์เพื่อสื่อสถานะ ไม่ใช้สีตกแต่งจนกลบข้อมูลยอดเงินหรือสถานะการชำระ

## 2. Color Palette & Token System

ทุกสีด้านล่างเป็น design token ที่ควรสร้างใน `AppColors` ระหว่างการรีดีไซน์ โดยชื่อ token เป็นข้อเสนอที่สอดคล้องกับ naming convention เดิมของโปรเจกต์

### Primary / Brand Colors

| Color Name | Variable in Code | Hex Code | RGB/Opacity | Usage Context |
|---|---|---:|---|---|
| Snap Pink | `AppColors.primary` | `#F76DB7` | `rgb(247, 109, 183)` / 100% | ปุ่ม CTA หลัก, selected state, highlight, progress/status bar |
| Soft Pink Surface | `AppColors.primarySurface` | `#FFD5EC` | `rgb(255, 213, 236)` / 100% | พื้นหลังของ card ที่ถูกเลือก, banner, chip และพื้นที่เน้นรอง |
| Pink at 68% | `AppColors.primaryOverlay` | `#F76DB7` | `rgb(247, 109, 183)` / 68% | overlay หรือ tint บนภาพ/พื้นผิวที่ต้องการลดความเข้ม |

### Secondary / Accent Colors

| Color Name | Variable in Code | Hex Code | RGB/Opacity | Usage Context |
|---|---|---:|---|---|
| Receipt Orange | `AppColors.accentOrange` | `#E37A51` | `rgb(227, 122, 81)` / 100% | accent icon, badge, illustration และจุดเน้นที่ต้องการความอบอุ่น |
| Deep Teal | `AppColors.accentTeal` | `#047E69` | `rgb(4, 126, 105)` / 100% | icon, secondary action, link และ accent ที่ต้องการความน่าเชื่อถือ |
| Linear Accent | `AppColors.accentGradient` | `linear-gradient(#047E69, #F76DB7)` | 100% | hero visual, illustration หรือพื้นที่ตกแต่งขนาดใหญ่; ไม่ใช้กับข้อความยาว |

### Background & Surface Colors

| Color Name | Variable in Code | Hex Code | RGB/Opacity | Usage Context |
|---|---|---:|---|---|
| App Background | `AppColors.background` | `#FFFFFF` | `rgb(255, 255, 255)` / 100% | พื้นหลังหน้าจอหลักและพื้นที่อ่านข้อมูล |
| Card / Dialog Surface | `AppColors.surface` | `#FFFFFF` | `rgb(255, 255, 255)` / 100% | card, modal, dialog และ input container |
| Soft Pink Panel | `AppColors.panelPink` | `#FFD5EC` | `rgb(255, 213, 236)` / 100% | panel สรุปบิล, callout และ selected container |
| White Overlay | `AppColors.surfaceOverlay` | `#FFFFFF` | `rgb(255, 255, 255)` / 24% | layer บนภาพหรือ gradient ที่ต้องการความโปร่ง |
| Subtle White Overlay | `AppColors.surfaceSubtleOverlay` | `#FFFFFF` | `rgb(255, 255, 255)` / 7% | highlight/shine ที่ไม่ควรแย่งความสนใจ |

### Semantic & Status Colors

| Color Name | Variable in Code | Hex Code | RGB/Opacity | Usage Context |
|---|---|---:|---|---|
| Paid / Success Mint | `AppColors.success` | `#B6F7C1` | `rgb(182, 247, 193)` / 100% | ชำระเสร็จสิ้น, สำเร็จ, confirmation background หรือ success chip |
| Pending / Waiting Yellow | `AppColors.warning` | `#FFF9D4` | `rgb(255, 249, 212)` / 100% | รอชำระ, รอเพื่อนโอน, pending background และ reminder |
| Warning Action Yellow | `AppColors.warningStrong` | `#FFC800` | `rgb(255, 200, 0)` / 100% | warning icon, emphasis ของสถานะรอชำระ และ attention indicator |
| Error / Attention Orange | `AppColors.error` | `#E37A51` | `rgb(227, 122, 81)` / 100% | error, validation, การลบ หรือการแจ้งเตือนที่ต้องแก้ไข |
| Teal Status | `AppColors.info` | `#047E69` | `rgb(4, 126, 105)` / 100% | informational status, shared/active state และสถานะดำเนินการ |

> **แนวทางการเข้าถึง:** สีสถานะอ่อน เช่น `#B6F7C1`, `#FFF9D4` และ `#FFD5EC` ใช้เป็นพื้นหลัง ไม่ควรใช้เป็นสีตัวอักษรบนพื้นขาวโดยตรง ให้ใช้ `#000000` หรือสีเข้มที่ผ่านการตรวจ contrast แทน

### Text & Neutral Colors

| Color Name | Variable in Code | Hex Code | RGB/Opacity | Usage Context |
|---|---|---:|---|---|
| Default Text | `AppColors.textPrimary` | `#000000` | `rgb(0, 0, 0)` / 100% | title, ยอดเงิน, label สำคัญ และเนื้อหาหลัก |
| Secondary Icon / Text | `AppColors.textSecondary` | `#757575` | `rgb(117, 117, 117)` / 100% | subtitle, supporting text, icon รอง และ metadata |
| Disabled / Muted Text | `AppColors.textMuted` | `#000000` | `rgb(0, 0, 0)` / 28% | hint, disabled label และข้อมูลที่ลดความสำคัญ |
| Divider / Border | `AppColors.divider` | `#000000` | `rgb(0, 0, 0)` / 28% | divider หรือเส้นขอบบางบนพื้นขาว; ใช้เป็น `rgba(0, 0, 0, 0.28)` |
| Disabled Surface | `AppColors.disabledSurface` | `#000000` | `rgb(0, 0, 0)` / 7% | พื้นที่ disabled, pressed tint อ่อน หรือ skeleton background |

## 3. Typography

Typography ต้องคงบุคลิกที่อ่านง่ายและเป็นมิตรกับภาษาไทย โดยผูกกับ `lib/theme/app_text_styles.dart` ผ่าน `AppTextStyles` และใช้ `IBM Plex Sans Thai` เป็น font family หลัก

| Type Role | Existing Style / Token | Font Size | Font Weight | Line Height | Usage |
|---|---|---:|---:|---:|---|
| Display / Headline | `AppTextStyles.headline` | 26px | 700 | 1.3 (33.8px) | heading หน้าหลัก, ยอดรวม หรือข้อความนำ |
| Title | `AppTextStyles.title` | 18px | 600 | 1.3 (23.4px) | ชื่อ card, section title และ dialog title |
| Body | `AppTextStyles.body` | 15px | 400 | 1.5 (22.5px) | รายละเอียดบิล, label หลัก และเนื้อหาอ่านต่อเนื่อง |
| Body Small | `bodyMedium` / body variant | 14px | 400–600 | 1.5 | metadata, button label และเนื้อหารองที่ยังต้องอ่านชัด |
| Caption | `AppTextStyles.caption` | 12px | 400 | 1.4 (16.8px) | hint, timestamp, helper text และสถานะรอง |
| Label Small | `labelSmall` | 11px | 400 | 1.4 | chip, badge หรือข้อมูลประกอบที่มีพื้นที่จำกัด |

### Typography Rules

- ใช้ `fontWeight.w700` เฉพาะ heading หรือยอดเงินที่ต้องการนำสายตา
- ใช้ `fontWeight.w600` กับ title, button และ label ที่เป็น action
- ไม่ใช้ตัวพิมพ์เล็กกว่า 11px กับข้อมูลที่ผู้ใช้ต้องตัดสินใจเรื่องการเงิน
- ใช้ `textPrimary` กับข้อมูลสำคัญ และ `textSecondary` กับคำอธิบาย หลีกเลี่ยงการใช้สีชมพูเป็น body text บนพื้นขาว

## 4. Component Design Guidelines

### Border Radius

| Token | Value | Recommended Usage |
|---|---:|---|
| `AppRadius.small` | 8px | chip, compact input, small icon container |
| `AppRadius.medium` | 12px | input, list item และ card ขนาดเล็ก |
| `AppRadius.large` | 16px | card หลัก, dialog และ section container |
| `AppRadius.pill` | 999px | button แบบ pill, filter chip และ status badge |

ปุ่ม CTA หลักควรใช้ radius **12px** เพื่อให้รู้สึกชัดเจนและกดง่าย ส่วน card/panel ที่เป็นพื้นที่สำคัญใช้ **16px** เพื่อคงความนุ่มนวลตาม reference

### Elevation & Box Shadow

| Level | Token | Recommendation |
|---|---|---|
| Flat | `AppElevation.none` | พื้นหลังและ card ที่แยกด้วยสีหรือเส้นขอบ |
| Raised | `AppElevation.card` | `0 2px 8px rgba(0, 0, 0, 0.07)` สำหรับ card ที่ลอยจากพื้น |
| Overlay | `AppElevation.dialog` | `0 8px 24px rgba(0, 0, 0, 0.16)` สำหรับ dialog, bottom sheet และ popover |

ใช้เงาเท่าที่จำเป็น โดยให้สีพื้นผิวและ radius เป็นตัวแบ่งลำดับชั้นหลัก เงาไม่ควรเข้มจนทำให้ UI ดูหนักหรือแข่งขันกับ CTA สีชมพู

### Spacing & Padding

ใช้ระบบ spacing แบบฐาน 4px เพื่อให้ layout สม่ำเสมอ:

| Token | Value | Recommended Usage |
|---|---:|---|
| `AppSpacing.xs` | 4px | gap ระหว่าง icon กับข้อความ, micro spacing |
| `AppSpacing.sm` | 8px | chip padding, ระยะห่างใน row ขนาดเล็ก |
| `AppSpacing.md` | 12px | input padding, card content gap |
| `AppSpacing.lg` | 16px | screen horizontal padding, card padding และระยะห่าง section |
| `AppSpacing.xl` | 24px | ระยะห่างระหว่างกลุ่มเนื้อหาและ vertical section spacing |
| `AppSpacing.xxl` | 32px | hero spacing หรือพื้นที่หายใจของหน้าสำคัญ |

**ค่าเริ่มต้นที่ควรใช้**

- Screen padding: `16px`
- Card padding: `16px`
- Button horizontal padding: `16px` ถึง `24px`
- Gap ระหว่าง title กับ body: `8px`
- Gap ระหว่าง section: `24px`

### Component Behavior

- **Primary button:** พื้น `#F76DB7`, ข้อความ `#000000`, radius 12px และมี pressed state เป็นสีชมพูเข้มขึ้นด้วย overlay สีดำเล็กน้อย
- **Selected card:** พื้น `#FFD5EC`, border หรือ indicator `#F76DB7`
- **Status chip:** ใช้พื้นสี semantic อ่อนและข้อความสีดำ/เทาเข้ม ไม่ใช้สีอ่อนเป็นข้อความเดี่ยว
- **Icon:** icon หลักใช้ `#000000`, icon รองใช้ `#757575`, icon สถานะใช้สี semantic ของสถานะนั้น
- **Card:** พื้นขาว radius 16px; ใช้ border หรือ shadow อย่างใดอย่างหนึ่งเป็นหลัก ไม่ใช้ทั้งสองแบบเข้มพร้อมกัน

## Implementation Checklist

- [ ] เพิ่ม/ปรับ token ใน `AppColors` ให้ตรงกับตารางนี้
- [ ] ตรวจทุก screen ให้ใช้ `AppTextStyles` แทนค่า font ที่เขียนกระจาย
- [ ] สร้าง shared radius, elevation และ spacing tokens ก่อนรีแฟกเตอร์ component
- [ ] ตรวจ contrast ของข้อความและสถานะในทุกพื้นผิว
- [ ] ใช้เอกสารนี้เป็น baseline เดียวกันระหว่าง designer, developer และ QA

---
title: solo-event-hub — Product Card
doc_id: CARD-solo-event-hub
doc_type: product-card
verdict: showcase
version: 0.1
date: 2026-10-11
status: ร่างเพื่อพิจารณา
owner: Product owner (Book Dev)
---

# solo-event-hub — Product Card

## 1. สรุปคุณค่าในหนึ่งประโยค

รับเหตุการณ์จากอุปกรณ์/แหล่งภายนอกผ่าน MQTT และ HTTP เข้า lake กันซ้ำ มีหน้าจอเปิด-ปิดแหล่งข้อมูลและ retry งานที่ล้มเหลว

## 2. ปัญหาและผู้ใช้เป้าหมาย

ต้องมีจุดรับเหตุการณ์ IoT/แจ้งเตือนที่ไม่ส่งซ้ำและตรวจย้อนได้ ผู้ใช้คือเจ้าของ (pilot)

## 3. สิ่งที่ทำได้จริงตอนนี้

- Docker compose (Mosquitto + service) ใน `infra/event-hub/` และหน้าจอที่พอร์ต 8112 ตาม README
- onboarding อุปกรณ์: สร้าง identity/ACL ต่ออุปกรณ์ (secret เก็บใน `.runtime` สิทธิ์ 0600)
- เทสต์ 19 ไฟล์

## 4. หลักฐานสถานะ

| รายการ | ค่า |
|---|---|
| Stack | Python, MQTT (Mosquitto), Docker |
| Commit | 6 ครั้ง (2026-09-09 ถึง 2026-10-11) |
| ซอร์สโค้ด | 29 ไฟล์ / 7907 บรรทัด |
| เทสต์ | 19 ไฟล์ (ไม่ได้รันในงานนี้) |
| CI | ไม่มี workflow |
| Deploy config | `compose.yml` (local Docker); ทะเบียนระบุ exception |
| Live URL | ไม่มี |

## 5. คุณค่าและจุดต่าง

- ใช้ MQTT/HTTP ร่วมกันกับ dedup ในตัว
- **[สมมติฐาน]** ใช้เป็นฐาน IoT ให้ลูกค้าได้ แต่ยังเป็น pilot

## 6. ช่องว่างสำคัญ

- เป็น pilot ไม่มีอุปกรณ์จริงที่ยืนยัน **[ต้องยืนยัน]**
- โครงสร้าง `infra/...` คงเดิม
- ไม่มี CI

## 7. คำตัดสิน

**`showcase`** — สถาปัตยกรรมน่าสนใจและทดสอบดี แต่ยังเป็น pilot ไม่มีผู้ใช้จริง จะเปลี่ยนเป็น `invest` หากมีอุปกรณ์/ผู้ใช้ที่ส่งเหตุการณ์จริง

## 8. ขั้นต่อไป

1. ระบุ use case จริงอย่างน้อยหนึ่งรายการ

## การอนุมัติ

| บทบาท | สถานะ | วันที่ | ลงนาม |
|---|---|---|---|
| Product owner (Book Dev) | รอพิจารณา | — | ________ |

## แหล่งข้อมูล

- `README.md`
- `infra/event-hub/`, `infra/scripts/services/event_hub*.py`

---
title: Event Hub — MQTT and HTTP local pilot
tags: [infra, integrations, iot, data-engineering]
created: 2026-09-08
updated: 2026-09-08
description: Local event intake, verified lake storage, configurable rules, and internal notifications.
---

# ศูนย์เชื่อมต่อ Event Hub

รับข้อมูลตัวเลขจาก IoT ผ่าน MQTT หรือแอปผ่าน HTTP แล้วประเมินกฎเพื่อสร้าง
การแจ้งเตือนภายในระบบ มีหน้าจอเปิด–ปิดแหล่งข้อมูล ปรับ threshold/cooldown
ดูเหตุการณ์ การแจ้งเตือน และสั่ง retry งานที่ล้มเหลวได้

## เริ่มใช้งาน

รันจาก root ของ Solo Empire ด้วย Docker และ Python ที่ติดตั้ง
`infra/event-hub/requirements.txt` แล้ว:

```bash
task event-hub -- setup
docker compose -f infra/event-hub/compose.yml up -d --build
task event-hub -- simulate --transport mqtt --value 38
task event-hub -- simulate --transport http --value 39
```

เปิด <http://127.0.0.1:8112> และเข้าสู่ระบบด้วยค่า `operator` ในไฟล์ส่วนตัว
`.runtime/secrets.json` ภายใน directory นี้ อ่านค่านั้นบนเครื่องของตนเอง
และกรอกในหน้าจอเท่านั้น ไม่ส่งลงแชต/บันทึก/คำสั่ง shell ที่เก็บ history
รหัสแหล่งข้อมูลอยู่ใน `mqtt` และ `http` ของไฟล์เดียวกัน
`setup` เก็บไฟล์ด้วย permission `0600` และไม่แสดงค่าออกทาง stdout

## เพิ่มอุปกรณ์จริง

ใช้คำสั่ง onboarding หลัง `setup` เพื่อสร้าง identity แยกให้อุปกรณ์หนึ่งตัว
คำสั่งจะเพิ่ม source ใน runtime config, สร้าง password และ ACL เฉพาะ
`se/events/<source-id>`, แล้วเขียน connection profile ที่มี password ลงใน
`.runtime/devices/<source-id>.json` ด้วย permission `0600` คำตอบบนหน้าจอจะ
ไม่แสดง password:

```bash
task event-hub -- onboard \
  --source-id living-room \
  --event-type temperature.reading \
  --device-host 192.168.1.20 \
  --device-port 1884
docker compose -f infra/event-hub/compose.yml restart mqtt
```

ส่งไฟล์ profile ให้ผู้ตั้งค่าอุปกรณ์ผ่านช่องทางส่วนตัวเท่านั้น แล้วให้อุปกรณ์
ส่ง JSON ตาม [สัญญา event.v1](#สัญญา-eventv1) ด้วย username/password ใน profile
ห้ามคัดลอก profile ลง Git หรือแชต หลังเพิ่ม source ต้อง restart broker เพื่อ
โหลด ACL ใหม่; worker hub จะเห็น source จาก runtime config ในรอบถัดไป

ค่าเริ่มต้นยัง bind MQTT ที่ `127.0.0.1` ถ้าอุปกรณ์อยู่ LAN ให้ตั้ง IP ของ
เครื่องที่รัน broker และ port ที่ต้องการก่อน recreate container:

```bash
EVENT_HUB_MQTT_BIND=192.168.1.10 EVENT_HUB_MQTT_PORT=1884 \
  docker compose -f infra/event-hub/compose.yml up -d --force-recreate mqtt
```

เปิด port ใน firewall เฉพาะ subnet ของอุปกรณ์ และใช้ TLS/tunnel เมื่อข้าม
เครือข่ายที่ไว้ใจไม่ได้ รุ่น pilot นี้ใช้ MQTT TCP ภายใน LAN และยังไม่มี TLS
จึงไม่ควร bind `0.0.0.0` หรือเปิดอินเทอร์เน็ต

Compose เปิดเฉพาะ `127.0.0.1:8112` (หน้าเว็บ/API) และ `127.0.0.1:1884`
(MQTT) ใช้ broker `se-event-hub-mqtt` และ worker `se-event-hub` ของ pilot
โดยไม่แก้ broker/Redpanda ใน shared stack ที่กำลังใช้งานอยู่
container worker ใช้ UID/GID 1000 โดยค่าเริ่มต้น หากเครื่องใช้ UID/GID อื่น
ตั้ง `EVENT_HUB_UID`/`EVENT_HUB_GID` ให้ตรงกับเจ้าของ `.runtime` ก่อนเริ่ม

```bash
# ตรวจ runtime และ retry ผ่านหน้าจอเมื่อ container กำลังรัน
docker compose -f infra/event-hub/compose.yml ps

# หยุด/เริ่มใหม่โดยคงข้อมูลและ credentials
docker compose -f infra/event-hub/compose.yml stop
docker compose -f infra/event-hub/compose.yml start
```

สำหรับพัฒนาในเครื่อง ให้เริ่มเฉพาะ broker แล้วใช้ `task event-hub -- serve`:

```bash
docker compose -f infra/event-hub/compose.yml up -d mqtt
task event-hub -- serve
```

อย่ารัน host worker และ container worker พร้อมกันกับ runtime เดียวกัน
ตัวล็อกไฟล์จะป้องกัน writer ซ้อนกัน คำสั่ง `status`, `retry`, `demo`
ใช้แบบ offline หลังหยุด worker; ขณะทำงานใช้หน้าเว็บหรือ API

## สัญญา event.v1

```json
{
  "schema_version": "event.v1",
  "event_id": "reading-0001",
  "source_id": "sensor-demo",
  "event_type": "temperature.reading",
  "occurred_at": "2026-09-08T01:00:00Z",
  "payload": {"value": 38, "unit": "celsius"}
}
```

- MQTT: username `sensor-demo`, topic `se/events/sensor-demo`, QoS 1,
  `retain=false`; password มาจาก secret file ฝั่งอุปกรณ์
- HTTP: `POST /api/events/app-demo`, `Authorization: Bearer <source-token>`,
  `Content-Type: application/json`; ใช้ `source_id=app-demo` ใน body
- ID ใช้ lowercase letters, numbers, dot, underscore, hyphen ยาว 1–64 ตัว
- ต้องมี timezone และ payload ไม่เกิน 4096 bytes ไม่มี field เพิ่มเติม
- `value` เป็น finite number; `unit` รองรับ `celsius`, `percent`, `count`,
  `seconds`, `watts`, `volts` รุ่นนี้รองรับ telemetry ตัวเลขเท่านั้น
- HTTP token แยกตาม source และใช้แทนรหัสผู้ดูแลไม่ได้; MQTT ACL ผูก username
  กับ topic และตรวจ `source_id` ซ้ำใน adapter

เพิ่มชนิดเหตุการณ์/กฎใน `.runtime/config.json` หรือปรับค่าบนหน้าเว็บ
runtime โหลด config ก่อนรับงานแต่ละครั้ง ไม่ต้อง restart เมื่อปรับกฎ
กฎรองรับ `gt`, `gte`, `lt`, `lte`, `eq` และ action `internal_notification`
การเพิ่ม identity ใหม่ต้อง provision credentials และ MQTT ACL ของ identity
นั้นด้วย; การใส่ชื่อใน config อย่างเดียวไม่ให้สิทธิ์เชื่อมต่อ

## การรับข้อมูลและกู้คืน

```text
MQTT / HTTP
  → ตรวจ source และ event.v1
  → immutable raw + metadata receipt
  → Source Registry / Intake เดิม
  → exact landing + Bronze Parquet + manifest
  → verify checksum / อ่าน Bronze
  → กฎ + notification + cooldown ใน transaction เดียวกัน
```

ใช้ helper `data_lake.ingest.ingest_payload` และคำสั่ง intake เดิมกับฐาน
`hub.db` ของ pilot ซึ่งมีเฉพาะตาราง intake และ projection ของ hub
ไม่มีการเขียนฐาน operational หลักของ Solo Empire
เส้นทางนี้เขียนตรงลง filesystem lake ของ pilot; Redpanda เป็นทางเลือกในอนาคต
เมื่อมีเหตุผลต้องใช้ buffering/fan-out ปริมาณมาก

อัตลักษณ์คือ `(source_id,event_id)` ข้อมูลเหมือนเดิมแม้ whitespace ต่างกัน
ไม่ทำงานซ้ำ; ID เดิมที่เนื้อหาเปลี่ยนถูกปฏิเสธ เก็บ exact bytes ของคำขอแรก
metadata receipt เก็บ hash/lineage/rule snapshot โดยไม่มี raw payload
ผู้รับอ่าน Bronze ที่ผ่านการตรวจ manifest ก่อนสร้าง action

ประเมิน cooldown ตาม `occurred_at` แยก source/rule และไม่ลด watermark:
event เก่าหรือเวลาเท่ากันเก็บประวัติได้แต่ไม่แจ้งเตือนใหม่
ข้อมูลเก่ากว่า `max_age_seconds` หรืออนาคตเกิน 60 วินาทีไม่ขยับ watermark
rule snapshot ของ event แรกทำให้ retry ใช้เงื่อนไขเดิม แต่การปิด/ลบ source
หรือปิด/ลบ rule ปัจจุบันหยุด action ที่ยังไม่เสร็จได้

MQTT acknowledge หลังทำงานสำเร็จ บันทึก rejection หรือเก็บงานที่ครบ
retry limit ไว้ในคิวล้มเหลวอย่างถาวรแล้วเท่านั้น
เมื่อประมวลผลล้มเหลวจะ disconnect เพื่อให้ broker ส่ง QoS 1 ใหม่
ใช้ persistent session/client ID คงที่ตาม
[Paho manual acknowledgment](https://eclipse.dev/paho/files/paho.mqtt.python/html/client.html)
และตรวจ retry receipt ที่ยังไม่เสร็จครั้งละ 10 รายการทุก 15 วินาที
ใช้ backoff 15/30/60/120 วินาที รวมไม่เกิน 5 attempts อัตโนมัติ
งานที่ยังล้มเหลวคงสถานะให้ตรวจสอบและสั่ง retry เองได้
คำขอ HTTP ที่ได้ 503 ควรส่งซ้ำด้วย event ID และเนื้อหาเดิม
เวลาที่ simulator รายงาน `broker_accepted` หมายถึง broker รับแล้ว;
ดูสถานะ `complete` ใน hub เพื่อยืนยันการประมวลผลครบเส้นทาง

ข้อมูลไม่ผ่าน validation เก็บเฉพาะ digest และ reason code ใน quarantine
metadata ไม่เก็บ raw เพราะอาจมี secret หลุดมา ผู้ส่งต้องแก้ข้อมูลและส่งใหม่
ข้อมูลที่ผ่าน validation แล้วล้มเหลวเก็บ raw สำหรับ retry พร้อม error class
และไม่บันทึกข้อความ exception ที่อาจมีข้อมูลส่วนตัว

## ตรวจสอบ

```bash
task test:event-hub
# ส่งข้อมูลสังเคราะห์ผ่าน MQTT และ HTTP จริง; เพิ่มกฎชั่วคราวแล้วคืน config
bash infra/scripts/setup/run-python3.sh infra/tests/integrations/event_hub_live_test.py
# รวมการหยุด/เริ่มเฉพาะ worker ของ pilot และส่ง event ระหว่าง worker หยุด
bash infra/scripts/setup/run-python3.sh infra/tests/integrations/event_hub_live_test.py --restart
```

Live check ตรวจค่าปกติ/เกิน threshold, duplicate, cooldown, late event,
HTTP auth และ MQTT ACL; evidence สรุปอยู่ใน `.runtime/live-evidence.json`
Offline tests เพิ่ม lake failure, manifest failure, action rollback,
restart/replay, Bronze corruption, source/rule pause และ writer lock

## ขอบเขต pilot และขั้นถัดไป

Owner คือ Solo Empire operator; source ปัจจุบันเป็นข้อมูลจำลองที่ผู้ใช้อนุญาต
สำหรับทดลอง telemetry และกฎภายใน ใช้ privacy `internal`, retention
`operational` (เป้าหมาย 30 วัน; ไม่มีการลบอัตโนมัติ)
ดู [ingestion specification](../../systems/ai-data/event-hub-ingestion-spec.md)

รุ่นนี้เป็น local pilot, ใช้ SQLite writer เดียวและ Parquet part ต่อ event
เหมาะกับการทดสอบปริมาณน้อย; ต้องเพิ่ม compaction/batching ก่อนใช้ข้อมูลถี่
broker persistence ใช้ autosave 10 วินาที จึงไม่รับประกัน zero loss หาก
เครื่องดับก่อน flush; เหตุการณ์ที่มี verified manifest คือขอบเขตการกู้คืน

อุปกรณ์จริงยังต้องระบุรุ่น/เครือข่ายและตั้ง credentials/topic ให้ตรงกัน
loopback ไม่รับการเชื่อมจาก LAN โดยตรง ต้องจัดทางเชื่อมผ่าน tunnel หรือ
listener ที่มี TLS/ACL ตามเครือข่ายที่เลือกก่อนเปิดใช้งาน
การส่งข้อความภายนอก สั่ง actuator หรือเรียก API ภายนอกยังต้องเพิ่ม action
adapter และทดสอบผลข้างเคียงของปลายทางนั้น

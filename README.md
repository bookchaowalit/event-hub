# solo-event-hub

Event Hub pilot (MQTT + HTTP ingestion, lake-first, action deduplication) พร้อม `data-intake-cli` ที่ใช้ส่ง intake.

ที่มา: ย้ายจาก `solo-empire/infra/event-hub/`, `infra/scripts/services/event_hub*.py`, `infra/scripts/cli/data-intake-cli.py` และ `infra/tests/integrations/event_hub*_test.py` (2026-10-11) พร้อมประวัติของ `infra/event-hub/` (git subtree split).

## โครงสร้าง

Repo นี้คงโครงสร้างแบบ `infra/` เดิมไว้เพื่อให้ path ใน Dockerfile/compose/tests ทำงานเหมือนเดิม:

- `infra/event-hub/` — Dockerfile, compose.yml, mosquitto, config.json, README ของ pilot
- `infra/scripts/services/event_hub*.py`, `infra/scripts/cli/data-intake-cli.py`
- `infra/scripts/utils/{_env,cell_store,task_store,recurring_step,secret_resolver}.py` และ `infra/scripts/data_lake/{ingest,storage,parquet,iceberg}.py` — สำเนา vendored จาก solo-empire (ต้นฉบับ data lake อยู่ใน solo-data-lake)
- `infra/database/migrations/033_source_registry_intake_queue.sql` — สำเนา migration ของ source registry/intake queue
- `infra/tests/` — event_hub_test.py, event_hub_live_test.py, sqlite_cell_store double

## ทดสอบ

```bash
python3 infra/tests/integrations/event_hub_test.py
```

หมายเหตุ: ณ วันที่ย้าย การทดสอบนี้มี 7 failures + 8 errors เหมือนกันทั้งใน solo-empire ก่อนย้าย (ต้นเหตุยังไม่ได้แก้ในงานย้าย) — ตรวจสอบ dependency ของ lake (pyarrow/duckdb) ก่อน.
Live test ต้องรัน `infra/event-hub/compose.yml` เท่านั้น.

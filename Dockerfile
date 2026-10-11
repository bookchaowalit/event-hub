FROM python:3.11-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /app
COPY event-hub/requirements.txt /tmp/event-hub-requirements.txt
RUN pip install --no-cache-dir -r /tmp/event-hub-requirements.txt
COPY scripts/data_lake /app/infra/scripts/data_lake
COPY scripts/utils/_env.py /app/infra/scripts/utils/
COPY scripts/cli/data-intake-cli.py /app/infra/scripts/cli/
COPY scripts/services/event_hub.py scripts/services/event_hub_transport.py /app/infra/scripts/services/
COPY database/migrations/033_source_registry_intake_queue.sql /app/infra/database/migrations/
COPY event-hub/config.json event-hub/index.html /app/infra/event-hub/
USER 1000:1000
CMD ["python", "infra/scripts/services/event_hub.py", "serve", "--bind", "0.0.0.0", "--mqtt-host", "mqtt", "--mqtt-port", "1883"]

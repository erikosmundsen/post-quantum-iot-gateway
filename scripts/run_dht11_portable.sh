#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$REPO_ROOT/configs/sensor_portable.env"

if [ -f "$ENV_FILE" ]; then
  # shellcheck disable=SC2046
  export $(grep -v '^#' "$ENV_FILE" | xargs -d '\n')
fi

PY_SCRIPT="$REPO_ROOT/scripts/sensor-publish/dht11_to_mqtt_portable.py"

echo "Broker: ${MQTT_BROKER_HOST:-localhost}:${MQTT_BROKER_PORT:-8884}"
echo "Topic : ${MQTT_TOPIC:-team1/sensor}"
echo "GPIO  : ${DHT11_PIN:-4}"

python3 "$PY_SCRIPT"

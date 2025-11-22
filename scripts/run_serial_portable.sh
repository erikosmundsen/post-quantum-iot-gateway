#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ENV_FILE="$REPO_ROOT/software/serial_bridge/serial_portable.env"
if [ -f "$ENV_FILE" ]; then
  # shellcheck disable=SC2046
  export $(grep -v '^#' "$ENV_FILE" | xargs -d '\n')
fi

PY_SCRIPT="$REPO_ROOT/software/serial_bridge/serial_to_mqtt_portable.py"

echo "Using serial device: ${SERIAL_DEVICE:-unset}"
echo "MQTT broker: ${MQTT_BROKER_HOST:-localhost}:${MQTT_BROKER_PORT:-8884}"
echo "MQTT topic: ${MQTT_TOPIC:-team1/sensor}"

python3 "$PY_SCRIPT"

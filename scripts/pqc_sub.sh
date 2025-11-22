#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Load MQTT CLI config
ENV_FILE="$REPO_ROOT/configs/mqtt_cli.env"
if [ -f "$ENV_FILE" ]; then
  # shellcheck disable=SC2046
  export $(grep -v '^#' "$ENV_FILE" | xargs -d '\n')
fi

HOST="${MQTT_CLI_HOST:-localhost}"
PORT="${MQTT_CLI_PORT:-8884}"
TOPIC="${MQTT_CLI_TOPIC:-team1/sensor}"

CA_CERT="${MQTT_CLI_CA_CERT:-$REPO_ROOT/artifacts/tls/ca/ca.crt}"
CLIENT_CERT="${MQTT_CLI_CLIENT_CERT:-$REPO_ROOT/artifacts/tls/client/client.crt}"
CLIENT_KEY="${MQTT_CLI_CLIENT_KEY:-$REPO_ROOT/artifacts/tls/client/client.key}"

echo "Subscribing to mqtts://${HOST}:${PORT}/${TOPIC}"
echo "CA:   ${CA_CERT}"
echo "Cert: ${CLIENT_CERT}"
echo "Key:  ${CLIENT_KEY}"

mosquitto_sub \
  -h "$HOST" -p "$PORT" -t "$TOPIC" -q 1 \
  --cafile "$CA_CERT" \
  --cert "$CLIENT_CERT" \
  --key "$CLIENT_KEY" \
  --tls-version tlsv1.3

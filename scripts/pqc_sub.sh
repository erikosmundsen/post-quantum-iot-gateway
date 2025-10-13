#!/usr/bin/env bash
set -euo pipefail
source "$HOME/post-quantum-iot-gateway/scripts/pqc_env.sh"
mosquitto_sub -h 127.0.0.1 -p 8883 -t "pqc/demo" -q 1 \
  --cafile  "$HOME/post-quantum-iot-gateway/artifacts/tls/ca/ca.crt" \
  --cert    "$HOME/post-quantum-iot-gateway/artifacts/tls/client/client.crt" \
  --key     "$HOME/post-quantum-iot-gateway/artifacts/tls/client/client.key" \
  --tls-version tlsv1.3

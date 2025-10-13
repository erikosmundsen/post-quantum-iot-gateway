#!/usr/bin/env bash
set -euo pipefail
source "$HOME/post-quantum-iot-gateway/scripts/pqc_env.sh"
exec "$(command -v mosquitto)" -c "$HOME/post-quantum-iot-gateway/artifacts/mosquitto/pqc-mtls.conf" -v

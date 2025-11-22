#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ENV_FILE="$REPO_ROOT/configs/mosquitto_pqc.env"
TEMPLATE="$REPO_ROOT/configs/mosquitto_pqc_portable.conf"
OUTPUT="/etc/mosquitto/conf.d/pqc_mtls.conf"

# Load environment variables
if [ -f "$ENV_FILE" ]; then
    export $(grep -v '^#' "$ENV_FILE" | xargs -d '\n')
else
    echo "ERROR: Env file not found: $ENV_FILE"
    exit 1
fi

# Render the template by replacing placeholders ${VAR} with actual values
echo "Building Mosquitto PQC config..."

BUILD_DIR="$REPO_ROOT/build"
mkdir -p "$BUILD_DIR"
TEMP_CONF="$BUILD_DIR/pqc_mtls.conf"

# Run envsubst as the current user so it sees our exported env vars
envsubst < "$TEMPLATE" > "$TEMP_CONF"

echo "Temp config written to: $TEMP_CONF"
echo "Copying to $OUTPUT (sudo)..."
sudo cp "$TEMP_CONF" "$OUTPUT"

echo "Mosquitto PQC config written to: $OUTPUT"
echo "Reloading Mosquitto..."
sudo systemctl restart mosquitto

echo "Done."


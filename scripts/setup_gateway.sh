#!/usr/bin/env bash
set -euo pipefail

echo "=== Post-Quantum IoT Gateway Setup ==="

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "Repo root: ${REPO_ROOT}"

# 1) Check architecture (must be aarch64)
ARCH="$(uname -m)"
echo "Detected architecture: ${ARCH}"
if [[ "${ARCH}" != "aarch64" ]]; then
  echo "ERROR: This setup script expects a 64-bit ARM system (aarch64)."
  echo "Your architecture is: ${ARCH}"
  echo "Install a 64-bit Raspberry Pi OS before running this script."
  exit 1
fi

# 2) Check for OQS OpenSSL and preflight script
OPENSSL_BIN="/opt/openssl-3/bin/openssl"
PREFLIGHT="${REPO_ROOT}/artifacts/tools/preflight.sh"

if [[ ! -x "${OPENSSL_BIN}" ]]; then
  echo "WARNING: OQS OpenSSL not found at ${OPENSSL_BIN}."
  echo "Please complete the liboqs + OpenSSL build steps before using this gateway."
else
  echo "OQS OpenSSL found at: ${OPENSSL_BIN}"
fi

if [[ ! -x "${PREFLIGHT}" ]]; then
  echo "WARNING: Preflight script not found at ${PREFLIGHT}."
  echo "TLS config verification will not run automatically."
else
  echo "Preflight script found: ${PREFLIGHT}"
fi

echo
echo "Checking required configuration files..."

MISSING=0

check_file() {
  local path="$1"
  if [[ -f "$path" ]]; then
    echo "  [OK]  $path"
  else
    echo "  [MISSING] $path"
    MISSING=1
  fi
}

check_file "${REPO_ROOT}/configs/mosquitto_pqc.env"
check_file "${REPO_ROOT}/configs/api_portable.env"
check_file "${REPO_ROOT}/configs/sensor_portable.env"
check_file "${REPO_ROOT}/configs/mqtt_cli.env"
check_file "${REPO_ROOT}/software/serial_bridge/serial_portable.env"

if [[ $MISSING -ne 0 ]]; then
  echo
  echo "One or more required config files are missing."
  echo "Please create or copy the missing files before continuing."
  echo "Setup will stop here to avoid partial configuration."
  exit 1
fi

echo
echo "Loading Mosquitto PQC env variables..."

MOSQ_ENV="${REPO_ROOT}/configs/mosquitto_pqc.env"
if [[ -f "$MOSQ_ENV" ]]; then
  # shellcheck disable=SC2046
  export $(grep -v '^#' "$MOSQ_ENV" | xargs -d '\n')
  echo "  [OK] Loaded $MOSQ_ENV"
else
  echo "  [MISSING] $MOSQ_ENV (this should not happen; it was just checked)"
  exit 1
fi


echo
echo "=== Step: Generate portable PQC Mosquitto config ==="

BUILD_DIR="${REPO_ROOT}/build"
mkdir -p "$BUILD_DIR"

TEMPLATE="${REPO_ROOT}/configs/mosquitto_pqc_portable.conf"
OUTPUT="${BUILD_DIR}/pqc_mtls.conf"

if [[ ! -f "$TEMPLATE" ]]; then
  echo "ERROR: Template not found: $TEMPLATE"
  exit 1
fi

echo "Rendering template..."
envsubst < "$TEMPLATE" > "$OUTPUT"

echo "Portable config generated:"
echo "  $OUTPUT"

echo
echo "You may now review and install it manually with:"
echo "  sudo cp $OUTPUT /etc/mosquitto/conf.d/pqc_mtls.conf"
echo "  sudo systemctl restart mosquitto"
echo
echo "This script will not apply any system changes automatically."

echo
echo "=== Step: Health Check (read-only) ==="

# A) Check required cert/key files
echo "[A] Checking certificate files:"
for f in "$MOSQ_PQC_CA_CERT" "$MOSQ_PQC_SERVER_CERT" "$MOSQ_PQC_SERVER_KEY"; do
  if [[ -f "$f" ]]; then
    echo "  [OK]  $f"
  else
    echo "  [MISSING] $f"
  fi
done

# B) Check that OQS OpenSSL can verify CA cert
echo
echo "[B] Verifying CA certificate with OQS OpenSSL:"
if [[ -x "$OPENSSL_BIN" ]]; then
  "$OPENSSL_BIN" x509 -in "$MOSQ_PQC_CA_CERT" -text -noout >/dev/null && \
    echo "  [OK] CA certificate loaded successfully" || \
    echo "  [FAIL] Could not load CA certificate"
else
  echo "  [SKIP] OQS OpenSSL not installed"
fi

# C) Check that generated config looks valid
echo
echo "[C] Checking generated Mosquitto config syntax:"
if head -n 1 "$OUTPUT" >/dev/null 2>&1; then
  echo "  [OK] $OUTPUT exists"
else
  echo "  [FAIL] $OUTPUT missing or unreadable"
fi

echo
echo "Health check complete (no changes applied)."


echo
echo "Next steps (not yet automated in this skeleton):"
echo "  - Ensure configs/*.env files are filled in for this Pi"
echo "  - Run: scripts/build_mosquitto_pqc_conf.sh to update /etc/mosquitto/conf.d/pqc_mtls.conf"
echo "  - Start the FastAPI server with: python3 -m uvicorn api.app:app --host 0.0.0.0 --port 8000"
echo "  - Run sensor and serial bridge using run_dht11_portable.sh and run_serial_portable.sh"
echo
echo "Setup skeleton complete. No system changes were made."

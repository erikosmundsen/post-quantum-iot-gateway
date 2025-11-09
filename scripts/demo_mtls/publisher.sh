#!/usr/bin/env bash
set -e
source "$(dirname "$0")/env_demo.sh"
MSG="${1:-Hello from PQC mTLS!}"
echo "Ready to publish to demo/pqc (TLS 1.3 mTLS)."
echo "Press Enter to publish, or Ctrl+C to abort."
read -r
mosquitto_pub -h 127.0.0.1 -p 8884 -t "demo/pqc" -m "$MSG" \
  --cafile  "$CLIENTLOCAL/ca_cert.pem" \
  --cert    "$CLIENTLOCAL/client_cert.pem" \
  --key     "$CLIENTLOCAL/client_key.pem" \
  --tls-version tlsv1.3 -d
echo "Published: $MSG"
echo "You can close this window."

#!/usr/bin/env bash
set -e
source "$(dirname "$0")/env_demo.sh"
echo "Connecting subscriber to demo/pqc @ 127.0.0.1:8884 (TLS 1.3 mTLS)"
mosquitto_sub -h 127.0.0.1 -p 8884 -t "demo/pqc" \
  --cafile  "$CLIENTLOCAL/ca_cert.pem" \
  --cert    "$CLIENTLOCAL/client_cert.pem" \
  --key     "$CLIENTLOCAL/client_key.pem" \
  --tls-version tlsv1.3 -d

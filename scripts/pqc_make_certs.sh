#!/usr/bin/env bash
set -euo pipefail
REPO="$HOME/post-quantum-iot-gateway"
TLS="$REPO/artifacts/tls"
OSSL="/opt/openssl-3/bin/openssl"

source "$REPO/scripts/pqc_env.sh"

mkdir -p "$TLS/ca" "$TLS/server" "$TLS/client" "$TLS/configs"

# ML-DSA-65 Root CA
if [[ ! -s "$TLS/ca/ca.crt" ]]; then
  $OSSL genpkey -algorithm MLDSA65 \
    -provider default -provider /opt/openssl-3/lib/ossl-modules/oqsprovider.so \
    -out "$TLS/ca/ca.key"
  $OSSL req -x509 -new -key "$TLS/ca/ca.key" -out "$TLS/ca/ca.crt" -days 3650 \
    -subj "/C=US/ST=FL/L=Miami/O=PQ-IoT/OU=Root CA/CN=PQIoT-MLDSA65-CA" \
    -sha512 -config "$TLS/configs/ca_sign.cnf" -extensions v3_ca
fi

# ECDSA server with SANs
if [[ ! -s "$TLS/server/server-ecdsa.crt" ]]; then
  $OSSL ecparam -name prime256v1 -genkey -noout -out "$TLS/server/server-ecdsa.key"
  $OSSL req -new -key "$TLS/server/server-ecdsa.key" \
    -out "$TLS/server/server-ecdsa.csr" -config "$TLS/configs/server.cnf"
  $OSSL x509 -req -in "$TLS/server/server-ecdsa.csr" -CA "$TLS/ca/ca.crt" -CAkey "$TLS/ca/ca.key" -CAcreateserial \
    -out "$TLS/server/server-ecdsa.crt" -days 825 -sha512 \
    -extfile "$TLS/configs/server.cnf" -extensions v3_req
fi

# ML-DSA client cert
if [[ ! -s "$TLS/client/client.crt" ]]; then
  $OSSL genpkey -algorithm MLDSA65 \
    -provider default -provider /opt/openssl-3/lib/ossl-modules/oqsprovider.so \
    -out "$TLS/client/client.key"
  $OSSL req -new -key "$TLS/client/client.key" \
    -out "$TLS/client/client.csr" \
    -subj "/C=US/ST=FL/L=Miami/O=PQ-IoT/OU=Device/CN=sensor-client"
  $OSSL x509 -req -in "$TLS/client/client.csr" -CA "$TLS/ca/ca.crt" -CAkey "$TLS/ca/ca.key" \
    -out "$TLS/client/client.crt" -days 825 -sha512
fi

chmod 600 "$TLS"/{ca/ca.key,client/client.key,server/server-ecdsa.key} || true
chmod 644 "$TLS"/{ca/ca.crt,client/client.crt,server/server-ecdsa.crt} || true

echo "✅ PQC certs ready:"
$OSSL x509 -in "$TLS/ca/ca.crt" -noout -issuer -subject -text | grep -i "Signature Algorithm" | head -n1
$OSSL x509 -in "$TLS/client/client.crt" -noout -text | grep -i "Signature Algorithm" | head -n1

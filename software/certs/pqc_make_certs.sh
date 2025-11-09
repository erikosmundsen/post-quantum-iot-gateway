#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p out
cd out

# Pick the best available PQ signature algorithm on this build
choose_sig() {
  if openssl list -signature-algorithms 2>/dev/null | grep -qi '^mldsa65$'; then
    echo mldsa65
  elif openssl list -signature-algorithms 2>/dev/null | grep -qi '^dilithium3$'; then
    echo dilithium3
  elif openssl list -signature-algorithms 2>/dev/null | grep -qi '^p384_mldsa65$'; then
    echo p384_mldsa65
  elif openssl list -signature-algorithms 2>/dev/null | grep -qi '^p256_mldsa44$'; then
    echo p256_mldsa44
  elif openssl list -signature-algorithms 2>/dev/null | grep -qi '^p521_mldsa87$'; then
    echo p521_mldsa87
  else
    echo "ERROR: No suitable PQ signature alg found (mldsa*/dilithium*)."; exit 1
  fi
}

SIG_ALG="$(choose_sig)"
echo "[*] Using signature algorithm: $SIG_ALG"

# Clean any prior run
rm -f ca.* server.* client.* *.srl

# CA
openssl genpkey -algorithm "$SIG_ALG" -out ca.key
openssl req -x509 -new -key ca.key -subj "/CN=PQ Root CA" -days 3650 -out ca.crt

# Server
openssl genpkey -algorithm "$SIG_ALG" -out server.key
openssl req -new -key server.key -subj "/CN=mosquitto-server" -out server.csr
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -days 825 -out server.crt

# Client
openssl genpkey -algorithm "$SIG_ALG" -out client.key
openssl req -new -key client.key -subj "/CN=pq-client" -out client.csr
openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial -days 825 -out client.crt

echo "[*] Generated:"; ls -l ca.* server.* client.*

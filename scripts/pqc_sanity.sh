#!/usr/bin/env bash
set -euo pipefail
OSSL=/opt/openssl-3/bin/openssl

# Minimal config that forces the OQS provider:
cat > /tmp/oqs-min.cnf <<'CNF'
openssl_conf = openssl_init
[openssl_init]
providers = provider_sect
[provider_sect]
default = def
oqsprovider = oqs
[def]
activate = 1
[oqs]
module = /opt/openssl-3/lib/ossl-modules/oqsprovider.so
activate = 1
CNF

# Clean env so nothing leaks:
env -i PATH=/usr/bin:/bin:/opt/openssl-3/bin \
  LD_LIBRARY_PATH=/opt/openssl-3/lib \
  OPENSSL_CONF=/tmp/oqs-min.cnf \
  $OSSL list -providers

mkdir -p "$HOME/post-quantum-iot-gateway/artifacts/tls/ca"
cd       "$HOME/post-quantum-iot-gateway/artifacts/tls"

# Generate ML-DSA-65 CA key (providers explicitly named)
env -i PATH=/usr/bin:/bin:/opt/openssl-3/bin \
  LD_LIBRARY_PATH=/opt/openssl-3/lib \
  OPENSSL_CONF=/tmp/oqs-min.cnf \
  $OSSL genpkey -algorithm ML-DSA-65 \
    -provider /opt/openssl-3/lib/ossl-modules/oqsprovider.so \
    -provider default \
    -out ca/ca.key

# Quick sanity on the key
head -n 3 ca/ca.key

echo "Sanity OK: ML-DSA-65 key created."

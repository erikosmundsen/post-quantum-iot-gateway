#!/usr/bin/env bash
set -euo pipefail

REPO="$HOME/post-quantum-iot-gateway"
ART="$REPO/artifacts"
TLS_DIR="$ART/tls"
CONF_DIR="$TLS_DIR/configs"
MOSQ_CONF="$ART/mosquitto/pqc-mtls.conf"
OSSL="/opt/openssl-3/bin/openssl"

# PQC/OpenSSL env for this script
export PATH="/opt/openssl-3/bin:/usr/sbin:/usr/bin:/bin:$PATH"
export LD_LIBRARY_PATH="/opt/openssl-3/lib"
export OPENSSL_MODULES="/opt/openssl-3/lib/ossl-modules"
export OPENSSL_CONF="$ART/pqc/openssl-pqc.cnf"

mkdir -p "$TLS_DIR/ca" "$TLS_DIR/server" "$TLS_DIR/client" "$CONF_DIR" "$ART/mosquitto"

# CA config
cat > "$CONF_DIR/ca_sign.cnf" <<'CNC'
[ ca ]
default_ca = myca
[ myca ]
x509_extensions = v3_ca
[ v3_ca ]
basicConstraints = critical,CA:true
keyUsage = critical, keyCertSign, cRLSign
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer:always
CNC

# Server req config
cat > "$CONF_DIR/server_req.cnf" <<'SNC'
[ req ]
distinguished_name = dn
prompt = no
req_extensions = v3_req
[ dn ]
C  = US
ST = FL
L  = Miami
O  = PQ-IoT
OU = Gateway
CN = raspberrypi.local
[ v3_req ]
subjectAltName = @alt_names
[ alt_names ]
DNS.1 = raspberrypi.local
DNS.2 = localhost
IP.1  = 127.0.0.1
SNC

# Client req config
cat > "$CONF_DIR/client_req.cnf" <<'CLC'
[ req ]
distinguished_name = dn
prompt = no
[ dn ]
C  = US
ST = FL
L  = Miami
O  = PQ-IoT
OU = Device
CN = sensor-client
CLC

# Create ML-DSA CA (if missing)
/usr/bin/test -s "$TLS_DIR/ca/ca.crt" || {
  $OSSL genpkey -algorithm ML-DSA-65 -provider oqsprovider -provider default -out "$TLS_DIR/ca/ca.key"
  $OSSL req -x509 -new -key "$TLS_DIR/ca/ca.key" -out "$TLS_DIR/ca/ca.crt" -days 3650 \
    -subj "/C=US/ST=FL/L=Miami/O=PQ-IoT/OU=Root CA/CN=PQIoT-MLDSA65-CA" \
    -sha512 -config "$CONF_DIR/ca_sign.cnf" -extensions v3_ca
}

# Create ML-DSA client cert (if missing)
/usr/bin/test -s "$TLS_DIR/client/client.crt" || {
  $OSSL genpkey -algorithm ML-DSA-65 -provider oqsprovider -provider default -out "$TLS_DIR/client/client.key"
  $OSSL req -new -key "$TLS_DIR/client/client.key" -out "$TLS_DIR/client/client.csr" -config "$CONF_DIR/client_req.cnf"
  $OSSL x509 -req -in "$TLS_DIR/client/client.csr" -CA "$TLS_DIR/ca/ca.crt" -CAkey "$TLS_DIR/ca/ca.key" \
    -out "$TLS_DIR/client/client.crt" -days 825 -sha512
}

# Temporary ECDSA server key/cert (for Mosquitto)
/usr/bin/test -s "$TLS_DIR/server/server-ecdsa.crt" || {
  $OSSL ecparam -name prime256v1 -genkey -noout -out "$TLS_DIR/server/server-ecdsa.key"
  $OSSL req -new -key "$TLS_DIR/server/server-ecdsa.key" -out "$TLS_DIR/server/server-ecdsa.csr" -config "$CONF_DIR/server_req.cnf"
  $OSSL x509 -req -in "$TLS_DIR/server/server-ecdsa.csr" -CA "$TLS_DIR/ca/ca.crt" -CAkey "$TLS_DIR/ca/ca.key" -CAcreateserial \
    -out "$TLS_DIR/server/server-ecdsa.crt" -days 825 -sha512 -extfile "$CONF_DIR/server_req.cnf" -extensions v3_req
}

chmod 600 "$TLS_DIR"/{ca/ca.key,client/client.key,server/server-ecdsa.key} || true
chmod 644 "$TLS_DIR"/{ca/ca.crt,client/client.crt,server/server-ecdsa.crt} || true

# Broker config (TLS 1.3 + mTLS)
cat > "$MOSQ_CONF" <<MCF
listener 8883
cafile  $TLS_DIR/ca/ca.crt
certfile $TLS_DIR/server/server-ecdsa.crt
keyfile  $TLS_DIR/server/server-ecdsa.key
require_certificate true
use_identity_as_username true
tls_version tlsv1.3
log_type all
MCF

echo "✅ Setup complete. Starting Mosquitto..."
env -i \
  PATH="/usr/sbin:/usr/bin:/bin:/opt/openssl-3/bin" \
  LD_LIBRARY_PATH="/opt/openssl-3/lib" \
  OPENSSL_CONF="$OPENSSL_CONF" \
  OPENSSL_MODULES="/opt/openssl-3/lib/ossl-modules" \
  HOME="$HOME" \
  "$(command -v mosquitto)" -c "$MOSQ_CONF" -v

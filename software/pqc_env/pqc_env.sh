#!/usr/bin/env bash
# This loads our post-quantum version of OpenSSL

export OQS_OPENSSL="/opt/oqsprovider"
export OPENSSL_MODULES="/usr/lib/aarch64-linux-gnu/ossl-modules"
export PATH="$OQS_OPENSSL/bin:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export OPENSSL_CONF="$SCRIPT_DIR/pqc_openssl.cnf"

echo "[PQC] Environment ready"
openssl version

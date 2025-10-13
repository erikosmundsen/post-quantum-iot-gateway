#!/usr/bin/env bash
export PATH=/opt/openssl-3/bin:$PATH
export LD_LIBRARY_PATH=/opt/openssl-3/lib:/usr/local/lib
export OPENSSL_MODULES=/opt/openssl-3/lib/ossl-modules
export OPENSSL_CONF=$HOME/post-quantum-iot-gateway/artifacts/pqc/openssl-pqc-min.cnf

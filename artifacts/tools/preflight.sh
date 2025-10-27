#!/usr/bin/env bash
set -euo pipefail
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
: "${HOME:=/home/erikosmundsen13}"
# Usage: preflight.sh [/path/to/mosquitto.conf]

pick_conf() {
  local c="${1:-}"
  for x in "$c" \
           "$HOME/post-quantum-iot-gateway/artifacts/mosquitto/pqc-mtls.conf" \
           "/etc/mosquitto/conf.d/pqc-mtls.conf" \
           "/etc/mosquitto/mosquitto.conf"; do
    [ -n "$x" ] && [ -f "$x" ] && { echo "$x"; return; }
  done
  echo ""
}

CONF="$(pick_conf "${1-}")"
[ -n "$CONF" ] || { echo "PRECHECK: no mosquitto config found."; exit 1; }
echo "PRECHECK: using config: $CONF"

line() { awk '!/^\s*#/{print}' "$CONF"; }
get1() { line | awk -v k="$1" '$1==k{print $2; exit}'; }

CA=$(get1 cafile)
SRV=$(get1 certfile)
KEY=$(get1 keyfile)
PORT=$(line | awk '$1=="listener"{print $2; exit}')
TLSVER=$(get1 tls_version)
HAS_CIPHERS=$(line | grep -E '^[[:space:]]*ciphers[[:space:]]' || true)
HAS_CIPHERS13=$(line | grep -E '^[[:space:]]*ciphers_tls13[[:space:]]' || true)

err(){ echo "PRECHECK: ERROR: $*" >&2; exit 1; }
warn(){ echo "PRECHECK: WARN:  $*" >&2; }

[ -n "$CA"  ]  || err "cafile not set in $CONF"
[ -n "$SRV" ]  || err "certfile not set in $CONF"
[ -n "$KEY" ]  || err "keyfile not set in $CONF"
[ -n "$PORT" ] || { PORT="8883"; warn "no 'listener' found; defaulting port=$PORT"; }

[ -f "$CA"  ] || err "missing CA: $CA"
[ -f "$SRV" ] || err "missing server cert: $SRV"
[ -f "$KEY" ] || err "missing server key: $KEY"

openssl x509 -in "$CA"  -noout -text | grep -qi 'sha1' && err "CA shows SHA-1"
openssl x509 -in "$SRV" -noout -text | grep -qi 'sha1' && err "Server cert shows SHA-1"

openssl verify -CAfile "$CA" "$SRV" | grep -q ': OK' || err "OpenSSL verify failed"

runuser -u mosquitto -- head -c1 "$CA"  >/dev/null 2>&1 || err "mosquitto cannot read CA (check ACLs)"
runuser -u mosquitto -- head -c1 "$SRV" >/dev/null 2>&1 || err "mosquitto cannot read server cert (check ACLs)"
runuser -u mosquitto -- head -c1 "$KEY" >/dev/null 2>&1 || err "mosquitto cannot read server key (group/ACL)"

[ -n "${TLSVER:-}" ] || warn "tls_version not set; Mosquitto may allow < TLS 1.3"
echo "${TLSVER:-}" | grep -qi 'tlsv1\.3' || warn "tls_version is not TLSv1.3 (found: '${TLSVER:-unset}')"
[ -z "$HAS_CIPHERS" ]   || warn "legacy 'ciphers' present (TLS ≤1.2). Remove for TLS 1.3-only listeners."
[ -z "$HAS_CIPHERS13" ] || warn "'ciphers_tls13' present; consider removing to use OpenSSL defaults."

if ss -tln | awk '{print $4}' | grep -q ":$PORT$"; then
  warn "port $PORT already in use (ok if broker running)"
else
  echo "PRECHECK: port $PORT free"
fi

echo "PRECHECK: OK"

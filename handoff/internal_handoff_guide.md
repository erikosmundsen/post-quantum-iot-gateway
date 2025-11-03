# Post-Quantum IoT Gateway – Internal Handoff Guide

## Overview

This document is intended for internal use by the team to coordinate the next phase of the project now that mutual TLS (mTLS) with post-quantum certificates is operational. It outlines what has been completed, what responsibilities are delegated, and what guidance is available for team members starting development on the Arduino side and the API/GUI layer.

The system now supports:

- A functional Mosquitto MQTT broker secured with TLS 1.3 and post-quantum client/server certificates (ML-DSA-65 via OpenSSL + liboqs)
- Preflight configuration and validation scripts
- Verified broker listening on port `8884` with working publisher/subscriber test scripts

The next steps involve plugging in the sensor layer (via Arduino) and the application layer (via API + GUI).

---

## Completed Setup

The following are working and documented in the `README.md` on branch `docs/full-setup`:

- End-to-end setup instructions for mTLS with PQC certificates on a Raspberry Pi 4
- Scripted environment to generate certificates, provision the broker, and validate security
- Working publisher and subscriber demo (`pqc_pub.sh`, `pqc_sub.sh`)
- Preflight script to catch config errors before Mosquitto startup
- Folder structure organized into:
  - `artifacts/` for configs and certs
  - `scripts/` for automation
  - `software/` for Python MQTT demo clients

---

## Arduino Integration

### What’s expected

- Use the Arduino to collect sensor data (e.g., DHT11).
- Transmit data via serial (USB) to the Raspberry Pi.

### What you need to know

- The Pi runs a Python script that reads from `/dev/ttyUSB0` or similar.
- This script then **publishes to MQTT on `localhost:8884`** with post-quantum certificates.
- No TLS is needed on the Arduino side — the Pi terminates all secure connections.
- The Arduino should simply print newline-delimited or JSON-formatted data over serial.

### Next steps

- Write and flash a sketch that reads the sensor and outputs to serial.
- Test the serial connection using screen or a Python script.
- Collaborate on message format (JSON recommended: `{ "temperature": ..., "humidity": ... }`)

---

## API and GUI Integration

### What’s expected
# Post-Quantum IoT Gateway – Internal Handoff Guide

## Overview

This document is intended for internal use by the team to coordinate the next phase of the project now that mutual TLS (mTLS) with post-quantum certificates is operational. It outlines what has been completed, what responsibilities are delegated, and what guidance is available for team members starting development on the Arduino side and the API/GUI layer.

The system now supports:

- A functional Mosquitto MQTT broker secured with TLS 1.3 and post-quantum client/server certificates (ML-DSA-65 via OpenSSL + liboqs)
- Preflight configuration and validation scripts
- Verified broker listening on port `8884` with working publisher/subscriber test scripts

The next steps involve plugging in the sensor layer (via Arduino) and the application layer (via API + GUI).

---

## Completed Setup

The following are working and documented in the `README.md` on branch `docs/full-setup`:

- End-to-end setup instructions for mTLS with PQC certificates on a Raspberry Pi 4
- Scripted environment to generate certificates, provision the broker, and validate security
- Working publisher and subscriber demo (`pqc_pub.sh`, `pqc_sub.sh`)
- Preflight script to catch config errors before Mosquitto startup
- Folder structure organized into:
  - `artifacts/` for configs and certs
  - `scripts/` for automation
  - `software/` for Python MQTT demo clients

---

## Arduino Integration

### What’s expected

- Use the Arduino to collect sensor data (e.g., DHT11).
- Transmit data via serial (USB) to the Raspberry Pi.

### What you need to know

- The Pi runs a Python script that reads from `/dev/ttyUSB0` or similar.
- This script then **publishes to MQTT on `localhost:8884`** with post-quantum certificates.
- No TLS is needed on the Arduino side — the Pi terminates all secure connections.
- The Arduino should simply print newline-delimited or JSON-formatted data over serial.

### Next steps

- Write and flash a sketch that reads the sensor and outputs to serial.
- Test the serial connection using screen or a Python script.
- Collaborate on message format (JSON recommended: `{ "temperature": ..., "humidity": ... }`)

---

## API and GUI Integration

### What’s expected

- Build an API and GUI that reads MQTT messages from the broker and presents them via a dashboard or HTTP endpoints.
- The backend service must authenticate to the broker using mTLS and the provided PQ certs.

### Credentials already provisioned

The following certs are available on the Pi (and used in test scripts):

- `/etc/mosquitto/pqc/ca/ca_cert.pem`
- `/etc/mosquitto/pqc/client/client_cert.pem`
- `/etc/mosquitto/pqc/client/client_key.pem`

### Guidelines

- Use `mqtts://localhost:8884` for all secure broker connections.
- You may use any HTTP framework (Flask, FastAPI, etc.) and any MQTT client that supports TLS and client certs.
- Connection code can follow the same structure as `pqc_pub.sh` or `pqc_sub.sh`.
- The GUI may use a polling approach (fetch from API) or push-based (subscribe directly).

---

Keep this document updated as integration work continues.

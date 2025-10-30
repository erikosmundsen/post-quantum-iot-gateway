# Post-Quantum IoT Gateway – Internal Handoff Guide

## Overview

This document is intended for internal use by the team to coordinate the next phase of the project now that **mutual TLS (mTLS) with post-quantum certificates** is operational. It outlines what has been completed, what responsibilities are delegated, and what guidance is available for team members starting development on the Arduino side and the API/GUI layer.

The system now supports:

- A functional Mosquitto MQTT broker secured with TLS 1.3 and post-quantum client/server certificates (ML-DSA-65 via OpenSSL + liboqs)
- Preflight configuration and validation scripts
- Verified broker listening on port 8884 with working publisher/subscriber test scripts

The next steps involve plugging in the sensor layer (via Arduino) and the application layer (via API + GUI).

---

## Completed Setup

The following are working and documented in the `README.md` (branch: `docs/full-setup`):

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

**What’s expected:**

- Use the Arduino (Uno/Nano/etc.) to collect sensor data (e.g., DHT11).
- Transmit data via **serial (USB)** to the Raspberry Pi.

**What you need to know:**

- The Pi will run a Python script that reads the serial input from `/dev/ttyUSB0` or similar and publishes it to MQTT (`localhost:8884`).
- No TLS is needed on the Arduino side — all TLS is terminated at the Pi.
- The Arduino can just `Serial.println()` JSON-formatted or newline-delimited readings.

**Next steps:**

- Write a simple sketch to read the sensor and print data over serial
- Test serial communication with Pi using `screen` or a Python serial monitor
- Share expected message format with the API team (ideally JSON with fields like "temperature" and "humidity")
# Post-Quantum Secure IoT Gateway

## Project Overview

This project demonstrates an early-stage prototype of a secure IoT gateway built using a Raspberry Pi 4. It reads data from a DHT11 temperature and humidity sensor and transmits that data using MQTT (Message Queuing Telemetry Transport). The final goal is to secure this communication using **TLS 1.3** and **Post-Quantum Cryptography** (Kyber and Dilithium via liboqs/OpenSSL).

This version of the project includes a working sensor-to-MQTT pipeline.  
This repository now includes a working MQTT pipeline secured with TLS 1.3 mutual authentication; client authentication and the trust anchor use a post-quantum ML-DSA-65 CA via the OQS provider for OpenSSL.

---

## Hardware Used

| Component        | Description                             |
|------------------|-----------------------------------------|
| Raspberry Pi 4   | Main controller for the IoT gateway     |
| DHT11 Sensor     | Temperature and humidity sensor         |
| Breadboard       | For prototyping the circuit             |
| Jumper Wires     | For making GPIO connections             |
| 10kΩ Resistor    | Pull-up resistor on DHT11 data line     |
| MicroSD Card     | Storage for Raspberry Pi OS             |
| Power Supply     | 5V 3A USB-C power for the Raspberry Pi  |

See the full Bill of Materials here: [`hardware/BOM.md`](hardware/BOM.md)

---

## Demo Summary

This demo shows a basic working system with:

- Sensor data collected using the DHT11 connected to the Raspberry Pi GPIO
- Real-time data publishing over MQTT using the Mosquitto broker (localhost)
- Two-terminal output: one for sensor publishing, one for MQTT subscription
- Python scripts written and documented for ease of use

In future stages, we will secure MQTT using TLS 1.3 and add post-quantum security using Kyber/Dilithium via `liboqs`.

---

## How It Works (Demo Version)

1. The DHT11 sensor is connected to GPIO4 on the Raspberry Pi.
2. A Python script (`publish_dht11_mqtt.py`) reads the sensor values.
3. The values are published to a local Mosquitto MQTT broker on the topic `sensor/data`.
4. A second terminal listens to that topic using `mosquitto_sub`.

Detailed setup and usage instructions are available here:  
[`documentation/setup_instructions.md`](documentation/setup_instructions.md)

---

## Repository Structure

```plaintext
post-quantum-iot-gateway/
├── diagrams/                   # Block diagram and schematic
│   └── block-diagram.png
├── documentation/              # Setup guide and demo checklist
│   ├── setup_instructions.md
│   └── demo_checklist.md
├── hardware/                   # BOM and schematics
│   ├── BOM.md
│   └── schematics/
│       └── raspberrypi-dht11.png
├── software/                   # Python scripts
│   ├── dht11_reader.py
│   └── publish_dht11_mqtt.py
├── requirements.txt            # Python dependencies
├── .gitignore
└── README.md                   # You're here!

---

## Security (TLS 1.3 mTLS)

This project now runs Mosquitto over TLS 1.3 with mutual authentication.  
The Root CA and client certificates use ML-DSA-65 (via the OQS provider), and the broker serves an ECDSA P-256 server certificate signed by that CA for compatibility.

**Test it:**
```bash
./scripts/pqc_sub.sh
./scripts/pqc_pub.sh

Hello from PQC mTLS!

```

**Expected output on subscriber:**
```
Hello from PQC mTLS!
```

---

## 🔧 Setup Instructions (Updated)

This project requires two sets of dependencies — one for the IoT sensor demo (DHT11), and another for the secure MQTT + Post-Quantum Cryptography stack.

### 1. Sensor & MQTT Libraries (Python)
These are used for collecting temperature/humidity data and publishing over MQTT.
```bash
sudo apt-get install -y python3-pip
pip3 install paho-mqtt Adafruit_DHT

sudo apt-get install -y build-essential cmake git pkg-config ca-certificates curl ninja-build libssl-dev

# liboqs (Open Quantum Safe cryptographic library)
cd ~/oqs-work
git clone https://github.com/open-quantum-safe/liboqs.git
cd liboqs
git submodule update --init --recursive
mkdir build && cd build
cmake -G "Ninja" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local ..
ninja
sudo ninja install
sudo ldconfig

# OpenSSL 3 + OQS Provider (for PQC TLS 1.3)
cd ~/oqs-work
curl -LO https://www.openssl.org/source/openssl-3.2.1.tar.gz
tar xzf openssl-3.2.1.tar.gz
cd openssl-3.2.1
./Configure linux-aarch64 --prefix=/opt/openssl-3 --libdir=lib
make -j"$(nproc)"
sudo make install_sw

# OQS Provider
cd ~/oqs-work
git clone https://github.com/open-quantum-safe/oqs-provider.git
cd oqs-provider
cmake -S . -B _build -G "Ninja" \
  -DOPENSSL_ROOT_DIR=/opt/openssl-3 \
  -Dliboqs_DIR=/usr/local/lib/cmake/liboqs
cmake --build _build -j"$(nproc)"
sudo cmake --install _build

sudo apt-get install -y mosquitto mosquitto-clients


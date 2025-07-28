# Post-Quantum Secure IoT Gateway

## Project Overview

This project demonstrates an early-stage prototype of a secure IoT gateway built using a Raspberry Pi 4. It reads data from a DHT11 temperature and humidity sensor and transmits that data using MQTT (Message Queuing Telemetry Transport). The final goal is to secure this communication using **TLS 1.3** and **Post-Quantum Cryptography** (Kyber and Dilithium via liboqs/OpenSSL).

This version of the project includes a working sensor-to-MQTT pipeline.  
TLS and Post-Quantum integration are planned for the next phase.

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

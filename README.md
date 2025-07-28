# Post-Quantum Secure IoT Gateway

## Project Description

This project demonstrates a secure IoT gateway that uses Post-Quantum Cryptography (PQC) to protect data communication. It includes:

- A DHT11 sensor for temperature and humidity monitoring
- The Mosquitto MQTT Broker for messaging
- TLS 1.3 for transport-layer encryption
- Kyber and Dilithium for post-quantum secure key exchange and signatures
- All implemented on a Raspberry Pi 4

The gateway encrypts sensor data and publishes it securely to subscribed clients over MQTT.

---

## Hardware Components

| Component        | Description                             | Quantity |
|------------------|-----------------------------------------|----------|
| Raspberry Pi 4   | Main IoT Gateway controller              | 1        |
| MicroSD Card     | RPi OS Storage (16GB or higher)          | 1        |
| Power Supply     | 5V 3A USB-C Power for Pi                 | 1        |
| Breadboard       | For prototyping and sensor connection    | 1        |
| Jumper Wires     | M-to-M connections                       | Assorted |
| DHT11 Sensor     | Temperature and humidity sensor          | 1        |
| 10kΩ Resistor    | Pull-up resistor for DHT11 data line     | 1        |
| Ethernet Cable   | Optional (Wi-Fi also supported)          | 1        |

See [`hardware/BOM.md`](hardware/BOM.md) for purchase links and prices.

---

## Diagrams and Schematics

### Block Diagram

This diagram shows the flow of data from the DHT11 sensor to the Raspberry Pi IoT gateway, through the MQTT broker secured with TLS 1.3 and post-quantum cryptography.

See: [`diagrams/block-diagram.png`](diagrams/block-diagram.png)

### Wiring Schematic

This schematic shows how to connect the DHT11 sensor to the Raspberry Pi, including the 10kΩ pull-up resistor on the data line.

See: [`diagrams/schematic.png`](diagrams/schematic.png)

## Documentation

- [Technologies Explained](documentation/technologies_explained.md): Simple guide on MQTT, TLS 1.3, Mosquitto, and post-quantum crypto.

- [Demo Video Checklist](documentation/demo_checklist.md)

This checklist includes:
- Video storyboard requirements
- Team roles and responsibilities
- Required content and hardware footage
- Visual and narration guidelines

---

## Project Status

- Block diagram completed  
- Schematic completed  
- Hardware staged  
- DHT11 sensor pending arrival  
- Software configuration in progress  

---

## Repository Structure

```plaintext
post-quantum-iot-gateway/
├── diagrams/
│   ├── block-diagram.png
├── hardware/
│   └── BOM.md
│   └── schematics/
│       └── raspberrypi-dht11.png
├── software/
├── documentation/
├── README.md
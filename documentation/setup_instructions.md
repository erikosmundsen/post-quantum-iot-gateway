# Setup Instructions – DHT11 MQTT Demo

This guide walks you step-by-step through setting up the working demo for the Post-Quantum Secure IoT Gateway. It covers hardware wiring, software installation, running the demo, and verifying that MQTT is working properly.

---

## Overview

In this demo, we will:

- Wire a DHT11 sensor to the Raspberry Pi
- Install required software and libraries
- Use one terminal to publish sensor data
- Use another terminal to receive data over MQTT
- Confirm the pipeline works from sensor → Python → MQTT → subscriber

This guide is intended for beginners and assumes no prior experience with MQTT or Python.

---

## Hardware Wiring

### Components Required

| Component        | Description                       |
|------------------|-----------------------------------|
| Raspberry Pi 4   | Running Raspberry Pi OS           |
| DHT11 Sensor     | Temperature and humidity sensor   |
| Breadboard       | For prototyping                   |
| Jumper Wires     | For GPIO connections              |
| 10kΩ Resistor    | Pull-up on DHT11 data line        |

### DHT11 Pinout

| DHT11 Pin | Connects To      |
|-----------|------------------|
| VCC       | 3.3V (Pin 1)      |
| DATA      | GPIO4 (Pin 7)     |
| GND       | GND (Pin 6)       |
| 10kΩ Resistor | Between VCC and DATA (pull-up) |

Refer to: [`diagrams/schematic.png`](../diagrams/schematic.png)

---

## Software Setup

### 1. Clone the Repository

```
git clone git@github.com:erikosmundsen13/post-quantum-iot-gateway.git
cd post-quantum-iot-gateway
```

### 2. Create and Activate a Python Virtual Environment

```
python3 -m venv venv
source venv/bin/activate
```

### 3. Install Required Python Libraries

Make sure you're inside the virtual environment:
```
pip install -r requirements.txt
```
The libraries installed will include:
- Adafruit_DHT (for reading the sensor)
- paho-mqtt (for publishing to MQTT)

## Install MQTT Broker (Mosquitto)

Install Mosquitto and its command-line tools:
```
sudo apt update
sudo apt install mosquitto mosquitto-clients
```
Enable and start the broker:
```
sudo systemctl enable mosquitto
sudo systemctl start mosquitto
```
## Running the Demo

Open two terminal windows or tabs on your Raspberry Pi.

### Terminal 1: Start the MQTT Subscriber

This window listens for data being published.
```
mosquitto_sub -h localhost -t "sensor/data" -v
```
Keep this window open. You’ll see output appear here once the script publishes data.

### Terminal 2: Run the Publisher Script

This window reads the sensor and sends the data.
```
cd ~/post-quantum-iot-gateway
source venv/bin/activate
python3 software/publish_dht11_mqtt.py
```

You should see output like:
```
Published: Temperature: 24.0°C, Humidity: 49.0%
```

And in Terminal 1, you'll see:
```
sensor/data Temperature: 24.0°C, Humidity: 49.0%
```

That means your sensor → Python → MQTT → terminal pipeline works!

## Troubleshooting Tips

Sensor not detected?
- Double-check wiring: is GPIO4 connected to DATA?
- Try using a 10kΩ resistor between VCC and DATA
- Make sure the Pi is supplying 3.3V to the sensor
- Reboot and try again

MQTT messages not appearing?
- Is the Mosquitto broker running?
```
sudo systemctl status mosquitto
```
- Try restarting it:
```
sudo systemctl restart mosquitto
```
- Make sure you are subscribed to the correct topic: sensor/data

## Clean Up (Optional)

To deactivate the virtual environment when done:
```
deactivate
```

To stop the broker:
```
sudo systemctl stop mosquitto
```

## Related Files
- software/publish_dht11_mqtt.py – MQTT publishing script
- software/dht11_reader.py – basic reader for sensor testing
- requirements.txt – required Python packages
- README.md – full project overview

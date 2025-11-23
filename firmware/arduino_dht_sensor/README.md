# Arduino and ESP32 Firmware for Serial DHT Sensor Node

This folder contains the firmware used by the Arduino or ESP32 when acting as a serial-based sensor node for the Post-Quantum Secure IoT Gateway. The purpose of this code is simple: the microcontroller reads a DHT sensor and prints a small JSON message over USB so the Raspberry Pi can read it, normalize it, and publish it securely to the PQC-protected MQTT broker. All of the TLS and MQTT work happens on the Pi. The microcontroller only needs to send JSON over serial.

## What this firmware does

The sketch in `arduino_dht_sensor.ino` reads temperature and humidity from a DHT sensor and prints a JSON line that looks like this:

```json
{"temp_c": 22.15, "hum": 41.90}
```

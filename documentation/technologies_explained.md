# Technologies Explained

This file provides a beginner-friendly explanation of the technologies used in the Post-Quantum Secure IoT Gateway project.

---

## MQTT (Message Queuing Telemetry Transport)
MQTT is a lightweight messaging protocol used for sending data between devices — perfect for IoT. It uses a "publish/subscribe" model where devices publish data and others subscribe to it.

---

## TLS 1.3 (Transport Layer Security)
TLS 1.3 is the latest encryption protocol used to secure data as it moves across the internet. It prevents anyone from snooping on your IoT data.

---

## Mosquitto
Mosquitto is an open-source MQTT broker that manages the sending and receiving of messages between devices.

---

## Kyber & Dilithium (Post-Quantum Cryptography)
These are new encryption algorithms designed to protect data from quantum computers. They are more secure than classical cryptography and are part of the NIST post-quantum standardization.

---

## OpenSSL with liboqs
- **OpenSSL** is a software library that supports encryption.
- **liboqs** is an extension that allows OpenSSL to support Kyber and Dilithium for post-quantum security.
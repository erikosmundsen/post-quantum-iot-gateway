# Post-Quantum Secure IoT Gateway

## Introduction & Project Overview

Most small IoT systems today rely on cryptographic tools that are strong for the moment but may fail the moment large-scale quantum computers arrive. It is easy to forget that the sensors and microcontrollers we deploy today will still be running five, ten, or fifteen years from now. If their security depends on algorithms that future machines can break, the entire chain collapses.

This project explores what it looks like to build a small IoT gateway on a Raspberry Pi using post-quantum cryptography. The goal is not to produce a commercial device. The goal is to create a working, understandable example of how to combine modern IoT design with the next generation of cryptographic tools. In other words, this is a teaching system that happens to be fully functional.

The gateway accepts data from different kinds of sensor nodes. One type of node is directly connected to the Pi and uses a DHT11 temperature and humidity sensor. Another type of node uses an ESP32 or Arduino board connected through USB and sends readings as JSON text. Whatever the shape of the node, its data flows into a Mosquitto MQTT broker running on the Pi. This broker does not use passwords or insecure defaults. It requires TLS 1.3 with mutual authentication, and the certificates involved are created with post-quantum signature algorithms provided by the Open Quantum Safe project.

A FastAPI backend subscribes to the sensor messages coming through the broker. The API normalizes the structure of each reading so that the dashboard can treat all sensors in a consistent way. The backend also provides a live dashboard that displays the latest values and a rolling history. This gives you a clear picture of how data is moving through the system.

One of the main ideas in this project is portability. Hardcoded file paths and assumptions about usernames or Pi models always lead to fragile systems that only work on the machine they were developed on. To avoid this, each part of the gateway reads its configuration from small, clearly named environment files. If you move this project to a different Raspberry Pi, those files are the only things you need to update. The setup script reads these files, checks that the system meets the required conditions, generates a ready-to-install Mosquitto configuration, and performs a quick health check. It never modifies the system automatically, which keeps beginners safe while still providing clear guidance.

Although this is a research prototype, it provides a realistic experience. Real sensors are read. Real MQTT traffic moves through the system. A real broker enforces strong security policies, and the data appears on a real dashboard. The value of this project is that it shows the full shape of an IoT gateway that is built with tomorrow in mind, not yesterday.

## System Architecture

This system is small enough to understand in one sitting, but it contains all the major parts of a modern IoT gateway. The design is built from the ground up to be approachable, while still reflecting real engineering decisions used in production environments.

At the outer edge of the system are the sensor nodes. These represent the physical world. In this prototype, there are two types of nodes. The first is a DHT11 sensor directly attached to the Raspberry Pi’s GPIO pins. The Pi reads temperature and humidity values through a Python script that uses the Adafruit DHT library. The second type of node uses an external microcontroller. An ESP32 or Arduino board is connected by USB and sends readings as JSON text over a serial connection. In both cases, the Pi acts as the first staging point for sensor data.

From there, data is sent to the Mosquitto MQTT broker running on the Pi. MQTT is a lightweight protocol that is well suited to small devices. The broker’s job is simple. It accepts messages from publishers, verifies that they are authenticated, and then forwards those messages to any subscribers who have registered an interest. The interesting part of this broker is not the protocol. What makes it special is the security configuration. Every connection to the broker requires TLS 1.3 mutual authentication. The certificates used for this authentication are created with post-quantum signature algorithms through the Open Quantum Safe OpenSSL provider. This means that even if a future quantum computer can break RSA or ECC, the identity verification in this system will still hold.

Once a message reaches the broker, it becomes available to the FastAPI backend. The backend subscribes to the sensor topic, receives each reading as it arrives, and performs a small amount of normalization. Each sensor publishes data in a slightly different format. Some send a field called temperature. Others send temp c or t. The API converts all of these into a uniform structure so that the rest of the system does not need to care which node sent which message. The API stores the latest reading as well as a history buffer large enough to support live visualization.

The dashboard is the outer face of the gateway. It is a simple HTTP interface served by FastAPI. It fetches data from the backend and displays it as a table of current values and a live chart of historical readings. The dashboard never interacts with Mosquitto directly. It only interacts with the API, which helps contain complexity and makes the visual layer easier to extend or replace.

A key part of the architecture is portability. Every piece of the system is configured through environment files rather than hardcoded paths or assumptions. The API knows where to connect by reading configs/api_portable.env. The DHT11 node reads configs/sensor_portable.env. The serial bridge has its own configuration file under software/serial_bridge. The MQTT command line tools use their own environment file as well. Even the PQC Mosquitto configuration can be generated from a portable template with a single script. This approach allows the entire system to be moved to a new Pi or a new directory simply by updating a few small files.

The architecture is deliberately simple. It does not attempt to include container orchestration, message persistence layers, or any heavy management features. Instead, it focuses on the core lifecycle of an IoT message. A value is read from a sensor. It is transferred securely to the broker. It flows into the backend. It appears on the screen. Every part of that journey uses modern tools, post-quantum cryptography, and a configuration model that emphasizes clarity. This keeps the design easy to understand while still demonstrating what a more advanced IoT system could look like.

## Cryptography Rationale

Security in IoT systems is usually an afterthought. Small devices often rely on weak authentication methods or outdated cryptographic libraries. They are designed to run for years without updates, which becomes a serious problem once their underlying algorithms are no longer secure. This project takes a different approach. Instead of accepting whatever security tools happen to be available on a Raspberry Pi by default, the gateway is built around a modern TLS 1.3 stack and a set of post-quantum security primitives that are intended to remain safe even when quantum computers become practical.

TLS 1.3 is the foundation of the secure channel. It simplifies the handshake, removes many older unsafe features, and provides strong forward secrecy. More importantly, it has a clean structure that is easier to adapt to new cryptographic algorithms. The system uses mutual TLS, which means both the server and the client authenticate themselves with certificates. In a typical consumer setup, only the server provides a certificate. The client connects blindly and trusts whatever certificate the server presents. Mutual TLS moves in the opposite direction. It requires every device that publishes to the gateway to present its own certificate, and that certificate must be signed by the gateway’s certificate authority. This gives the system a strong identity layer that is not dependent on passwords or insecure tokens.

The most important part of the design is the use of post-quantum signature schemes. The certificates used by the gateway are built using ML DSA 65, which is part of the Dilithium family of algorithms. These belong to a class of signature schemes that are believed to resist attacks from large quantum computers. Traditional algorithms such as RSA and ECDSA rely on mathematical problems that quantum algorithms are expected to break. Dilithium is based on lattice problems that are currently considered strong against both classical and quantum attacks.

To make all of this work on a Raspberry Pi, the system uses the Open Quantum Safe project’s support for integrating post-quantum algorithms into OpenSSL. The Pi builds its own copy of OpenSSL 3.2.1 that includes the OQS provider. This provider is a plug-in that extends OpenSSL with post-quantum algorithms. Once OpenSSL is built with OQS support, Mosquitto and the Python MQTT clients can use post-quantum certificates just like they would use traditional ones. The gateway does not need any special logic in the MQTT scripts or API. The cryptographic work is handled by the underlying library.

Although the system uses post-quantum signatures, it is important to be realistic about what is and is not post-quantum in this prototype. The handshake and certificate verification rely on ML DSA 65, but the key exchange may involve hybrid groups or classical elements, depending on the exact configuration of OQS OpenSSL. The system is intended to demonstrate a post-quantum identity layer, not a fully certified quantum resistant transport stack. This distinction matters in research and industry contexts, but the model remains valid. It shows how to begin integrating PQC tools into an existing IoT pipeline without replacing everything at once.

The decision to rely on mutual TLS with post-quantum certificates gives the gateway a forward-looking security posture. Even if the rest of the IoT world continues to rely on older algorithms, this project gives a concrete example of what a future resistant system can look like on real hardware today. It answers a simple but important question. If we were to build a secure IoT gateway for the next decade instead of the last one, what would the cryptography actually look like? The answer is here in this system, running on a Raspberry Pi, reading physical sensors, and authenticating every connection with signatures designed for a world where quantum attacks are practical.

## Sensor Nodes

An IoT gateway is only as interesting as the devices that speak to it. In this project, the gateway supports two different kinds of sensor nodes. Each one represents a different part of the real-world IoT ecosystem. The first type is a sensor directly attached to the Raspberry Pi. The second is an external microcontroller device that communicates through a serial link. Together they show how an IoT gateway can bridge hardware of different capabilities and communication styles while using the same secure pipeline.

### 1. Pi-based DHT11 Node

The simplest sensor in the system is a DHT11 temperature and humidity module connected to the GPIO pins of the Raspberry Pi. The DHT11 is not a high-precision device, but it is an ideal example for a small gateway. It gives predictable readings, it is electrically safe for beginners, and it has a well maintained Python library that works smoothly on the Pi.

The DHT11 script reads raw sensor values through the Adafruit DHT library. The script then packages the reading into a compact JSON structure. It includes the temperature in Celsius, the humidity percentage, the Unix timestamp, and the size of the payload in bytes. The script sends that JSON to the MQTT broker using TLS 1.3 with mutual authentication. This means even the simplest node in the system participates fully in the security model.

The more interesting part of the Pi-based node is how it is configured. Nothing is hardcoded in the script. The GPIO pin number, the MQTT broker address, the TLS certificate paths, the MQTT topic, and even the client ID are all read from a small environment file. This allows the script to run on any Pi without modification. The script can point to a different broker, a different topic, or a different TLS directory simply by changing the env file. This is the first example of how the project avoids accidental dependencies on the local machine.

### 2. USB Serial Node (ESP32 or Arduino)

The second sensor path demonstrates a more general case. Many IoT devices have their own microcontroller and communicate using UART or USB serial. This project uses an ESP32 or Arduino board that reads a temperature and humidity sensor and prints the readings as JSON strings. The microcontroller does not know anything about TLS or PQC or MQTT. It only knows how to write bytes to a serial port. This separation lets the Pi act as a bridge between constrained devices and secure cloud-style messaging.

A portable Python script on the Pi reads from the serial device, usually /dev/ttyACM0 on most boards. The script listens for JSON messages. It ignores partial or malformed lines and only processes a reading when the entire payload begins with a brace and ends with one. It then applies a small normalization step. Different microcontrollers sometimes name fields differently. A field named temp_c or t is rewritten as temperature so that all nodes report in a consistent structure. The script then connects to the PQC MQTT broker using client certificates and publishes the normalized message.

Just like the DHT11 script, the serial bridge script is completely driven by environment files. The serial device path, baud rate, MQTT host, port, topic, and TLS certificate paths are all set in a separate configuration file. This makes the serial node portable in the same way as the Pi-based node. The Pi does not need to know which USB port the device will occupy on someone else’s machine. They simply edit the env file for their environment.

### 3. Why Two Node Types Matter

The two node types in this project illustrate two ends of the IoT spectrum. The GPIO-based node shows what happens when the Pi itself acts as the sensor. It handles both the physical reading and the secure MQTT publishing. The serial-based node represents the more common case where the sensor and the gateway are different devices. The gateway does not read physical pins. It just receives bytes over USB and forwards them securely.

Both nodes ultimately feed into the exact same MQTT topic and the exact same API endpoint. Because the gateway normalizes incoming messages, the dashboard does not need to care which device produced which reading. It treats everything as a unified stream of sensor data.

The point of having two node types is not to complicate the system. It is to show how flexible the pipeline is. Whether the data starts on a Pi CPU or a small microcontroller, it ends up following the same secure path and appears in the same dashboard. This is how real IoT gateways behave. They accept data from many devices, over many physical interfaces, and unify everything into a consistent format before sending it further upstream.

## Installation and Setup Guide

Setting up this gateway on a fresh Raspberry Pi is straightforward once you understand the moving parts. The goal of this guide is to walk through each step slowly and clearly so that anyone familiar with basic Raspberry Pi usage can get the system running without surprises. Nothing in this guide assumes expertise in cryptography or MQTT. It focuses on being practical.

### 1. Prepare the Raspberry Pi

Before anything else, the Raspberry Pi must meet a few requirements.
- The operating system should be Raspberry Pi OS 64 bit. The project relies on the aarch64 architecture so that the post-quantum OpenSSL build works correctly.
- The system package list should be up to date. Run sudo apt-get update before installing anything.
- You should be connected to the network because several tools and libraries need to be downloaded or cloned.

Check the architecture:

```
uname -m
```

If the output is aarch64, the Pi is ready for the PQC components. If it is armv7l or something else, the 64 bit image needs to be installed before continuing.

### 2. Clone the Repository

The repository contains all scripts, configuration templates, setup tools, and documentation needed for the gateway. Start by cloning it:

```
git clone https://github.com/erikosmundsen/post-quantum-iot-gateway.git
cd post-quantum-iot-gateway
```

You may optionally switch to the portability branch if that is where active development is happening:

```
git checkout feature/portability-pi
```

This directory is referred to as the project root for the rest of the guide.

### 3. Install System Packages

The project requires several common packages. These include Python libraries, development tools, and Mosquitto. Install them with:

```
sudo apt-get install -y python3-pip python3-venv python3-fastapi python3-uvicorn \
    python3-paho-mqtt python3-serial python3-libgpiod \
    mosquitto mosquitto-clients git cmake ninja-build build-essential pkg-config
```

Some Python packages may not be available as system packages on certain Pi OS releases. In that situation, they can be installed with pip:

```
python3 -m pip install --break-system-packages adafruit-blinka adafruit-circuitpython-dht fastapi uvicorn paho-mqtt pyserial
```

The --break-system-packages flag tells pip that you are intentionally adding packages to the system Python, which is sometimes necessary on Debian based systems.

### 4. Build the Post-Quantum OpenSSL Stack

The security model of this gateway depends on a version of OpenSSL that includes the Open Quantum Safe provider. This provider includes post-quantum signature algorithms such as ML DSA 65. Building this stack is documented in more depth in the project, but the basic process is:
- Clone and build liboqs.
- Build OpenSSL 3.2.1 using liboqs support.
- Install the resulting binaries under /opt/openssl-3.

At the end of this step, the following commands should work:

```
/opt/openssl-3/bin/openssl version
/opt/openssl-3/bin/openssl list -providers
```

You should see the oqs provider listed. If not, revisit the build instructions.

### 5. Configure Environment Files

The project separates configuration from code. Every component reads from small environment files that live under the configs directory or the relevant subsystem directory. These include:
- configs/mosquitto_pqc.env for the broker.
- configs/api_portable.env for the FastAPI backend.
- configs/sensor_portable.env for the DHT11 node.
- configs/mqtt_cli.env for the MQTT command line tools.
- software/serial_bridge/serial_portable.env for the serial bridge.

Each file contains variables such as:
- Broker host and port.
- Certificate file paths.
- MQTT topics.
- Serial device names.
- Client IDs.

These paths and values must be adjusted for each Raspberry Pi. This is the heart of portability. The code never needs to be changed, but the configuration does.

### 6. Generate the Portable PQC Mosquitto Configuration

A setup script is included to help beginners generate a usable Mosquitto configuration without editing anything manually. The script does not apply changes automatically. It only prepares the configuration and performs checks.

Run:

```
./scripts/setup_gateway.sh
```

The script performs the following checks:
- Validates that the Pi is running on aarch64.
- Confirms that the OQS OpenSSL install is available.
- Verifies that all required environment files exist.
- Generates a portable PQC broker configuration in build/pqc_mtls.conf.
- Performs a read-only certificate and config sanity check.

To install the generated broker configuration:

```
sudo cp build/pqc_mtls.conf /etc/mosquitto/conf.d/pqc_mtls.conf
sudo systemctl restart mosquitto
sudo systemctl status mosquitto
```

### 7. Start the API and Dashboard

The FastAPI backend subscribes to the sensor topic and provides both JSON endpoints and a live dashboard. It reads its configuration from configs/api_portable.env. To start it:

```
export $(grep -v '^#' configs/api_portable.env | xargs -d '\n')
python3 -m uvicorn api.app:app --host 0.0.0.0 --port 8000
```

The dashboard will be available in your browser at:

```
http://<pi-ip>:8000/dashboard
```

This page shows the current readings, a rolling history, and the topic activity.

### 8. Running and Wiring the Sensor Nodes

The gateway supports two types of sensor nodes. Each has its own physical wiring requirements. The software scripts for both nodes are already portable, so once the wiring is complete, each node can be enabled simply by running the corresponding script.

The gateway does not depend on any single node. It will run correctly with only the Pi-based DHT11 sensor, with only the USB serial microcontroller, or with both nodes active at the same time. Each node publishes readings independently, and the MQTT broker treats every message the same way as long as it arrives on the correct topic and carries a valid client certificate.

The API does not assume that a specific device is producing data. It simply receives messages, normalizes their fields, and updates the live history and dashboard. Because the system is driven by messages rather than device identity, the dashboard continues to function even if one node is unplugged or if several nodes are active simultaneously.

This makes the overall system flexible. You can start with a single sensor to verify the pipeline or run both nodes at once to demonstrate how the gateway integrates readings from different types of hardware into a unified secure stream. Future nodes can be added the same way. As long as a device can produce well-formed data and authenticate with the broker, it becomes part of the system without any code changes.

#### 1. Pi-native DHT11 Node (GPIO)

The DHT11 sensor connects directly to the Raspberry Pi’s GPIO header. This is the simplest node in the system.

Connection summary (BCM numbering):
- DHT11 VCC → Raspberry Pi 3.3V
- DHT11 GND → Raspberry Pi Ground
- DHT11 DATA → Raspberry Pi GPIO 4 (BCM numbering)
- Place a 10 kΩ resistor between the DATA line and the VCC line. This resistor is required for the three-pin version because the module does not include an onboard pull-up. Without it, the Pi will get inconsistent or jittery readings, especially if the cable length is longer than a few centimeters.

#### 2. USB Serial Node (ESP32 or Arduino)

The second type of node represents a more realistic scenario where the sensor is not physically attached to the Pi at all. Instead, the readings come from a microcontroller that already knows how to poll its sensor but does not speak MQTT or TLS. The Pi acts as a bridge between the simple microcontroller and the secure PQC-enabled gateway.

In this project, the microcontroller (ESP32 or Arduino) sends its measurements over a USB serial connection. The Raspberry Pi listens on /dev/ttyACM0 or /dev/ttyUSB0 depending on the board. Once the Pi receives a valid JSON line from the microcontroller, it normalizes the fields and publishes the processed reading to the PQC-secured Mosquitto broker.

The connections for this node are straightforward:

Physical connections:
- The microcontroller connects to the Raspberry Pi through a standard USB cable.
- No additional wiring between the Pi and microcontroller is required.
- The microcontroller must be wired to its own sensor (for example, a DHT22 module) using the appropriate pins for that device. For instance, a typical DHT22 connection on an ESP32 might use:
  - Sensor VCC to 3.3V
  - Sensor GND to GND
  - Sensor DATA to a chosen GPIO pin (such as GPIO 5)
  - A pull-up resistor between DATA and VCC if the sensor module does not include one
 
Running the serial-bridge node:

Once the microcontroller is connected and sending JSON readings, launch the serial bridge with:

```
./scripts/run_serial_portable.sh
```

If the serial device path matches the one in serial_portable.env, the script will open the device, read incoming messages, normalize them, and publish them to the same MQTT topic used by the DHT11 node.

#### 3. Why both node types matter

These two nodes highlight two sides of real IoT systems.
- The Pi-native DHT11 node represents sensors that are physically and electrically tied to the gateway itself. The Pi performs the reading and acts as the MQTT publisher.
- The USB serial node represents sensors running on independent microcontrollers. These devices may not have the ability to run TLS, manage certificates, or speak MQTT. The gateway takes care of all of that, turning a simple serial feed into a fully authenticated post-quantum-secure MQTT message.

Both nodes ultimately publish readings to the same MQTT topic. The API backend normalizes the data from either source so the dashboard does not need to know which device sent each reading. This gives the project flexibility and demonstrates how IoT gateways unify different classes of hardware under a single, secure ingestion pipeline.

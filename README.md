# Post-Quantum Secure IoT Gateway

## Project Overview

The **Post-Quantum Secure IoT Gateway** is a research prototype that demonstrates secure communication between embedded IoT devices using mutual TLS (mTLS) and Post-Quantum Cryptography (PQC).

The system is built on a Raspberry Pi 4 and designed to serve as a fully integrated, modular, and secure IoT architecture. It includes:

- An Arduino microcontroller connected to a temperature and humidity sensor (e.g. DHT11), acting as the edge device.
- Serial communication between the Arduino and the Raspberry Pi for transmitting sensor data.
- An MQTT-based communication layer secured with TLS 1.3 mutual authentication on the Pi.
- Post-quantum certificates (ML-DSA-65) issued by a custom Root CA using OpenSSL with the Open Quantum Safe (OQS) provider.
- A user-facing API and web-based GUI (running on the Pi) for device registration, data visualization, and system configuration.

<<<<<<< HEAD
The goal is to create a lightweight but secure platform that demonstrates how PQC can be used in real-world embedded and IoT systems. The project targets constrained environments while incorporating modern cryptographic standards resistant to quantum attacks.

In short: Arduino reads data -> sends it to Pi -> Pi brokers it over secure MQTT -> API + GUI expose and display it.
=======
---
## Project Setup on Raspberry Pi (with Virtual Environment)

Follow these steps directly on the Raspberry Pi to set up the environment for the Post-Quantum Secure IoT Gateway:

1. **Clone the repository:**

    ```bash
    git clone https://github.com/erikosmundsen/post-quantum-iot-gateway.git
    cd post-quantum-iot-gateway
    ```

2. **Update packages and install Python 3 & venv if not already installed:**

    ```bash
    sudo apt update
    sudo apt install -y python3 python3-pip python3-venv
    ```

3. **Create a virtual environment:**

    ```bash
    python3 -m venv venv
    ```

4. **Activate the virtual environment:**

    ```bash
    source venv/bin/activate
    ```

    On Windows (if applicable):

    ```bash
    venv\Scripts\activate
    ```

5. **Install required Python packages:**

    If you already have a `requirements.txt` file:

    ```bash
    pip install -r requirements.txt
    ```

    Otherwise, install manually and export:

    ```bash
    pip install Adafruit_DHT
    pip freeze > requirements.txt
    ```

6. **Deactivate the virtual environment when you're done:**

    ```bash
    deactivate
    ```

7. **Exclude the virtual environment from version control by adding the following to `.gitignore`:**

    ```gitignore
    venv/
    ```
	
## Hardware Components
>>>>>>> f0ad68a (Add Raspberry Pi virtual environment setup instructions to README)

## System Features

This system integrates hardware, cryptography, and communication layers to form a post-quantum secure IoT gateway. Key features include:

- **Sensor Integration via Arduino** 
  The Arduino collects environmental data from sensors like the DHT11 and sends it to the Raspberry Pi over serial connection.

- **MQTT Communication Layer** 
  The Raspberry Pi runs an MQTT broker (Mosquitto), configured to require mutual TLS authentication. All messages between clients are encrypted with TLS 1.3 and authenticated using post-quantum certificates.

- **Post-Quantum Certificate Authority** 
  The system uses OpenSSL 3.2 with the Open Quantum Safe (OQS) provider to generate and validate certificates. The default cryptographic suite is ML-DSA-65 for digital signatures and ECDSA for server compatibility.

- **Preflight Certificate Verification** 
  A custom preflight script runs before the broker starts. It validates certificates, checks permissions, and ensures cryptographic policies are respected.

- **API and Web GUI** 
  The system will include a RESTful API and user interface for:
  - Device registration and key provisioning
  - Real-time data visualization
  - System diagnostics and configuration

- **Modular and Portable** 
  The system is designed for reproducibility and team collaboration. Scripts, configs, and build tools are grouped cleanly in the repository.

## System Architecture

This project is structured around a modular secure IoT gateway stack:

- **Sensor Layer (Arduino)**: Reads environmental data (e.g. temperature/humidity) and communicates via serial or USB to the Raspberry Pi.
- **Gateway Layer (Raspberry Pi)**:
  - Acts as the MQTT client publisher.
  - Handles mutual TLS (mTLS) communication using post-quantum certificates.
- **Broker Layer (Mosquitto)**:
  - Local MQTT broker configured for TLS 1.3 with client certificate authentication.
  - Uses Open Quantum Safe (OQS) provider for post-quantum algorithms.
- **API & GUI Layer**:
  - Web server for visualizing sensor data and managing device registration.
  - Communicates with the broker to receive and display published messages.

All components are connected locally during development, but can be extended to remote/clustered setups.

## Installation Guide

This guide walks through the full setup process for replicating the secure IoT gateway on a Raspberry Pi 4 using Git Bash or a Linux terminal.

### 1. Clone the Repository

Start by cloning the repository and navigating into it.

```
git clone https://github.com/erikosmundsen/post-quantum-iot-gateway.git
cd post-quantum-iot-gateway
```

### 2. Install Core Dependencies

Update your package list and install base tools, Python libraries, and MQTT:

```
sudo apt-get update
sudo apt-get install -y \
    python3-pip python3-venv \
    build-essential cmake git pkg-config curl ninja-build \
    libssl-dev mosquitto mosquitto-clients
```

### 3. Install liboqs (Open Quantum Safe) and OpenSSL 3.2

You will build both from source.

```
mkdir -p ~/oqs-work && cd ~/oqs-work

# Clone liboqs
git clone --recursive https://github.com/open-quantum-safe/liboqs.git
cd liboqs
mkdir build && cd build
cmake -G "Ninja" -DCMAKE_INSTALL_PREFIX=/usr/local ..
ninja
sudo ninja install
sudo ldconfig
```

### 4. Build OpenSSL 3.2.1 with OQS Provider

```
cd ~/oqs-work
curl -LO https://www.openssl.org/source/openssl-3.2.1.tar.gz
tar -xzf openssl-3.2.1.tar.gz
cd openssl-3.2.1
./Configure linux-aarch64 --prefix=/opt/openssl-3 --libdir=lib
make -j"$(nproc)"
sudo make install_sw
```
### 5. Verify the Setup

<<<<<<< HEAD
Confirm you’re running the right OpenSSL version:

```
/opt/openssl-3/bin/openssl version
/opt/openssl-3/bin/openssl list -providers | grep oqs
```

You should see something like:
```
OpenSSL 3.2.1 ...
  oqs
```

### 6. Run Preflight Check (Required for MQTT + TLS)

Before starting the broker, verify the certificate paths, permissions, and cryptographic requirements with the included preflight tool:

```
sudo ./artifacts/tools/preflight.sh /etc/mosquitto/conf.d/pqc-mtls.conf
```

You should see output like:

PRECHECK: using config: /etc/mosquitto/conf.d/pqc-mtls.conf
PRECHECK: port 8884 free
PRECHECK: OK

If any errors appear (e.g. permission denied, file not found, SHA-1 warnings), fix those before proceeding. The preflight ensures Mosquitto will start cleanly with the correct TLS settings.

### 7. Restart Mosquitto and Test Broker

Once preflight passes, restart the Mosquitto service and verify that it binds to the expected port:

```
sudo systemctl daemon-reload
sudo systemctl restart mosquitto
sudo ss -tlnp | grep 8884
```

You should see something like:
```
LISTEN 0      100    0.0.0.0:8884    0.0.0.0:*    users:(("mosquitto",pid=XXXX,fd=5))
```

This confirms Mosquitto is listening on the TLS 1.3 mTLS-secured port.

8. Test Secure MQTT Communication

You can verify mutual authentication by opening two terminals:

Terminal A – Start subscriber:

```
./scripts/pqc_sub.sh
```

Terminal B – Start publisher:

```
./scripts/pqc_pub.sh
```

Expected output in Terminal A:

```
Hello from PQC mTLS!

```

This confirms that certificate-based mTLS is working between publisher and subscriber using post-quantum credentials.
=======
```plaintext
├── diagrams/
│   └── block-diagram.png
├── documentation/
│   ├── .gitkeep
│   ├── demo_checklist.md
│   └── technologies_explained.md
├── hardware/
│   ├── BOM.md
│   └── schematics/
│       └── raspberrypi-dht11.png
├── software/
│   └── .gitkeep
├── .gitignore
└── README.md
>>>>>>> f0ad68a (Add Raspberry Pi virtual environment setup instructions to README)

# Arduino Nano ESP32 Integration Guide  
**For Post-Quantum Secure IoT Gateway** 
_Last updated: November 2025_

## 1. Overview of the Data Flow

1. **Arduino** reads sensor data.
2. Sends JSON via **HTTP POST** to the Pi’s FastAPI server (`/sensor`).
3. Pi **receives it** and **publishes it to MQTT**.
4. MQTT is secured with **PQC-enabled TLS 1.3 and mTLS**.
5. Dashboard/GUI or other subscribers can view the data securely.

## 2. Configure Mosquitto ACL and TLS

```bash
sudo nano /etc/mosquitto/acl
```
Add:
```
user sensor-client
topic readwrite arduino/data
```

Then in `/etc/mosquitto/mosquitto.conf`, confirm:
```
listener 8884
tls_version tlsv1.3
cafile /etc/mosquitto/certs/ca.crt
certfile /etc/mosquitto/certs/server.crt
keyfile /etc/mosquitto/certs/server.key
require_certificate true
allow_anonymous false
use_identity_as_username true
acl_file /etc/mosquitto/acl
```

Restart Mosquitto:
```bash
sudo systemctl restart mosquitto
```

## 3. Arduino Sketch

Upload this to the Nano ESP32 using Arduino IDE:

```cpp
#include <WiFi.h>
#include <HTTPClient.h>

const char* ssid = "YOUR_WIFI_SSID_HERE";
const char* password = "YOUR_WIFI_PASSWORD_HERE";
const char* serverUrl = "http://YOUR_PI_IP_HERE:5000/sensor";

void setup() {
  Serial.begin(115200);
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nConnected to Wi-Fi!");
}

void loop() {
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    http.begin(serverUrl);
    http.addHeader("Content-Type", "application/json");
    int sensorValue = analogRead(A0);
    String jsonData = "{\"value\": " + String(sensorValue) + "}";
    int httpResponseCode = http.POST(jsonData);
    Serial.print("HTTP Response code: ");
    Serial.println(httpResponseCode);
    http.end();
  }
  delay(1000);
}
```

## 4. Pi-Side API Forwarder (`pi_gateway.py`)

Located in: `~/post-quantum-iot-gateway/scripts`

```python
from flask import Flask, request
import paho.mqtt.client as mqtt

app = Flask(__name__)

client = mqtt.Client()
client.tls_set(
    ca_certs="/home/YOUR_PI_USER/post-quantum-iot-gateway/artifacts/tls/ca/ca.crt",
    certfile="/home/YOUR_PI_USER/post-quantum-iot-gateway/artifacts/tls/client/client.crt",
    keyfile="/home/YOUR_PI_USER/post-quantum-iot-gateway/artifacts/tls/client/client.key"
)
client.connect("localhost", 8884)

@app.route('/sensor', methods=['POST', 'GET'])
def receive_data():
    if request.method == 'POST':
        data = request.data.decode()
    else:
        data = request.args.get('data', '')
    print(f"Received from Arduino: {data}")
    client.publish("arduino/data", data)
    return "OK", 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

Run it with:
```bash
python3 pi_gateway.py
```

## 5. Subscribe to the Topic (MQTT)

In another terminal window on the Pi:

```bash
mosquitto_sub -h localhost -p 8884 \
  --cafile /etc/mosquitto/certs/ca.crt \
  --cert ~/post-quantum-iot-gateway/artifacts/tls/client/client.crt \
  --key ~/post-quantum-iot-gateway/artifacts/tls/client/client.key \
  -t "arduino/data"
```

You should now see real sensor data streaming through a quantum-safe TLS channel.

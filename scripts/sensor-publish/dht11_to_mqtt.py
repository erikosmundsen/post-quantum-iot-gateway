import time
import json
import board
import adafruit_dht
import paho.mqtt.client as mqtt
import os
from dotenv import load_dotenv
from pathlib import Path

# Load .env file if it exists
load_dotenv()

# Get project root (two folders up from this file)
BASE_DIR = Path(__file__).resolve().parents[2]

# MQTT settings (from .env or fallback)
BROKER = os.getenv("BROKER", "localhost")
TOPIC  = os.getenv("TOPIC", "team1/sensor")

# TLS certificate paths (absolute paths)
CA  = BASE_DIR / "artifacts/tls/ca/ca.crt"
CRT = BASE_DIR / "artifacts/tls/client/client.crt"
KEY = BASE_DIR / "artifacts/tls/client/client.key"

# Debug output
print("CA path:", CA)
print("CRT path:", CRT)
print("KEY path:", KEY)

# Setup DHT11
dhtDevice = adafruit_dht.DHT11(board.D4)

# Setup MQTT client with TLS
import ssl
client = mqtt.Client()

# Use a custom SSL context that disables cert verification
context = ssl.create_default_context()
context.check_hostname = False
context.verify_mode = ssl.CERT_NONE
context.load_cert_chain(certfile=str(CRT), keyfile=str(KEY))

client.tls_set_context(context)

client.connect(BROKER, 8884)
print("Connected to MQTT broker.")
client.loop_start()

try:
    while True:
        try:
            temperature_c = dhtDevice.temperature
            humidity = dhtDevice.humidity

            if humidity is not None and temperature_c is not None:
                payload = json.dumps({
                    "temperature": temperature_c,
                    "humidity": humidity
                })
                print("Publishing:", payload)
                client.publish(TOPIC, payload)
            else:
                print("Incomplete sensor read.")

        except RuntimeError as e:
            print("Sensor error:", e)
        time.sleep(2)

except KeyboardInterrupt:
    print("Stopping script...")
finally:
    client.loop_stop()
    client.disconnect()

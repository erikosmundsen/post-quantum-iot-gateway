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
BROKER = os.getenv("MQTT_BROKER_HOST", "localhost")
PORT = int(os.getenv("MQTT_BROKER_PORT", "8884"))
TOPIC = os.getenv("MQTT_TOPIC", "team1/sensor")
CLIENT_ID = os.getenv("MQTT_CLIENT_ID", "dht11-portable")

# TLS certificate paths (absolute paths)
CA = os.getenv("MQTT_CA_CERT")
CRT = os.getenv("MQTT_CLIENT_CERT")
KEY = os.getenv("MQTT_CLIENT_KEY")

# Debug output
print("CA path:", CA)
print("CRT path:", CRT)
print("KEY path:", KEY)

# Setup DHT11
DHT_PIN = int(os.getenv("DHT11_PIN", "4"))

# Convert pin number to board pin
pin = getattr(board, f"D{DHT_PIN}")

dhtDevice = adafruit_dht.DHT11(pin)


# Setup MQTT client with TLS
import ssl
client = mqtt.Client(client_id=CLIENT_ID)

# Use a custom SSL context that disables cert verification
context = ssl.create_default_context()
context.check_hostname = False
context.verify_mode = ssl.CERT_NONE
context.load_cert_chain(certfile=str(CRT), keyfile=str(KEY))

client.tls_set_context(context)

client.connect(BROKER, PORT)
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

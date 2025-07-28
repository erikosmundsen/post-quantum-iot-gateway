import Adafruit_DHT
import time
import paho.mqtt.client as mqtt

SENSOR = Adafruit_DHT.DHT11
PIN = 4

MQTT_BROKER = "localhost"
MQTT_PORT = 1883
MQTT_TOPIC = "sensor/data"

def read_sensor():
    humidity, temperature = Adafruit_DHT.read_retry(SENSOR, PIN)
    return humidity, temperature

def publish_data(client, humidity, temperature):
    payload = f"Temperature: {temperature:.1f}°C, Humidity: {humidity:.1f}%"
    client.publish(MQTT_TOPIC, payload)
    print(f"Published: {payload}")

def main():
    client = mqtt.Client()
    client.connect(MQTT_BROKER, MQTT_PORT, 60)

    print("Publishing DHT11 data to MQTT... Press Ctrl+C to stop.")
    try:
        while True:
            humidity, temperature = read_sensor()
            if humidity is not None and temperature is not None:
                publish_data(client, humidity, temperature)
            else:
                print("Sensor read failed. Retrying...")
            time.sleep(2)
    except KeyboardInterrupt:
        print("Stopped.")
        client.disconnect()

if __name__ == "__main__":
    main()

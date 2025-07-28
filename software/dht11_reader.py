import Adafruit_DHT
import time

# Sensor setup
DHT_SENSOR = Adafruit_DHT.DHT11
DHT_PIN = 4  # GPIO4

while True:
    humidity, temperature = Adafruit_DHT.read(DHT_SENSOR, DHT_PIN)

    if humidity is not None and temperature is not None:
        print(f"Temp: {temperature:.1f}°C  Humidity: {humidity:.1f}%")
    else:
        print("Failed to retrieve data from sensor")

    time.sleep(2)
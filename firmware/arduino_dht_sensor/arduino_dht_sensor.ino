#include <DHT.h>

// DHT sensor on digital pin D2
#define DHTPIN 2
#define DHTTYPE DHT22   // change to DHT11 if needed

DHT dht(DHTPIN, DHTTYPE);

void setup() {
  Serial.begin(9600);
  dht.begin();
}

void loop() {
  float temperature = dht.readTemperature(); // Celsius
  float humidity    = dht.readHumidity();

  if (isnan(temperature) || isnan(humidity)) {
    Serial.println("Sensor read error");
    delay(2000);
    return;
  }

    // JSON format expected by the Pi serial bridge:
    // {"temp_c": <float>, "hum": <float>}
  Serial.print("{\"temp_c\": ");
  Serial.print(temperature, 2);
  Serial.print(", \"hum\": ");
  Serial.print(humidity, 2);
  Serial.println("}");

  delay(1000);  // publish once per second
}

import os, sys, json, time, signal
import serial
import paho.mqtt.client as mqtt

SERIAL_PORT = os.getenv("SERIAL_PORT", "/dev/ttyACM0")
SERIAL_BAUD = int(os.getenv("SERIAL_BAUD", "115200"))
MQTT_HOST   = os.getenv("MQTT_HOST", "localhost")
MQTT_PORT   = int(os.getenv("MQTT_PORT", "8884"))
MQTT_TOPIC  = os.getenv("MQTT_TOPIC", "team1/sensor")
CAFILE      = os.getenv("MQTT_CAFILE","/etc/mosquitto/certs/classic/ca-classic-rsa.crt")

MQTT_CAFILE  = os.getenv("MQTT_CAFILE",
    "/home/erikosmundsen13/post-quantum-iot-gateway/artifacts/tls/ca/ca.crt")
MQTT_CERT    = os.getenv("MQTT_CERT",
    "/home/erikosmundsen13/post-quantum-iot-gateway/artifacts/tls/client/api-client.crt")
MQTT_KEY     = os.getenv("MQTT_KEY",
    "/home/erikosmundsen13/post-quantum-iot-gateway/artifacts/tls/client/api-client.key")

running=True
def stop(*_): 
    global running; running=False
signal.signal(signal.SIGINT, stop); signal.signal(signal.SIGTERM, stop)

def open_serial():
    while running:
        try:
            s=serial.Serial(SERIAL_PORT, SERIAL_BAUD, timeout=1)
            s.setDTR(False); time.sleep(0.1); s.setDTR(True)
            return s
        except Exception as e:
            print(f"[SER] open failed: {e}; retrying...", file=sys.stderr)
            time.sleep(1)

def open_mqtt():
    c=mqtt.Client(client_id="serial-publisher", clean_session=True)
    c.tls_set(ca_certs=CAFILE)
    while running:
        try:
            c.connect(MQTT_HOST, MQTT_PORT, keepalive=30)
            c.loop_start()
            return c
        except Exception as e:
            print(f"[MQTT] connect failed: {e}; retrying...", file=sys.stderr)
            time.sleep(1)

def main():
    ser=open_serial(); cli=open_mqtt()
    print(f"[RUN] {SERIAL_PORT}@{SERIAL_BAUD} -> mqtts://{MQTT_HOST}:{MQTT_PORT}/{MQTT_TOPIC}")
    while running:
        line=ser.readline()
        if not line: continue
        line=line.strip()
        if not(line.startswith(b"{") and line.endswith(b"}")): continue
        try:
            payload=json.loads(line.decode("utf-8"))
        except Exception as e:
            print(f"[JSON] bad line: {e}", file=sys.stderr); continue
        payload["_ts"]=int(time.time()*1000)
        cli.publish(MQTT_TOPIC, json.dumps(payload), qos=1)
    ser.close(); cli.loop_stop(); cli.disconnect()

if __name__=="__main__": main()

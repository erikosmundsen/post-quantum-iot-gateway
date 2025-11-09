import os, ssl, json, threading, time
import paho.mqtt.client as mqtt

# Read settings from environment
MQTT_HOST   = os.getenv("MQTT_HOST", "localhost")
MQTT_PORT   = int(os.getenv("MQTT_PORT", "8884"))      # PQC mTLS listener
MQTT_TOPIC  = os.getenv("MQTT_TOPIC", "team1/sensor")

CAFILE      = os.getenv("MQTT_TLS_CAFILE")
CERTFILE    = os.getenv("MQTT_TLS_CERT")
KEYFILE     = os.getenv("MQTT_TLS_KEY")

# In-memory cache for the most recent message
_latest = {"status": "init"}

def get_latest():
    return _latest

def _on_connect(client, userdata, flags, reason_code, properties=None):
    client.subscribe(MQTT_TOPIC, qos=1)

def _on_message(client, userdata, msg):
    try:
        payload = json.loads(msg.payload.decode("utf-8"))
    except Exception:
        return
    payload["_source"] = "pqc-mtls-8884"
    _latest.update(payload)

def start_mqtt_thread():
    def runner():
        client = mqtt.Client(client_id="api-subscriber", clean_session=True, protocol=mqtt.MQTTv311)

        # mTLS context (TLS 1.3 preferred if available)
        if CAFILE:
            ctx = ssl.create_default_context(ssl.Purpose.SERVER_AUTH, cafile=CAFILE)
            if CERTFILE and KEYFILE:
                ctx.load_cert_chain(certfile=CERTFILE, keyfile=KEYFILE)
            try:
                ctx.minimum_version = ssl.TLSVersion.TLSv1_3
            except Exception:
                pass
            client.tls_set_context(ctx)

        client.on_connect = _on_connect
        client.on_message = _on_message

        backoff = 1
        while True:
            try:
                client.connect(MQTT_HOST, MQTT_PORT, keepalive=30)
                client.loop_forever(retry_first_connection=True)
            except Exception:
                time.sleep(backoff)
                backoff = min(backoff * 2, 30)

    t = threading.Thread(target=runner, daemon=True)
    t.start()

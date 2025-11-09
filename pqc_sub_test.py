import ssl, paho.mqtt.client as mqtt

HOST="localhost"; PORT=8884; TOPIC="team1/#"
CA  = "/home/erikosmundsen13/post-quantum-iot-gateway/artifacts/tls/ca/ca.crt"
CRT = "/home/erikosmundsen13/post-quantum-iot-gateway/artifacts/tls/client/api-client.crt"
KEY = "/home/erikosmundsen13/post-quantum-iot-gateway/artifacts/tls/client/api-client.key"

def on_connect(c,u,f,rc,p=None):
    print("CONNECTED rc=", rc)
    c.subscribe(TOPIC, qos=1)

def on_msg(c,u,m):
    print(m.topic, m.payload.decode("utf-8","ignore"))

ctx = ssl.create_default_context(ssl.Purpose.SERVER_AUTH, cafile=CA)
ctx.load_cert_chain(certfile=CRT, keyfile=KEY)
try:
    ctx.minimum_version = ssl.TLSVersion.TLSv1_3
except Exception:
    pass

cli = mqtt.Client(client_id="api-subscriber", clean_session=True, protocol=mqtt.MQTTv311)
cli.tls_set_context(ctx)
cli.on_connect = on_connect
cli.on_message = on_msg
cli.connect(HOST, PORT, keepalive=30)
cli.loop_forever()

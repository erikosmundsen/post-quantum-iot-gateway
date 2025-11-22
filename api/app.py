#!/usr/bin/env python3
from __future__ import annotations
import json, ssl, threading, time
from typing import Dict, Any
from collections import deque
from fastapi import FastAPI, HTTPException, Query
from fastapi.responses import HTMLResponse, PlainTextResponse
import paho.mqtt.client as mqtt
from pathlib import Path
import os

# === Portable API MQTT config ===
BROKER = os.getenv("API_MQTT_BROKER_HOST", "localhost")
PORT = int(os.getenv("API_MQTT_BROKER_PORT", "8884"))
TOPIC_FILTER = os.getenv("API_MQTT_TOPIC_FILTER", "team1/#")

CA = os.getenv("API_MQTT_CA_CERT")
CRT = os.getenv("API_MQTT_CLIENT_CERT")
KEY = os.getenv("API_MQTT_CLIENT_KEY")

CLIENT_ID = os.getenv("API_MQTT_CLIENT_ID", "api-subscriber")

# --------------------------------------------------------------

# Most recent message per topic
LATEST: Dict[str, Dict[str, Any]] = {}
# Rolling history per topic (last N points for chart)
HISTORY: Dict[str, deque] = {}
HISTORY_MAX = 200

def on_connect(client: mqtt.Client, userdata, flags, rc):
    # Subscribe when TLS MQTT connection is made.
    if rc == 0:
        print("[MQTT] connected")
        client.subscribe(TOPIC_FILTER)
        print(f"[MQTT] subscribed to: {TOPIC_FILTER}")
    else:
        print(f"[MQTT] connect failed rc={rc}")

def _append_history(topic: str, ts: int, payload: Dict[str, Any], size: int):
    # Keep a compact, time-ordered buffer for charts.
    if topic not in HISTORY:
        HISTORY[topic] = deque(maxlen=HISTORY_MAX)
    rec = {"ts": ts, "size_bytes": size}
    if isinstance(payload, dict):
        # Accept either normalized or raw bridge fields
        t = payload.get("temperature", payload.get("temp_c"))
        h = payload.get("humidity",    payload.get("hum"))
        if isinstance(t, (int, float)): rec["temperature"] = t
        if isinstance(h, (int, float)): rec["humidity"]    = h
    HISTORY[topic].append(rec)

def on_message(client: mqtt.Client, userdata, msg: mqtt.MQTTMessage):
    # Store latest JSON payload per topic and normalize fields for charts.
    ts = int(time.time())
    try:
        text = msg.payload.decode("utf-8", errors="replace")
        data = json.loads(text)

        # ---- normalize field names from device/bridge ----
        if isinstance(data, dict):
            if "temp_c" in data and "temperature" not in data:
                data["temperature"] = data.get("temp_c")
            if "hum" in data and "humidity" not in data:
                data["humidity"] = data.get("hum")
        # --------------------------------------------------

        LATEST[msg.topic] = {
            "topic": msg.topic,
            "payload": data,
            "size_bytes": len(msg.payload),
            "ts": ts
        }
        _append_history(msg.topic, ts, data, len(msg.payload))
    except Exception as e:
        raw = {"raw": msg.payload.hex()}
        LATEST[msg.topic] = {
            "topic": msg.topic,
            "payload": raw,
            "size_bytes": len(msg.payload),
            "ts": ts,
            "error": str(e)
        }
        _append_history(msg.topic, ts, raw, len(msg.payload))

def start_mqtt():
    c = mqtt.Client(client_id="api-subscriber", clean_session=True, protocol=mqtt.MQTTv311)

    # Strict TLS verification with PQC chain + present client cert (mTLS)
    context = ssl.create_default_context(purpose=ssl.Purpose.SERVER_AUTH)
    context.load_verify_locations(cafile=str(CA))
    context.check_hostname = True          # SAN on server cert includes IP/DNS; leave True if you reissued with SAN
    context.verify_mode = ssl.CERT_REQUIRED
    context.load_cert_chain(certfile=str(CRT), keyfile=str(KEY))
    try:
        context.minimum_version = ssl.TLSVersion.TLSv1_3
    except Exception:
        pass

    c.tls_set_context(context)
    c.on_connect = on_connect
    c.on_message = on_message
    c.connect(BROKER, PORT, keepalive=60)
    c.loop_forever()

# Spin up the MQTT subscriber in background
threading.Thread(target=start_mqtt, daemon=True).start()

# FastAPI app and endpoints.
app = FastAPI(title="Gateway API", version="1.2")

@app.get("/gateway_ok")
def gateway_ok():
    # health / status
    return {"status": "ok", "broker": f"{BROKER}:{PORT}", "subscribed": TOPIC_FILTER}

@app.get("/telemetry/latest")
def latest_all():
    # Latest message per topic as JSON
    return LATEST

@app.get("/telemetry/by_topic")
def latest_by_topic(topic: str):
    # Latest record for a topic.
    row = LATEST.get(topic)
    if not row:
        raise HTTPException(404, f"No data for topic '{topic}'")
    return row

@app.get("/telemetry/history")
def history(topic: str, n: int = Query(120, ge=1, le=HISTORY_MAX)):
    # Last n history points for a topic (for charts)
    buf = HISTORY.get(topic)
    if not buf:
        raise HTTPException(404, f"No history for topic '{topic}'")
    return list(buf)[-n:]

@app.get("/overview", response_class=PlainTextResponse)
def overview():
    # Text summary for debugging
    topics = ", ".join(sorted(LATEST.keys())) if LATEST else "none"
    return (
        "Status: ok\n"
        f"Broker: {BROKER}:{PORT}\n"
        f"Subscribed: {TOPIC_FILTER}\n"
        f"Topics seen: {topics}\n"
        f"Count: {len(LATEST)}\n"
    )

@app.get("/dashboard", response_class=HTMLResponse)
def dashboard():
    # Dashboard with table and a live chart using Chart.js
    return f"""
<!doctype html>
<html>
<head>
  <meta charset="utf-8" />
  <title>Gateway Dashboard</title>
  <style>
    body {{ font-family: Arial, sans-serif; padding: 24px; }}
    table {{ border-collapse: collapse; width: 100%; margin-top: 16px; }}
    th, td {{ border: 1px solid #ddd; padding: 8px; }}
    th {{ background: #f7f7f7; text-align: left; }}
    code {{ background: #f0f0f0; padding: 2px 4px; border-radius: 4px; }}
    #row {{ display:flex; gap:24px; align-items:flex-start; }}
    #left, #right {{ flex:1; min-width: 360px; }}
    select {{ padding: 6px; }}
  </style>
  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
  <h1>Gateway Dashboard</h1>
  <p>Broker: <b>{BROKER}:{PORT}</b> | Subscribed to: <code>{TOPIC_FILTER}</code></p>

  <div id="row">
    <div id="left">
      <h3>Latest readings</h3>
      <table id="tbl">
        <thead>
          <tr><th>Topic</th><th>Temperature (°C)</th><th>Humidity (%)</th><th>Size (B)</th></tr>
        </thead>
        <tbody></tbody>
      </table>
    </div>

    <div id="right">
      <h3>Live chart</h3>
      <label>Topic:&nbsp;
        <select id="topicSel"></select>
      </label>
      <canvas id="chart" height="180"></canvas>
    </div>
  </div>

  <script>
    let chart, chartData = {{ labels: [], datasets: [
      {{ label: "Temperature (°C)", data: [], yAxisID: 'y' }},
      {{ label: "Humidity (%)",    data: [], yAxisID: 'y1' }}
    ] }};

    function ensureChart() {{
      if (chart) return;
      const ctx = document.getElementById('chart').getContext('2d');
      chart = new Chart(ctx, {{
        type: 'line',
        data: chartData,
        options: {{
          animation: false,
          scales: {{
            y:  {{ type:'linear', position:'left' }},
            y1: {{ type:'linear', position:'right', grid: {{ drawOnChartArea: false }} }}
          }},
          plugins: {{ legend: {{ display: true }} }}
        }}
      }});
    }}

    async function refreshTableAndTopics() {{
      const res = await fetch('/telemetry/latest');
      const data = await res.json();
      const tbody = document.querySelector('#tbl tbody');
      tbody.innerHTML = '';
      const seenTopics = Object.keys(data).sort();
      for (const topic of seenTopics) {{
        const row = data[topic] || {{}};
        const p = row.payload || {{}};
        const tr = document.createElement('tr');
        tr.innerHTML = '<td>'+topic+'</td>'+
                       '<td>'+(p.temperature ?? '')+'</td>'+
                       '<td>'+(p.humidity ?? '')+'</td>'+
                       '<td>'+(row.size_bytes ?? '')+'</td>';
        tbody.appendChild(tr);
      }}
      // maintain topic dropdown
      const sel = document.getElementById('topicSel');
      const current = sel.value;
      sel.innerHTML = '';
      for (const t of seenTopics) {{
        const opt = document.createElement('option');
        opt.value = t; opt.textContent = t;
        sel.appendChild(opt);
      }}
      if (!seenTopics.includes(current) && seenTopics.length) sel.value = seenTopics[0];
      else sel.value = current;
    }}

    async function refreshChart() {{
      ensureChart();
      const selTopic = document.getElementById('topicSel').value;
      if (!selTopic) return;
      const res = await fetch('/telemetry/history?topic='+encodeURIComponent(selTopic)+'&n=120');
      if (!res.ok) return;
      const hist = await res.json();
      chartData.labels = hist.map(p => new Date(p.ts*1000).toLocaleTimeString());
      const temp = hist.map(p => p.temperature ?? null);
      const hum  = hist.map(p => p.humidity ?? null);
      chartData.datasets[0].data = temp;
      chartData.datasets[1].data = hum;
      chart.update();
    }}

    async function tick() {{
      await refreshTableAndTopics();
      await refreshChart();
    }}
    tick();
    setInterval(tick, 1500);
  </script>
</body>
</html>
"""

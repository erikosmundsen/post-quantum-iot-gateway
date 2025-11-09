#!/usr/bin/env bash
sudo pkill -x mosquitto || true
echo "Stopped mosquitto (if it was running)."

#!/usr/bin/env bash
set -e
source "$(dirname "$0")/env_demo.sh"
echo "Starting Mosquitto on :8884 with $TESTCONF"
echo "Close this window to stop the broker."
sudo mosquitto -c "$TESTCONF" -v

#!/usr/bin/env bash
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
term=""
if command -v lxterminal >/dev/null 2>&1; then term="lxterminal -t"; fi
if [ -z "$term" ] && command -v xterm >/dev/null 2>&1; then term="xterm -T"; fi

if [ -n "$term" ]; then
  $term "Broker :8884"    -e bash -lc "cd '$DIR'; ./broker.sh" &
  sleep 1
  $term "Subscriber"      -e bash -lc "cd '$DIR'; ./subscriber.sh" &
  sleep 1
  $term "Publisher (press Enter)" -e bash -lc "cd '$DIR'; ./publisher.sh" &
else
  # No GUI terminal? use tmux
  tmux new-session  -d -s pqc 'cd "'"$DIR"'" && ./broker.sh'
  tmux split-window -h -t pqc 'cd "'"$DIR"'" && ./subscriber.sh'
  tmux split-window -v -t pqc:0.1 'cd "'"$DIR"'" && ./publisher.sh'
  tmux select-layout -t pqc tiled
  tmux attach -t pqc
fi

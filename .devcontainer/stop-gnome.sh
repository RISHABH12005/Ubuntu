#!/usr/bin/env bash
set -euo pipefail
STATE_DIR="$HOME/.local/state/ubuntu-gnome"
for name in novnc x11vnc gnome-shell xvfb; do
  file="$STATE_DIR/$name.pid"
  if [ -f "$file" ]; then pid="$(cat "$file")"; kill "$pid" 2>/dev/null || true; rm -f "$file"; fi
done
pkill -u "$(id -u)" -x gnome-shell 2>/dev/null || true
pkill -u "$(id -u)" -x x11vnc 2>/dev/null || true
pkill -u "$(id -u)" -f 'novnc_proxy' 2>/dev/null || true
pkill -u "$(id -u)" -f 'Xvfb :1' 2>/dev/null || true
echo "Ubuntu GNOME desktop services stopped."

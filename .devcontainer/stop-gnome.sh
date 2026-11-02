#!/usr/bin/env bash
set -euo pipefail
VNC_DIR="$HOME/.vnc"
if [ -f "$VNC_DIR/novnc.pid" ]; then
  pid="$(cat "$VNC_DIR/novnc.pid")"
  if kill -0 "$pid" 2>/dev/null; then kill "$pid" || true; fi
  rm -f "$VNC_DIR/novnc.pid"
fi
vncserver -kill :1 >/dev/null 2>&1 || true
echo "Ubuntu desktop services stopped."

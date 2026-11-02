#!/usr/bin/env bash
set -euo pipefail

export DISPLAY=:1
mkdir -p "$HOME/.vnc"

if pgrep -u "$(id -u)" Xtigervnc >/dev/null 2>&1; then
  echo "VNC display is already running."
else
  vncserver :1 -localhost yes -geometry 1600x900 -depth 24 -SecurityTypes None
fi

# noVNC serves the VNC display on port 6080.
if ! pgrep -af 'novnc_proxy.*6080' >/dev/null 2>&1; then
  nohup /usr/share/novnc/utils/novnc_proxy --listen 6080 --vnc localhost:5901 \
    > "$HOME/.vnc/novnc.log" 2>&1 &
fi

echo "GNOME desktop endpoint: http://localhost:6080/vnc.html"

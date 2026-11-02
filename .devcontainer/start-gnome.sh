#!/usr/bin/env bash
set -Eeuo pipefail

DISPLAY_NUM=":1"
VNC_PORT="5901"
WEB_PORT="6080"
VNC_DIR="$HOME/.vnc"
mkdir -p "$VNC_DIR"
export DISPLAY="$DISPLAY_NUM"

# Ensure the container's system D-Bus exists (Codespaces does not run systemd).
if [ ! -S /run/dbus/system_bus_socket ]; then
  sudo mkdir -p /run/dbus
  sudo dbus-daemon --system --fork --nopidfile
fi

# Start/restart the VNC server only when it is not already healthy.
if ! timeout 2 bash -c ":</dev/tcp/127.0.0.1/$VNC_PORT" 2>/dev/null; then
  vncserver -kill "$DISPLAY_NUM" >/dev/null 2>&1 || true
  rm -f /tmp/.X1-lock /tmp/.X11-unix/X1
  vncserver "$DISPLAY_NUM" -localhost yes -geometry 1600x900 -depth 24 \
    -SecurityTypes None -xstartup "$VNC_DIR/xstartup"
fi

# Wait for the VNC endpoint before exposing the browser proxy.
for _ in $(seq 1 30); do
  if timeout 2 bash -c ":</dev/tcp/127.0.0.1/$VNC_PORT" 2>/dev/null; then break; fi
  sleep 1
done
if ! timeout 2 bash -c ":</dev/tcp/127.0.0.1/$VNC_PORT" 2>/dev/null; then
  echo "VNC did not start on $VNC_PORT. Recent VNC logs:" >&2
  find "$VNC_DIR" -maxdepth 1 -name '*.log' -type f -exec sh -c 'echo "--- $1"; tail -60 "$1"' _ {} \;
  exit 1
fi

# Keep a single noVNC proxy. VNC remains bound to localhost; only noVNC is forwarded.
if ! timeout 2 bash -c ":</dev/tcp/127.0.0.1/$WEB_PORT" 2>/dev/null; then
  nohup /usr/share/novnc/utils/novnc_proxy --listen "$WEB_PORT" \
    --vnc "127.0.0.1:$VNC_PORT" --web /usr/share/novnc \
    > "$VNC_DIR/novnc.log" 2>&1 &
  echo $! > "$VNC_DIR/novnc.pid"
fi

for _ in $(seq 1 15); do
  if timeout 2 bash -c ":</dev/tcp/127.0.0.1/$WEB_PORT" 2>/dev/null; then break; fi
  sleep 1
done

echo "Desktop port checks:"
ss -ltn | grep -E ":$VNC_PORT|:$WEB_PORT" || true
echo "Open the forwarded private port $WEB_PORT and visit /vnc.html."

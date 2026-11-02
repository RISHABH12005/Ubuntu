#!/usr/bin/env bash
set -Eeuo pipefail

DISPLAY_NUM=":1"
VNC_PORT="5901"
WEB_PORT="6080"
STATE_DIR="$HOME/.local/state/ubuntu-gnome"
mkdir -p "$STATE_DIR"
chmod 700 "$STATE_DIR"

export DISPLAY="$DISPLAY_NUM"
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=ubuntu:GNOME
export XDG_SESSION_DESKTOP=ubuntu
export DESKTOP_SESSION=ubuntu
export GDK_BACKEND=x11
export LIBGL_ALWAYS_SOFTWARE=1
export GALLIUM_DRIVER=llvmpipe
export MUTTER_DEBUG_DISABLE_HW_CURSORS=1

log() { printf '[ubuntu-gnome] %s\n' "$*"; }
port_open() { timeout 2 bash -c ":</dev/tcp/127.0.0.1/$1" 2>/dev/null; }
pid_alive() { [ -n "${1:-}" ] && kill -0 "$1" 2>/dev/null; }
start_background() {
  local name="$1"; shift
  local pidfile="$STATE_DIR/$name.pid"
  local oldpid=""
  [ -f "$pidfile" ] && oldpid="$(cat "$pidfile" 2>/dev/null || true)"
  if pid_alive "$oldpid"; then return 0; fi
  rm -f "$pidfile"
  nohup "$@" > "$STATE_DIR/$name.log" 2>&1 < /dev/null &
  echo "$!" > "$pidfile"
}

# Ensure the container has the system bus; systemd is not PID 1 in Codespaces.
if [ ! -S /run/dbus/system_bus_socket ]; then
  sudo mkdir -p /run/dbus
  sudo dbus-daemon --system --fork --nopidfile
fi

# User runtime directory needed by modern GNOME components in the absence of logind.
RUNTIME_DIR="/run/user/$(id -u)"
if [ ! -d "$RUNTIME_DIR" ]; then
  sudo mkdir -p "$RUNTIME_DIR"
  sudo chown "$(id -u):$(id -g)" "$RUNTIME_DIR"
  sudo chmod 700 "$RUNTIME_DIR"
fi
export XDG_RUNTIME_DIR="$RUNTIME_DIR"

# Clean stale X display lock only when no server is listening on the display.
if ! timeout 2 bash -c ':</dev/tcp/127.0.0.1/6001' 2>/dev/null && [ ! -S /tmp/.X11-unix/X1 ]; then
  rm -f /tmp/.X1-lock
fi

# Xvfb does not expose TCP (port 6001); its Unix socket is the readiness check.
XVFB_PID=""
[ -f "$STATE_DIR/xvfb.pid" ] && XVFB_PID="$(cat "$STATE_DIR/xvfb.pid" 2>/dev/null || true)"
if ! pid_alive "$XVFB_PID" || [ ! -S /tmp/.X11-unix/X1 ]; then
  if [ -S /tmp/.X11-unix/X1 ] && ! pgrep -x Xvfb >/dev/null 2>&1; then
    rm -f /tmp/.X11-unix/X1 /tmp/.X1-lock
  fi
  rm -f "$STATE_DIR/xvfb.pid"
  start_background xvfb Xvfb :1 -screen 0 1600x900x24 -nolisten tcp -ac
fi

for _ in $(seq 1 30); do
  XVFB_PID="$(cat "$STATE_DIR/xvfb.pid" 2>/dev/null || true)"
  if pid_alive "$XVFB_PID" && [ -S /tmp/.X11-unix/X1 ]; then break; fi
  sleep 1
done
XVFB_PID="$(cat "$STATE_DIR/xvfb.pid" 2>/dev/null || true)"
if ! pid_alive "$XVFB_PID" || [ ! -S /tmp/.X11-unix/X1 ]; then
  log "Xvfb failed to become ready. Log:"
  tail -100 "$STATE_DIR/xvfb.log" 2>/dev/null || true
  exit 1
fi
log "Xvfb display :1 is ready."

# Start the complete Ubuntu GNOME session inside a dedicated session bus.
# Track the wrapper PID and verify gnome-shell remains alive after initialization.
SESSION_PID=""
[ -f "$STATE_DIR/session.pid" ] && SESSION_PID="$(cat "$STATE_DIR/session.pid" 2>/dev/null || true)"
if ! pid_alive "$SESSION_PID" || ! pgrep -u "$(id -u)" -x gnome-shell >/dev/null 2>&1; then
  [ -n "$SESSION_PID" ] && kill "$SESSION_PID" 2>/dev/null || true
  rm -f "$STATE_DIR/session.pid"
  start_background session dbus-run-session -- gnome-session --session=ubuntu
fi

GNOME_READY=0
for _ in $(seq 1 45); do
  SESSION_PID="$(cat "$STATE_DIR/session.pid" 2>/dev/null || true)"
  if pid_alive "$SESSION_PID" && pgrep -u "$(id -u)" -x gnome-shell >/dev/null 2>&1; then
    GNOME_READY=1
    break
  fi
  sleep 1
done
if [ "$GNOME_READY" -ne 1 ]; then
  log "Ubuntu GNOME session did not stay alive. Session log:"
  tail -120 "$STATE_DIR/session.log" 2>/dev/null || true
  exit 1
fi
log "Ubuntu GNOME session is running."

# Export the display over loopback-only VNC.
if ! port_open "$VNC_PORT"; then
  start_background x11vnc x11vnc -display :1 -rfbport "$VNC_PORT" -localhost \
    -forever -shared -nopw -noxdamage -repeat
fi
for _ in $(seq 1 25); do port_open "$VNC_PORT" && break; sleep 1; done
if ! port_open "$VNC_PORT"; then
  log "x11vnc failed to listen on $VNC_PORT. Log:"
  tail -100 "$STATE_DIR/x11vnc.log" 2>/dev/null || true
  exit 1
fi
log "Loopback VNC is ready on $VNC_PORT."

# Expose only noVNC through the forwarded Codespaces port.
if ! port_open "$WEB_PORT"; then
  start_background novnc /usr/share/novnc/utils/novnc_proxy --listen "$WEB_PORT" \
    --vnc "127.0.0.1:$VNC_PORT" --web /usr/share/novnc
fi
for _ in $(seq 1 20); do port_open "$WEB_PORT" && break; sleep 1; done
if ! port_open "$WEB_PORT"; then
  log "noVNC failed to listen on $WEB_PORT. Log:"
  tail -100 "$STATE_DIR/novnc.log" 2>/dev/null || true
  exit 1
fi

log "Ready. Open forwarded port $WEB_PORT and visit /vnc.html."
ss -ltn | grep -E ":$VNC_PORT|:$WEB_PORT" || true

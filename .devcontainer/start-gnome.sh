#!/usr/bin/env bash
set -Eeuo pipefail
DISPLAY_NUM=":1"; VNC_PORT="5901"; WEB_PORT="6080"
STATE_DIR="$HOME/.local/state/ubuntu-gnome"
mkdir -p "$STATE_DIR" "$HOME/.vnc"
export DISPLAY="$DISPLAY_NUM" XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=ubuntu:GNOME XDG_SESSION_DESKTOP=ubuntu DESKTOP_SESSION=ubuntu
export GDK_BACKEND=x11 LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=llvmpipe MUTTER_DEBUG_DISABLE_HW_CURSORS=1
is_listening(){ timeout 2 bash -c ":</dev/tcp/127.0.0.1/$1" 2>/dev/null; }
if [ ! -S /run/dbus/system_bus_socket ]; then
  sudo mkdir -p /run/dbus
  sudo dbus-daemon --system --fork --nopidfile
fi
RUNTIME_DIR="/run/user/$(id -u)"
if [ ! -d "$RUNTIME_DIR" ]; then
  sudo mkdir -p "$RUNTIME_DIR"
  sudo chown "$(id -u):$(id -g)" "$RUNTIME_DIR"
  sudo chmod 700 "$RUNTIME_DIR"
fi
export XDG_RUNTIME_DIR="$RUNTIME_DIR"
if ! pgrep -af 'Xvfb :1' >/dev/null; then
  rm -f /tmp/.X1-lock /tmp/.X11-unix/X1
  nohup Xvfb :1 -screen 0 1600x900x24 -nolisten tcp -ac > "$STATE_DIR/xvfb.log" 2>&1 &
  echo $! > "$STATE_DIR/xvfb.pid"
fi
for _ in $(seq 1 20); do [ -S /tmp/.X11-unix/X1 ] && break; sleep 1; done
if [ ! -S /tmp/.X11-unix/X1 ]; then echo "Xvfb failed; see $STATE_DIR/xvfb.log" >&2; tail -80 "$STATE_DIR/xvfb.log" || true; exit 1; fi
if ! pgrep -u "$(id -u)" -x gnome-shell >/dev/null; then
  nohup dbus-run-session -- gnome-shell --x11 --replace > "$STATE_DIR/gnome-shell.log" 2>&1 &
  echo $! > "$STATE_DIR/gnome-shell.pid"
fi
for _ in $(seq 1 30); do pgrep -u "$(id -u)" -x gnome-shell >/dev/null && break; sleep 1; done
if ! pgrep -u "$(id -u)" -x gnome-shell >/dev/null; then
  echo "GNOME Shell exited. Recent log:" >&2; tail -100 "$STATE_DIR/gnome-shell.log" 2>/dev/null || true; exit 1
fi
if ! is_listening "$VNC_PORT"; then
  nohup x11vnc -display :1 -rfbport "$VNC_PORT" -localhost -forever -shared -nopw -noxdamage -repeat > "$STATE_DIR/x11vnc.log" 2>&1 &
  echo $! > "$STATE_DIR/x11vnc.pid"
fi
for _ in $(seq 1 20); do is_listening "$VNC_PORT" && break; sleep 1; done
if ! is_listening "$VNC_PORT"; then echo "x11vnc failed; recent log:" >&2; tail -80 "$STATE_DIR/x11vnc.log" 2>/dev/null || true; exit 1; fi
if ! is_listening "$WEB_PORT"; then
  nohup /usr/share/novnc/utils/novnc_proxy --listen "$WEB_PORT" --vnc "127.0.0.1:$VNC_PORT" --web /usr/share/novnc > "$STATE_DIR/novnc.log" 2>&1 &
  echo $! > "$STATE_DIR/novnc.pid"
fi
for _ in $(seq 1 15); do is_listening "$WEB_PORT" && break; sleep 1; done
if ! is_listening "$WEB_PORT"; then echo "noVNC failed; recent log:" >&2; tail -80 "$STATE_DIR/novnc.log" 2>/dev/null || true; exit 1; fi
echo "Ubuntu GNOME desktop services:"
ss -ltn | grep -E ":$VNC_PORT|:$WEB_PORT" || true
echo "Open forwarded port $WEB_PORT and visit /vnc.html."

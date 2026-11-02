#!/usr/bin/env bash
set -euo pipefail

export DISPLAY=:1
mkdir -p "$HOME/.vnc"

# Codespaces containers do not run systemd; start the system D-Bus explicitly.
if [ ! -S /run/dbus/system_bus_socket ]; then
  sudo mkdir -p /run/dbus
  sudo dbus-daemon --system --fork --nopidfile
fi

# Restart VNC so it uses the Ubuntu GNOME Shell xstartup, not an old session.
vncserver -kill :1 >/dev/null 2>&1 || true
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1
vncserver :1 -localhost yes -geometry 1600x900 -depth 24 \
  -SecurityTypes None -xstartup "$HOME/.vnc/xstartup"

for i in $(seq 1 20); do
  if ss -ltn 2>/dev/null | grep -q ':5901'; then break; fi
  sleep 1
done

if ! pgrep -af '[n]ovnc_proxy.*6080' >/dev/null 2>&1; then
  nohup /usr/share/novnc/utils/novnc_proxy --listen 6080 --vnc localhost:5901 \
    > "$HOME/.vnc/novnc.log" 2>&1 &
fi

sleep 4
echo "Ubuntu GNOME desktop startup requested."
echo "Listening services:"
ss -ltn | grep -E ':5901|:6080' || true
echo "If GNOME does not appear, inspect: tail -60 ~/.vnc/*.log"

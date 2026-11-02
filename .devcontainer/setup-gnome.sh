#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -eq 0 ]; then
  echo "Run this script as the Codespaces user, not root." >&2
  exit 1
fi

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  ubuntu-desktop-minimal gnome-session gnome-session-flashback metacity \
  gnome-panel gnome-applets gnome-flashback dbus-x11 dbus-user-session \
  x11-xserver-utils tigervnc-standalone-server tigervnc-common novnc websockify \
  firefox file-roller nautilus gnome-terminal gnome-tweaks \
  curl wget git ca-certificates fonts-dejavu-core

# GDM is not used: Codespaces has no physical display or system login manager.
sudo systemctl disable gdm3.service 2>/dev/null || true

mkdir -p "$HOME/.vnc" "$HOME/.config"
cat > "$HOME/.vnc/xstartup" <<'EOF'
#!/usr/bin/env bash
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=GNOME-Flashback:GNOME
export DESKTOP_SESSION=gnome-flashback-metacity
export GDK_BACKEND=x11
exec dbus-run-session -- gnome-session --session=gnome-flashback-metacity
EOF
chmod +x "$HOME/.vnc/xstartup"

# VNC is loopback-only; Codespaces forwards the private browser port.
cat > "$HOME/.vnc/config" <<'EOF'
geometry=1600x900
localhost
SecurityTypes=None
EOF

echo "GNOME Flashback desktop installed. Run: bash .devcontainer/start-gnome.sh"

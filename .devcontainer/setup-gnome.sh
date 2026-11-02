#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -eq 0 ]; then
  echo "Run this script as the Codespaces user, not root." >&2
  exit 1
fi

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  ubuntu-desktop-minimal gnome-session gdm3 dbus-x11 x11-xserver-utils \
  tigervnc-standalone-server tigervnc-common novnc websockify \
  firefox file-roller nautilus gnome-terminal gnome-tweaks \
  curl wget git ca-certificates fonts-dejavu-core

# Prevent GDM from attempting to own a physical display in a container.
sudo systemctl disable gdm3.service 2>/dev/null || true
mkdir -p "$HOME/.vnc" "$HOME/.config"

cat > "$HOME/.vnc/xstartup" <<'EOF'
#!/usr/bin/env bash
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=GNOME
export DESKTOP_SESSION=gnome
exec dbus-launch --exit-with-session gnome-session --session=gnome-classic
EOF
chmod +x "$HOME/.vnc/xstartup"

# Use an unauthenticated loopback-only VNC endpoint; browser access is through
# the Codespaces forwarded port. Codespaces port privacy should remain Private.
touch "$HOME/.vnc/config"
grep -q '^geometry=' "$HOME/.vnc/config" || echo 'geometry=1600x900' >> "$HOME/.vnc/config"
grep -q '^localhost$' "$HOME/.vnc/config" || echo 'localhost' >> "$HOME/.vnc/config"
grep -q '^SecurityTypes=None$' "$HOME/.vnc/config" || echo 'SecurityTypes=None' >> "$HOME/.vnc/config"

echo "GNOME desktop packages installed. Start with: bash .devcontainer/start-gnome.sh"

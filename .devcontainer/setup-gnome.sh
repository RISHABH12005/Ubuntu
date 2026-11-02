#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -eq 0 ]; then
  echo "Run as the Codespaces user, not root." >&2
  exit 1
fi

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  ubuntu-desktop-minimal ubuntu-session gnome-shell gnome-session \
  gnome-shell-extension-ubuntu-dock gnome-shell-extension-appindicator \
  yaru-theme-gtk ubuntu-wallpapers gnome-control-center \
  dbus dbus-x11 dbus-user-session x11-xserver-utils \
  tigervnc-standalone-server tigervnc-common novnc websockify \
  firefox file-roller nautilus gnome-terminal gnome-tweaks \
  curl wget git ca-certificates fonts-dejavu-core

mkdir -p "$HOME/.vnc" "$HOME/.config"
cat > "$HOME/.vnc/xstartup" <<'EOF'
#!/usr/bin/env bash
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=ubuntu:GNOME
export XDG_SESSION_DESKTOP=ubuntu
export DESKTOP_SESSION=ubuntu
export GDK_BACKEND=x11
# Software rendering is required because Codespaces VNC has no physical GPU.
export LIBGL_ALWAYS_SOFTWARE=1
export GALLIUM_DRIVER=llvmpipe
exec dbus-run-session -- gnome-session --session=ubuntu
EOF
chmod +x "$HOME/.vnc/xstartup"

cat > "$HOME/.vnc/config" <<'EOF'
geometry=1600x900
localhost
SecurityTypes=None
EOF

if [ ! -f /usr/share/gnome-session/sessions/ubuntu.session ]; then
  echo "Ubuntu GNOME session file is missing. Check ubuntu-session installation." >&2
  exit 1
fi

echo "Ubuntu GNOME Shell installed and configured. Run: bash .devcontainer/start-gnome.sh"

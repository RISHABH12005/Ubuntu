#!/usr/bin/env bash
set -euo pipefail
if [ "$(id -u)" -eq 0 ]; then echo "Run as the Codespaces user, not root." >&2; exit 1; fi
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  ubuntu-desktop-minimal ubuntu-session gnome-shell gnome-session \
  gnome-shell-extension-ubuntu-dock gnome-shell-extension-appindicator \
  yaru-theme-gtk ubuntu-wallpapers gnome-control-center \
  dbus dbus-x11 dbus-user-session x11-xserver-utils \
  xvfb x11vnc novnc websockify \
  firefox file-roller nautilus gnome-terminal gnome-tweaks \
  curl wget git ca-certificates fonts-dejavu-core
mkdir -p "$HOME/.vnc" "$HOME/.config" "$HOME/.local/state/ubuntu-gnome"
cat > "$HOME/.vnc/xstartup" <<'EOF'
#!/usr/bin/env bash
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export DISPLAY=:1
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=ubuntu:GNOME
export XDG_SESSION_DESKTOP=ubuntu
export DESKTOP_SESSION=ubuntu
export GDK_BACKEND=x11
export LIBGL_ALWAYS_SOFTWARE=1
export GALLIUM_DRIVER=llvmpipe
export MUTTER_DEBUG_DISABLE_HW_CURSORS=1
exec dbus-run-session -- gnome-shell --x11 --replace
EOF
chmod +x "$HOME/.vnc/xstartup"
for binary in /usr/bin/gnome-shell /usr/bin/Xvfb /usr/bin/x11vnc; do
  if [ ! -x "$binary" ]; then echo "Required binary missing: $binary" >&2; exit 1; fi
done
echo "Ubuntu GNOME, Xvfb and x11vnc installed."
echo "Start the desktop with: bash .devcontainer/start-gnome.sh"

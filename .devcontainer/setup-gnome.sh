#!/usr/bin/env bash
set -Eeuo pipefail

# Install the GNOME desktop and the headless display/VNC stack.
# Run by the non-root Codespaces user; package installation is elevated via sudo.
if [ "$(id -u)" -eq 0 ]; then
  echo "Run this script as the Codespaces user, not root." >&2
  exit 1
fi

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  ubuntu-desktop-minimal ubuntu-session gnome-shell gnome-session \
  gnome-shell-extension-ubuntu-dock gnome-shell-extension-appindicator \
  yaru-theme-gtk ubuntu-wallpapers gnome-control-center \
  dbus dbus-x11 dbus-user-session x11-xserver-utils \
  xvfb x11vnc novnc websockify \
  firefox file-roller nautilus gnome-terminal gnome-tweaks \
  curl wget git ca-certificates fonts-dejavu-core procps iproute2

STATE_DIR="$HOME/.local/state/ubuntu-gnome"
mkdir -p "$HOME/.vnc" "$HOME/.config" "$STATE_DIR"

# Session launcher used by gnome-session. Do not run a second D-Bus daemon here:
# start-gnome.sh creates a private session bus for the complete Ubuntu session.
cat > "$HOME/.vnc/xstartup" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
export DISPLAY=:1
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=ubuntu:GNOME
export XDG_SESSION_DESKTOP=ubuntu
export DESKTOP_SESSION=ubuntu
export GDK_BACKEND=x11
export LIBGL_ALWAYS_SOFTWARE=1
export GALLIUM_DRIVER=llvmpipe
export MUTTER_DEBUG_DISABLE_HW_CURSORS=1
exec gnome-session --session=ubuntu
EOF
chmod 700 "$HOME/.vnc/xstartup"

# Verify files and commands that must exist before the desktop can start.
for binary in /usr/bin/gnome-shell /usr/bin/gnome-session /usr/bin/Xvfb /usr/bin/x11vnc /usr/bin/dbus-run-session; do
  if [ ! -x "$binary" ]; then
    echo "Required executable is missing after installation: $binary" >&2
    exit 1
  fi
done
if [ ! -f /usr/share/gnome-session/sessions/ubuntu.session ]; then
  echo "Ubuntu GNOME session definition is missing: ubuntu.session" >&2
  exit 1
fi
if [ ! -x /usr/share/novnc/utils/novnc_proxy ]; then
  echo "noVNC proxy executable is missing." >&2
  exit 1
fi

echo "Ubuntu GNOME and headless display packages are installed."

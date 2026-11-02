# Ubuntu 24.04 GNOME Desktop in GitHub Codespaces

This repository configures an Ubuntu 24.04 Codespaces container with Ubuntu GNOME Shell and browser access through noVNC.

The desktop uses Xvfb for its virtual X11 display and x11vnc for a loopback-only VNC connection. This avoids relying on TigerVNC's X server for GNOME.

## Start

1. Create or open a Codespace on the `main` branch.
2. Rebuild the container after changing the Dev Container configuration so the new packages are installed.
3. Wait for the GNOME package installation to finish.
4. The desktop attempts to start automatically. If it does not, run:

   ```bash
   bash .devcontainer/start-gnome.sh
   ```

5. Open the **Ports** tab and open the private forwarded port **6080**.
6. Navigate to `/vnc.html` if the noVNC page does not open automatically, then click **Connect**.

## Commands

- Start: `bash .devcontainer/start-gnome.sh`
- Stop: `bash .devcontainer/stop-gnome.sh`

## Port design

- `6080/tcp`: noVNC web interface; the only forwarded port and must remain **Private**.
- `5901/tcp`: x11vnc endpoint bound to loopback inside the container; do not forward it.

## Diagnostics

- GNOME Shell log: `~/.local/state/ubuntu-gnome/gnome-shell.log`
- Xvfb log: `~/.local/state/ubuntu-gnome/xvfb.log`
- VNC log: `~/.local/state/ubuntu-gnome/x11vnc.log`
- noVNC log: `~/.local/state/ubuntu-gnome/novnc.log`

## Limitations

This is a browser-accessible desktop session inside a Codespaces container, not a full Ubuntu virtual machine. Hardware acceleration, audio, systemd/logind, suspend and hardware access are limited. Codespaces must remain running while the desktop is in use.

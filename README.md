# Ubuntu 24.04 GNOME Desktop in GitHub Codespaces

This repository configures an Ubuntu 24.04 Codespaces container with the Ubuntu GNOME session, TigerVNC and browser access through noVNC.

## Start

1. Create or open a Codespace on the `main` branch.
2. Wait for the dev-container build and GNOME package installation to finish.
3. The desktop services start automatically when the Codespace starts. If needed, run:

   ```bash
   bash .devcontainer/start-gnome.sh
   ```

4. Open the **Ports** tab and open the private forwarded port **6080**.
5. Navigate to `/vnc.html` if the noVNC connection page does not open automatically, then click **Connect**.

## Commands

- Start: `bash .devcontainer/start-gnome.sh`
- Stop: `bash .devcontainer/stop-gnome.sh`

## Port design

- `6080/tcp`: noVNC web interface; the only forwarded port and must remain **Private**.
- `5901/tcp`: TigerVNC endpoint bound to loopback inside the container; do not forward it.

## Limitations

This is a browser-accessible desktop session inside a Codespaces container, not a full Ubuntu virtual machine. Hardware acceleration, audio, systemd/logind, suspend and hardware access are limited. GNOME Shell may not work reliably with every virtual display/graphics combination. Codespaces must remain running while the desktop is in use.

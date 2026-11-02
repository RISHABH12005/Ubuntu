# Ubuntu GNOME Desktop in GitHub Codespaces

Run an Ubuntu 24.04-based GNOME desktop in a GitHub Codespace and access it from your browser using noVNC.

## Create the Codespace

1. Open the [Ubuntu repository](https://github.com/RISHABH12005/Ubuntu).
2. Select **Code → Codespaces → Create codespace on main**.
3. Wait for the dev container to finish its first build. GNOME packages are installed by the post-create script.
4. In the Codespaces terminal, run:

   ```bash
   bash .devcontainer/start-gnome.sh
   ```

5. Open the **Ports** tab and open port **6080** in your browser. The devcontainer is configured to open it automatically.
6. In noVNC, select **Connect**. The GNOME desktop should appear.

## Desktop controls

- Start: `bash .devcontainer/start-gnome.sh`
- Stop: `bash .devcontainer/stop-gnome.sh`
- Desktop URL: `http://localhost:6080/vnc.html`

## Notes and limitations

- This is a browser-accessible GNOME session inside an Ubuntu 24.04 Codespaces container, not a full Ubuntu VM or a replacement for a locally installed desktop OS.
- The initial build downloads a substantial desktop package set and can take significant time and disk space. Use a Codespace with at least 4 CPUs and 8 GB RAM where available.
- Keep forwarded port **6080 Private**. The VNC service is configured without a VNC password and is intended to be reachable only through the private Codespaces port forwarding.
- GUI performance, audio, GPU acceleration, systemd services, hardware access and suspend behavior are limited by the Codespaces container environment.
- Stop the desktop when it is not needed and stop the Codespace to avoid consuming its billable compute time.

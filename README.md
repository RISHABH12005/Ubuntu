# Ubuntu 24.04 GNOME Desktop in GitHub Codespaces

This repository configures a browser-accessible Ubuntu GNOME desktop in a GitHub Codespaces container.

## Architecture

- Ubuntu 24.04 base container
- Ubuntu GNOME session (`gnome-session --session=ubuntu`)
- Xvfb virtual X11 display at `:1`
- x11vnc bound to container loopback at `127.0.0.1:5901`
- noVNC browser gateway at port `6080` (the only forwarded port; keep it private)

## First launch

1. Create or open a Codespace on `main`.
2. Rebuild the container after changing Dev Container configuration. This runs `.devcontainer/setup-gnome.sh` to install desktop packages.
3. The desktop starts through `postStartCommand`. Codespaces remains available even if the desktop session fails.
4. Open the **Ports** tab and open private port **6080**.
5. Visit `/vnc.html` and select **Connect**.

## Start and stop

Start: `bash .devcontainer/start-gnome.sh`

Stop: `bash .devcontainer/stop-gnome.sh`

## Logs

All service logs are stored in `~/.local/state/ubuntu-gnome/`: `xvfb.log`, `session.log`, `x11vnc.log`, and `novnc.log`.

## Diagnostics

```bash
pgrep -af 'Xvfb|gnome-session|gnome-shell|x11vnc|novnc_proxy' || true
ss -ltn | grep -E ':5901|:6080' || true
for f in ~/.local/state/ubuntu-gnome/*.log; do
  [ -f "$f" ] && { echo "===== $f"; tail -100 "$f"; }
done
```

## Limitations

A Codespaces container is not a full virtual machine. Hardware acceleration, audio, systemd/logind, suspend, and hardware device access may be limited. The Codespace must remain running while the desktop is in use.

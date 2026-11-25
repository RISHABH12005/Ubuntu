# Ubuntu 24.04 XFCE Desktop in GitHub Codespaces

This repository configures a browser-accessible Ubuntu XFCE desktop in a GitHub Codespaces container. Codespaces uses the Ubuntu 24.04 image; point releases such as 24.04.5 are delivered through that image's updates rather than a separate container tag. XFCE is used because GNOME Shell requires systemd/logind services that are not available in a standard Codespaces container.

## Start a Codespace

1. Create a Codespace for this repository, or rebuild an existing Codespace so it picks up `.devcontainer/devcontainer.json`.
2. Wait for the desktop port to open in your browser. If it does not, open port **6080** from the Codespaces **Ports** tab and visit `/vnc.html`.

The desktop port is configured as private to your Codespace. The container runs Ubuntu 24.04 with XFCE, KDE Plasma, and Firefox; its browser desktop is provided by noVNC. Choose XFCE or KDE Plasma in the dialog when the VNC session starts. Firefox is installed from Mozilla's signed APT repository because Ubuntu's Firefox package is a Snap launcher, which is not suitable for this container.

Keep port **6080** private. The noVNC service listens only on the container's loopback interface and requires HTTP Basic authentication. Get its generated credentials from the Codespace terminal with `cat ~/.vnc/websockify-auth`, then enter them when the browser prompts.

To switch desktops later, run `vncserver -kill :1` and then `/usr/local/bin/start-desktop` in the Codespace terminal. Reload the noVNC page and choose the other desktop.

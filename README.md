# Ubuntu 24.04 Desktop Environments in GitHub Codespaces

This repository configures browser-accessible Ubuntu desktop environments in a GitHub Codespaces container. Codespaces uses the Ubuntu 24.04 image; point releases such as 24.04.5 are delivered through that image's updates rather than a separate container tag.

## Start a Codespace

1. Create a Codespace for this repository, or rebuild an existing Codespace so it picks up `.devcontainer/devcontainer.json`.
2. Wait for the desktop port to open in your browser. If it does not, open port **6080** from the Codespaces **Ports** tab and visit `/vnc.html`.

The desktop port is configured as private to your Codespace. The container runs Ubuntu 24.04 with XFCE, KDE Plasma, GNOME, and Firefox; its browser desktop is provided by noVNC. Choose one of the three desktops in the dialog when the VNC session starts. Firefox is installed from Mozilla's signed APT repository because Ubuntu's Firefox package is a Snap launcher, which is not suitable for this container.

Keep port **6080** private. It is configured to open in a browser automatically. The noVNC service listens only on the container's loopback interface and requires HTTP Basic authentication. To keep the same login across rebuilds and new Codespaces, add GitHub Codespaces secrets named `NOVNC_USERNAME` and `NOVNC_PASSWORD` in your GitHub Settings under **Codespaces > Secrets**, and grant this repository access. The startup script writes them to the protected credentials file whenever the Codespace starts. Restart running Codespaces after adding or changing secrets. Choose a strong password.

If those secrets are not set, the startup script generates a password for the current Codespace. Read it in the Codespace terminal with `cat ~/.vnc/websockify-auth`, then enter it when the browser prompts. A generated password may differ in a new Codespace.

To switch desktops later, run `vncserver -kill :1` and then `/usr/local/bin/start-desktop` in the Codespace terminal. Reload the noVNC page and choose the other desktop.

#!/usr/bin/env bash
set -Eeuo pipefail
STATE_DIR="$HOME/.local/state/ubuntu-gnome"

# Stop proxy/servers first, then the session, then its X display.
for name in novnc x11vnc session xvfb; do
  pidfile="$STATE_DIR/$name.pid"
  [ -f "$pidfile" ] || continue
  pid="$(cat "$pidfile" 2>/dev/null || true)"
  if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
    kill "$pid" 2>/dev/null || true
  fi
  rm -f "$pidfile"
done

# Reap user-owned child processes that may outlive their wrapper.
pkill -u "$(id -u)" -x gnome-shell 2>/dev/null || true
pkill -u "$(id -u)" -x gnome-session-binary 2>/dev/null || true
pkill -u "$(id -u)" -x x11vnc 2>/dev/null || true
pkill -u "$(id -u)" -f '[n]ovnc_proxy' 2>/dev/null || true
pkill -u "$(id -u)" -x Xvfb 2>/dev/null || true
echo "Ubuntu GNOME desktop services stopped."

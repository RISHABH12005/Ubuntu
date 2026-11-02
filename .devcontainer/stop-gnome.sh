#!/usr/bin/env bash
set -euo pipefail
vncserver -kill :1 2>/dev/null || true
pkill -f 'novnc_proxy.*6080' 2>/dev/null || true
echo "Desktop stopped."

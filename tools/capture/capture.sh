#!/usr/bin/env bash
# Screenshot a Godot project off-screen (Docker + Xvfb + software GL). No window opens on the host.
# Usage: tools/capture/capture.sh <project_dir> [extra godot user args, default: --capture]
# The project must save its own screenshot when given the user args (e.g. res://shot.png).
set -euo pipefail
proj="$(cd "${1:?usage: capture.sh <project_dir> [args]}" && pwd)"; shift
args="${*:---capture}"
img=godot-capture:4.7.2
here="$(cd "$(dirname "$0")" && pwd)"
docker image inspect "$img" >/dev/null 2>&1 || docker build -t "$img" "$here"
docker run --rm -v "$proj":/work "$img" sh -c "
  godot --headless --path /work --import >/dev/null 2>&1
  xvfb-run -a -s '-screen 0 1280x720x24' godot --rendering-driver opengl3 --path /work --resolution 1280x720 -- $args 2>&1 | grep -vE 'ALSA|V-Sync' || true"

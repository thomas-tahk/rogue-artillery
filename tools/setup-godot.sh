#!/usr/bin/env bash
# Makes `godot` available. On his Mac it comes from Homebrew; in a Linux cloud
# run this downloads the pinned version into ~/.local/bin. Safe to rerun.
set -euo pipefail
VERSION=4.7.2-stable
if command -v godot >/dev/null && godot --version | grep -q "${VERSION%-stable}"; then exit 0; fi
case "$(uname -s)" in
  Darwin) echo "run: brew install --cask godot" >&2; exit 1 ;;
esac
zip="Godot_v${VERSION}_linux.x86_64"
mkdir -p "$HOME/.local/bin"
tmp=$(mktemp -d)
curl -fsSL -o "$tmp/g.zip" "https://github.com/godotengine/godot/releases/download/${VERSION}/${zip}.zip"
unzip -q "$tmp/g.zip" -d "$tmp"
mv "$tmp/$zip" "$HOME/.local/bin/godot"
chmod +x "$HOME/.local/bin/godot"
echo "installed: $("$HOME/.local/bin/godot" --version) (add ~/.local/bin to PATH)"

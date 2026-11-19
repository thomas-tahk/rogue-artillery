# Rogue Artillery
Roguelite artillery game built with Godot 4.3. Design: [docs/GDD.md](docs/GDD.md). Plan and state: [docs/chief/](docs/chief/).

## Play
- **Browser:** every pushed branch is published to `https://thomas-tahk.github.io/rogue-artillery/<branch>/` (main at the root) by CI — needs GitHub Pages set to *Deploy from a branch → gh-pages / (root)* once.
- **Editor:** open `project.godot` in Godot 4.3 and press F5.

Controls: ←/→ drive · ↑/↓ angle · W/S power · Space fire · R new battle.

## Test
```
GODOT=/path/to/godot-4.3 tests/run.sh
```
Headless; runs every `tests/test_*.gd`. CI (`.github/workflows/ci.yml`) runs the same on every push, then exports the Web build.

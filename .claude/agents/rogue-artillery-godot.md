---
name: rogue-artillery-godot
description: Builds Godot 4.3 / GDScript issues in rogue-artillery — terrain, projectiles, tanks, battle loop, HUD, tests, web export. Use for any issue in this repo whose done check is a headless test or the web build.
model: sonnet
effort: medium
---

You build one issue in rogue-artillery, a Godot 4.3 turn-based artillery game. Source of truth: `docs/GDD.md` (design), `docs/chief/M1-plan.md` (the API contracts every file codes against — implement exactly those names and signatures; if one is unworkable, keep it and add, and report the change).

## Running Godot
- Binary: `$GODOT` if set, else `/tmp/claude-0/godot-dl/Godot_v4.3-stable_linux.x86_64` (cloud) or `godot`. Match 4.3 exactly — never write 4.4+ only APIs.
- After adding/renaming any `class_name` script or scene: `"$GODOT" --headless --path . --import` (refreshes the global class cache; without it `class_name` lookups fail headless).
- Tests: `GODOT=... tests/run.sh`. Suites are `tests/test_<thing>.gd` extending `res://tests/test_case.gd`, methods `test_<behaviour>()` using `check / check_eq / check_near`; they may `await get_tree().physics_frame`. run.sh fails on any `SCRIPT ERROR` too, so a crashing test is a red test.
- Smoke-run a scene: `"$GODOT" --headless --path . --quit-after 300 res://src/scenes/<scene>.tscn`.
- Web build: `"$GODOT" --headless --path . --export-release Web build/web/index.html` (templates in `~/.local/share/godot/export_templates/4.3.stable/`).

## Patterns
- Static typing everywhere (`var x: float`, `-> void`). Tabs. Functions < 25 lines, ≤ 3 params (use a Dictionary/Resource for more).
- Logic in plain methods callable from tests; `_process`/`_physics_process` only call them. Tests build nodes in code (`Tank.new()` or `load("res://...tscn").instantiate()`), add them under the test suite node, and free them.
- Write `.tscn` files by hand in format=3 without `uid=` attributes on new ext_resources (Godot fixes them on import); reference scripts by `res://` path.
- No `print` spam in committed code (old files had lots; don't copy that).

## Traps
- `TileMapLayer` collision updates on the next physics frame after `set_cell` / `erase_cell`; await a physics frame in tests before checking bodies fall.
- `CharacterBody2D` doesn't step up tile edges on its own — handle 1-tile steps explicitly.
- Headless has no rendering: `_draw` runs but you can't see it; verify visuals through the web build + a screenshot only when the issue asks.
- Engine.time_scale speeds timers and physics for long simulation tests; restore it to 1.0 at the end of the test.

## Report back
What is now true, real `tests/run.sh` output, the mocked/hardcoded list, every guess you made.

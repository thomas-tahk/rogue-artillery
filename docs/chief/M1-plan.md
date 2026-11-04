# M1 plan — First real battle

**Done-gate:** "In a browser, I trade shots with an enemy tank in turns (move, aim, set power, fire, wind matters), one of us dies or falls off the map, a You Win / You Lose screen appears, and R starts a fresh battle on new terrain."

Branch: `m1-first-battle`. Engine: Godot **4.3-stable**, Compatibility renderer (needed for web). Tests: `GODOT=<godot binary> tests/run.sh` (headless; see `tests/run_tests.gd`).

## Architecture (contracts — every issue codes against these)
Coordinates: Godot pixels, y down. World = rectangle from (0,0) to terrain size. Tile = 16 px.

| File | `class_name` | Public API |
|---|---|---|
| `src/scripts/ballistics.gd` | `Ballistics` (static, RefCounted) | `const GRAVITY := 980.0` · `const SPEED_PER_POWER := 12.0` · `const WIND_ACCEL_PER_UNIT := 8.0` · `static launch_velocity(elevation_deg: float, facing: int, power_pct: float) -> Vector2` · `static step(pos, vel, wind_accel, dt) -> PackedVector2Array [new_pos, new_vel]` · `static trajectory(start, vel, wind_accel, max_time, dt) -> PackedVector2Array` · `static first_hit(start, vel, wind_accel, is_hit: Callable, bounds: Rect2) -> Dictionary {hit: bool, position: Vector2}` (hit false = left bounds / timed out) |
| `src/scripts/terrain.gd` on `TileMapLayer` (`src/scenes/terrain.tscn`) | `Terrain` | `const TILE := 16` · `generate(seed: int, width_tiles: int, height_tiles: int)` · `is_solid(world_pos: Vector2) -> bool` · `surface_y(world_x: float) -> float` (top of the highest solid tile in that column, `INF` if none) · `destroy_circle(world_pos: Vector2, radius_px: float)` · `world_rect() -> Rect2` |
| `src/scripts/projectile.gd` (`src/scenes/projectile.tscn`) | `Projectile` (Node2D) | `setup(start: Vector2, velocity: Vector2, config: Dictionary)` with config keys `wind_accel: float`, `is_hit: Callable(Vector2)->bool`, `bounds: Rect2` · `signal landed(position: Vector2, exploded: bool)` · moves itself with `Ballistics.step` each physics frame (sub-stepped so it cannot tunnel through a 16 px tile), frees itself after emitting |
| `src/scripts/enemy_ai.gd` | `EnemyAI` (RefCounted) | `var is_hit: Callable` · `var bounds: Rect2` · `var aim_error_px := 60.0` · `var rng := RandomNumberGenerator.new()` · `choose_shot(from: Vector2, target: Vector2, wind_accel: float) -> Vector2` (x = elevation_deg 0..90, y = power_pct 10..100); searches angles/powers with `Ballistics.first_hit`, then aims at a target offset by up to `aim_error_px` |
| `src/scripts/tank.gd` on `CharacterBody2D` (`src/scenes/tank.tscn`) | `Tank` | `@export var team := "player"` · `@export var facing := 1` (1 right, -1 left) · `max_hp := 100`, `hp` · `aim_deg := 45.0` (0..90 elevation toward facing) · `power_pct := 60.0` (10..100) · `fuel := 100.0` (px of driving per turn), `refuel()` · `adjust_aim(delta_deg)` · `adjust_power(delta)` · `drive(direction: int, delta: float)` (spends fuel, climbs 1-tile steps) · `muzzle_position() -> Vector2` · `launch_velocity() -> Vector2` · `take_damage(amount: int)` · `is_dead() -> bool` · `contains_point(world_pos) -> bool` · `var show_aim := false` (draws aim line, length grows with power) · draws its own HP bar · gravity + `move_and_slide` every physics frame · `signal hp_changed(hp, max_hp)` · `signal died` |
| `src/scripts/battle.gd` (`src/scenes/battle.tscn`, the main scene) | `Battle` | owns Terrain, two Tanks, Camera2D (static, frames whole world), HUD; turn loop; `@export var player_is_ai := false` (autoplay for tests); `@export var battle_seed := 0` (0 = random); `signal battle_ended(player_won: bool)` |
| `src/scripts/hud.gd` on `CanvasLayer` | `Hud` | `set_turn(text)` · `set_aim(deg, power)` · `set_wind(strength: int)` (arrow + number) · `set_fuel(fuel)` · `show_result(player_won: bool)` · always-visible key legend |

Tuning defaults: world 100×40 tiles (1600×640 px); surface between 40–75 % of height; flat spawn pads at x≈15 % / 85 %. Wind = integer −10..10, re-rolled each turn. Explosion radius 40 px; damage = 50 × (1 − d / (40 + 16)) clamped ≥ 0, d = distance from blast to tank centre; direct hit = 50. Tank falls below the world → dies. **Shooter exclusion:** for each shot Battle builds one `is_hit` Callable = terrain solid OR inside the *opponent's* box (never the shooter's), and passes that same Callable to `EnemyAI.is_hit` and `Projectile.setup`, so prediction and flight agree. Self-damage still applies through the blast radius. Leaving through the top of the world is not out (`Ballistics.is_out` checks left/right/bottom only).

## Controls (M1)
← / → drive (fuel-limited) · ↑ / ↓ angle · W / S power · Space fire · R new battle.

## Issues
| # | Issue | Specialist | Blocked by |
|---|---|---|---|
| #2 | Procedural destructible terrain | backend-engineer | — |
| #3 | Deterministic projectile + ballistics + enemy aim solver | backend-engineer | — |
| #4 | Tank unit (HP, gravity, driving, aim/power, HP bar) | backend-engineer | — |
| #5 | CI: tests + Web build published to GitHub Pages per branch | general-build-helper | — |
| #6 | Battle loop: turns, wind, damage, win/lose, restart, HUD; new main scene | frontend-engineer | #2, #3, #4 |

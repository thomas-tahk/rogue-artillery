# Rogue Artillery — Resumption Plan

*Reference doc for getting this project moving again. Written 2026-05-01 after a one-month pause.*

---

## Why this project

"Gunbound but roguelite, single-player" is a sharp 5-second pitch with a real underserved audience. Gunbound players have spent 20 years asking for a spiritual successor; the few attempts (ShellShock Live, Worms WMD's tournament mode) don't satisfy the meta-progression itch. Turn-based physics + roguelite is a nearly empty intersection — most artillery games are dead multiplayer, most roguelites aren't physics. The vehicle-identity-driven combat translates cleanly to a roguelite upgrade tree, and the GDD already designs around that.

**Goal**: ship a good game in this niche, ideally to Steam Early Access. Not chasing Balatro/StS-tier hits. A devoted small audience is the win condition.

**Realistic ceiling**: 5–50k wishlists, $20k–$200k lifetime. That's a real outcome, not a lottery ticket.

---

## Honest blockers (named so they can be solved)

1. **Godot fluency is shallow.** Existing code was vibe-coded; debugging it costs more time than understanding it would have. This is the biggest hidden cost right now.
2. **Art pipeline is unstarted.** "Do all my own art" instinct is admirable but is the most common solo-indie killer. Needs a deliberate plan.
3. **Game feel is bad.** No trajectory preview, no hit pause, no screen shake, no real explosion particles, tile-based terrain destruction that can't feel "Worms-y." Feel is a prototype property, not an end-of-project polish task.
4. **Design minutia uncertainty.** Acceptable — resolves through playtesting once feel is good. Don't pre-resolve on paper.
5. **Time.** Part-time, ~10–15 hrs/week realistic. Plan must respect this.

---

## Realistic timeline to Early Access

Part-time, 10–15 hrs/week:

| Phase | Duration | Outcome |
|---|---|---|
| 0. Godot fundamentals | 1–2 months | Can read & write Godot 4 idiomatically without LLM crutches |
| 1. Juicy 60-second core loop | 1–2 months | One shot feels *amazing* — trajectory preview, hit pause, particles, shake, audio |
| 2. Vertical slice | 6–9 months | One full run playable end-to-end: 1 biome, 3 vehicles, 6 enemies, basic meta |
| 3. EA-acceptable content | 4–6 months | Steam Early Access launch |

**Total: 12–18 months.** Anyone (including LLMs) telling you faster is lying.

Steam page goes up at month 4–5 once a juicy 30-second GIF exists. Wishlists compound from there — start early.

---

## Phase 0: Godot fundamentals (1–2 months)

**Stop writing game code until this is done.** The vibe-coded `src/` is fine to keep as a sandbox, but expect to rewrite most of it.

### Pick one structured course and finish it

- **GDQuest "Learn Godot 4"** (free + paid) — most thorough, recommended.
- **Brackeys' Godot 4 series** (YouTube, free) — faster, less depth.
- **Heartbeast tutorials** (YouTube) — practical, project-based.

### Minimum competencies before resuming game work

- [ ] Scene tree, node hierarchy, instancing — when does a scene own vs. reference a node
- [ ] Signals: emitting, connecting in editor, connecting in code, when to use which
- [ ] `_ready` vs `_process` vs `_physics_process` — when each fires, what to put in each
- [ ] RigidBody2D vs CharacterBody2D vs Area2D — when to use which (current code uses CharacterBody2D for `gun.gd` but never uses its features — that's a smell)
- [ ] Autoloads / singletons — when to use, when to avoid
- [ ] Resources (`.tres`) for shared data
- [ ] Tween for procedural animation (camera shake, hit pause, UI motion)
- [ ] GPUParticles2D basics
- [ ] TileMapLayer including custom data layers (for material hardness)
- [ ] Input map (move all `ui_left` etc. references to named actions like `aim_left`)

### Anti-pattern checklist (avoid in all future code)

- ❌ Reaching across scene tree with `$"../UI/PowerBar"` style paths — couples scenes; use signals or exported NodePaths
- ❌ String matching node names (`body.name.contains("TileMapLayer")`) — use groups or class checks
- ❌ Hardcoded positions in `_ready()` (`global_position = Vector2(400, 300)`) — set in scene file
- ❌ `print()` debug statements left in code — use `print_debug()` or remove
- ❌ Scripts doing UI layout in code (anchors, offsets) when scene editor would do it
- ❌ Mixing concerns in one script (input + UI + firing + collision response all in `gun.gd`)

---

## Phase 1: Juicy 60-second core loop (1–2 months)

**Premise**: until firing one shot at one enemy on flat ground feels addictive, no other system matters. No campaign, no upgrades, no menus. Just: aim, fire, satisfying impact. Polish *this* before anything else.

### Mandatory feel ingredients (in order of impact)

1. **Trajectory preview ghost** — dotted/faded arc that updates as aim/power changes. Single biggest UX upgrade for any artillery game. Transforms it from "guess and check" to "skill expression." Calculate via repeated physics step or analytic equation; plot 20–40 points.
2. **Hit pause** — freeze (or slow to 0.05x) for 50–100ms on impact. `Engine.time_scale` or per-node pause.
3. **Screen shake** — Camera2D offset noise on impact, decaying. ~5–15px depending on shot weight.
4. **Particle explosions** — `GPUParticles2D` burst on impact. Even default-ish settings look good. Tune emission count, lifetime, spread, color ramp.
5. **Terrain debris** — chunks fly out on destruction (can be particles with sprite frames or rigid debris bodies despawning after 1s).
6. **Layered audio** — fire whoosh + impact thud + debris tinkle. Even placeholder freesound.org clips. Audio is half of feel; don't defer.
7. **Smoke trail** following projectile mid-flight.
8. **Recoil animation** on the gun barrel — quick kickback + return tween.

### Decision: terrain destruction method

Current `terrain_destroyer.gd` removes whole tiles — Worms-style smooth craters are impossible with this approach. Three options:

| Approach | Pros | Cons |
|---|---|---|
| **Tile-based (current)** | Simple, performant | Looks blocky, can't do smooth craters, limits feel |
| **Pixel-based (Image manipulation)** | Worms-feel, smooth craters | More complex collision, potentially slow without care |
| **Polygon-based (CollisionPolygon2D + Geometry2D.clip_polygons)** | Smooth, performant if managed | More math, harder to draw/render |

**Recommendation**: pixel-based, following the bookmarked Rungeon tutorial. The "feel" of artillery games is heavily tied to satisfying terrain deformation. Tile-based caps the ceiling. Bite the complexity now.

### Decision: mobile vs PC

`project.godot` says `mobile` renderer; GDD says PC primary. **Pick one.** Recommendation: **PC primary** to match GDD intent, with mobile renderer kept (it's fine on PC, and leaves the mobile port option open). Note: precise aim with mouse is fundamentally different UX from touch, so a real mobile port is its own design pass — not free.

### Phase 1 success criteria

- [ ] Single scene, single tank, single enemy stationary target, flat ground
- [ ] Trajectory preview is live and updates in real-time as aim/power change
- [ ] Firing → hit pause → particles → shake → debris → audio happens every shot
- [ ] Terrain destruction looks smooth (not blocky)
- [ ] You record a 30-second clip and rewatch it and *want to play more*
- [ ] You send the clip to one trusted person and they say "that looks fun"

If criteria 5 isn't met, you're not done. Don't move on.

---

## Phase 2: Vertical slice (6–9 months)

One full run playable end-to-end. After this exists, the rest of dev is content + polish, not invention.

### Scope

- 1 biome (Grasslands — start here, defer the other 3)
- 3 player vehicles (one per upgrade-path identity: mobility, defense/melee, damage; defer terrain-destruction archetype to later)
- 6 enemy types: 2 basic, 2 mobile, 1 special, 1 mini-boss
- 3 projectile types: standard shell, heavy shell, one wildcard (cluster or bouncing)
- Working turn system, win/lose conditions, between-battle shop, basic meta-progression
- Campaign map: ~8 nodes, 1 mini-boss, 1 final boss
- One full run = 20–30 minutes

### Don't build until vertical slice is done

- Other 3 biomes
- Weather systems
- Hazards beyond basic
- Cosmetics / skins
- Achievements
- Difficulty modifiers
- Settings menu beyond the basics

### Phase 2 milestones (rough)

1. Turn system with player + 1 enemy alternating (1–2 weeks)
2. Health/damage/death (1 week)
3. Camera that follows projectiles in flight, returns to overview after (1–2 weeks)
4. Wind system + indicator (1 week)
5. Enemy AI v1: aim at player, vary by personality (2–3 weeks)
6. Campaign map UI + node-to-battle flow (2–3 weeks)
7. Shop UI + 8–12 upgrade options across 4 paths (2–3 weeks)
8. Run start → finish loop with permadeath + meta currency (1–2 weeks)
9. 6 enemy variants + mini-boss + final boss (4–6 weeks)
10. UI pass: power bar, angle indicator, wind, health bars, turn banner (2–3 weeks)
11. Audio pass: every action has a sound (2 weeks)
12. Steam page up + 30-sec trailer (1 week)

---

## Phase 3: EA-acceptable content (4–6 months)

Add the other 3 biomes, more vehicles/enemies, weather and hazards, polish. Ship to Steam Early Access. Roadmap public.

---

## Art plan — challenge the "do everything myself" instinct

Doing all your own art is admirable but is the single biggest source of solo-indie schedule slip. Be deliberate.

### Recommended approach: deliberately limited pixel art

- **Commit to a small canvas size now and don't change it.** Suggested: 32×32 vehicles, 16×16 tiles, 16×16 projectiles. Half the indie art rework comes from rescoping canvas mid-project.
- **Pick one palette and don't change it.** Endesga 32 or DB16 are common starting points. Aseprite supports indexed mode — use it.
- **Aseprite-only for sprites.** Krita for backgrounds/concept only.
- **Animation budget per sprite**: idle (2–4 frames), fire/recoil (2–4 frames), damaged variant (1 frame), destroyed (4–8 frames). That's it. No walk cycles for stationary turrets.

### Acceptable pragmatic shortcuts

- **Buy a base asset pack on itch.io ($10–30) for placeholders.** Replace later if it matters. Vampire Survivors used asset-store sprites for years.
- **Programmer art with intentional vector/geometric style** if pixel art learning is too slow. See early Nuclear Throne builds. Only works if the *style* is committed and consistent.

### Phase-aligned art priority

| Phase | Art needed |
|---|---|
| 1 (juicy core loop) | 1 player tank, 1 enemy tank, 1 shell sprite, 1 explosion spritesheet, 1 grasslands tileset (~6 tiles) |
| 2 (vertical slice) | + 2 more vehicles, 5 more enemies, 2 more projectiles, full Grasslands background layers, all UI sprites |
| 3 (EA) | + 3 biome tilesets + backgrounds, remaining enemies, boss, menus, polish |

---

## Existing code evaluation

Honest take after reading `src/`. Most of this is salvageable as reference but expect to rewrite once Godot fluency lands.

### `gun.gd` — needs rewrite

Issues:
- Mixed concerns: UI setup (power bar anchors), input handling, firing logic, world positioning, scene-tree-reaching all in one script.
- `extends CharacterBody2D` but never uses CharacterBody2D's `move_and_slide` etc. Should be `Node2D` or a child of one.
- Hardcoded `global_position = Vector2(400, 300)` in `_ready()` — should be set in scene file.
- Reaches across tree with `$"../UI/PowerBar"` and `$"../AngleIndicatorUI"`. Use signals + exported NodePaths instead.
- Power bar layout (anchors, offsets) configured in code, not scene editor — backwards.
- `call_deferred("setup_angle_indicator")` is a workaround for an initialization-order bug that proper signal usage would avoid.
- `get_parent().add_child(bullet)` and `get_parent().get_node("TerrainDestroyer")` — gun shouldn't know about its parent's siblings. Emit a `fired(bullet)` signal; let a battle manager handle placement.

Keep as reference for: physics impulse calculation, angle/power input pattern, basic firing loop.

### `bullets.gd` — mostly OK, small fixes

Issues:
- `body.name.contains("TileMapLayer")` — string matching node names is brittle. Use `body.is_in_group("terrain")` only and add the group properly.
- `print` debug noise should go.
- `gravity_scale = 1.0` in `_ready()` should just be set in the scene's RigidBody2D properties.

Otherwise the structure (signal up, queue_free) is fine and idiomatic.

### `terrain_destroyer.gd` — design-blocker, needs replacement

Issues:
- Tile-based destruction with `set_cell(tile_pos, -1)` produces blocky craters. This caps the entire feel ceiling of the game.
- Cross/circle-of-tiles is cosmetically wrong for an artillery game. Players expect Worms-style smooth deformation.
- Reaches `$"../TileMapLayer"`. Same scene-tree-reaching antipattern.

Replace entirely with pixel-based destruction (see Phase 1 decision above). Treat current as a working proof-of-concept of the signal flow only.

### `angle_indicator_ui.gd` — significantly over-engineered

Issues:
- ~130 lines doing what should be ~30. State flags (`is_initialized`, `tank_reference`, `indicator_visible`, `is_player_turn`) duplicate what node visibility + parent-child relationships already give you.
- `_process` polling for tank position is unnecessary — make it a child of the gun node, position is automatic.
- Two Line2D arcs created in code; this should be a small scene file with the visuals authored in the editor.
- "VERY VISIBLE for testing" sizing + colors left in production code.
- Multiple defensive null checks for state that proper scene structure prevents.

Rewrite as: child Node2D of gun with two Line2D children authored in scene, single `update_angle(angle)` method. ~25 lines.

### General observations

- Scene/architecture is ad-hoc. After Phase 0, design a proper scene hierarchy: `Battle.tscn` (root) → `Player.tscn`, `Enemies/`, `Terrain.tscn`, `BattleUI.tscn`, `BattleManager` (Node, mediates). Communication: signals up, method calls down. No sibling-reaching.
- Move debug `print` calls to `print_debug` or behind a `DEBUG = true` flag. Production builds should be silent by default.
- Add `class_name` declarations to scripts that get reused, so type-safe references replace string node lookups.
- All `ui_left` etc. inputs should be remapped to named actions (`aim_left`, `aim_right`, `charge_fire`) in the input map. Future gamepad support depends on this.

---

## Open design questions (defer until playtesting)

These don't need answers now. Note them, decide via prototype.

1. **Power mechanic**: GDD says "no timing-based power." How is power actually set then? Upgrade-determined? Full-power always? Discrete steps? — playtest both during Phase 1.
2. **Movement**: how much does player tank move per turn? Free movement within a range? Discrete tiles? Fuel-based (Worms-style)?
3. **Wind**: per-shot reroll, per-turn, per-battle, biome-static? Stronger or weaker than Gunbound?
4. **Number of turns per battle**: cap at N turns? Sudden death like Gunbound? Until one side dies?
5. **Single artillery vs. squad**: GDD says single. Worth pressure-testing — one of Gunbound's key appeals was the team. Defer this question, but flag it.
6. **PvP later?**: async leaderboards? seed-sharing? — pure post-EA question, but worth keeping in mind for architecture (deterministic physics seeds).

---

## Cadence and accountability

The single biggest determinant of shipping vs. shelving: **showing up consistently.**

- Pick a non-negotiable weekly minimum (e.g. "Saturday 9–11am, no exceptions"). Slow and consistent ships. Fast and sporadic doesn't.
- Commit at end of every session, even if WIP. Momentum is fragile.
- Devlog (X/Mastodon/Bluesky) starting Phase 1. One GIF per week. Public commitment + start of marketing.
- Steam page at month 4–5. Wishlists compound — every month delayed is wishlists lost.
- Re-read this doc when stuck.

---

## Concrete next move (this week)

Pick *one*:

1. **Start GDQuest's Godot 4 path.** 2 hours this weekend. No game-building until at least module 3 is done.
2. **OR** if you can't commit dedicated learning time: define your weekly minimum cadence and start doing the Phase 1 feel work alongside learning, accepting it'll be slower.

Don't add new mechanics. Don't restructure the existing code yet (do that after Phase 0). Don't start art. Don't open a Steam page. Just learn.

---

*End of plan. This document is the north star — update it as decisions are made and milestones hit. Stale plan = useless plan.*

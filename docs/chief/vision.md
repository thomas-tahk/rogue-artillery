# Vision — Rogue Artillery

Source of truth for design detail: [`docs/GDD.md`](../GDD.md). This file is the chief's summary of intent plus the defaults chosen without a Shape session (owner asked for shape-by-default, 2026-11-04). Disagree with any line → say so on the milestone PR.

## Intent
A single-player, turn-based artillery roguelite: Gunbound's "fight the physics" shot-making inside a Slay-the-Spire-style run (battle → reward → choice → next battle, permadeath, meta unlocks). One vehicle, built up through upgrade paths (mobility, defense/melee, terrain destruction, damage). Variety comes from enemies and biome weather/hazards, not cards.

## Goals
- Satisfying, readable shots: angle + power + wind, arcing projectiles, destructible terrain that matters (craters, ring-outs).
- Runs of 20–40 min across 3 acts in one biome.
- Learnable enemy personalities instead of telegraphed intents.
- Playable on PC; the build also runs in a browser so the owner can test from anywhere.

## Non-goals (for now)
- Multiplayer, mobile port, final art/audio, 2.5D.
- Deckbuilding of any kind (GDD: "not a deckbuilder").

## Anti-goals
- Timing-based power (GDD rules out the hold-and-release power bar).
- Enemy intent telegraphs.
- Random-per-turn weather noise (weather belongs to the biome) — per-turn *wind* is allowed.

## Project done-gate
"In a browser, I start a run, fight through three acts of battles in one biome, spend scrap on upgrades between battles, and either beat the final boss or die and start a new run."

## Milestones
| # | Name | Done-gate |
|---|---|---|
| M1 | First real battle | "In a browser, I trade shots with an enemy tank in turns (move, aim, set power, fire, wind matters), one of us dies or falls off the map, a You Win / You Lose screen appears, and R starts a fresh battle on new terrain." |
| M2 | Battle feel | Explosion particles, screen shake, camera follows the shell, trajectory feel tuned; mouse click-drag aiming (GDD controls). |
| M3 | Run skeleton | A node map of 3–4 battles + mini-boss; scrap earned; one shop with the four upgrade paths; permadeath → new run. |
| M4 | Enemy variety | 3+ enemy types with distinct, learnable behaviour; a mini-boss. |
| M5 | First biome | Grasslands weather/hazards; pixel-bitmap terrain (replacing tiles) with dirt/stone/metal. |

## Assumptions (unverified; Research queue)
- **Assumption:** the discrete-action-per-turn question in `docs/TODO_research.md` can wait until M3; M1 uses classic move-then-shoot turns. *(open)*
- **Assumption:** tile-based terrain (16 px tiles) is good enough until M5; the GDD's pixel-bitmap terrain is a later swap behind the same `Terrain` API. *(open)*
- **Assumption:** setting power with keys (not a timing bar) satisfies the GDD's "no timing-based power mechanic". *(open — owner call, see docs/questions/M1.md)*
- **Assumption:** Godot 4.3 web export (no threads, Compatibility renderer) runs the game well enough in a work browser. *(verified locally in headless Chromium, 2026-11-04)*

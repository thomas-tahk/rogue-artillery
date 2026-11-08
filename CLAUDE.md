# Rogue Artillery (working title)

Godot 4.7 game prototype. Repo name and title are placeholders; the real name is decided much later.

## Pitch (the owner's idea, paraphrased 2026-11-07; not yet a design)

Turn-based artillery combat with a roguelite run structure. Gunbound is the main inspiration (wind, vehicle types, special shots), Worms for destructible terrain. Not a deckbuilder. Full design: `docs/GDD.md`, plan: `docs/PLAN.md`. Already working: aim and power, physics shots, destructible terrain. Next goal: a real playable prototype with decent stand-in art.

## Originality rule

Borrow genres, mechanics and moods freely. Never copy another game's names, characters, unit or card lists, art, story or exact rule set. Inspirations are named here so we know what to diverge from, not what to reproduce.

## How this project runs

- Design first, with the owner: run `/chief` (Shape) and write `docs/design.md`. Don't build gameplay until he signs off on it.
- After sign-off, builds run with no input from him. He only plays builds and gives feedback.
- Questions for him go in `needs-you` issues, one ask per issue.

## Commands

| What | Command |
|---|---|
| Install Godot (cloud) | `tools/setup-godot.sh && export PATH=$HOME/.local/bin:$PATH` |
| Import assets | `godot --headless --path . --import` |
| Smoke test | `godot --headless --path . --script res://tests/smoke_test.gd` |
| Play (Mac) | `godot --path .` |

## Agents can't see the game

Every playable change needs a headless test, plus a "what to try" list in the PR so he knows what to play-test. Screenshot capture in cloud runs is not verified yet. Whoever gets it working documents it here.

## Assets

Stand-in art comes from CC0 packs (Kenney.nl and similar). Record each pack's source and license in `assets/CREDITS.md`. No AI-generated assets until he picks a tool.

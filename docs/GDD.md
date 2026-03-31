# Artillery Roguelite - Game Design Document

## Introduction

### Game Summary Pitch

Artillery Roguelite is a turn-based physics combat game where players command a single artillery vehicle through procedurally generated campaigns. Each run takes place within a single biome with unique terrain, weather conditions, and enemy compositions, requiring strategic adaptation and precise aim to survive increasingly difficult battles.

### Inspiration

**Gunbound**
The primary inspiration. Gunbound demonstrated how artillery games could incorporate RPG elements through different vehicle types, avatar customization, and special abilities. Its approach to wind mechanics and diverse vehicle types — each with unique movement, shot patterns, and roles — directly informs this project's vehicle upgrade system and combat feel. The goal is to capture what made Gunbound compelling (fighting the game's physics in a competitive context) and translate it into a single-player roguelite structure.

**Worms Series**
Provides reference for physics-based artillery gameplay — destructible terrain, trajectory-based combat, environmental interaction. Useful as a design reference but not a direct template.

**Modern Roguelites (Slay the Spire, Hades)**
Provide inspiration for run structure, meta-progression, and campaign pacing. The roguelite skeleton (branching encounters, escalating difficulty, pre-run choices, permadeath) is drawn from this space. **Note: this is not a deckbuilder.** No cards, no card-based mechanics. The combat system is built from scratch around artillery, not adapted from card game design.

### Player Experience

Players will experience the satisfaction of perfectly calculated shots, the tension of risky positioning, and the strategic depth of building a vehicle identity over the course of a run. Each run challenges players to adapt their upgrade strategy to the biome conditions and enemy types they encounter. Success requires both tactical planning and skillful execution.

### Platform

PC (Windows, Mac, Linux) with potential mobile ports

### Development Software

- **Engine**: Godot 4.x
- **Art**:
  - **Aseprite**: Industry standard for pixel art with excellent animation tools, onion skinning, and pixel-perfect editing
  - **Krita**: Free, open-source alternative to Photoshop, great for backgrounds and concept art
- **Audio**:
  - **Audacity**: Free, reliable audio editor perfect for cleaning up sound effects and basic editing
  - **BeepBox**: Browser-based chiptune creator, perfect for retro-style music that fits artillery games
- **Version Control**: Git with GitHub

### Genre

Turn-based strategy, Physics puzzle, Roguelite

### Target Audience

- **Primary**: Fans of tactical/strategy games who enjoy roguelites
- **Secondary**: Physics game enthusiasts, Gunbound/Worms veterans
- **Tertiary**: Casual players who enjoy "easy to learn, hard to master" experiences

## Concept

### Gameplay Overview

Players control a **single artillery vehicle** through a procedurally generated campaign. Combat is turn-based. Between battles, players navigate through the campaign, acquire upgrades, and make strategic decisions. Death is permanent, but meta-progression unlocks new vehicles, upgrades, and starting bonuses for future runs.

The primary sources of encounter variety are **enemy design** and **environmental conditions**. The upgrade system provides run-to-run build variety without any deckbuilding or card mechanics.

### Primary Mechanics

#### **Physics-Based Combat**

- Projectile trajectory affected by angle and wind
- Realistic physics simulation for arcing, bouncing, and explosive force
- Environmental factors: wind strength/direction, weather conditions
- **No timing-based power mechanic** — power/range is handled through other means (upgrade-based or fixed per shot type)

#### **Destructible Terrain**

- Fully destructible 2D terrain using pixel-perfect collision
- Different material types: dirt (easy), stone (medium), metal (hard)
- Terrain destruction is a core strategic element — not just environmental flavor
- Terrain destruction as a win condition: cause fall damage or ring-outs by destroying ground beneath enemies

#### **Turn-Based Structure**

- Player and enemy alternate turns
- Each turn: move, then shoot (or other action)
- **No enemy telegraphing** (or minimal/reduced) — enemy behavior is readable through patterns and AI personality, not pre-announced intent cards
- Turn structure kept lean — complexity comes from positioning and build decisions, not action menus

#### **Roguelite Structure**

- Campaign progression with meaningful choices between battles
- Battle → Reward → Choice → Next Battle loop
- Currency earned from battles spent on upgrades
- Permadeath with meta-progression unlocks
- Single biome per run (see Biomes section)

### Vehicle Upgrade System

The upgrade system is the primary build-identity layer of the game. Players invest in one or more of the following upgrade paths, enabling synergistic strategies:

- **Mobility** — increased movement range and maneuverability; enables hit-and-reposition play, avoidance of return fire
- **Defense/Melee** — armor and damage resistance; enables tanking shots and closing distance for melee-range attacks or outlasting the enemy
- **Terrain Destruction** — enhanced explosive radius and terrain-shaping tools; enables environmental win conditions (fall damage, ring-outs, cover removal)
- **Damage** — raw firepower increase; straightforward escalation, high risk/reward

These paths are not exclusive — hybrid builds and synergies between paths are intentional design goals.

### Secondary Mechanics

#### **Weather and Visibility**

- Each biome has characteristic weather patterns that affect gameplay
- Weather can modify visibility, projectile behavior, or disable/limit certain actions
- Weather is a feature of the biome/run, not random per-turn noise
- Different builds are advantaged or disadvantaged by different weather conditions (e.g. high-mobility builds thrive in low visibility)

#### **Environmental Hazards**

- Rising water/lava (forces aggressive play)
- Falling debris zones
- Wind tunnels that affect projectiles
- Explosive barrels and environmental weapons
- Hazards are biome-appropriate, not generic

#### **Enemy Design**

Enemy variety is a primary driver of encounter-to-encounter interest alongside environment. Enemies have distinct behavioral patterns and personalities that players learn to read over time — not telegraphed intent, but consistent and learnable AI behavior.

- **Basic**: Stationary turrets, simple tanks
- **Mobile**: Jumping units, repositioning enemies, flying drones
- **Special**: Shielded units, terrain-exploiting enemies, high-durability units
- **Bosses**: Multi-phase battles with unique mechanics

Enemy design needs significant iteration — this is one of the most important systems for making the game feel fresh across encounters.

## Art

### Visual Style

**Overall Aesthetic**
- Colorful, cartoony style with modern polish
- High contrast for gameplay clarity
- Destructible terrain uses particle effects for satisfaction
- UI clean and informative

**Character Design**
- Artillery units are anthropomorphized vehicles with personality
- Each unit type has distinct silhouette and animation style
- Enemies range from basic tanks to bizarre contraptions
- Cosmetic customization unlocked through play

### Technical Considerations

**2D Implementation**
- Sprite-based characters with skeletal animation
- Terrain stored as destructible bitmap
- Particle systems for explosions and effects
- Layered backgrounds for depth

**Potential 2.5D Enhancement**
- 3D models rendered to 2D sprites
- Allows for smooth rotation and more detailed units
- Keeps gameplay strictly 2D while enhancing visuals

## Audio

### Music

**Dynamic Soundtrack**
- Calm exploration theme for map navigation
- Tension builds during enemy turns
- Victory fanfare and defeat dirge
- Each biome has unique musical theme

### Sound Effects

**Combat Audio**
- Unique sound for each weapon/shot type
- Satisfying explosion and destruction sounds
- Character voice barks (kept minimal)
- Environmental audio (wind, weather, etc.)

## Game Experience

### UI

**Battle HUD**
- Angle indicator attached to vehicle, visible during player turn
- Wind indicator (direction and strength)
- Turn indicator
- Mini-map showing unit positions

**Campaign Map**
- Node-based path system
- Clear iconography for node types
- Preview of upcoming encounters
- Current run statistics

### Controls

**Mouse + Keyboard**
- Click and drag for aiming
- WASD/Arrows for camera movement
- Space to fire

**Gamepad Support**
- Analog stick for precise aiming
- Shoulder buttons for adjustments
- D-pad for action selection

### Progression Systems

**In-Run Progression**
- Currency: "Scrap" collected from destroyed enemies
- Spent at shops for upgrades
- Risk/reward: terrain destruction and aggressive play yields more scrap
- Special objectives in battles for bonus rewards

**Meta Progression**
- "Research Points" earned based on run performance
- Unlock new vehicles, upgrades, and starting loadouts
- Cosmetic unlocks (skins, victory animations)
- New enemy types and difficulty modifiers

### Pre-Run Choices (à la Neow)

Before each run, players are offered a small set of starting boons. These can include:

- Stat bonuses (extra HP, scrap, etc.)
- Early upgrade access
- **Biome selection** — normally the run biome is randomized; biome choice appears here as an occasional perk, giving players agency without making it a default option

### Content Structure

**Biomes** (3-4 at launch)

Each run takes place entirely within a single biome, randomized at run start (or chosen via pre-run perk). The biome defines the terrain character, weather patterns, and environmental hazards for the entire run. Encounter variety within the run comes from enemy escalation, map layout differences, and upgrade trajectory — not biome switching.

1. **Grasslands** — Tutorial biome, standard physics, mild wind
2. **Desert** — High winds, sandstorm visibility events
3. **Arctic** — Slippery ice physics, freezing hazards
4. **Volcanic** — Lava hazards, updrafts affect shot trajectories

**Run Structure**
- Act 1: 3-4 battles + mini-boss
- Act 2: 4-5 battles + mini-boss
- Act 3: 3-4 battles + final boss
- Total run time: 20-40 minutes

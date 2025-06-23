# Artillery Roguelite - Game Design Document

## Introduction

### Game Summary Pitch

Artillery Roguelite is a turn-based physics combat game where players command either a single artillery unit or a squad of specialized units (TBD) through procedurally generated campaigns. Each run presents unique terrain, enemy compositions, and weapon loadouts, requiring strategic adaptation and precise aim to survive increasingly difficult battles.

### Inspiration

**Worms Series**
The Worms franchise provides the core artillery gameplay loop - turn-based combat where trajectory, power, and weapon selection determine success. The destructible terrain and physics-based combat create emergent gameplay moments where no two battles play the same. The humor and weapon variety inspire our approach to keeping combat entertaining.

**Gunbound**
This Korean classic demonstrated how artillery games could incorporate RPG elements through different mobile types, avatar customization, and special abilities. Its approach to wind mechanics and diverse vehicle types (each with unique shot patterns and special abilities) showed how to add variety to the artillery formula. The game's "Mobile" system - where different vehicles had different movement capabilities, shot types, and roles - provides inspiration for potential squad variety.

**Modern Roguelites (Slay the Spire, Hades)**
These titles provide inspiration for meta-progression and campaign structure, showing how procedural content and permanent unlocks can create addictive gameplay loops while maintaining run variety.

### Player Experience

Players will experience the satisfaction of perfectly calculated shots, the tension of risky positioning, and the excitement of discovering powerful weapon combinations. Each 15-30 minute run challenges players to adapt their strategy based on available weapons, terrain advantages, and enemy types. Success requires both tactical planning and skillful execution.

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
- **Secondary**: Physics game enthusiasts, Worms series veterans
- **Tertiary**: Casual players who enjoy "easy to learn, hard to master" experiences

## Concept

### Gameplay Overview

Players control either a single artillery unit OR a squad of specialized units (design decision pending) through procedurally generated campaigns. Combat is turn-based, with players and enemies alternating shots. Between battles, players navigate through the campaign, acquire upgrades, and manage their loadout. Death is permanent, but meta-progression unlocks new weapons and starting bonuses for future runs.

**Potential Squad System**: If going with multiple units, each would have distinct roles:
- Not enforced roles, but units could naturally fit into damage, terrain manipulation, or support
- No duplicate units allowed in a squad
- Each unit type would have unique characteristics and shot patterns (inspired by Gunbound's Mobile variety)

### Primary Mechanics

#### **Physics-Based Combat**
- Projectile trajectory affected by power, angle, and wind
- Realistic physics simulation for bouncing, rolling, and explosive force
- Environmental factors: wind strength/direction changes each turn
- Weapon-specific physics properties (weight, bounce, friction)

#### **Destructible Terrain**
- Fully destructible 2D terrain using pixel-perfect collision
- Different material types: dirt (easy), stone (medium), metal (hard)
- Terrain destruction affects strategy - create cover or expose enemies
- Water/lava pools that flow realistically when terrain is destroyed

#### **Turn-Based Strategy**
- Each unit gets one action per turn (move OR shoot)
- Turn order based on unit speed stats
- Time limit per turn (optional, for tension)
- Preview system shows trajectory before committing to shot

#### **Roguelite Structure**
- Campaign progression with meaningful choices between battles
- Battle -> Reward -> Choice -> Next Battle loop
- Currency earned from battles spent on upgrades
- Permadeath with meta-progression unlocks
- Note: Specific structure (map style, node types, etc.) will evolve during development

### Secondary Mechanics

#### **Unit Variety** (If Squad System Implemented)
- Each unit type has unique movement patterns and abilities
- Customizable loadouts before each run
- Units can be upgraded during runs
- Synergies between different unit types

#### **Upgrade System** (Ideas in Development)
- **Vehicle Upgrades**: Armor plating, engine improvements, stabilizers for better accuracy
- **Weapon Enhancements**: Increased blast radius, special effects, trajectory modifiers
- **Stat Improvements**: Movement range, turn speed, reload time
- **Relics/Artifacts**: Game-changing items like "All shots bounce twice" or "Explosions heal allies"
- Mix and match approach - not locked to single upgrade type

#### **Weapon Variety**
- **Basic**: Grenade, Rocket, Shot
- **Utility**: Teleport, Drill, Repair Kit
- **Advanced**: Cluster Bomb, Homing Missile, Lightning Strike
- **Exotic**: Black Hole, Time Bomb, Gravity Well
- Unlimited ammo with cooldowns or energy system (TBD)

#### **Environmental Hazards**
- Rising water/lava (forces aggressive play)
- Falling debris zones
- Wind tunnels that affect projectiles
- Explosive barrels and environmental weapons

#### **Power-ups and Items**
- Temporary buffs: Double damage, No wind, Perfect accuracy
- Permanent upgrades: +Max HP, +Movement range, +Starting ammo
- Consumables: Health packs, Ammo crates, Shield generators

## Art

### Visual Style

**Overall Aesthetic**
- Colorful, cartoony style similar to Worms but with modern polish
- High contrast for gameplay clarity
- Destructible terrain uses particle effects for satisfaction
- UI inspired by modern card games - clean, informative, elegant

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
- Unique sound for each weapon type
- Satisfying explosion and destruction sounds
- Character voice barks (kept minimal)
- Environmental audio (wind, water, etc.)

## Game Experience

### UI

**Battle HUD**
- Power/angle indicator with numeric display
- Wind indicator (direction and strength)
- Weapon selector with ammo counts
- Turn timer (if enabled)
- Mini-map showing unit positions

**Campaign Map**
- Node-based path system
- Clear iconography for node types
- Preview of upcoming battles
- Current run statistics

### Controls

**Mouse + Keyboard**
- Click and drag for aiming
- Scroll wheel for weapon selection
- WASD/Arrows for camera movement
- Space to fire
- Tab for unit switching

**Gamepad Support**
- Analog stick for precise aiming
- Shoulder buttons for power adjustment
- D-pad for weapon selection

### Progression Systems

**In-Run Progression**
- Currency: "Scrap" collected from destroyed enemies
- Spent at shops for weapons, items, and upgrades
- Risk/reward: Destroying more terrain yields more scrap
- Special objectives in battles for bonus rewards

**Meta Progression**
- "Research Points" earned based on run performance
- Unlock new weapons, units, and starting loadouts
- Cosmetic unlocks (skins, victory animations)
- New biomes and enemy types
- Difficulty modifiers for experienced players

### Content Structure

**Biomes** (3-4 at launch)
1. **Grasslands** - Tutorial biome, standard physics
2. **Desert** - High winds, sandstorm events
3. **Arctic** - Slippery ice physics, freezing water
4. **Volcanic** - Lava hazards, updrafts affect shots

**Run Structure**
- Act 1: 3-4 battles + mini-boss
- Act 2: 4-5 battles + mini-boss  
- Act 3: 3-4 battles + final boss
- Total run time: 20-40 minutes

**Enemy Variety**
- Basic: Stationary turrets, simple tanks
- Mobile: Jumping units, flying drones
- Special: Shielded units, healers, summoners
- Bosses: Multi-phase battles with unique mechanics

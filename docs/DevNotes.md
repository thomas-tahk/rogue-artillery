# Rogue Artillery (Working Title) - Development Resources & Guide (generated by using Claude)

# Current Development Status - July 15, 2025

## ✅ Completed Milestones

### Core Mechanics Working
- **Physics-based projectiles** - RigidBody2D with gravity, realistic arcing
- **Angle/power control** - Arrow keys for aim, spacebar hold for power charging
- **Visual feedback** - Power bar appears during charging
- **Terrain collision** - TileMapLayer with proper collision shapes
- **Bullet collision** - Fixed collision size (was Godot logo sized, now proper bullet size)
- **Basic sprites** - Replaced Godot icons with simple tank and bullet sprites

### Technical Architecture Established
- **Scene structure**: Shooter.tscn (main) with instantiated Terrain.tscn
- **Physics**: RigidBody2D for bullets, TileMapLayer for terrain
- **Collision debugging**: Enabled visual collision shapes for troubleshooting

## 🔄 Current Focus: Destructible Terrain

**Why This Next**: We have solid collision detection working. Destructible terrain is the core differentiator for artillery games and builds directly on what we've accomplished.

**Implementation Approach**: 
- Method needs research - likely image-based destruction like Worms
- Remove terrain tiles where bullets hit
- Update collision after destruction

## 📋 Immediate To-Do List

### High Priority
1. **Research destructible terrain methods** - Review tutorials and decide on approach
2. **Implement basic crater creation** - Remove tiles where bullets hit
3. **Update collision after destruction** - Ensure physics still work
4. **Add visual effects** - Explosion particles, screen shake

### Medium Priority  
1. **Camera system** - Proper world positioning, bullet tracking
2. **Angle indicator** - Visual arrow showing aim direction
3. **Turn system** - Basic player/enemy alternation
4. **Enemy AI** - Simple aiming at player

### Later
1. **Weapon variety** - Different projectile types
2. **Upgrade system** - Between-battle progression
3. **Roguelite structure** - Campaign map, meta progression

## 🤔 Current Decisions Pending

1. **Destructible terrain method**: Image-based vs polygon-based vs tile removal
2. **Camera behavior**: Static vs following projectiles vs manual control
3. **Turn system timing**: Immediate switch vs animation delays
4. **Enemy AI complexity**: Simple vs tactical vs varied personalities

## 🚧 Known Issues

1. **Positioning**: Terrain/tank positioning works in editor but not in play (camera system will fix)
2. **Bullet spawn**: Slight collision with tank on spawn (adjusting spawn offset helped)
3. **Performance**: No optimization done yet (not a concern until more complex systems)

## 📚 Resources Bookmarked for Next Phase

### Destructible Terrain
- "Worms-style Destructible Terrain in Godot" by Rungeon
- Official Godot docs on Image manipulation
- Geometry2D class documentation for polygon methods

### Camera Systems
- "Camera Follow in Godot 4" tutorials
- Artillery game camera reference videos

## 🎯 Success Metrics for Current Phase

- [ ] Bullets create visible holes in terrain
- [ ] Collision updates properly after destruction  
- [ ] Basic explosion effect on impact
- [ ] No performance issues with destruction

**Target**: Complete destructible terrain by end of week

---

## Development Log Entries

### July 15, 2025 - Terrain Collision Success
- Fixed bullet collision shape (was Godot logo size!)
- Terrain collision working perfectly
- Collision debug view is invaluable for troubleshooting
- Ready to move on to destructible terrain

### July 15, 2025 - Basic Terrain Implemented  
- Successfully created TileMapLayer with collision
- Learned proper Godot 4 TileSet workflow (very different from older versions)
- Bullets now bounce/stop on terrain as expected

### July 15, 2025 - Visual Assets Replaced
- Created simple tank and bullet sprites
- Much more readable than Godot icons
- Game starting to look like actual artillery game

### July 15, 2025 - Power/Angle Controls Complete
- Arrow keys adjust aim angle (-90° to +90°)
- Spacebar charging system working
- Power bar UI provides clear feedback
- Core artillery mechanics feeling solid

## Godot Learning Path

### Complete Beginner Resources
1. **Official Godot Documentation**
   - [Getting Started Guide](https://docs.godotengine.org/en/stable/getting_started/introduction/index.html)
   - [Your First 2D Game](https://docs.godotengine.org/en/stable/getting_started/first_2d_game/index.html)
   - Keep this bookmarked - best reference material

2. **Video Tutorial Series**
   - **Brackeys** - "How to make a game in Godot" (great for beginners)
   - **GDQuest** - Free Godot courses on YouTube
   - **HeartBeast** - Action RPG Tutorial (teaches many concepts you'll need)
   - **KidsCanCode** - Godot Recipes (bite-sized problem solutions)

3. **Interactive Learning**
   - **GDQuest's Learn GDScript App** - Practice coding directly

### Physics & Artillery Specific Tutorials

1. **Projectile Motion**
   - Search: "Godot projectile trajectory preview"
   - "Godot 2D physics tutorial"
   - "Angry Birds clone Godot" (similar physics)

2. **Destructible Terrain**
   - **Method 1**: Polygon2D with Geometry2D class
   - **Method 2**: Image-based destruction (like Worms)
   - Video: "Godot Destructible Terrain Tutorial" by Godotneers

3. **Turn-Based Combat**
   - "Godot Turn Based Combat" by Game Endeavor
   - State machine tutorials (crucial for turn management)

## Technical Implementation Guides

### Core Systems Breakdown

#### 1. Physics System
```gdscript
# Basic projectile physics you'll need:
extends RigidBody2D

var initial_velocity = Vector2()
var gravity_scale = 1.0
var wind_force = Vector2()

func launch(power: float, angle: float):
	var direction = Vector2(cos(angle), sin(angle))
	initial_velocity = direction * power
	linear_velocity = initial_velocity
	
func _physics_process(delta):
	# Apply wind
	apply_force(wind_force)
```

**Extended Projectile System:**
```gdscript
# ProjectileManager.gd - Handles all projectiles
extends Node

var projectile_scene = preload("res://scenes/Projectile.tscn")
var active_projectiles = []

func fire_projectile(weapon_type: String, start_pos: Vector2, power: float, angle: float):
	var projectile = projectile_scene.instantiate()
	projectile.weapon_type = weapon_type
	projectile.position = start_pos
	projectile.launch(power, angle)
	
	# Connect signals
	projectile.exploded.connect(_on_projectile_exploded)
	projectile.timeout.connect(_on_projectile_timeout)
	
	active_projectiles.append(projectile)
	get_tree().current_scene.add_child(projectile)

func _on_projectile_exploded(projectile, explosion_pos):
	# Handle terrain destruction
	TerrainManager.create_explosion(explosion_pos, projectile.explosion_radius)
	# Clean up
	active_projectiles.erase(projectile)
	projectile.queue_free()
```

**Resources:**
- Godot RigidBody2D documentation
- "2D Physics Best Practices" in Godot docs
- Box2D tutorials (Godot uses similar physics)

#### 2. Destructible Terrain System

**Approach 1: Image-Based (Recommended)**
```gdscript
# Pseudo-code for terrain destruction
extends Node2D

var terrain_image: Image
var terrain_texture: ImageTexture
var collision_bitmap: BitMap

func create_explosion(position: Vector2, radius: float):
	# 1. Modify image pixels in radius
	# 2. Update texture
	# 3. Regenerate collision from bitmap
```

**Tutorial:** "Worms-style Destructible Terrain in Godot" by Rungeon

**Approach 2: Polygon-Based**
- Use Geometry2D.clip_polygons()
- Better performance but more complex
- Good for simpler terrain shapes

#### 3. Turn Management State Machine

**Resources:**
- "Godot State Machine Tutorial" by GDQuest
- "Turn-Based Strategy in Godot" by Game Development Center

```gdscript
# Basic turn structure
enum TurnState {
	PLAYER_TURN,
	ENEMY_TURN,
	ANIMATING,
	BETWEEN_TURNS
}

var current_state = TurnState.PLAYER_TURN
var current_unit_index = 0
var units = [] # Array of all units in battle

func _ready():
	# Initialize turn order based on unit speed or other criteria
	units.sort_custom(func(a, b): return a.speed > b.speed)

func process_turn():
	match current_state:
		TurnState.PLAYER_TURN:
			if current_unit.is_player_controlled:
				# Wait for player input
				if Input.is_action_just_pressed("end_turn"):
					end_current_turn()
			else:
				end_current_turn()
				
		TurnState.ENEMY_TURN:
			# AI takes its turn
			var ai_action = current_unit.ai_component.decide_action()
			execute_action(ai_action)
			
		TurnState.ANIMATING:
			# Wait for animations to complete
			pass

func end_current_turn():
	current_state = TurnState.BETWEEN_TURNS
	current_unit_index = (current_unit_index + 1) % units.size()
	
	# Check win/lose conditions
	if check_battle_end():
		return
		
	# Start next turn
	current_state = TurnState.PLAYER_TURN if units[current_unit_index].is_player else TurnState.ENEMY_TURN
```

#### 4. Roguelite Map System

**Basic Campaign Structure:**
```gdscript
# CampaignManager.gd
extends Node

class_name CampaignManager

var current_location = 0
var completed_battles = []
var currency = 0
var unlocked_weapons = ["basic_grenade", "basic_rocket"]

# Simplified progression - linear for MVP
func get_next_encounter():
	var encounter_types = ["battle", "battle", "upgrade", "battle", "boss"]
	return encounter_types[current_location % encounter_types.size()]

func complete_encounter(reward_currency: int):
	currency += reward_currency
	current_location += 1
	
	# Check for meta progression unlocks
	MetaProgression.add_experience(reward_currency)
```

**Tutorial:** "Simple Roguelike Progression in Godot" by HeartBeast

### Additional System Pseudocode

#### 5. Upgrade System
```gdscript
# UpgradeManager.gd
extends Node

# Different upgrade types as discussed in GDD
var upgrade_categories = {
	"vehicle": ["armor", "engine", "stabilizer"],
	"weapon": ["blast_radius", "reload_speed", "special_effect"],
	"stats": ["movement", "accuracy", "health"],
	"relics": [] # Loaded from JSON
}

var current_upgrades = []

func apply_upgrade(upgrade_id: String, target_unit):
	var upgrade_data = load_upgrade_data(upgrade_id)
	
	match upgrade_data.type:
		"vehicle":
			target_unit.armor += upgrade_data.armor_bonus
			target_unit.speed += upgrade_data.speed_bonus
		"weapon":
			target_unit.weapon_component.modify_stats(upgrade_data)
		"relic":
			# Relics need special handling
			RelicSystem.activate_relic(upgrade_data.relic_effect, target_unit)
```

#### 6. Unit/Vehicle System (If Squad-Based)
```gdscript
# Unit.gd - Base class for all artillery units
extends CharacterBody2D

class_name Unit

@export var unit_type: String = "basic_tank"
@export var max_health: int = 100
@export var movement_range: int = 3
@export var unique_ability: String = ""

var current_health: int
var has_moved: bool = false
var has_fired: bool = false

# Components
@onready var weapon_component = $WeaponComponent
@onready var movement_component = $MovementComponent
@onready var ability_component = $AbilityComponent

func _ready():
	current_health = max_health
	load_unit_data()

func load_unit_data():
	# Load from JSON or Resource
	var data = load("res://data/units/" + unit_type + ".tres")
	if data:
		max_health = data.health
		movement_range = data.movement
		unique_ability = data.ability
```

### Asset Creation Resources

#### Free Art Tools & Assets

1. **Sprite Creation**
   - **Aseprite** ($20) - Best pixel art tool
   - **LibreSprite** (Free) - Open source Aseprite
   - **Piskel** (Free, browser-based)
   - **GraphicsGale** (Free) - Good for animations

2. **Free Asset Packs**
   - **OpenGameArt.org** - Terrain textures, UI elements
   - **Itch.io** - Search "artillery game assets"
   - **Kenney.nl** - High quality, free game assets
   - **CraftPix** - Some free packs for prototyping

3. **Sound Resources**
   - **Freesound.org** - Explosion sounds, ambient
   - **Zapsplat** - Free with account
   - **SFXR/BFXR** - Generate retro sound effects
   - **BeepBox** - Browser-based music creation

#### Creating Your Own Assets

**Pixel Art Tutorials:**
- "Pixel Art for Games" by AdamCYounis
- "How to Make Pixel Art" by Brandon James Greer
- MortMort's pixel art tutorials

**Quick Art Pipeline:**
1. Sketch concepts on paper
2. Create base sprites in Aseprite (32x32 or 64x64)
3. Animate key frames (idle, shoot, hit, death)
4. Export as sprite sheets

### Code Architecture Patterns

#### Component System
```gdscript
# Unit.gd
extends Node2D

@export var max_health: int = 100
@export var move_speed: float = 50.0

@onready var health_component = $HealthComponent
@onready var weapon_component = $WeaponComponent
@onready var movement_component = $MovementComponent
```

#### Signal-Based Communication
```gdscript
# Use signals to decouple systems
signal turn_ended
signal unit_destroyed(unit)
signal projectile_hit(position, damage)
```

### Useful Godot Addons

1. **Dialogic** - For event/story sequences
2. **ProtonScatter** - For environment decoration
3. **SmartShape2D** - For terrain creation
4. **GUT** - Unit testing framework

### Development Workflow Tips

#### Version Control
```bash
# .gitignore for Godot projects
.import/
export.cfg
export_presets.cfg
*.tmp
```

**Tutorial:** "Git for Game Developers" by Brackeys

#### Project Organization
```
res://
├── scenes/
│   ├── units/
│   ├── weapons/
│   ├── ui/
│   └── maps/
├── scripts/
│   ├── components/
│   ├── systems/
│   └── utilities/
├── assets/
│   ├── sprites/
│   ├── sounds/
│   └── music/
└── data/
	├── weapons.json
	└── enemies.json
```

### Technical Architecture Diagram

A technical architecture diagram is a visual representation of how your game's systems connect and communicate. It helps you:
- Plan before coding
- Identify dependencies
- Spot potential problems early
- Keep organized as complexity grows

Here's a simple architecture for your artillery roguelite:

```
┌─────────────────────────────────────────────────────────┐
│                     Game Manager                         │
│  (Scene transitions, save/load, global state)           │
└─────────────┬─────────────────────────┬─────────────────┘
			  │                         │
			  ▼                         ▼
┌─────────────────────────┐ ┌───────────────────────────┐
│   Campaign Manager      │ │     Battle Manager        │
│ - Track progression     │ │ - Turn system             │
│ - Handle unlocks        │ │ - Win/lose conditions     │
│ - Manage currency       │ │ - Combat flow             │
└───────────┬─────────────┘ └─────────┬─────────────────┘
			│                         │
			▼                         ▼
┌─────────────────────────┐ ┌───────────────────────────┐
│   Meta Progression      │ │    Combat Systems         │
│ - Permanent unlocks     │ ├───────────────────────────┤
│ - Statistics            │ │ ┌─────────────────────┐   │
│ - Achievements          │ │ │  Physics Manager    │   │
└─────────────────────────┘ │ │ - Projectiles       │   │
							│ │ - Wind              │   │
							│ └─────────────────────┘   │
							│ ┌─────────────────────┐   │
							│ │  Terrain Manager    │   │
							│ │ - Destruction       │   │
							│ │ - Collision         │   │
							│ └─────────────────────┘   │
							│ ┌─────────────────────┐   │
							│ │   Unit Manager      │   │
							│ │ - Player units      │   │
							│ │ - Enemy AI          │   │
							│ └─────────────────────┘   │
							└───────────────────────────┘

Signal Flow:
━━━━━━━━━━━━
GameManager.battle_started → BattleManager.initialize()
Unit.fired_projectile → PhysicsManager.create_projectile()
Projectile.exploded → TerrainManager.destroy_terrain()
BattleManager.battle_ended → CampaignManager.process_rewards()
```

**How to Use This:**
1. Each box is a separate script/scene in Godot
2. Arrows show which systems talk to each other
3. Start building from the bottom up (Physics → Combat → Campaign)
4. Use Godot's signal system for the connections

**Implementation in Godot:**
```gdscript
# Example of how these connect via signals

# In BattleManager.gd
signal battle_ended(victory: bool, rewards: Dictionary)

func end_battle(player_won: bool):
	var rewards = calculate_rewards()
	battle_ended.emit(player_won, rewards)

# In CampaignManager.gd
func _ready():
	BattleManager.battle_ended.connect(_on_battle_ended)

func _on_battle_ended(victory: bool, rewards: Dictionary):
	if victory:
		currency += rewards.currency
		unlock_items(rewards.unlocks)
	# Transition to next screen
```

#### 1. Trajectory Preview Performance
**Problem:** Calculating trajectory every frame is slow
**Solution:** 
- Update preview only when aim changes
- Use simple line renderer, not physics simulation
- Limit preview points (20-30 is usually enough)

#### 2. Pixel-Perfect Collision
**Problem:** Bitmap collision is expensive
**Solution:**
- Use lower resolution collision map
- Update collision shapes only after destruction
- Consider chunk-based updates

#### 3. Save System for Roguelite
**Problem:** Saving mid-run state
**Solution:**
- Use Godot's ResourceSaver for simple data
- JSON for complex save states
- Tutorial: "Godot Save Game System" by GDQuest

### Testing & Polishing

#### Debug Tools to Build
1. **Level skipper** - Jump to any battle
2. **Weapon unlocker** - Test all weapons
3. **Terrain editor** - Design specific scenarios
4. **AI override** - Control enemy actions

#### Performance Optimization
- **Profile early**: Use Godot's built-in profiler
- **Particle pooling**: Reuse explosion effects
- **LOD for terrain**: Simpler collision far from action
- **Texture atlasing**: Combine sprites for fewer draw calls

### Community & Help

#### Where to Get Help
1. **Godot Discord** - Very active and helpful
2. **r/godot** - Reddit community
3. **Godot Forum** - Official forums
4. **Stack Overflow** - Tag: godot

#### Showcasing Progress
- **#screenshotsaturday** on Twitter
- **r/IndieDev** - Get feedback
- **itch.io devlogs** - Build community early
- **YouTube devlogs** - Document journey

### Minimum Viable Product (MVP) Checklist

#### Week 1-2: Core Mechanics
- [ ] Basic unit movement
- [ ] Projectile physics with gravity
- [ ] Simple terrain (non-destructible first)
- [ ] Turn switching

#### Week 3-4: Combat Polish  
- [ ] Destructible terrain
- [ ] 3-5 basic weapons
- [ ] Enemy AI (aim at player)
- [ ] Health/damage system

#### Week 5-6: Roguelite Structure
- [ ] Map navigation
- [ ] 2-3 node types (Battle, Shop)
- [ ] Basic progression (unlock 1-2 weapons)
- [ ] Run complete/fail states

#### Week 7-8: Content & Polish
- [ ] 5-10 battle scenarios
- [ ] Sound effects
- [ ] Basic animations
- [ ] UI polish

### Recommended Learning Order

1. **Start Here**: Make a simple projectile that falls with gravity
2. **Then**: Add power/angle controls with mouse
3. **Next**: Create basic terrain collision
4. **After**: Implement turn switching
5. **Then**: Add destructible terrain
6. **Finally**: Build roguelite wrapper

Remember: **Done is better than perfect**. Get a playable prototype first, then iterate!

## Step-by-Step Development Guide

### Phase 1: Foundation (Week 1-2)
**Goal**: Get basic physics and controls working

#### Step 1: Project Setup
- [ ] Create new Godot project
- [ ] Set up folder structure (scenes/, scripts/, assets/)
- [ ] Configure project settings (2D, pixel snap, window size)
- [ ] Create basic test scene with ground

**Resources:**
- [Godot: Your First 2D Game - Project Setup](https://docs.godotengine.org/en/stable/getting_started/first_2d_game/01.project_setup.html)
- [HeartBeast: Godot 4 Beginner Tutorial](https://www.youtube.com/watch?v=LOhfqjmasi0)
- Video: "Godot 4 Project Settings for 2D Games" by DevWorm (does this even exist??? the yt channel exists but didn't find that video yet)

#### Step 2: Basic Projectile
- [ ] Create projectile scene with RigidBody2D
- [ ] Add simple sprite (even just a circle)
- [ ] Script basic launch function
- [ ] Test with hardcoded values

**Resources:**
- [Godot Docs: RigidBody2D](https://docs.godotengine.org/en/stable/classes/class_rigidbody2d.html)
- Video: "Godot Projectile Tutorial" by KidsCanCode
- [Code example from this guide](#1-physics-system) (scroll up)
- Tutorial: "Making a Bullet in Godot" by GDQuest

#### Step 3: Aiming System
- [ ] Create aiming UI (power bar, angle indicator)
- [ ] Mouse control for angle
- [ ] Click-drag for power
- [ ] Visual trajectory preview (optional but recommended)

**Resources:**
- Video: "Angry Birds Style Aiming in Godot" by Game Development Center
- [Godot Recipe: Aiming with Mouse](https://kidscancode.org/godot_recipes/2d/8_direction_movement/)
- Tutorial: "Drawing Trajectory Lines in Godot 4" by Godotneers
- Code snippet: "Mouse Aim and Power" from Godot Forums

#### Step 4: Basic Terrain
- [ ] Create static terrain using StaticBody2D
- [ ] Add collision shapes
- [ ] Test projectile collision
- [ ] Add simple camera follow

**Resources:**
- [Godot Docs: StaticBody2D](https://docs.godotengine.org/en/stable/classes/class_staticbody2d.html)
- Video: "Creating Terrain in Godot" by Brackeys
- Tutorial: "Camera Follow in Godot 4" by DevWorm
- [Godot Recipe: Smooth Camera](https://kidscancode.org/godot_recipes/2d/smooth_camera/)

### Phase 2: Core Combat (Week 3-4)
**Goal**: Make it feel like a game

#### Step 5: Tank/Unit Creation
- [ ] Create unit scene (CharacterBody2D or Area2D)
- [ ] Add movement system (grid or free movement)
- [ ] Basic health system
- [ ] Connect shooting to unit

**Resources:**
- [Godot Docs: CharacterBody2D](https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html)
- Video: "Grid-Based Movement in Godot" by Game Endeavor
- Tutorial: "Health System in Godot 4" by Heartbeast
- [Unit system code example](#6-unitvehicle-system-if-squad-based) (from this guide)

#### Step 6: Turn System
- [ ] Implement state machine for turns
- [ ] Player turn -> Enemy turn -> Player turn
- [ ] Prevent actions during wrong turn
- [ ] Add turn indicator UI

**Resources:**
- Video: "Turn-Based Combat in Godot" by Game Development Center
- [GDQuest: Finite State Machine](https://www.gdquest.com/tutorial/godot/design-patterns/finite-state-machine/)
- [Turn management code example](#3-turn-management-state-machine) (from this guide)
- Tutorial: "State Machines in Godot 4" by Firebelley Games

#### Step 7: Basic AI
- [ ] Simple enemy that aims at player
- [ ] Random power within reasonable range
- [ ] Basic obstacle detection
- [ ] Make AI take turns

**Resources:**
- Video: "Simple Enemy AI in Godot" by KidsCanCode
- Tutorial: "Line of Sight in Godot" by GDQuest
- Article: "Basic Artillery AI" on Gamedeveloper.com
- Code: "AI Aiming Algorithm" from r/godot

#### Step 8: Destructible Terrain
- [ ] Research terrain destruction method
- [ ] Implement basic explosion holes
- [ ] Update collision after destruction
- [ ] Add visual effects

**Resources:**
- Video: "Worms-Style Destructible Terrain in Godot" by Rungeon
- Tutorial: "Destructible Terrain with Godot" by Godotneers
- [Terrain destruction code example](#2-destructible-terrain-system) (from this guide)
- GitHub: "GodotDestructibleTerrain" example project

### Phase 3: Game Feel (Week 5-6)
**Goal**: Make it fun and juicy

#### Step 9: Weapons
- [ ] Create weapon system architecture
- [ ] Implement 3-5 basic weapons
- [ ] Different projectile behaviors
- [ ] Weapon switching UI

**Resources:**
- Video: "Weapon System in Godot" by Heartbeast
- Tutorial: "Scriptable Weapons in Godot 4" by DevWorm
- [Weapon variety ideas](#weapon-variety) (from GDD)
- Code: "Modular Weapon System" by GDQuest

#### Step 10: Visual Polish
- [ ] Explosion particles
- [ ] Screen shake on impact
- [ ] Damage numbers
- [ ] Better sprites/animations

**Resources:**
- Video: "Juice it or Lose it" - GDC Talk (must watch!)
- Tutorial: "Screen Shake in Godot" by KidsCanCode
- Video: "Particle Effects in Godot 4" by GDQuest
- Asset: Kenney's Particle Pack (free)

#### Step 11: Audio
- [ ] Shooting sounds
- [ ] Explosion sounds
- [ ] UI feedback sounds
- [ ] Basic background music

**Resources:**
- [Freesound.org](https://freesound.org) - Search "explosion", "cannon"
- [SFXR](https://sfxr.me/) - Generate retro sounds
- Video: "Audio in Godot 4" by Brackeys
- Tutorial: "Dynamic Audio in Godot" by GDQuest

#### Step 12: Win/Lose
- [ ] Battle end conditions
- [ ] Victory/defeat screens
- [ ] Return to menu/continue

**Resources:**
- Tutorial: "Game Over Screen in Godot" by HeartBeast
- Video: "Scene Transitions in Godot 4" by DevWorm
- Code: "Victory Conditions" from Godot Forums
- UI Asset: Kenney's UI Pack

### Phase 4: Roguelite Structure (Week 7-8)
**Goal**: Add progression and replayability

#### Step 13: Campaign Structure
- [ ] Main menu with "New Run" option
- [ ] Basic progression between battles
- [ ] Currency/reward system
- [ ] Run statistics tracking

**Resources:**
- Video: "Roguelike Save System" by Game Endeavor
- Tutorial: "Scene Management in Godot" by GDQuest
- [Campaign structure code](#4-roguelite-map-system) (from this guide)
- Example: "Simple Roguelike Loop" on GitHub

#### Step 14: Upgrade System
- [ ] Create upgrade UI
- [ ] Implement 5-10 basic upgrades
- [ ] Save upgrades between battles
- [ ] Apply upgrade effects in combat

**Resources:**
- Video: "Upgrade System like Vampire Survivors" by DevWorm
- Tutorial: "Persistent Upgrades in Godot" by Firebelley
- [Upgrade system code](#5-upgrade-system) (from this guide)
- UI Tutorial: "Shop System in Godot" by HeartBeast

#### Step 15: Meta Progression
- [ ] Unlock system for new weapons/units
- [ ] Persistent save file
- [ ] Achievement/milestone tracking
- [ ] "New unlock" notifications

**Resources:**
- Video: "Save Game System in Godot 4" by GDQuest
- Tutorial: "Unlockables and Achievements" by Game Endeavor
- Code: "Godot Save Game Template" on GitHub
- Article: "Designing Meta-Progression" on Gamasutra

#### Step 16: Content & Balance
- [ ] Create 10+ battle scenarios
- [ ] Different terrain layouts
- [ ] Enemy variety
- [ ] Difficulty progression

**Resources:**
- Video: "Procedural Level Generation" by GDQuest
- Article: "Balancing Roguelikes" by Josh Ge (Cogmind dev)
- Tool: GodotPlot (for tracking balance)
- Tutorial: "Enemy Variety in Roguelikes" by Game Maker's Toolkit

### Build Order Rationale

**Why This Order?**
1. **Physics First**: Core gameplay must feel good
2. **Combat Before Meta**: Fun moment-to-moment gameplay is priority
3. **Polish Early**: Easier to stay motivated with good game feel
4. **Roguelite Last**: Can always release as regular artillery game if needed

**Critical Path Items:**
- Projectile physics (everything depends on this)
- Turn system (defines game flow)
- Destructible terrain (key differentiator)
- Basic roguelite loop (minimum for genre)

**Can Be Added Later:**
- Multiple units/squad system
- Advanced AI behaviors
- Complex progression systems
- Multiplayer (if desired)

# Salt & Cinder - Godot Game Project

## Project Overview
Salt & Cinder is a 2D cartoon puzzle-adventure game where players control Embe, a volcanic island spirit that absorbs environmental materials to change form and solve traversal puzzles.

## Key Systems & Architecture

### Autoloaded Singletons (Defined in project.godot)
- **GameState** (`res://scripts/core/game_state.gd`): Global state tracking dialogue flags, collected lore, and chapter progress
- **RoomManager** (`res://scripts/core/room_manager.gd`): Manages room transitions and world navigation
- **MusicDirector** (`res://scripts/core/music_director.gd`): Handles music playback and audio cues
- **DebugSequenceTracker** (`res://scripts/core/debug_sequence_tracker.gd`): Tracks debug sequences for testing

### Core Systems
1. **State Management**: GameState uses Dictionary for flags and Array for collected lore
2. **Room System**: Room-based navigation with door triggers for scene transitions
3. **Absorption Mechanic**: Objects can be absorbed by Embe to change form/material properties
4. **Dialogue System**: DialogueRunner processes dialogue lines with choices that affect GameState flags
5. **Lore System**: Collectible lore entries tracked in GameState

## GDScript Conventions

### File Organization
- `scripts/core/` - Core game systems and singletons
- `scripts/components/` - Reusable gameplay components (triggers, absorption, UI elements)
- `scripts/entities/` - Player and NPC controller scripts
- `scripts/ui/` - UI-specific components
- `scripts/world/` - World-level systems
- `scenes/` - Organized by chapter (chapter_01) and entity types (entities/embe, entities/npcs, scenes/ui, scenes/world)
- `assets/` - Game assets organized by type (audio, fonts, sprites, tilesets)
- `resources/` - Data resources (dialogue, lore, materials)

### Coding Patterns Observed
1. **Documentation**: Every script includes header comments explaining purpose
2. **Type Safety**: Explicit variable typing (var flags: Dictionary = {})
3. **Naming**: snake_case for variables and functions, PascalCase for class names
4. **Signals**: Used for communication between nodes (observed in door triggers)
5. **Encapsulation**: Components expose clear APIs (set_flag, collect_lore, etc.)

### Common Patterns
- **Singletons**: Autoloaded nodes accessed via `get_node("/root/GameState")` or direct reference
- **Component-Based**: Reusable components like AbsorbableObject, DialogueChoice, DoorTrigger
- **Scene Instancing**: Scenes instantiated via `ext_resource` and `instance=` in .tscn files
- **Resource System**: Custom .tres files for data (materials, dialogue entries)

## Scene Structure Conventions

### Typical Scene (.tscn) Structure
1. **Root Node**: Node2D or Area2D for gameplay elements
2. **Child Nodes**: 
   - Visual elements (Sprite2D, TileMapLayer)
   - Collision (Area2D, CollisionShape2D)
   - Scripts attached to nodes
   - Instanced scenes (player, NPCs)
3. **Resources**: External resources referenced via `ext_resource`
4. **SubResources**: Inline resources like TileSet, Shapes

### TileMap Usage
- Terrain and decoration use TileMapLayer with TileSet resources
- Physics layers defined per tile source for collision filtering
- Z-index used for rendering order (decoration typically z_index = 1)

## Development Guidelines

### Adding New Features
1. **Systems**: Add to `scripts/core/` as autoloaded singletons if globally needed
2. **Gameplay Objects**: Create components in `scripts/components/` for reuse
3. **Entities**: Create controller scripts in `scripts/entities/` or `scripts/world/`
4. **UI**: Add to `scripts/ui/` following existing UI component patterns
5. **Scenes**: Organize under appropriate `scenes/` subdirectory
6. **Resources**: Create .tres files in `resources/` for data-driven content

### Making Changes
1. Follow existing GDScript conventions (typing, naming, documentation)
2. Maintain separation of concerns - systems vs components vs entities
3. Use signals for loose coupling between nodes
4. Keep scenes organized and reusable where possible
5. Document any new systems or significant changes

### Testing & Debugging
- Use DebugSequenceTracker for testing specific sequences
- GameState flags can be manipulated for testing different states
- RoomManager can be used to navigate directly to test areas

## Project-Specific Notes

### Input System
- Defined in project.godot under [input] section
- Actions: move_left, move_right, jump, interact, absorb_release
- Uses both keyboard (WASD, E, Q) and gamepad inputs

### Physics Layers
- layer_1 = terrain
- layer_2 = entities  
- layer_3 = triggers
- layer_4 = interactables
- Used for collision filtering between different object types

### Art Style
- 2D cartoon aesthetic
- Emphasis on clear visual feedback for absorption/interactions
- Consistent tile-based terrain with decorative overlays

## Getting Started
1. Open project in Godot 4.6+
2. Main scene is `res://scenes/world/chapter_01/room_arrival.tscn`
3. Press F5 to run the game
4. Use WASD/Arrow keys to move, E to interact, Q to absorb/release

---
*This document captures the current project structure and conventions. Update as the project evolves.*
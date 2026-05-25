# Scenes Directory - Salt & Cinder

## Overview
The `scenes/` directory contains all .tscn scene files for the game, organized by functionality and chapter.

## Subdirectory Structure

### world/
Main game world scenes, organized by chapter:
- **chapter_01/**: First chapter (Stoneback Shelf)
  - **room_arrival.tscn**: Starting room where player first appears
  - Other rooms in Chapter 1 (following naming convention: room_[purpose].tscn)
- **shared/**: Reusable scenes used across chapters
  - Common objects, effects, or UI elements

### entities/
Character and NPC scenes:
- **embe/**: Player character scenes
  - **embe.tscn**: Main player character with AbsorptionComponent, etc.
- **npcs/**: Non-player character scenes
  - Individual NPC scenes following naming convention: [npc_name].tscn

### ui/
User interface scenes:
- **dialogue_box.tscn**: Displays dialogue text and choices
- **form_indicator.tscn**: Shows interaction prompts
- **lore_notification.tscn**: Displays lore collection feedback
- *Pattern*: UI scenes are typically instanced as needed

### components/
Reusable scene components:
- **door_trigger.tscn**: Area2D for scene transitions
- **absorbable_object.tscn**: Objects that can be absorbed by Embe
- *Pattern*: Component scenes designed for instancing in other scenes

## Scene Organization Conventions

### Naming
- Use descriptive names: `room_arrival.tscn`, `dialogue_box.tscn`
- For similar objects: `[descriptor]_[purpose].tscn` (e.g., `door_to_forest.tscn`)
- Chapter organization: `scenes/world/chapter_[number]/`
- Reusable assets: `scenes/[category]/[specific_name].tscn`

### Structure
Typical scene (.tscn) structure follows these patterns:

1. **Root Node Type** based on purpose:
   - `Node2D`: For containers, managers, or logic-only scenes
   - `Area2D`: For trigger zones, interactable objects
   - `CharacterBody2D`: For player/NPC controllers
   - `TileMapLayer`: For tile-based terrain/decoration
   - `CanvasLayer`: For UI elements that should stay fixed on screen

2. **Essential Child Nodes** (when applicable):
   - **Visual**: Sprite2D, AnimatedSprite2D, TileMapLayer
   - **Collision**: CollisionShape2D, CollisionPolygon2D (as children of Area2D/CharacterBody2D)
   - **Script**: Attached GDScript defining behavior
   - **Instanced Scenes**: Other scenes instanced via the editor
   - **UI Elements**: Label, TextureRect, etc. for information display
   - **Markers**: Position2D or Node for spawn points, attachment points

3. **Resource References**:
   - External resources: `.tres` files (MaterialProfile, DialogueLine) via `ext_resource`
   - Internal resources: Shapes, TileSets via `sub_resource`
   - Textures: Usually imported automatically, referenced via `ext_resource`

4. **Groups** (for categorization):
   - `"embe"`: Player character node
   - `"interactable"`: Objects that can be interacted with
   - `"dialogue"`: Dialogue-related nodes
   - Custom groups as needed for specific systems

## Scene-Specific Patterns

### Room Scenes (chapter_01/)
- **Root**: Usually Node2D as container
- **Layers**:
  - Background (ParallaxBackground for depth)
  - Terrain (TileMapLayer with terrain tileset)
  - Decoration (TileMapLayer with decoration tileset, z_index = 1)
  - Entities (Node2D container with y_sort_enabled = true for proper draw order)
  - UI/Markers (CanvasLayer for fixed UI, Position2D for spawn points)
- **Scripts**: Door triggers on Area2D nodes, room-specific logic on root or manager nodes
- **Groups**: Often use `"room"` group for room management systems

### Character Scenes (entities/embe/embe.tscn)
- **Root**: CharacterBody2D for physics-based movement
- **Children**:
  - Sprite2D or AnimatedSprite2D for visuals
  - CollisionShape2D for hitbox
  - RayCast2D for ground detection (if custom movement)
  - Instanced components: AbsorptionComponent, etc.
  - UI: FormIndicator (instanced as needed)
- **Script**: EmbeController.gd handling input, movement, absorption
- **Groups**: `"embe"` for easy finding by other systems

### UI Scenes
- **Root**: Often CanvasLayer for fixed screen position, or Control for flexible layout
- **Children**: Label, TextureRect, NinePatchRect, etc. for visual elements
- **Script**: Handles visibility, text updates, animations
- **Instancing**: Typically created via code when needed, not placed directly in main scenes

### Component Scenes
Designed for instancing:
- **Minimal Setup**: Just enough to function when instanced
- **Export Variables**: `@export` for configuration from parent scene
- **Signals**: For communication back to parent (e.g., `absorbed`, `activated`)
- **Cleanup**: Properly free resources when removed

## Adding New Scenes

### Rooms
Place in `scenes/world/chapter_[number]/` if:
- Part of the main game world
- Represents a distinct area/location
- Contains terrain, decoration, entities specific to that area

### Entities
Place in `scenes/entities/` if:
- Represents a character (player or NPC)
- Has its own movement/behavior logic
- May appear in multiple rooms/chapters

### UI
Place in `scenes/ui/` if:
- Specific user interface element
- Typically instanced as needed via code
- Manages its own visibility and updates

### Components
Place in `scenes/components/` if:
- Reusable gameplay object
- Designed to be instanced in multiple places
- Has configurable properties via exports
- Communicates via signals

## Scene Instance Best Practices

1. **Keep Scenes Focused**: One clear purpose per scene
2. **Use Inheritance Wisely**: Create base scenes when appropriate (e.g., base door trigger)
3. **Export for Configuration**: Use `@export` variables instead of hardcoding values
4. **Signal Communication**: Prefer signals over direct parent access
5. **Resource Sharing**: Reuse textures, materials, and other resources when possible
6. **Naming Consistency**: Follow existing naming patterns in the directory
7. **Group Usage**: Add to appropriate groups for easy finding
8. **Documentation**: Add comments explaining the scene's purpose and usage

## Testing Scenes
- Test instancing: Can the scene be instanced multiple times without issues?
- Check dependencies: Does it fail if required exports aren't set?
- Verify signals: Are they emitted correctly and received by listeners?
- Visual inspection: Does it look correct in the editor and at runtime?
- Integration: Does it work correctly when placed in actual game scenes?

---
*This document supplements the root AGENTS.md with scenes-specific guidance.*
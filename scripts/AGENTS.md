# Scripts Directory - Salt & Cinder

## Overview
The `scripts/` directory contains all GDScript code for the game, organized by functionality.

## Subdirectory Structure

### core/
Autoloaded singleton systems that provide global functionality:
- **GameState.gd**: Tracks dialogue flags, collected lore, chapter progress
- **RoomManager.gd**: Manages room transitions and world navigation  
- **MusicDirector.gd**: Handles music playback and audio cues
- **DebugSequenceTracker.gd**: Tracks debug sequences for testing
- *Pattern*: All core systems are autoloaded in project.godot and accessed globally

### components/
Reusable gameplay components that can be attached to various nodes:
- **AbsorbableObject.gd**: Area2D component for objects Embe can absorb
- **AbsorptionComponent.gd**: Manages Embe's material form state
- **Dialogue*.gd**: Dialogue system components (lines, choices, runner)
- **DoorTrigger.gd**: Area2D for scene transitions between rooms
- **MaterialProfile.gd**: Resource defining material properties
- *Pattern*: Components expose clear APIs and use signals for communication

### entities/
Controller scripts for player characters and NPCs:
- **EmbeController.gd**: Player character controller with movement/absorption
- **VeldNPC.gd**: Non-player character with dialogue/interaction
- *Pattern*: Entity controllers handle input, movement, and core gameplay logic

### ui/
UI-specific components and interfaces:
- **DialogueBox.gd**: Displays dialogue text and choices
- **FormIndicator.gd**: Shows interaction prompts near objects
- **LoreNotification.gd**: Displays when lore is collected
- *Pattern*: UI components are typically instanced as needed and manage their own visibility

### world/
World-level systems and managers:
- *Pattern*: Systems that manage collections of objects or world-state

## GDScript Conventions in Scripts

### Documentation
- Every script file begins with header comments explaining purpose
- Public methods and properties are documented with comments
- Complex logic includes inline explanations

### Type Safety
- Explicit typing for variables: `var flags: Dictionary = {}`
- Typed function parameters and return types
- Use of `assert()` for critical preconditions

### Naming Conventions
- snake_case for variables and functions (`is_depleted`, `try_absorb`)
- PascalCase for class names (`AbsorbableObject`, `GameState`)
- Leading underscore (`_`) for private/internal variables (`_active_profile`, `_embe_in_range`)

### Signals
- Used for loose communication between nodes
- Declared at top of class: `signal absorbed_by(entity: Node)`
- Emitted with appropriate parameters when events occur
- Connected in `_ready()` or via editor

### Export Variables
- `@export` makes variables editable in the inspector
- Used for configuration: `@export var material_profile: MaterialProfile`
- Resources and nodes often exported for editor assignment

### Resource Usage
- Custom resources (.tres) for data: MaterialProfile, DialogueLine
- References via `@export var material_profile: MaterialProfile`
- Loading with `ResourceLoader.load()` when needed

## Adding New Scripts

### Core Systems
Place in `scripts/core/` if:
- Needs global access throughout game
- Should be autoloaded singleton
- Manages fundamental game state/systems

### Components
Place in `scripts/components/` if:
- Reusable gameplay functionality
- Can be attached to various node types
- Exposes clear API for interaction
- Uses signals for communication

### Entities
Place in `scripts/entities/` if:
- Controls player or NPC behavior
- Handles input and movement
- Manages entity-specific state

### UI
Place in `scripts/ui/` if:
- Specifically for user interface
- Manages visibility/display
- Interacts with input systems

### World Systems
Place in `scripts/world/` if:
- Manages collections of objects
- Handles world-state logic
- Not tied to specific entities

## Common Patterns to Follow

1. **Header Documentation**: Always include purpose explanation
2. **Type Safety**: Use explicit typing whenever possible
3. **Signal-Based Communication**: Prefer signals over direct node references
4. **Encapsulation**: Keep internal state private with `_` prefix
5. **Resource Export**: Export resources/nodes for editor assignment
6. **Null Checks**: Validate required exports in `_ready()`
7. **Group Usage**: Use groups for categorizing nodes (e.g., "embe")
8. **Method Organization**: Public methods first, then private/_methods

## Testing Approach
- Test components in isolation when possible
- Use autoloaded singletons for global state testing
- Verify signal emissions and connections
- Check edge cases (null inputs, boundary conditions)

---
*This document supplements the root AGENTS.md with scripts-specific guidance.*
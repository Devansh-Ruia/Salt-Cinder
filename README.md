# Salt & Cinder

A Godot 4.6 game project featuring procedural generation narrative-driven gameplay and atmospheric exploration.

## Project Structure

```
new-game-project/
├── .godot/                 # Godot editor configuration and cache
├── assets/                 # Game assets (audio fonts sprites tilesets)
├── resources/              # Game resources (dialogue lore materials)
├── scenes/                 # Game scenes organized by category
│   ├── components/         # Reusable scene components
│   ├── entities/           # Player NPC and interactive entities
│   ├── ui/                 # User interface scenes
│   └── world/              # World and level scenes
├── scripts/                # Game logic organized by system
│   ├── components/         # Component-based scripts
│   ├── core/               # Core game systems
│   ├── entities/           # Entity behavior scripts
│   ├── ui/                 # UI logic scripts
│   └── world/              # World generation and management
├── tests/                  # Test scenes and scripts
├── AGENTS.md               # AI agent guidelines for this project
├── .gitattributes          # Git attributes configuration
├── .gitignore              # Git ignore rules
├── icon.svg                # Game icon
├── project.godot           # Godot project configuration
└── README.md               # This file
```

## Key Systems

- GameState: Global state management for persistent game data
- RoomManager: Handles navigation between different game areas
- MusicDirector: Manages audio playback and music transitions
- DebugSequenceTracker: Tracks and validates debug sequences for testing
- AbsorbableObject/AbsorptionComponent: Core gameplay mechanic for object interaction
- DoorTrigger: Manages scene transitions and level loading

## Development Guidelines

### Documentation
- All GDScript files should include documentation headers describing purpose and usage
- Use clear descriptive comments for complex logic
- Maintain updated documentation when modifying systems

### Coding Conventions
- Use snake_case for variables functions and signals
- Implement type safety where possible
- Follow signal-based communication patterns between nodes
- Encapsulate functionality within appropriate classes and components
- Utilize Godot's resource system for reusable data assets

### Security Considerations
- No external API keys or secrets stored in repository
- All game data is self-contained within the project
- Input validation implemented for all user-interactive systems
- Resource loading uses relative paths to prevent directory traversal
- No network communication implemented in current version

## Getting Started

1. Install Godot 4.6 or later from https://godotengine.org/download
2. Clone this repository
3. Open the project in Godot Editor
4. Select the main scene (typically found in scenes/world/chapter_01/)
5. Press F5 to run the game

## Contributing

Please read AGENTS.md for detailed contribution guidelines before making changes to the project.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
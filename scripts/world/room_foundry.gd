# room_foundry.gd
# Primary light source: PointLight2D at x=1200, y=300 (foundry vent glow)
# Light direction: left-to-right, warm amber (#FFB347)
# Puzzle solution order: basalt → driftwood → coral → sea_glass → talk to Veld
extends Node2D

## Debug-only: spawn a test player if this room is run directly (F5). On the
## normal bootstrap path a persistent Embe already exists, so it is a no-op.
## Toggle off in-editor to inspect the room without a player.
@export var debug_spawn: bool = true

## DoorTrigger door_id the debug player spawns at (the room's entry from Approach).
@export var debug_spawn_door: String = "from_approach"


func _ready() -> void:
	# Add LightSource to group so LightReflector can find it
	var light_source := $PuzzleElements/LightSource
	if light_source:
		light_source.add_to_group("light_source")

	# Deferred: the tree is locked during _ready; the fallback reparents/spawns.
	if debug_spawn:
		RoomManager.spawn_debug_player_if_absent.call_deferred(self, debug_spawn_door)


## Called by the FoundryGate when activated by the ReflectorTarget.
func _on_gate_activated() -> void:
	var gate := $PuzzleElements/FoundryGate as Node2D
	if gate:
		gate.visible = false
		# Disable gate collision
		var gate_body := gate.get_node_or_null("StaticBody2D") as StaticBody2D
		if gate_body:
			gate_body.process_mode = Node.PROCESS_MODE_DISABLED
		print("[RoomFoundry] Gate unlocked!")

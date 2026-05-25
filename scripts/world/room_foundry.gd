# room_foundry.gd
# Primary light source: PointLight2D at x=1200, y=300 (foundry vent glow)
# Light direction: left-to-right, warm amber (#FFB347)
# Puzzle solution order: basalt → driftwood → coral → sea_glass → talk to Veld
extends Node2D


func _ready() -> void:
	# Add LightSource to group so LightReflector can find it
	var light_source := $PuzzleElements/LightSource
	if light_source:
		light_source.add_to_group("light_source")


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

## RoomManager — Autoload that handles scene transitions between rooms.
## Preserves Embe's MaterialProfile across transitions.
## Uses a fade-to-black transition (0.3s in/out).
extends Node

## Emitted after a room transition completes and the new room is ready.
signal room_loaded(room_name: String)

## Registry of room names → scene file paths.
## Rooms register themselves here; scripts should never use hardcoded paths.
var _room_registry: Dictionary = {}

## Reference to the currently loaded room scene instance.
var _current_room: Node = null

## The ColorRect used for fade transitions. Created at runtime.
var _fade_overlay: ColorRect = null

## Duration of each fade direction (in, out) in seconds.
const FADE_DURATION: float = 0.3


func _ready() -> void:
	_setup_fade_overlay()
	_register_chapter_01_rooms()


## Build the fullscreen fade overlay used for transitions.
func _setup_fade_overlay() -> void:
	var canvas_layer := CanvasLayer.new()
	canvas_layer.layer = 100  # Above everything
	add_child(canvas_layer)

	_fade_overlay = ColorRect.new()
	_fade_overlay.color = Color.BLACK
	_fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_overlay.modulate.a = 0.0
	canvas_layer.add_child(_fade_overlay)


## Register all Chapter 1 rooms. Called once on startup.
func _register_chapter_01_rooms() -> void:
	register_room("arrival", "res://scenes/world/chapter_01/room_arrival.tscn")
	register_room("foundry", "res://scenes/world/chapter_01/room_foundry.tscn")
	register_room("approach", "res://scenes/world/chapter_01/room_approach.tscn")


## Register a room by name so it can be loaded by change_room().
func register_room(room_name: String, scene_path: String) -> void:
	_room_registry[room_name] = scene_path


## Transition to a new room. entry_door_id identifies which DoorTrigger
## to spawn Embe at in the target room.
func change_room(room_name: String, entry_door_id: String) -> void:
	print("[RoomManager] Changing room → ", room_name, " | Entry door: ", entry_door_id)
	if not _room_registry.has(room_name):
		push_error("RoomManager: room '%s' not found in registry." % room_name)
		return

	var scene_path: String = _room_registry[room_name]

	# Fade to black
	var tween := create_tween()
	tween.tween_property(_fade_overlay, "modulate:a", 1.0, FADE_DURATION)
	await tween.finished

	# Unload current room
	if _current_room != null:
		_current_room.queue_free()
		_current_room = null

	# Load and instance the new room
	var packed_scene: PackedScene = load(scene_path)
	if packed_scene == null:
		push_error("RoomManager: failed to load scene at '%s'." % scene_path)
		return

	_current_room = packed_scene.instantiate()
	get_tree().root.add_child(_current_room)

	# Position Embe at the target door
	_place_embe_at_door(_current_room, entry_door_id)

	# Fade from black
	var tween_out := create_tween()
	tween_out.tween_property(_fade_overlay, "modulate:a", 0.0, FADE_DURATION)
	await tween_out.finished

	room_loaded.emit(room_name)
	print("[RoomManager] Room loaded: ", room_name)


## Find the DoorTrigger with matching door_id in the room and place Embe there.
func _place_embe_at_door(room: Node, door_id: String) -> void:
	# Search for DoorTrigger nodes with a matching door_id export
	for child in room.get_children():
		if child.has_method("get_door_id"):
			if child.get_door_id() == door_id:
				# Find Embe in the scene tree
				var embe := get_tree().get_first_node_in_group("embe")
				if embe:
					embe.global_position = child.global_position
				return

	push_warning("RoomManager: door_id '%s' not found in room." % door_id)

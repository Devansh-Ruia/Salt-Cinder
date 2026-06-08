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

## The single persistent Embe. Embe is embedded in the start room's scene; on
## the first transition it is reparented to the scene root so freeing a room
## never frees Embe. Re-instanced rooms that embed their own Embe have that
## duplicate stripped (see _consolidate_embe). Guarantees exactly one node in
## the "embe" group across all transitions.
var _embe: Node = null

## Guards change_room against re-entry. The fade uses await (~0.3s each way);
## without this guard a transition triggered mid-fade (e.g. a spawn overlap)
## would overlap the first — the old room would not be freed before the next is
## instanced, so doors/zones/signals accumulate and detections double each cycle.
var _is_transitioning: bool = false

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
	# Re-entrancy guard: ignore any call that arrives while a transition is
	# still awaiting its fades. This is what stops the loop from escalating.
	if _is_transitioning:
		print("[RoomManager] Transition already in progress, ignoring → ", room_name)
		return

	print("[RoomManager] Changing room → ", room_name, " | Entry door: ", entry_door_id)
	if not _room_registry.has(room_name):
		push_error("RoomManager: room '%s' not found in registry." % room_name)
		return

	_is_transitioning = true

	# The start room is loaded by Godot as the main scene, not via change_room,
	# so it is never registered as _current_room. Capture it now so it (and the
	# Embe embedded in it) is handled like any other room from here on.
	if _current_room == null:
		_current_room = get_tree().current_scene

	var scene_path: String = _room_registry[room_name]

	# Move Embe out of the room being unloaded so the queue_free below cannot
	# free it. After this, exactly one Embe exists, parented to the scene root.
	_consolidate_embe()

	# Fade to black
	var tween := create_tween()
	tween.tween_property(_fade_overlay, "modulate:a", 1.0, FADE_DURATION)
	await tween.finished

	# Unload current room
	if _current_room != null and is_instance_valid(_current_room):
		_current_room.queue_free()
		_current_room = null

	# Load and instance the new room
	var packed_scene: PackedScene = load(scene_path)
	if packed_scene == null:
		push_error("RoomManager: failed to load scene at '%s'." % scene_path)
		_is_transitioning = false
		return

	_current_room = packed_scene.instantiate()
	get_tree().root.add_child(_current_room)

	# A re-instanced room may embed its own Embe (the start room does). Strip any
	# such duplicate so only the persistent Embe remains in the "embe" group.
	_consolidate_embe()

	# Position Embe at the target door (and disarm that door against the spawn
	# overlap so it does not immediately transition back).
	_place_embe_at_door(_current_room, entry_door_id)

	# Fade from black
	var tween_out := create_tween()
	tween_out.tween_property(_fade_overlay, "modulate:a", 0.0, FADE_DURATION)
	await tween_out.finished

	# Only clear the guard once the transition has fully completed: old room
	# freed, new room ready, fades done. A door cannot fire mid-transition.
	_is_transitioning = false

	room_loaded.emit(room_name)
	print("[RoomManager] Room loaded: ", room_name)


## Ensure exactly one Embe exists and that it lives at the scene root (not inside
## a room), so room frees never free it and re-instanced rooms cannot duplicate
## it. Keeps the already-tracked persistent Embe if valid, else adopts the first
## one found; frees any others.
func _consolidate_embe() -> void:
	var embes := get_tree().get_nodes_in_group("embe")
	if embes.is_empty():
		return

	var keep: Node = _embe if (_embe != null and is_instance_valid(_embe)) else embes[0]

	for e in embes:
		if e != keep:
			print("[RoomManager] Stripping duplicate Embe instanced by room.")
			e.queue_free()

	_embe = keep

	# Reparent to the scene root so unloading a room cannot take Embe with it.
	var root := get_tree().root
	if keep.get_parent() != root:
		keep.reparent(root)


## Find the DoorTrigger with matching door_id in the room, place Embe there, and
## disarm that door so the spawn overlap does not bounce Embe straight back.
func _place_embe_at_door(room: Node, door_id: String) -> void:
	# Search for DoorTrigger nodes with a matching door_id export
	for child in room.get_children():
		if child.has_method("get_door_id"):
			if child.get_door_id() == door_id:
				if _embe != null and is_instance_valid(_embe):
					_embe.global_position = child.global_position
				# Arm-on-exit: this door is the entry door, so Embe spawns
				# overlapping it. Disarm it until Embe walks out.
				if child.has_method("disarm_for_spawn"):
					child.disarm_for_spawn()
				return

	push_warning("RoomManager: door_id '%s' not found in room." % door_id)

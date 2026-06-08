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

## The single persistent Embe. Embe is owned by the bootstrap (Main) scene, not
## by any room. On the first transition RoomManager adopts it and reparents it to
## the scene root, so freeing/re-instancing a room never frees or duplicates it.
## Rooms contain no Embe of their own, so there is nothing to strip.
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

	# Validate the target before doing anything. An empty or unregistered name
	# means a misconfigured door (unset target_room) or a typo — fail loud and
	# return rather than silently no-op (a silent no-op hid exactly this bug).
	if room_name.is_empty() or not _room_registry.has(room_name):
		push_error("[RoomManager] ERROR: unknown/empty room name '%s' — ignoring" % room_name)
		return

	print("[RoomManager] Changing room → ", room_name, " | Entry door: ", entry_door_id)

	_is_transitioning = true

	# The bootstrap (Main) scene is loaded by Godot as the main scene, not via
	# change_room, so it is never registered as _current_room. Capture it now so
	# it (and the Embe it owns) is freed/handled like any other scene from here on.
	if _current_room == null:
		_current_room = get_tree().current_scene

	var scene_path: String = _room_registry[room_name]

	# Adopt Embe (from the bootstrap scene on first call) and reparent it to the
	# scene root so the queue_free below cannot take it with the old room/scene.
	_adopt_embe()

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

	# Safety: keep the persistent Embe parented to the root. Rooms no longer embed
	# an Embe, so this never finds a duplicate — it only re-asserts ownership.
	_adopt_embe()

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


## Adopt the persistent Embe and keep it parented to the scene root (not inside a
## room or the bootstrap scene), so freeing a room never frees Embe. On the first
## call it adopts the Embe owned by the bootstrap (Main) scene; thereafter it just
## re-asserts that the tracked instance lives at the root. Rooms embed no Embe of
## their own, so there is never a duplicate to remove.
func _adopt_embe() -> void:
	if _embe == null or not is_instance_valid(_embe):
		var embes := get_tree().get_nodes_in_group("embe")
		if embes.is_empty():
			return
		_embe = embes[0]

	# Reparent to the scene root so unloading a room/scene cannot take Embe with it.
	var root := get_tree().root
	if _embe.get_parent() != root:
		_embe.reparent(root)


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

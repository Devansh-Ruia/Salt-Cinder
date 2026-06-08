## DoorTrigger — Area2D placed at room exits. When Embe enters, triggers RoomManager transition.
##
## Arm-on-exit: a door must NOT fire a transition for a body that was already
## overlapping it at spawn. When RoomManager places Embe on this door (it is the
## target room's entry door) it calls disarm_for_spawn(); the door then ignores
## body_entered until Embe leaves its area (body_exited re-arms it). Doors Embe
## did not spawn on stay armed and fire normally. This prevents the entry door —
## which doubles as the return door — from bouncing Embe straight back.
class_name DoorTrigger
extends Area2D

## The room name (as registered in RoomManager) this door leads to.
@export var target_room: String

## The door_id in the target room where Embe should spawn.
@export var target_door_id: String

## This door's own ID, used by RoomManager to place Embe on arrival.
@export var door_id: String

## Whether this door will fire a transition on body_entered. Disarmed by
## RoomManager when Embe spawns overlapping this door; re-armed on body_exited.
var _armed: bool = true


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func get_door_id() -> String:
	return door_id


## Called by RoomManager on the entry door when it places Embe here, so the
## first body_entered (from the spawn overlap) does not bounce Embe back.
func disarm_for_spawn() -> void:
	_armed = false
	print("[DoorTrigger] '", door_id, "' disarmed for spawn (Embe placed here).")


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("embe"):
		return
	if not _armed:
		print("[DoorTrigger] '", door_id, "' entered while disarmed — ignoring (spawn overlap).")
		return
	RoomManager.change_room(target_room, target_door_id)


func _on_body_exited(body: Node) -> void:
	if not body.is_in_group("embe"):
		return
	if not _armed:
		_armed = true
		print("[DoorTrigger] '", door_id, "' re-armed (Embe left the door).")

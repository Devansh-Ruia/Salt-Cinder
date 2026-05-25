## DoorTrigger — Area2D placed at room exits. When Embe enters, triggers RoomManager transition.
class_name DoorTrigger
extends Area2D

## The room name (as registered in RoomManager) this door leads to.
@export var target_room: String

## The door_id in the target room where Embe should spawn.
@export var target_door_id: String

## This door's own ID, used by RoomManager to place Embe on arrival.
@export var door_id: String


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func get_door_id() -> String:
	return door_id


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("embe"):
		RoomManager.change_room(target_room, target_door_id)

## Bootstrap — the game's entry scene (project.godot run/main_scene). Owns the
## single persistent Embe and hands control to RoomManager, which adopts Embe
## (reparents it to the scene root) and loads the first room. Rooms themselves
## never embed an Embe; this scene is the sole owner. This is what lets rooms be
## freed/re-instanced on every transition without ever duplicating the player.
extends Node

## First room to load on startup. Must be registered in RoomManager.
@export var first_room: String = "arrival"

## The door_id in the first room where Embe should spawn.
@export var first_entry_door: String = "from_approach"


func _ready() -> void:
	# Children run _ready before their parent, so the embedded Embe has already
	# added itself to the "embe" group by the time this runs. RoomManager then
	# adopts it during the transition.
	#
	# Defer the first transition: while _ready runs, this node is still inside its
	# setup window and Godot locks the tree (data.blocked > 0). _adopt_embe mutates
	# the tree (add_child/reparent of Embe), which fails on a locked tree. Running
	# change_room one idle frame later, after the lock clears, lets the adopt succeed.
	RoomManager.change_room.call_deferred(first_room, first_entry_door)

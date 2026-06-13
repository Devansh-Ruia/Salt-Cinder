## RoomApproach — Logic for the Approach corridor (Chapter 1, Stoneback Shelf).
##
## The Approach is the connecting haulway between Arrival (sea cove) and the
## Foundry. It is a low-stakes practice space: one AbsorbableObject of each of
## the four forms sits along the corridor so the player can rehearse absorbing
## and releasing before the Foundry puzzle proper.
##
## ─── Primary light source ──────────────────────────────────────────────
## Source : ambient daylight spilling in from the sea-facing opening on the
##          LEFT (the same cove mouth the player arrives through). No
##          artificial lights in this room.
## Direction: light travels left → right; shadows fall to the RIGHT.
## Tint    : CanvasModulate #C4A882 (warm overcast stone), matching Arrival
##          and Foundry so the chapter reads as one continuous shelf.
## ────────────────────────────────────────────────────────────────────────
extends Node2D


## Container holding the AbsorbableObjects. Reset on room entry so the
## corridor stays a replayable practice space.
@onready var _entities: Node2D = $Entities

## Debug-only: spawn a test player if this room is run directly (F5). On the
## normal bootstrap path a persistent Embe already exists, so it is a no-op.
## Toggle off in-editor to inspect the room without a player.
@export var debug_spawn: bool = true

## DoorTrigger door_id the debug player spawns at (the room's entry from Arrival).
@export var debug_spawn_door: String = "from_arrival"


func _ready() -> void:
	assert(_entities != null, "RoomApproach: 'Entities' container node is required.")
	_reset_absorbables()
	print("[RoomApproach] Ready. Corridor between Arrival and Foundry.")

	# Deferred: the tree is locked during _ready; the fallback reparents/spawns.
	if debug_spawn:
		RoomManager.spawn_debug_player_if_absent.call_deferred(self, debug_spawn_door)


## Re-arm every AbsorbableObject in the room so each form can be practised
## again on every visit. Absorbables expose reset(); respawn honours their
## own `respawns` flag.
func _reset_absorbables() -> void:
	var count: int = 0
	for node: Node in _entities.get_children():
		var absorbable := node.get_node_or_null("AbsorbableObject")
		if absorbable != null and absorbable.has_method("reset"):
			absorbable.reset()
			count += 1
	print("[RoomApproach] Re-armed ", count, " absorbable(s).")

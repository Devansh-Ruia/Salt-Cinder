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


func _ready() -> void:
	assert(_entities != null, "RoomApproach: 'Entities' container node is required.")
	_reset_absorbables()
	print("[RoomApproach] Ready. Corridor between Arrival and Foundry.")


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

## LorePickup — An Area2D that registers a LoreEntry in GameState when interacted with.
## Becomes visually inert after collection (no deletion — preserves world feel).
class_name LorePickup
extends Area2D

## Emitted when the player collects this lore entry. UI listens for notification.
signal lore_collected(entry: LoreEntry)

## The lore entry this pickup grants.
@export var lore_entry: LoreEntry

var _collected: bool = false
var _embe_in_range: bool = false


func _ready() -> void:
	assert(lore_entry != null, "LorePickup: lore_entry must be assigned.")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Check if already collected from a prior visit
	if GameState.has_lore(lore_entry.entry_id):
		_set_collected_visual()


func _input(event: InputEvent) -> void:
	if _collected or not _embe_in_range:
		return

	if event.is_action_pressed("interact"):
		_collect()


func _collect() -> void:
	var newly_added := GameState.collect_lore(lore_entry.entry_id)
	if newly_added:
		_collected = true
		_set_collected_visual()
		lore_collected.emit(lore_entry)


## Switch to an inert visual state — dimmed, no glow, no particle.
func _set_collected_visual() -> void:
	_collected = true
	# TODO: swap sprite to collected/inert variant, reduce modulate alpha
	modulate = Color(0.5, 0.5, 0.5, 0.6)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("embe"):
		_embe_in_range = true


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("embe"):
		_embe_in_range = false

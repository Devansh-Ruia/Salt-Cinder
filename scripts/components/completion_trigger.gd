## CompletionTrigger — Area2D component that sets a GameState flag when Embe enters.
## Used for greybox completion markers.
class_name CompletionTrigger
extends Area2D

## The GameState flag to set when triggered.
@export var flag_to_set: String = ""

## Whether this trigger has already been activated.
var _activated: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("embe"):
		return
	if _activated:
		return
	_activated = true
	var game_state = get_node("/root/GameState")
	if game_state and game_state.has_method("set_flag"):
		game_state.set_flag(flag_to_set)
		print("[CompletionTrigger] Flag set: ", flag_to_set)
	else:
		push_error("[CompletionTrigger] GameState not found or missing set_flag method.")
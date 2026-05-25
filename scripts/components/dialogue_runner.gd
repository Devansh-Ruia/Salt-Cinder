## DialogueRunner — Executes a DialogueResource line by line.
## Does NOT own UI — emits signals that a separate DialogueBox scene listens to.
## Freezes Embe input while dialogue is active.
class_name DialogueRunner
extends Node

signal dialogue_started()
signal line_displayed(line: DialogueLine)
signal choice_presented(choices: Array[DialogueChoice])
signal dialogue_ended()

## The dialogue resource to run. Assign in the editor or via code.
@export var dialogue: DialogueResource

var _current_index: int = 0
var _is_running: bool = false


## Start running the assigned dialogue from the beginning.
func start() -> void:
	if dialogue == null or dialogue.lines.is_empty():
		push_warning("DialogueRunner: no dialogue to run.")
		return

	_current_index = 0
	_is_running = true
	_freeze_embe(true)
	dialogue_started.emit()
	_display_current_line()


## Advance to the next line. Called by the UI when the player presses interact.
func advance() -> void:
	if not _is_running:
		return

	var current_line: DialogueLine = dialogue.lines[_current_index]

	# If the current line has choices, don't advance — wait for choice selection
	if not current_line.choices.is_empty():
		return

	_go_to_line(current_line.next_line_index)


## Select a dialogue choice by index within the current line's choices array.
func select_choice(choice_index: int) -> void:
	if not _is_running:
		return

	var current_line: DialogueLine = dialogue.lines[_current_index]
	if choice_index < 0 or choice_index >= current_line.choices.size():
		push_error("DialogueRunner: invalid choice index %d." % choice_index)
		return

	var choice: DialogueChoice = current_line.choices[choice_index]

	# Set GameState flag if specified
	if choice.sets_flag != "":
		GameState.set_flag(choice.sets_flag)

	_go_to_line(choice.next_line_index)


## Navigate to a specific line index, or end dialogue if index is -1.
func _go_to_line(index: int) -> void:
	if index < 0 or index >= dialogue.lines.size():
		_end_dialogue()
		return

	_current_index = index
	_display_current_line()


func _display_current_line() -> void:
	var line: DialogueLine = dialogue.lines[_current_index]
	line_displayed.emit(line)

	if not line.choices.is_empty():
		choice_presented.emit(line.choices)


func _end_dialogue() -> void:
	_is_running = false
	_freeze_embe(false)
	dialogue_ended.emit()


func _freeze_embe(frozen: bool) -> void:
	var embe := get_tree().get_first_node_in_group("embe")
	if embe and embe.has_method("set_input_frozen"):
		embe.set_input_frozen(frozen)


func is_running() -> bool:
	return _is_running

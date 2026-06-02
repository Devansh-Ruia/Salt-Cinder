## DialogueBox — UI panel that displays dialogue from a DialogueRunner.
## Styled like a tide-worn document: bone-white panel, ink-black text,
## no rounded corners, no drop shadow.
## Typewriter effect at 30 chars/sec. Skip on first interact press; advance on second.
class_name DialogueBox
extends PanelContainer

## Typewriter speed in characters per second.
const CHARS_PER_SECOND: float = 30.0

@onready var speaker_label: Label = $VBoxContainer/SpeakerLabel
@onready var text_label: RichTextLabel = $VBoxContainer/TextLabel
@onready var choice_container: VBoxContainer = $VBoxContainer/ChoiceContainer

var _dialogue_runner: DialogueRunner = null
var _full_text: String = ""
var _displayed_chars: int = 0
var _typewriter_active: bool = false
var _typewriter_timer: float = 0.0
var _waiting_for_advance: bool = false
var _current_choices: Array[DialogueChoice] = []


func _ready() -> void:
	visible = false
	choice_container.visible = false


## Connect this dialogue box to a DialogueRunner instance.
func bind_to_runner(runner: DialogueRunner) -> void:
	if _dialogue_runner:
		_unbind()

	_dialogue_runner = runner
	_dialogue_runner.dialogue_started.connect(_on_dialogue_started)
	_dialogue_runner.line_displayed.connect(_on_line_displayed)
	_dialogue_runner.choice_presented.connect(_on_choice_presented)
	_dialogue_runner.dialogue_ended.connect(_on_dialogue_ended)


func _unbind() -> void:
	if _dialogue_runner == null:
		return
	_dialogue_runner.dialogue_started.disconnect(_on_dialogue_started)
	_dialogue_runner.line_displayed.disconnect(_on_line_displayed)
	_dialogue_runner.choice_presented.disconnect(_on_choice_presented)
	_dialogue_runner.dialogue_ended.disconnect(_on_dialogue_ended)
	_dialogue_runner = null


func _process(delta: float) -> void:
	if _typewriter_active:
		_typewriter_timer += delta
		var target_chars := int(_typewriter_timer * CHARS_PER_SECOND)
		if target_chars > _displayed_chars:
			_displayed_chars = min(target_chars, _full_text.length())
			text_label.text = _full_text.substr(0, _displayed_chars)

			if _displayed_chars >= _full_text.length():
				_typewriter_active = false
				_waiting_for_advance = true
				_show_choices_if_any()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("interact"):
		if _typewriter_active:
			# First press: skip typewriter, show full text
			_typewriter_active = false
			_displayed_chars = _full_text.length()
			text_label.text = _full_text
			_waiting_for_advance = true
			_show_choices_if_any()
		elif _waiting_for_advance and _current_choices.is_empty():
			# Second press: advance to next line
			_waiting_for_advance = false
			if _dialogue_runner:
				_dialogue_runner.advance()


func _on_dialogue_started() -> void:
	visible = true
	if _dialogue_runner and _dialogue_runner.dialogue:
		speaker_label.text = _dialogue_runner.dialogue.speaker_name


func _on_line_displayed(line: DialogueLine) -> void:
	_full_text = line.text
	_displayed_chars = 0
	_typewriter_timer = 0.0
	_typewriter_active = true
	_waiting_for_advance = false
	_current_choices = []
	text_label.text = ""
	choice_container.visible = false

	# Clear old choice buttons
	for child in choice_container.get_children():
		child.queue_free()


func _on_choice_presented(choices: Array[DialogueChoice]) -> void:
	_current_choices = choices
	# Choices are shown only after typewriter finishes (handled in _show_choices_if_any)


func _show_choices_if_any() -> void:
	if _current_choices.is_empty():
		return

	choice_container.visible = true
	for i in _current_choices.size():
		var choice: DialogueChoice = _current_choices[i]
		var btn := Button.new()
		btn.text = choice.label
		# Style: flat, no rounded corners
		btn.flat = true
		var idx := i
		btn.pressed.connect(func(): _on_choice_selected(idx))
		choice_container.add_child(btn)


func _on_choice_selected(index: int) -> void:
	_waiting_for_advance = false
	_current_choices = []
	choice_container.visible = false
	if _dialogue_runner:
		_dialogue_runner.select_choice(index)


func _on_dialogue_ended() -> void:
	visible = false
	_typewriter_active = false
	_waiting_for_advance = false
	_current_choices = []

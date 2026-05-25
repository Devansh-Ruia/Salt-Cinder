## FormIndicator — Displays Embe's current material form in the bottom-left corner.
## Hidden when in default basalt form. Animates in/out on form change.
extends Control

@onready var icon: TextureRect = $HBoxContainer/Icon       # TODO: assign form icons
@onready var name_label: Label = $HBoxContainer/NameLabel

## Duration of the show/hide tween animation.
const TWEEN_DURATION: float = 0.2

var _visible_form: bool = false


func _ready() -> void:
	modulate.a = 0.0
	visible = false

	# Connect to Embe's AbsorptionComponent once the tree is ready
	_connect_to_embe.call_deferred()


func _connect_to_embe() -> void:
	var embe := get_tree().get_first_node_in_group("embe")
	if embe and embe.has_node("AbsorptionComponent"):
		var absorption: AbsorptionComponent = embe.get_node("AbsorptionComponent")
		absorption.form_changed.connect(_on_form_changed)


func _on_form_changed(profile: MaterialProfile) -> void:
	# Default form (basalt) = hide indicator
	var embe := get_tree().get_first_node_in_group("embe")
	if embe and embe.has_node("AbsorptionComponent"):
		var absorption: AbsorptionComponent = embe.get_node("AbsorptionComponent")
		if not absorption.is_transformed():
			_hide_indicator()
			return

	name_label.text = profile.material_name
	# TODO: set icon texture based on profile
	_show_indicator()


func _show_indicator() -> void:
	if _visible_form:
		return
	_visible_form = true
	visible = true
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, TWEEN_DURATION)


func _hide_indicator() -> void:
	if not _visible_form:
		return
	_visible_form = false
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, TWEEN_DURATION)
	await tween.finished
	visible = false

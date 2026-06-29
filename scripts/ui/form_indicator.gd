## FormIndicator — Persistent placeholder HUD readout of Embe's current form.
## Bottom-left corner. Shows a colour swatch plus a readable symbol/short label
## until final form icons exist. Updates on form_changed and stays visible at all
## times (including default basalt) so the player can always read the active form.
##
## ART GATE: assign per-form textures to `icon` later, then hide the text labels.
extends Control

@onready var icon: TextureRect = $Panel/HBox/Icon     # TODO: assign per-form form icons (art gate)
@onready var swatch: ColorRect = $Panel/HBox/Swatch
@onready var symbol_label: Label = $Panel/HBox/SymbolLabel
@onready var form_label: Label = $Panel/HBox/FormLabel

const FORM_READOUTS: Dictionary = {
	"basalt": {"symbol": "[]", "label": "BASALT"},
	"driftwood": {"symbol": "///", "label": "WOOD"},
	"coral": {"symbol": "Y", "label": "CORAL"},
	"seaglass": {"symbol": "<>", "label": "GLASS"},
	"sea_glass": {"symbol": "<>", "label": "GLASS"},
}


func _ready() -> void:
	# Embe is adopted into the tree after this autoload-built UI; attempt to bind
	# now and again on every room load until the AbsorptionComponent is reachable.
	_try_connect.call_deferred()
	if not RoomManager.room_loaded.is_connected(_on_room_loaded):
		RoomManager.room_loaded.connect(_on_room_loaded)


func _on_room_loaded(_room_name: String) -> void:
	_try_connect()


func _try_connect() -> void:
	var embe: Node = get_tree().get_first_node_in_group("embe")
	if embe == null or not embe.has_node("AbsorptionComponent"):
		return
	var absorption: AbsorptionComponent = embe.get_node("AbsorptionComponent")
	if not absorption.form_changed.is_connected(_on_form_changed):
		absorption.form_changed.connect(_on_form_changed)
	# Initialise to the current (default) form so the indicator is persistent.
	_apply_profile(absorption.get_active_profile())


func _on_form_changed(profile: MaterialProfile) -> void:
	_apply_profile(profile)


func _apply_profile(profile: MaterialProfile) -> void:
	if profile == null:
		return
	swatch.color = profile.ambient_color_modulate
	var key: String = _profile_key(profile)
	var readout: Dictionary = FORM_READOUTS[key] if FORM_READOUTS.has(key) else {"symbol": "?", "label": profile.material_name.to_upper()}
	symbol_label.text = readout.get("symbol", "?")
	form_label.text = readout.get("label", profile.material_name.to_upper())
	# TODO (art gate): when a per-form icon texture exists, assign it to `icon`
	# and hide symbol_label/form_label.
	visible = true


func _profile_key(profile: MaterialProfile) -> String:
	return profile.material_name.to_lower().replace(" ", "_")

## FormIndicator — Persistent, glyphs-only HUD readout of Embe's current form.
## Bottom-left corner. Shows a colour swatch (placeholder) + a swappable icon
## slot for the active MaterialProfile. NO TEXT — the swatch/icon is the whole
## language. Updates on form_changed / form_released; stays visible at all times
## (including default basalt) so the player can always read "what form am I".
##
## ART GATE: the colour swatch is a placeholder. Assign per-form textures to the
## `icon` slot to replace it. # TODO: art gate
extends Control

@onready var icon: TextureRect = $Panel/HBox/Icon     # TODO: assign per-form form icons (art gate)
@onready var swatch: ColorRect = $Panel/HBox/Swatch


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
	# TODO (art gate): when a per-form icon texture exists, assign it to `icon`
	# and hide the swatch — e.g. icon.texture = profile.form_icon; swatch.hide().
	visible = true

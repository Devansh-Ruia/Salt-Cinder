## AbsorbableObject — Area2D component for environmental objects that Embe can absorb.
## Place on any world object that grants a material form.
class_name AbsorbableObject
extends Area2D

## Emitted when this object is absorbed by an entity.
signal absorbed_by(entity: Node)

## The MaterialProfile this object grants when absorbed.
@export var material_profile: MaterialProfile

## Whether this object has been absorbed and is in its depleted visual state.
var is_depleted: bool = false

## If true, the object respawns (resets depleted state) when the player
## leaves and re-enters the room.
@export var respawns: bool = true

## Reference to the prompt indicator UI element shown when Embe is in range.
var _prompt_indicator: Control = null

## Whether Embe is currently inside the interaction range.
var _embe_in_range: bool = false


func _ready() -> void:
	assert(material_profile != null, "AbsorbableObject: material_profile must be assigned.")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_create_prompt_indicator()


## Create the interaction prompt indicator (screen-space, not world text).
func _create_prompt_indicator() -> void:
	# TODO: replace with a proper UI scene/texture
	_prompt_indicator = Label.new()
	_prompt_indicator.text = "[E] Absorb"
	_prompt_indicator.visible = false
	_prompt_indicator.add_theme_font_size_override("font_size", 12)
	add_child(_prompt_indicator)
	_prompt_indicator.position = Vector2(0, -40)


## Called by EmbeController when the player presses interact while in range.
func try_absorb(entity: Node) -> void:
	if is_depleted:
		return

	if not entity.has_node("AbsorptionComponent"):
		return

	var absorption: AbsorptionComponent = entity.get_node("AbsorptionComponent")
	absorption.absorb(material_profile)
	_set_depleted(true)
	absorbed_by.emit(entity)
	print("[AbsorbableObject] absorbed_by fired. Depleted: ", is_depleted)


func _set_depleted(depleted: bool) -> void:
	is_depleted = depleted
	_prompt_indicator.visible = false
	# TODO: swap to depleted visual state (dim sprite, grey-out, particles off)


## Reset to non-depleted state. Called by room manager on re-entry if respawns == true.
func reset() -> void:
	if respawns:
		_set_depleted(false)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("embe"):
		print("[AbsorbableObject] Embe in range. Profile: ", material_profile.material_name if material_profile else "MISSING PROFILE")
		_embe_in_range = true
		if not is_depleted:
			_prompt_indicator.visible = true
		if body.has_method("set_nearby_absorbable"):
			body.set_nearby_absorbable(self)


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("embe"):
		print("[AbsorbableObject] Embe left range.")
		_embe_in_range = false
		_prompt_indicator.visible = false
		if body.has_method("clear_nearby_absorbable"):
			body.clear_nearby_absorbable(self)

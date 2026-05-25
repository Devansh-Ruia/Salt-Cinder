## AbsorptionComponent — Manages Embe's material form state.
## Attach as a child of any CharacterBody2D that can absorb materials.
## Embe can only hold one material at a time; absorbing while transformed
## auto-releases the current form first.
class_name AbsorptionComponent
extends Node

## Emitted when Embe absorbs a new material. Carries the new profile.
signal form_changed(new_profile: MaterialProfile)

## Emitted when Embe releases the current material. Carries the old profile.
signal form_released(old_profile: MaterialProfile)

## Emitted when the current form shatters due to impact fragility.
signal form_shattered

## The default profile used when no material is absorbed.
## Assign basalt.tres here in the editor — Embe's natural state.
@export var default_profile: MaterialProfile

## The profile currently driving Embe's physics and visuals.
var _active_profile: MaterialProfile = null


func _ready() -> void:
	assert(default_profile != null, "AbsorptionComponent: default_profile must be assigned.")
	_active_profile = default_profile


## Returns the currently active MaterialProfile.
func get_active_profile() -> MaterialProfile:
	return _active_profile


## Returns true if Embe is in a non-default material form.
func is_transformed() -> bool:
	return _active_profile != default_profile


## Absorb a new material. If already transformed, releases the current form first.
func absorb(profile: MaterialProfile) -> void:
	print("[Absorption] Absorbing: ", profile.material_name if profile else "null", " | Was transformed: ", is_transformed())
	if profile == null:
		push_warning("AbsorptionComponent: attempted to absorb a null profile.")
		return

	if profile == _active_profile:
		return

	# Auto-release current form before absorbing a new one
	if is_transformed():
		release()

	_active_profile = profile
	form_changed.emit(_active_profile)
	print("[Absorption] form_changed signal emitted → ", _active_profile.material_name)


## Release the current material form, reverting to the default profile.
func release() -> void:
	print("[Absorption] Releasing form: ", _active_profile.material_name if _active_profile else "none")
	if not is_transformed():
		return

	var old_profile := _active_profile
	_active_profile = default_profile
	form_released.emit(old_profile)
	form_changed.emit(_active_profile)
	print("[Absorption] form_changed signal emitted → ", _active_profile.material_name)

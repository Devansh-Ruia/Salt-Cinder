## WaterZone — Area2D component that defines a body of water in the world.
## Applies buoyancy, underwater walk, or sinking based on Embe's active MaterialProfile.
## Listens for form changes while Embe is inside the zone and re-evaluates immediately.
class_name WaterZone
extends Area2D

## Emitted when Embe enters the water zone.
signal embe_entered_water
## Emitted when Embe exits the water zone.
signal embe_exited_water
## Emitted when buoyancy (float) mode is applied.
signal buoyancy_applied
## Emitted when underwater walk mode is applied.
signal underwater_walk_applied
## Emitted when sinking mode is applied (wrong form penalty).
signal sinking_applied

## Visual reference for water depth. Not used in physics.
@export var water_depth: float = 200.0

## Gravity override values for each mode.
const BUOYANCY_UPWARD_SPEED: float = 80.0
const UNDERWATER_WALK_GRAVITY_SCALE: float = 0.3
const SINKING_GRAVITY_SCALE: float = 2.5

## Tracked reference to Embe while inside the zone.
var _embe: CharacterBody2D = null
var _embe_absorption: AbsorptionComponent = null
var _current_mode: String = ""


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _physics_process(_delta: float) -> void:
	if _embe == null:
		return

	# Apply constant upward buoyancy velocity when in float mode
	if _current_mode == "float":
		_embe.velocity.y = -BUOYANCY_UPWARD_SPEED


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("embe"):
		return

	_embe = body as CharacterBody2D
	if _embe == null:
		return

	_embe_absorption = _embe.get_node_or_null("AbsorptionComponent") as AbsorptionComponent
	if _embe_absorption == null:
		push_warning("[WaterZone] Embe has no AbsorptionComponent.")
		return

	# Listen for form changes while inside the zone
	if not _embe_absorption.form_changed.is_connected(_on_form_changed_inside):
		_embe_absorption.form_changed.connect(_on_form_changed_inside)

	# Notify Embe's controller with water zone reference
	if _embe.has_method("set_in_water"):
		_embe.set_in_water(true, self)

	var active_profile := _embe_absorption.get_active_profile()
	print("[WaterZone] Embe entered. Active form: ", active_profile.material_name if active_profile else "default")
	embe_entered_water.emit()

	_evaluate_water_mode(active_profile)


func _on_body_exited(body: Node) -> void:
	if not body.is_in_group("embe"):
		return
	if body != _embe:
		return

	# Disconnect form change listener
	if _embe_absorption and _embe_absorption.form_changed.is_connected(_on_form_changed_inside):
		_embe_absorption.form_changed.disconnect(_on_form_changed_inside)

	# Restore Embe's default gravity and exit water
	if _embe.has_method("set_in_water"):
		_embe.set_in_water(false, null)

	_restore_gravity()

	print("[WaterZone] Embe exited water.")
	embe_exited_water.emit()

	_embe = null
	_embe_absorption = null
	_current_mode = ""


func _on_form_changed_inside(_new_profile: MaterialProfile) -> void:
	# Re-evaluate water mode when Embe changes form while inside the zone
	if _embe_absorption:
		var active_profile := _embe_absorption.get_active_profile()
		_restore_gravity()
		_evaluate_water_mode(active_profile)


func _evaluate_water_mode(profile: MaterialProfile) -> void:
	if profile == null:
		_current_mode = "sink"
		print("[WaterZone] Buoyancy mode: sink")
		sinking_applied.emit()
		return

	if profile.can_float:
		_current_mode = "float"
		# Override gravity to zero — buoyancy handled in _physics_process
		_embe.velocity.y = min(_embe.velocity.y, 0.0)
		print("[WaterZone] Buoyancy mode: float")
		buoyancy_applied.emit()
	elif profile.can_walk_underwater:
		_current_mode = "walk"
		# Sluggish but grounded — reduced gravity
		print("[WaterZone] Buoyancy mode: walk")
		underwater_walk_applied.emit()
	else:
		_current_mode = "sink"
		# Strong downward pull — penalty for wrong form
		print("[WaterZone] Buoyancy mode: sink")
		sinking_applied.emit()


func _restore_gravity() -> void:
	# Gravity restoration happens automatically via MaterialProfile.gravity_scale
	# in EmbeController._apply_gravity — we just need to clear our mode.
	_current_mode = ""


## Returns the current water interaction mode for external queries.
func get_current_mode() -> String:
	return _current_mode


## Returns the gravity scale override for the current mode.
## Called by EmbeController to apply water-specific gravity.
func get_gravity_scale_override() -> float:
	match _current_mode:
		"float":
			return 0.0
		"walk":
			return UNDERWATER_WALK_GRAVITY_SCALE
		"sink":
			return SINKING_GRAVITY_SCALE
		_:
			return -1.0  # No override

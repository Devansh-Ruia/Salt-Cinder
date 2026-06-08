## LightReflector — Component for SeaGlass form light reflection mechanic.
## Emits a directional RayCast2D toward the nearest LightSource.
## If the ray hits a ReflectorTarget and Embe is stationary for 0.5s, activates the target.
class_name LightReflector
extends Node2D

## Emitted when a reflectable target comes into / leaves the ray's sight while
## the reflective form is active. Drives the data-driven reflect affordance glyph.
signal reflect_target_changed(available: bool)

## Last emitted availability, so reflect_target_changed only fires on edges.
var _target_available_emitted: bool = false

## Time Embe must remain stationary before the reflection is considered stable.
const STABILITY_TIME: float = 0.5

## The RayCast2D used to detect reflection hits.
var _ray: RayCast2D = null

## Timer tracking how long Embe has been stationary.
var _stationary_timer: float = 0.0

## Whether the ray is currently active (SeaGlass form).
var _active: bool = false

## Last known Embe position for movement detection.
var _last_position: Vector2 = Vector2.ZERO

## Whether the current reflection is stable (stationary long enough).
var _is_stable: bool = false

## The currently hit target, if any.
var _current_target: Node = null

@onready var _absorption: AbsorptionComponent = get_parent().get_node_or_null("AbsorptionComponent")


func _ready() -> void:
	# Located by the teaching layer via group, not a node path.
	add_to_group("light_reflector")

	# Create the RayCast2D programmatically
	_ray = RayCast2D.new()
	_ray.enabled = false
	_ray.collide_with_areas = true
	_ray.collide_with_bodies = false
	add_child(_ray)

	if _absorption:
		_absorption.form_changed.connect(_on_form_changed)
		_check_active(_absorption.get_active_profile())


func _physics_process(delta: float) -> void:
	if not _active:
		_set_target_available(false)
		return

	var parent_body := get_parent() as Node2D
	if parent_body == null:
		return

	# Update ray direction toward nearest LightSource
	var light_source := _find_nearest_light_source()
	if light_source == null:
		_ray.enabled = false
		_set_target_available(false)
		return

	_ray.enabled = true

	# Ray points FROM Embe in the reflection direction (away from light)
	var to_light := (light_source.global_position - global_position).normalized()
	var reflect_dir := -to_light  # Reflect away from light source
	_ray.target_position = reflect_dir * 1000.0  # Long ray

	_ray.force_raycast_update()

	# Check movement for stability
	var current_pos := global_position
	if current_pos.distance_to(_last_position) > 1.0:
		_stationary_timer = 0.0
		_is_stable = false
		_current_target = null
	else:
		_stationary_timer += delta

	_last_position = current_pos

	# Check for ReflectorTarget hits
	if _ray.is_colliding():
		var collider := _ray.get_collider()
		if collider and collider.is_in_group("reflector_target"):
			_current_target = collider
			print("[LightReflector] Ray active. Target hit: ", collider.name)

			if _stationary_timer >= STABILITY_TIME and not _is_stable:
				_is_stable = true
				if collider.has_method("_on_reflection_hit"):
					collider._on_reflection_hit(self)
		else:
			_current_target = null
			print("[LightReflector] Ray active. Target hit: none")
	else:
		_current_target = null
		print("[LightReflector] Ray active. Target hit: none")

	_set_target_available(_current_target != null)


## Emit reflect_target_changed only on edges (target gained / lost).
func _set_target_available(available: bool) -> void:
	if available != _target_available_emitted:
		_target_available_emitted = available
		reflect_target_changed.emit(available)


func _on_form_changed(new_profile: MaterialProfile) -> void:
	_check_active(new_profile)


func _check_active(profile: MaterialProfile) -> void:
	_active = profile != null and profile.light_reflective
	if not _active:
		_ray.enabled = false
		_stationary_timer = 0.0
		_is_stable = false
		_current_target = null


func _find_nearest_light_source() -> Node2D:
	var lights := get_tree().get_nodes_in_group("light_source")
	if lights.is_empty():
		return null

	var nearest: Node2D = null
	var nearest_dist := INF

	for light in lights:
		var light_node := light as Node2D
		if light_node == null:
			continue
		var dist := global_position.distance_to(light_node.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = light_node

	return nearest

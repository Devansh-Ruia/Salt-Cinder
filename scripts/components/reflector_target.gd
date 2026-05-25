## ReflectorTarget — Area2D that activates a mechanism when hit by a light reflection.
## Place in the scene and assign the node it should activate via the `activates` export.
## The activated node must have an `activate()` method.
class_name ReflectorTarget
extends Area2D

## Emitted when this target is hit by a stable light reflection.
signal reflection_hit(source: Node)

## Path to the node this target activates when hit.
@export var activates: NodePath

## Whether this target has already been activated (one-shot by default).
var _activated: bool = false


func _ready() -> void:
	add_to_group("reflector_target")


## Called by LightReflector when the ray hits this target and is stable.
func _on_reflection_hit(source: Node) -> void:
	if _activated:
		return

	_activated = true
	reflection_hit.emit(source)

	var target_node := get_node_or_null(activates)
	if target_node and target_node.has_method("activate"):
		print("[ReflectorTarget] Activated by reflection → ", target_node.name)
		target_node.activate()
	else:
		print("[ReflectorTarget] Activated by reflection → ", activates, " (node not found or no activate method)")

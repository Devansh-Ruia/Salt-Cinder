## FoundryGate — A gate that blocks passage until activated by a puzzle mechanism.
## Exposes activate() for use with ReflectorTarget or other activators.
extends Node2D

signal gate_opened

var _is_open: bool = false


func activate() -> void:
	if _is_open:
		return
	_is_open = true

	# Hide the gate visual and disable collision
	visible = false
	var body := get_node_or_null("StaticBody2D") as StaticBody2D
	if body:
		body.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
		for child in body.get_children():
			if child is CollisionShape2D:
				child.set_deferred("disabled", true)

	gate_opened.emit()
	print("[FoundryGate] Gate opened!")

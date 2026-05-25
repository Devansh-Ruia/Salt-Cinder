# REMOVE BEFORE SHIP
## DebugSequenceTracker — Autoload that tracks the order of material forms used.
## Listens to AbsorptionComponent.form_changed globally and logs the sequence.
extends Node

var form_history: Array[String] = []


func _ready() -> void:
	# Connect to form_changed on any AbsorptionComponent in the tree
	get_tree().node_added.connect(_on_node_added)
	# Also scan existing nodes
	_scan_existing_nodes()


func _scan_existing_nodes() -> void:
	_scan_recursive(get_tree().root)


func _scan_recursive(node: Node) -> void:
	if node is AbsorptionComponent:
		_connect_to_absorption(node)
	for child in node.get_children():
		_scan_recursive(child)


func _on_node_added(node: Node) -> void:
	if node is AbsorptionComponent:
		_connect_to_absorption(node)


func _connect_to_absorption(absorption: AbsorptionComponent) -> void:
	if not absorption.form_changed.is_connected(_on_form_changed):
		absorption.form_changed.connect(_on_form_changed)


func _on_form_changed(new_profile: MaterialProfile) -> void:
	if new_profile:
		form_history.append(new_profile.material_name)
	else:
		form_history.append("default")
	print("[SequenceTracker] Form history: ", form_history)

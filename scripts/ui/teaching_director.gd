## TeachingDirector — Autoload running the glyphs-only contextual teaching layer.
## Gris / A Short Hike philosophy: teach through tiny contextual icons, then get
## out of the way. NO HUD sentences, NO modal tutorials — words live only in
## opt-in lore and existing dialogue.
##
## Owns one screen-fixed CanvasLayer holding the persistent FormIndicator, the
## LoreNotification, and a small pool of PromptGlyphs. All show/hide is driven by
## existing signals + group lookups — never polling-by-name.
##
## Four channels:
##   1. Controls   — [Q] absorb, [Q] release, move + jump glyphs.
##                   Retire via GameState flags: taught_absorb / taught_release / taught_jump.
##   2. Form       — persistent FormIndicator swatch (form_changed / form_released).
##   3. Affordance — climb / float / reflect glyphs GATED ON THE ACTIVE
##                   MaterialProfile flags (can_wall_climb / can_float / light_reflective)
##                   plus proximity. Data-driven: a new form with a flag auto-participates.
##   4. Objective  — reflector-target glyph; FoundryGate already reads locked/unlocked
##                   by visual state (it vanishes on unlock), not text.
##   5. Lore       — [E] glyph over a LorePickup in range → existing LoreNotification.
##
## Note: this autoload follows the same code-built-CanvasLayer pattern RoomManager
## uses for its fade overlay. It is registered LAST in project.godot so GameState
## and RoomManager exist before it connects.
extends Node

const PROMPT_GLYPH_SCENE: PackedScene = preload("res://scenes/ui/prompt_glyph.tscn")
const FORM_INDICATOR_SCENE: PackedScene = preload("res://scenes/ui/form_indicator.tscn")
const LORE_NOTIFICATION_SCENE: PackedScene = preload("res://scenes/ui/lore_notification.tscn")

## Rooms considered the "opening" where the move/jump glyphs may appear. Keeping
## these scoped to the opening stops them reappearing later in the game.
const OPENING_ROOMS: Array[String] = ["arrival"]

var _layer: CanvasLayer = null
var _glyphs: Control = null
var _lore_notification: Node = null

# One glyph instance per channel; several can be visible at once.
var _absorb_glyph: PromptGlyph = null
var _release_glyph: PromptGlyph = null
var _move_glyph: PromptGlyph = null
var _jump_glyph: PromptGlyph = null
var _climb_glyph: PromptGlyph = null
var _float_glyph: PromptGlyph = null
var _reflect_glyph: PromptGlyph = null
var _objective_glyph: PromptGlyph = null
var _lore_glyph: PromptGlyph = null

# Tracked runtime state.
var _embe: Node = null
var _absorption: AbsorptionComponent = null
var _current_room: String = ""
var _nearby_absorbable: Node2D = null
var _nearby_lore: Node2D = null
var _on_wall: bool = false
var _in_water: bool = false
var _reflect_available: bool = false


func _ready() -> void:
	_build_layer()
	RoomManager.room_loaded.connect(_on_room_loaded)
	# Embe is adopted by RoomManager during the first transition; bind once it exists.
	_bind_embe.call_deferred()
	print("[Teaching] TeachingDirector ready.")


# ── Layer construction ───────────────────────────────────

func _build_layer() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 10  # Above the world, below RoomManager's fade overlay (100).
	add_child(_layer)

	var form_indicator: Node = FORM_INDICATOR_SCENE.instantiate()
	_layer.add_child(form_indicator)

	_lore_notification = LORE_NOTIFICATION_SCENE.instantiate()
	_layer.add_child(_lore_notification)

	_glyphs = Control.new()
	_glyphs.set_anchors_preset(Control.PRESET_FULL_RECT)
	_glyphs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_glyphs)

	# Control glyphs (placeholder keycaps / symbols — art gate TODO).
	# Key labels resolve from the live InputMap so they can never drift from the
	# actual bindings. Move teaches the WASD scheme (A / D); jump teaches Space —
	# a side-on platformer has no real "up", so no up-glyph is shown.
	_absorb_glyph = _make_glyph(_action_symbol("absorb_release"), "taught_absorb", Vector2(0, -52))
	_release_glyph = _make_glyph(_action_symbol("absorb_release"), "taught_release", Vector2(0, -86))
	var move_label: String = "%s / %s" % [_action_symbol("move_left"), _action_symbol("move_right")]
	_move_glyph = _make_glyph(move_label, "taught_jump", Vector2(-30, -52))
	_jump_glyph = _make_glyph(_action_symbol("jump"), "taught_jump", Vector2(30, -52))
	# Affordance glyphs (symbols, gated on MaterialProfile flags — art gate TODO).
	_climb_glyph = _make_glyph("=", "", Vector2(0, -60))
	_float_glyph = _make_glyph("~", "", Vector2(0, -60))
	_reflect_glyph = _make_glyph("*", "", Vector2(0, -60))
	# Objective + lore glyphs.
	_objective_glyph = _make_glyph("o", "", Vector2(0, -48))
	_lore_glyph = _make_glyph(_action_symbol("interact"), "", Vector2(0, -48))


func _make_glyph(label: String, flag: String, offset: Vector2) -> PromptGlyph:
	var g: PromptGlyph = PROMPT_GLYPH_SCENE.instantiate()
	g.anchor_mode = PromptGlyph.AnchorMode.WORLD
	g.key_label = label
	g.one_shot_flag = flag
	g.world_offset = offset
	_glyphs.add_child(g)
	return g


## Resolve an input action's PRIMARY bound key to a short display symbol, read
## live from the InputMap so glyph labels can never drift from the real bindings.
## Returns the first InputEventKey's human label (e.g. "A", "D", "Space", "Q").
## # TODO: art gate — real key-cap icons will replace these text placeholders.
func _action_symbol(action: StringName) -> String:
	if not InputMap.has_action(action):
		return "?"
	for event in InputMap.action_get_events(action):
		var key_event: InputEventKey = event as InputEventKey
		if key_event == null:
			continue
		# Prefer the physical keycode (layout-independent); map it back to a
		# logical keycode for a readable name. Fall back to the logical keycode.
		var code: int = key_event.physical_keycode
		if code != 0:
			code = DisplayServer.keyboard_get_keycode_from_physical(code)
		else:
			code = key_event.keycode
		if code == 0:
			continue
		return OS.get_keycode_string(code)
	return "?"


# ── Embe / per-room binding ──────────────────────────────

func _bind_embe() -> void:
	var embe: Node = get_tree().get_first_node_in_group("embe")
	if embe == null:
		return
	_embe = embe
	_absorption = embe.get_node_or_null("AbsorptionComponent") as AbsorptionComponent

	if _absorption != null:
		if not _absorption.form_changed.is_connected(_on_form_changed):
			_absorption.form_changed.connect(_on_form_changed)
		if not _absorption.form_released.is_connected(_on_form_released):
			_absorption.form_released.connect(_on_form_released)

	# Controller-exposed teaching signals. EmbeController has no class_name, so
	# connect by signal name (string) rather than member access.
	_connect_signal(embe, "absorbable_in_range", _on_absorbable_in_range)
	_connect_signal(embe, "absorbable_out_of_range", _on_absorbable_out_of_range)
	_connect_signal(embe, "wall_contact_changed", _on_wall_contact_changed)
	_connect_signal(embe, "jumped", _on_jumped)

	# LightReflector lives under Embe; located via group, not a node path.
	var reflector: Node = get_tree().get_first_node_in_group("light_reflector")
	_connect_signal(reflector, "reflect_target_changed", _on_reflect_target_changed)

	_refresh_controls()
	_refresh_affordances()


## Connect a signal by name if present and not already connected. Avoids static
## member-access errors on loosely-typed (class_name-less) nodes.
func _connect_signal(node: Node, signal_name: StringName, callable: Callable) -> void:
	if node == null or not node.has_signal(signal_name):
		return
	if not node.is_connected(signal_name, callable):
		node.connect(signal_name, callable)


func _on_room_loaded(room_name: String) -> void:
	_current_room = room_name
	# Per-room world nodes were freed/re-instanced — drop stale targets and re-scan.
	_nearby_absorbable = null
	_nearby_lore = null
	_on_wall = false
	_in_water = false
	_reflect_available = false
	_absorb_glyph.hide_glyph()
	_lore_glyph.hide_glyph()
	_objective_glyph.hide_glyph()

	_bind_embe()  # Embe persists; connections are guarded against duplicates.
	_connect_room_signals()
	_refresh_controls()
	_refresh_affordances()


func _connect_room_signals() -> void:
	for pickup in get_tree().get_nodes_in_group("lore_pickup"):
		_connect_signal(pickup, "lore_collected", _on_lore_collected)
		_connect_signal(pickup, "embe_entered_range", _on_lore_in_range)
		_connect_signal(pickup, "embe_exited_range", _on_lore_out_of_range)

	for target in get_tree().get_nodes_in_group("reflector_target"):
		_connect_signal(target, "reflection_hit", _on_reflection_hit)

	for wz in get_tree().get_nodes_in_group("water_zone"):
		_connect_signal(wz, "embe_entered_water", _on_water_entered)
		_connect_signal(wz, "embe_exited_water", _on_water_exited)


# ── Channel refresh ──────────────────────────────────────

func _refresh_controls() -> void:
	# Release glyph: any time Embe holds a non-default form (Q releases it).
	_set_glyph(_release_glyph, _embe, _absorption != null and _absorption.is_transformed())
	# Opening-only move/jump glyphs (also retired permanently once taught_jump is set).
	var in_opening: bool = _current_room in OPENING_ROOMS
	_set_glyph(_move_glyph, _embe, in_opening)
	_set_glyph(_jump_glyph, _embe, in_opening)


func _refresh_affordances() -> void:
	if _absorption == null:
		return
	var p: MaterialProfile = _absorption.get_active_profile()
	if p == null:
		return
	# Affordances appear ONLY because the active form enables them — that is the lesson.
	_set_glyph(_climb_glyph, _embe, p.can_wall_climb and _on_wall)
	_set_glyph(_float_glyph, _embe, p.can_float and _in_water)
	_set_glyph(_reflect_glyph, _embe, p.light_reflective and _reflect_available)

	# Objective glyph: mark the reflector target while a reflective form is held.
	var targets: Array = get_tree().get_nodes_in_group("reflector_target")
	if p.light_reflective and not targets.is_empty():
		_objective_glyph.set_world_target(targets[0] as Node2D)
		_objective_glyph.show_glyph()
	else:
		_objective_glyph.hide_glyph()


func _set_glyph(g: PromptGlyph, target: Node, want: bool) -> void:
	if g == null:
		return
	if want and target != null:
		g.set_world_target(target as Node2D)
		g.show_glyph()
	else:
		g.hide_glyph()


# ── Signal handlers ──────────────────────────────────────

func _on_form_changed(_profile: MaterialProfile) -> void:
	if _absorption != null and _absorption.is_transformed():
		if not GameState.has_flag("taught_absorb"):
			GameState.set_flag("taught_absorb")
		_absorb_glyph.hide_glyph()  # absorbing while in range consumes the prompt
	_refresh_controls()
	_refresh_affordances()


func _on_form_released(_old_profile: MaterialProfile) -> void:
	if not GameState.has_flag("taught_release"):
		GameState.set_flag("taught_release")
	_refresh_controls()
	_refresh_affordances()


func _on_absorbable_in_range(obj: Node) -> void:
	_nearby_absorbable = obj as Node2D
	# [Q] absorb only matters when NOT transformed; when transformed Q releases
	# (handled by the release glyph), so don't double up.
	if _absorption != null and _absorption.is_transformed():
		return
	_set_glyph(_absorb_glyph, _nearby_absorbable, true)


func _on_absorbable_out_of_range() -> void:
	_nearby_absorbable = null
	_absorb_glyph.hide_glyph()


func _on_wall_contact_changed(touching: bool) -> void:
	_on_wall = touching
	_refresh_affordances()


func _on_jumped() -> void:
	if not GameState.has_flag("taught_jump"):
		GameState.set_flag("taught_jump")
	_move_glyph.hide_glyph()
	_jump_glyph.hide_glyph()


func _on_water_entered() -> void:
	_in_water = true
	_refresh_affordances()


func _on_water_exited() -> void:
	_in_water = false
	_refresh_affordances()


func _on_reflect_target_changed(available: bool) -> void:
	_reflect_available = available
	_refresh_affordances()


func _on_lore_in_range(pickup: Node) -> void:
	_nearby_lore = pickup as Node2D
	_set_glyph(_lore_glyph, _nearby_lore, true)


func _on_lore_out_of_range(pickup: Node) -> void:
	if pickup == _nearby_lore:
		_nearby_lore = null
		_lore_glyph.hide_glyph()


func _on_lore_collected(entry: LoreEntry) -> void:
	_lore_glyph.hide_glyph()
	if _lore_notification != null and _lore_notification.has_method("show_lore"):
		_lore_notification.show_lore(entry)


func _on_reflection_hit(_source: Node) -> void:
	# Puzzle solved — the objective is met, retire its glyph.
	_objective_glyph.hide_glyph()

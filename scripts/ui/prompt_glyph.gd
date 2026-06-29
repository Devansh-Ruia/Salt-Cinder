## PromptGlyph — Reusable, glyphs-only contextual teaching cue.
## Gris / A Short Hike aesthetic: a single tiny input/affordance icon that fades
## in when relevant and fades out when it isn't. NEVER renders sentences — only a
## placeholder keycap letter or a swappable icon texture. Words live exclusively
## in opt-in lore and dialogue, never here.
##
## Anchoring:
##   WORLD — tracks a Node2D target's on-screen position (e.g. above Embe or a prop).
##   HUD   — stays where the owner positions it on screen.
##
## Retirement:
##   If `one_shot_flag` is set and already true in GameState, the glyph stays
##   permanently hidden — this is how a control glyph retires once its verb is learned.
##
## ART GATE: the keycap label + panel are FUNCTIONAL PLACEHOLDERS. Assign
## `icon_texture` to swap in final glyph art. Deliberate iconography is the art pass. # TODO: art gate
class_name PromptGlyph
extends Control

enum AnchorMode { HUD, WORLD }

## How this glyph positions itself: fixed on screen (HUD) or tracking a world node (WORLD).
@export var anchor_mode: AnchorMode = AnchorMode.WORLD

## Placeholder keycap text (e.g. "Q", "E", a small symbol). Ignored when icon_texture is set.
@export var key_label: String = "E"

## Swappable icon art slot. When assigned, replaces the keycap placeholder. # TODO: art gate
@export var icon_texture: Texture2D = null

## Optional GameState flag. If non-empty and already set, this glyph is retired (never shows).
@export var one_shot_flag: String = ""

## Screen-space offset applied above the anchor point.
@export var world_offset: Vector2 = Vector2(0.0, -52.0)

## Fade duration for show/hide. Never a hard pop.
const FADE_DURATION: float = 0.25

@onready var _panel: PanelContainer = $Panel
@onready var _icon: TextureRect = $Panel/Margin/Icon
@onready var _key_label: Label = $Panel/Margin/KeyLabel

var _world_target: Node2D = null
var _shown: bool = false
var _fade_tween: Tween = null


func _ready() -> void:
	modulate.a = 0.0
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_visual()


func _process(_delta: float) -> void:
	if anchor_mode != AnchorMode.WORLD or not _shown:
		return
	if _world_target == null or not is_instance_valid(_world_target):
		return
	# Convert the world target's position into this CanvasLayer's screen space,
	# then centre the panel on it and lift it by the configured offset.
	var screen_pos: Vector2 = _world_target.get_global_transform_with_canvas().origin
	global_position = screen_pos + world_offset - _panel.size * 0.5


## Refresh the placeholder vs. icon display from the current exports.
func _apply_visual() -> void:
	var has_icon: bool = icon_texture != null
	_icon.texture = icon_texture
	_icon.visible = has_icon
	_key_label.visible = not has_icon
	_key_label.text = key_label
	var label_width: float = maxf(18.0, float(key_label.length()) * 10.0)
	_key_label.custom_minimum_size = Vector2(label_width, 22.0)


## Reconfigure at runtime (key char, optional icon, optional retirement flag).
func configure(p_key_label: String, p_icon: Texture2D = null, p_one_shot_flag: String = "") -> void:
	key_label = p_key_label
	icon_texture = p_icon
	one_shot_flag = p_one_shot_flag
	if is_node_ready():
		_apply_visual()


## Assign the world node this glyph hovers above (WORLD anchor mode).
func set_world_target(target: Node2D) -> void:
	_world_target = target


## True if a one-shot flag is set and already satisfied — glyph is permanently retired.
func is_retired() -> bool:
	return one_shot_flag != "" and GameState.has_flag(one_shot_flag)


## Fade the glyph in. No-op if retired or already shown.
func show_glyph() -> void:
	if is_retired() or _shown:
		return
	_shown = true
	visible = true
	_kill_tween()
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", 1.0, FADE_DURATION)


## Fade the glyph out. No-op if already hidden.
func hide_glyph() -> void:
	if not _shown:
		return
	_shown = false
	_kill_tween()
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION)
	_fade_tween.tween_callback(_on_fade_out_done)


func _on_fade_out_done() -> void:
	if not _shown:
		visible = false


func _kill_tween() -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()

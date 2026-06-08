## EmbeController — CharacterBody2D state machine for Embe.
## Physics values are ALWAYS sourced from the active MaterialProfile via AbsorptionComponent.
## No combat logic. No health. No damage.
##
## ──────────────────────────────────────────────────────────
## Required Input Map Actions (defined in project.godot):
##   move_left     — A / Left Arrow
##   move_right    — D / Right Arrow
##   jump          — Space / W
##   interact      — E
##   absorb_release — Q
## ──────────────────────────────────────────────────────────
##
## ──────────────────────────────────────────────────────────
## Expected Animations (64×64px frames, referenced by _update_animation):
##   basalt_idle        — 4 frames, 4 fps, loop
##   basalt_run         — 6 frames, 10 fps, loop
##   basalt_jump        — 2 frames, hold last
##   basalt_fall         — 2 frames, hold last
##   basalt_land        — 3 frames, 12 fps, no loop
##   basalt_absorb      — 5 frames, 10 fps, no loop
##   basalt_wall_slide  — 2 frames, 6 fps, loop
##   basalt_wall_climb  — 4 frames, 8 fps, loop
##   coral_idle         — 4 frames, 4 fps, loop
##   coral_run          — 6 frames, 10 fps, loop
##   coral_jump         — 2 frames, hold last
##   coral_fall         — 2 frames, hold last
##   coral_land         — 3 frames, 12 fps, no loop
##   coral_absorb       — 5 frames, 10 fps, no loop
##   coral_wall_slide   — 2 frames, 6 fps, loop
##   coral_wall_climb   — 4 frames, 8 fps, loop
##   coral_shatter      — 6 frames, 12 fps, no loop
##   seaglass_idle      — 4 frames, 4 fps, loop
##   seaglass_run       — 6 frames, 10 fps, loop
##   seaglass_jump      — 2 frames, hold last
##   seaglass_fall      — 2 frames, hold last
##   seaglass_land      — 3 frames, 12 fps, no loop
##   seaglass_absorb    — 5 frames, 10 fps, no loop
##   seaglass_wall_slide — 2 frames, 6 fps, loop
##   driftwood_idle     — 4 frames, 4 fps, loop
##   driftwood_run      — 6 frames, 10 fps, loop
##   driftwood_jump     — 2 frames, hold last
##   driftwood_fall     — 2 frames, hold last
##   driftwood_land     — 3 frames, 12 fps, no loop
##   driftwood_absorb   — 5 frames, 10 fps, no loop
##   driftwood_float    — 3 frames, 4 fps, loop
## ──────────────────────────────────────────────────────────
extends CharacterBody2D

## Emitted when an AbsorbableObject enters interaction range (carries the object).
## The teaching layer hooks the [Q] absorb glyph onto this.
signal absorbable_in_range(obj: Node)
## Emitted when the nearby AbsorbableObject leaves range.
signal absorbable_out_of_range
## Emitted when Embe's wall-contact state changes (true = now touching a wall).
## Drives the data-driven climb affordance glyph.
signal wall_contact_changed(touching: bool)
## Emitted whenever Embe performs a jump (ground jump or wall-kick).
## Retires the opening move/jump teaching glyphs.
signal jumped

enum State {
	IDLE,
	RUNNING,
	JUMPING,
	FALLING,
	LANDING,
	ABSORBING,
	FLOATING,
	WALL_SLIDING,
	WALL_CLIMBING,
}

## How long the landing state holds before transitioning.
const LANDING_DURATION: float = 0.15

## Gravity (pixels/sec²). Scaled by MaterialProfile.gravity_scale.
const BASE_GRAVITY: float = 980.0

## Wall slide speed cap.
const WALL_SLIDE_SPEED: float = 60.0

## Buoyancy force applied when driftwood form is in a water zone.
const BUOYANCY_FORCE: float = 600.0

## Fall velocity threshold that shatters impact_fragile forms.
const FRAGILE_IMPACT_THRESHOLD: float = 400.0

## Gravity scale applied during WALL_SLIDING (non-climbing forms).
const WALL_SLIDE_GRAVITY_SCALE: float = 0.4

var _state: State = State.IDLE
var _landing_timer: float = 0.0
var _input_frozen: bool = false
var _in_water: bool = false

## Velocity at the moment of landing, used for impact fragility check.
var _pre_land_velocity_y: float = 0.0

## Closest absorbable object in range, or null.
var _nearby_absorbable: Node = null

## Previous wall-contact state, used to emit wall_contact_changed only on edges.
var _on_wall_prev: bool = false

## Reference to the WaterZone Embe is currently inside, or null.
var _active_water_zone: WaterZone = null

@onready var absorption: AbsorptionComponent = $AbsorptionComponent
@onready var anim_player: AnimationPlayer = $AnimationPlayer  # TODO: set up AnimationPlayer
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D      # TODO: assign sprite frames


func _ready() -> void:
	add_to_group("embe")
	absorption.form_changed.connect(_on_form_changed)


func _physics_process(delta: float) -> void:
	# TODO: jump input block not found in _physics_process — print not added
	# (jump input is handled in _state_idle, _state_running, _state_floating, _state_wall_sliding)
	if _input_frozen:
		return

	var profile := absorption.get_active_profile()
	_apply_gravity(delta, profile)
	_handle_state(delta, profile)
	_update_animation(profile)
	move_and_slide()
	_update_wall_contact()


## Emit wall_contact_changed only when the contact state flips (edge-triggered),
## so the teaching layer can react without polling.
func _update_wall_contact() -> void:
	var touching: bool = is_on_wall()
	if touching != _on_wall_prev:
		_on_wall_prev = touching
		wall_contact_changed.emit(touching)


# ── Gravity ──────────────────────────────────────────────

func _apply_gravity(delta: float, profile: MaterialProfile) -> void:
	if is_on_floor():
		return

	# Wall sliding uses reduced gravity regardless of form
	if _state == State.WALL_SLIDING:
		velocity.y += BASE_GRAVITY * WALL_SLIDE_GRAVITY_SCALE * delta
		return

	# Wall climbing has no passive gravity (player controls vertical movement)
	if _state == State.WALL_CLIMBING:
		return

	# Water zone gravity overrides
	if _in_water and _active_water_zone:
		var override := _active_water_zone.get_gravity_scale_override()
		if override == 0.0:
			# Float mode — buoyancy velocity applied by WaterZone._physics_process
			return
		elif override > 0.0:
			# Walk or sink mode — use override scale
			velocity.y += BASE_GRAVITY * override * delta
			return

	# Default: profile gravity (also covers can_float without a WaterZone ref)
	if _in_water and profile.can_float:
		velocity.y -= BUOYANCY_FORCE * delta
		velocity.y = max(velocity.y, -BUOYANCY_FORCE * 0.5)
	else:
		velocity.y += BASE_GRAVITY * profile.gravity_scale * delta


# ── State Machine ────────────────────────────────────────

func _handle_state(delta: float, profile: MaterialProfile) -> void:
	match _state:
		State.IDLE:
			_state_idle(profile)
		State.RUNNING:
			_state_running(profile)
		State.JUMPING:
			_state_jumping(profile)
		State.FALLING:
			_state_falling(profile)
		State.LANDING:
			_state_landing(delta)
		State.ABSORBING:
			pass  # Locked until animation completes
		State.FLOATING:
			_state_floating(profile)
		State.WALL_SLIDING:
			_state_wall_sliding(profile)
		State.WALL_CLIMBING:
			_state_wall_climbing(profile)


func _state_idle(profile: MaterialProfile) -> void:
	velocity.x = 0.0
	_check_absorb_input()

	if not is_on_floor():
		_transition_to(State.FALLING)
		return
	if Input.is_action_just_pressed("jump"):
		print("[Embe] Jump input detected. On floor: ", is_on_floor())
		_jump(profile)
		return
	if _get_horizontal_input() != 0.0:
		_transition_to(State.RUNNING)


func _state_running(profile: MaterialProfile) -> void:
	var h := _get_horizontal_input()
	velocity.x = h * profile.move_speed
	_flip_sprite(h)
	_check_absorb_input()

	if not is_on_floor():
		_transition_to(State.FALLING)
		return
	if Input.is_action_just_pressed("jump"):
		print("[Embe] Jump input detected. On floor: ", is_on_floor())
		_jump(profile)
		return
	if h == 0.0:
		_transition_to(State.IDLE)


func _state_jumping(profile: MaterialProfile) -> void:
	var h := _get_horizontal_input()
	velocity.x = h * profile.move_speed
	_flip_sprite(h)

	if velocity.y >= 0.0:
		_transition_to(State.FALLING)
		return
	if _in_water and profile.can_float:
		_transition_to(State.FLOATING)


func _state_falling(profile: MaterialProfile) -> void:
	var h := _get_horizontal_input()
	velocity.x = h * profile.move_speed
	_flip_sprite(h)

	if is_on_floor():
		_pre_land_velocity_y = velocity.y
		_landing_timer = LANDING_DURATION
		_transition_to(State.LANDING)
		return
	if is_on_wall() and h != 0.0:
		var can_climb := profile.can_wall_climb
		print("[Embe] Wall contact. Can climb: ", can_climb, " | Wall normal: ", get_wall_normal())
		if can_climb:
			_transition_to(State.WALL_CLIMBING)
		else:
			_transition_to(State.WALL_SLIDING)
		return
	if _in_water and profile.can_float:
		_transition_to(State.FLOATING)


func _state_landing(delta: float) -> void:
	velocity.x = 0.0

	# Impact fragility check on first frame of landing
	if _landing_timer == LANDING_DURATION:
		var profile := absorption.get_active_profile()
		var did_shatter := false
		if profile.impact_fragile and _pre_land_velocity_y > FRAGILE_IMPACT_THRESHOLD:
			did_shatter = true
			absorption.release()
			absorption.form_shattered.emit()
		print("[Embe] Impact velocity: ", _pre_land_velocity_y, " | Fragile shatter: ", did_shatter)

	_landing_timer -= delta
	if _landing_timer <= 0.0:
		_transition_to(State.IDLE)


func _state_floating(profile: MaterialProfile) -> void:
	var h := _get_horizontal_input()
	velocity.x = h * profile.move_speed
	_flip_sprite(h)

	# Exit floating when leaving water or changing to non-buoyant form
	if not _in_water or not profile.can_float:
		_transition_to(State.FALLING if not is_on_floor() else State.IDLE)
		return

	if Input.is_action_just_pressed("jump"):
		print("[Embe] Jump input detected. On floor: ", is_on_floor())
		_jump(profile)


## WALL_SLIDING — non-climbing forms. Gravity at 0.4x, slow slide down. No upward movement.
func _state_wall_sliding(profile: MaterialProfile) -> void:
	# Cap downward speed to wall slide speed
	velocity.y = min(velocity.y, WALL_SLIDE_SPEED)
	velocity.x = 0.0
	var h := _get_horizontal_input()

	if is_on_floor():
		_transition_to(State.IDLE)
		return
	if not is_on_wall():
		_transition_to(State.FALLING)
		return
	# Release input away from wall → fall
	if h == 0.0 or (h > 0.0 and get_wall_normal().x > 0.0) or (h < 0.0 and get_wall_normal().x < 0.0):
		_transition_to(State.FALLING)
		return


## WALL_CLIMBING — can_wall_climb forms (coral only). Full vertical movement.
## Horizontal input maps to vertical movement on the wall. Jump to wall-kick.
func _state_wall_climbing(profile: MaterialProfile) -> void:
	var h := _get_horizontal_input()
	var wall_normal := get_wall_normal()

	# Per spec: horizontal input maps to vertical movement on the wall.
	# Wall on right (normal.x < 0): pressing left (h<0) → climb up, right (h>0) → into wall (no vertical)
	# Wall on left (normal.x > 0): pressing right (h>0) → climb up, left (h<0) → into wall (no vertical)
	# Simplified: input toward wall = no climb, input away from wall = climb up
	velocity.y = -h * profile.move_speed if wall_normal.x > 0.0 else h * profile.move_speed
	velocity.x = 0.0

	if is_on_floor():
		_transition_to(State.IDLE)
		return
	if not is_on_wall():
		# Reached top of wall or lost contact
		_transition_to(State.FALLING)
		return
	if Input.is_action_just_pressed("jump"):
		print("[Embe] Jump input detected. On floor: ", is_on_floor())
		# Wall-kick: 45-degree angle away from wall
		var kick_dir := wall_normal.normalized()
		var kick_speed := profile.jump_force
		velocity.x = kick_dir.x * kick_speed * 0.707  # cos(45)
		velocity.y = -kick_speed * 0.707               # sin(45) upward
		jumped.emit()
		_transition_to(State.JUMPING)


func _transition_to(new_state: State) -> void:
	print("[Embe] State: ", State.keys()[_state], " → ", State.keys()[new_state])
	_state = new_state


# ── Input Helpers ────────────────────────────────────────

func _get_horizontal_input() -> float:
	return Input.get_axis("move_left", "move_right")


func _flip_sprite(direction: float) -> void:
	if direction != 0.0 and sprite:
		sprite.flip_h = direction < 0.0


func _jump(profile: MaterialProfile) -> void:
	velocity.y = -profile.jump_force
	jumped.emit()
	_transition_to(State.JUMPING)


## Handle absorb/release input. Absorption is grounded only.
func _check_absorb_input() -> void:
	if not is_on_floor():
		return

	if Input.is_action_just_pressed("absorb_release"):
		if absorption.is_transformed():
			absorption.release()
		elif _nearby_absorbable and _nearby_absorbable.has_method("try_absorb"):
			_transition_to(State.ABSORBING)
			_nearby_absorbable.try_absorb(self)


# ── Animation ────────────────────────────────────────────

func _update_animation(profile: MaterialProfile) -> void:
	var form_prefix: String = profile.material_name.to_lower()
	var anim_name: String = ""

	match _state:
		State.IDLE:
			anim_name = form_prefix + "_idle"
		State.RUNNING:
			anim_name = form_prefix + "_run"
		State.JUMPING:
			anim_name = form_prefix + "_jump"
		State.FALLING:
			anim_name = form_prefix + "_fall"
		State.LANDING:
			anim_name = form_prefix + "_land"
		State.ABSORBING:
			anim_name = form_prefix + "_absorb"
		State.FLOATING:
			anim_name = form_prefix + "_float"
		State.WALL_SLIDING:
			anim_name = form_prefix + "_wall_slide"
		State.WALL_CLIMBING:
			anim_name = form_prefix + "_wall_climb"

	# TODO: play animation via anim_player when AnimationPlayer is set up
	# if anim_player and anim_player.has_animation(anim_name):
	#     if anim_player.current_animation != anim_name:
	#         anim_player.play(anim_name)


# ── External Signals ─────────────────────────────────────

## Called when AbsorptionComponent changes the active form.
func _on_form_changed(_new_profile: MaterialProfile) -> void:
	# If we were absorbing, return to idle
	if _state == State.ABSORBING:
		_transition_to(State.IDLE)


## Called by dialogue system or cutscenes to freeze/unfreeze input.
func set_input_frozen(frozen: bool) -> void:
	_input_frozen = frozen
	if frozen:
		velocity = Vector2.ZERO


## Called by water trigger zones.
func set_in_water(in_water: bool, water_zone: WaterZone = null) -> void:
	_in_water = in_water
	_active_water_zone = water_zone


## Called by AbsorbableObject when Embe enters/exits its interaction range.
func set_nearby_absorbable(obj: Node) -> void:
	_nearby_absorbable = obj
	absorbable_in_range.emit(obj)


func clear_nearby_absorbable(obj: Node) -> void:
	if _nearby_absorbable == obj:
		_nearby_absorbable = null
		absorbable_out_of_range.emit()
		
func _change_state(new_state: State) -> void:
	print("[Embe] State: ", State.keys()[_state], " → ", State.keys()[new_state])
	_state = new_state

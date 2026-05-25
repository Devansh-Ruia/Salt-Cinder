## MaterialProfile — Custom resource defining a material form's physics and aesthetic properties.
## Each form Embe can absorb is described by one of these resources.
class_name MaterialProfile
extends Resource

@export_group("Identity")
@export var material_name: String

@export_group("Physics")
@export var move_speed: float = 200.0
@export var jump_force: float = 400.0
@export var gravity_scale: float = 1.0
@export var can_wall_climb: bool = false
@export var can_float: bool = false
@export var can_walk_underwater: bool = false

@export_group("Interaction Properties")
@export var is_flammable: bool = false
@export var light_reflective: bool = false
@export var impact_fragile: bool = false

@export_group("Audio")
@export var footstep_sound: AudioStream      # TODO: assign per form
@export var absorption_sound: AudioStream    # TODO: assign per form

@export_group("Visuals")
@export var ambient_color_modulate: Color = Color.WHITE  # scene light tint while form active
@export var sprite_shader_params: Dictionary = {}        # optional shader overrides

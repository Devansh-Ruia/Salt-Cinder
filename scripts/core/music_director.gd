## MusicDirector — Autoload that controls music playback based on GameState.
## Music does NOT autoplay on room load — it is triggered by conditions.
##
## ──────────────────────────────────────────────────────────
## Chapter 1: Stoneback Shelf — Emotional Cues
## ──────────────────────────────────────────────────────────
## Cue Name              | Trigger Condition                        | Mood
## ──────────────────────────────────────────────────────────
## "ch1_arrival"         | room_arrival loaded, first visit         | Desolate, wind-worn stillness
## "ch1_shelf_ambient"   | Exploring any room, no special state     | Low drone, distant tide, sparse melody
## "ch1_foundry_descent" | Entering room_foundry for the first time | Submerged heaviness, echoed drips
## "ch1_veld_encounter"  | Dialogue with Veld begins                | Quiet tension, plucked strings
## "ch1_veld_signs"      | Veld signs the petition                  | Bittersweet resolution, not triumph
## "ch1_foundry_cleared" | Foundry puzzle completed                 | Brief lift, then return to ambient
## "ch1_departure"       | Player exits Stoneback Shelf             | Fading, open — the sea ahead
## ──────────────────────────────────────────────────────────
extends Node

## The AudioStreamPlayer used for music. One at a time, crossfade later.
var _player: AudioStreamPlayer = null

## Currently playing cue name, or empty string if silent.
var _current_cue: String = ""

## Registry of cue names → AudioStream resources.
## Populated by _register_cues() or at runtime.
var _cue_registry: Dictionary = {}


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = "Music"  # TODO: ensure "Music" audio bus exists
	add_child(_player)
	_register_cues()


## Register all Chapter 1 cues. Streams are null until assets are created.
func _register_cues() -> void:
	# TODO: replace null with loaded AudioStream resources
	_cue_registry["ch1_arrival"] = null
	_cue_registry["ch1_shelf_ambient"] = null
	_cue_registry["ch1_foundry_descent"] = null
	_cue_registry["ch1_veld_encounter"] = null
	_cue_registry["ch1_veld_signs"] = null
	_cue_registry["ch1_foundry_cleared"] = null
	_cue_registry["ch1_departure"] = null


## Play a music cue by name. If the cue is already playing, does nothing.
## If a different cue is playing, stops it and starts the new one.
func play_cue(cue_name: String) -> void:
	if cue_name == _current_cue:
		return

	if not _cue_registry.has(cue_name):
		push_warning("MusicDirector: unknown cue '%s'." % cue_name)
		return

	var stream: AudioStream = _cue_registry[cue_name]
	if stream == null:
		push_warning("MusicDirector: cue '%s' has no AudioStream assigned (TODO)." % cue_name)
		_current_cue = cue_name
		return

	_player.stream = stream
	_player.play()
	_current_cue = cue_name


## Stop the currently playing music.
func stop() -> void:
	_player.stop()
	_current_cue = ""


## Returns the name of the currently active cue, or "" if silent.
func get_current_cue() -> String:
	return _current_cue

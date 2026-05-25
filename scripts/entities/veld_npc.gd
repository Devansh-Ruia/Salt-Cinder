## Veld — Stonemason NPC found in the Foundry (Chapter 1).
## Static character. Triggers dialogue on interact. Plays talking animation
## during dialogue, idle otherwise.
extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interact_range: Area2D = $InteractRange
@onready var dialogue_runner: DialogueRunner = $DialogueRunner

var _player_in_range: bool = false


func _ready() -> void:
	interact_range.body_entered.connect(_on_body_entered)
	interact_range.body_exited.connect(_on_body_exited)
	dialogue_runner.dialogue_started.connect(_on_dialogue_started)
	dialogue_runner.dialogue_ended.connect(_on_dialogue_ended)

	# TODO: play idle animation when sprite is set up
	# sprite.play("idle")


func _input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if dialogue_runner.is_running():
		return

	if event.is_action_pressed("interact"):
		# Set the veld_met flag the first time Embe talks to Veld
		if not GameState.has_flag("veld_met"):
			GameState.set_flag("veld_met")
		dialogue_runner.start()


func _on_dialogue_started() -> void:
	# TODO: sprite.play("talking")
	pass


func _on_dialogue_ended() -> void:
	# TODO: sprite.play("idle")
	pass


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("embe"):
		_player_in_range = true


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("embe"):
		_player_in_range = false

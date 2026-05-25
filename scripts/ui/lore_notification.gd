## LoreNotification — Small toast notification in the top-right corner.
## Auto-dismisses after 3 seconds. Displays lore entry title only.
extends PanelContainer

const DISPLAY_DURATION: float = 3.0
const SLIDE_DURATION: float = 0.25

@onready var title_label: Label = $MarginContainer/TitleLabel

var _dismiss_timer: float = 0.0
var _showing: bool = false


func _ready() -> void:
	visible = false
	modulate.a = 0.0


func _process(delta: float) -> void:
	if _showing:
		_dismiss_timer -= delta
		if _dismiss_timer <= 0.0:
			_hide_notification()


## Show the notification with a lore entry title.
func show_lore(entry: LoreEntry) -> void:
	title_label.text = entry.title
	_dismiss_timer = DISPLAY_DURATION
	_showing = true
	visible = true

	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, SLIDE_DURATION)


func _hide_notification() -> void:
	_showing = false
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, SLIDE_DURATION)
	await tween.finished
	visible = false

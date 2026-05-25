## DialogueChoice — A selectable option within a DialogueLine.
class_name DialogueChoice
extends Resource

## The text shown on the choice button.
@export var label: String = ""

## The line index to jump to when this choice is selected.
@export var next_line_index: int = -1

## Optional: a GameState flag to set when this choice is selected. Empty = no flag.
@export var sets_flag: String = ""

## DialogueLine — A single line of dialogue within a DialogueResource.
class_name DialogueLine
extends Resource

## The spoken text.
@export var text: String = ""

## Emotional tone for this line. Drives NPC animation and optional UI styling.
## Values: "neutral", "reluctant", "grief", "firm", "quiet", "distracted", etc.
@export var emotion: String = "neutral"

## Player-facing choices presented after this line. Empty = no branch (auto-advance).
@export var choices: Array[DialogueChoice] = []

## Index of the next line to display. -1 = end of dialogue.
@export var next_line_index: int = -1

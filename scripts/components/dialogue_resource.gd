## DialogueResource — Data container for a dialogue sequence.
## Each resource holds a speaker name and an ordered array of DialogueLines.
class_name DialogueResource
extends Resource

@export var speaker_name: String
@export var lines: Array[DialogueLine] = []

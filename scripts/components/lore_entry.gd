## LoreEntry — A collectible piece of world-building text.
## Every entry answers: what happened here, who was here, and what did they leave behind.
class_name LoreEntry
extends Resource

## Unique identifier for this entry, used in GameState.collected_lore.
@export var entry_id: String

## Title displayed in the lore notification and pause-menu journal (post-MVP).
@export var title: String

## The lore text itself, 2–4 sentences max, written in in-world voice.
@export_multiline var body_text: String

## Which island this lore originates from.
@export var island_origin: String

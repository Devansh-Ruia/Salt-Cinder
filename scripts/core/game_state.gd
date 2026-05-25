## GameState — Global state singleton (autoload).
## Tracks flags set by dialogue choices, collected lore, and chapter progress.
## No save/load yet — that's post-MVP.
extends Node

## String → bool flags set by dialogue, puzzle completion, NPC interactions, etc.
## Examples: "veld_met", "petition_signed_ch1", "foundry_cleared"
var flags: Dictionary = {}

## Array of lore entry IDs the player has collected.
var collected_lore: Array[String] = []

## Current chapter number. Chapter 1 = Stoneback Shelf.
var current_chapter: int = 1


## Set a flag to true.
func set_flag(key: String) -> void:
	print("[GameState] Flag set: ", key)
	flags[key] = true


## Check whether a flag has been set.
func has_flag(key: String) -> bool:
	return flags.get(key, false)


## Remove a flag entirely.
func clear_flag(key: String) -> void:
	flags.erase(key)


## Register a lore entry as collected if not already present.
## Returns true if the entry was newly added.
func collect_lore(entry_id: String) -> bool:
	if entry_id in collected_lore:
		return false
	collected_lore.append(entry_id)
	print("[GameState] Lore collected: ", entry_id)
	return true


## Check whether a lore entry has been collected.
func has_lore(entry_id: String) -> bool:
	return entry_id in collected_lore

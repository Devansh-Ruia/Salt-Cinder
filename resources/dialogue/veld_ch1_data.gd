## veld_ch1_data.gd — Builds Veld's Chapter 1 dialogue resource in code.
## Nested Resource arrays are painful to author in .tres format, so we
## construct the DialogueResource programmatically. Call build() to get it.
##
## ──────────────────────────────────────────────────────────
## Dialogue Map:
##
## Line 0: Veld's opening — measuring a wall that no longer exists
## Line 1: Veld continues, not waiting for a response
## Line 2: CHOICE — ask about the foundry / stay silent
## Line 3: (Ask path) Veld talks mortar ratios
## Line 4: (Ask path) Veld realizes he's been talking about grief
## Line 5: (Ask path) Veld catches himself, deflects
## Line 6: (Silent path) Veld notices the silence, respects it
## Line 7: (Silent path) Veld offers to help — no preamble
## Line 8: Shared — Veld's closing line before foundry puzzle
##
## POST-FOUNDRY (triggered after foundry_cleared flag is set):
## Line 9:  Veld recognizes the foundry is done
## Line 10: Veld signs the petition
## Line 11: Veld's farewell — Stoneback idiom, earned ending
## ──────────────────────────────────────────────────────────
class_name VeldCh1Data
extends RefCounted


static func build() -> DialogueResource:
	var res := DialogueResource.new()
	res.speaker_name = "Veld"

	var lines: Array[DialogueLine] = []

	# --- Line 0: Opening ---
	var l0 := DialogueLine.new()
	l0.text = "Fourteen by nine. Same as it was."
	l0.emotion = "distracted"
	l0.next_line_index = 1
	lines.append(l0)

	# --- Line 1: Still measuring ---
	var l1 := DialogueLine.new()
	l1.text = "The wall's been gone three tides now. I keep checking whether the numbers hold."
	l1.emotion = "quiet"
	l1.next_line_index = 2
	lines.append(l1)

	# --- Line 2: Choice branch ---
	var l2 := DialogueLine.new()
	l2.text = "..."
	l2.emotion = "neutral"

	var choice_ask := DialogueChoice.new()
	choice_ask.label = "What happened to this foundry?"
	choice_ask.next_line_index = 3
	choice_ask.sets_flag = "veld_asked_foundry"

	var choice_silent := DialogueChoice.new()
	choice_silent.label = "..."
	choice_silent.next_line_index = 6
	choice_silent.sets_flag = "veld_silence_respected"

	l2.choices = [choice_ask, choice_silent]
	lines.append(l2)

	# --- Line 3: Ask path — mortar ratios ---
	var l3 := DialogueLine.new()
	l3.text = "Three-to-oneite paste, quarter-weightiteite powder, and you cure it under salt cloth for — no. You didn't ask about the mortar."
	l3.emotion = "distracted"
	l3.next_line_index = 4
	lines.append(l3)

	# --- Line 4: Ask path — grief realized ---
	var l4 := DialogueLine.new()
	l4.text = "You asked what happened. That's — look, a shelf doesn't just crack. It gets tired. The stone gets tired of holding."
	l4.emotion = "grief"
	l4.next_line_index = 5
	lines.append(l4)

	# --- Line 5: Ask path — deflection ---
	var l5 := DialogueLine.new()
	l5.text = "Anyway. The lower section's flooded. You'll need weight to walk the bottom, then something that floats to get back up. If you're going."
	l5.emotion = "firm"
	l5.next_line_index = 8
	lines.append(l5)

	# --- Line 6: Silent path — Veld notices ---
	var l6 := DialogueLine.new()
	l6.text = "Hm. You're not the asking type. Good. The ones who ask usually aren't listening."
	l6.emotion = "reluctant"
	l6.next_line_index = 7
	lines.append(l6)

	# --- Line 7: Silent path — immediate offer ---
	var l7 := DialogueLine.new()
	l7.text = "The foundry's below. Flooded. Dense as a grudge down there. You'll need stone-weight for the bottom and something to ride the current back up."
	l7.emotion = "firm"
	l7.next_line_index = 8
	lines.append(l7)

	# --- Line 8: Shared closing ---
	var l8 := DialogueLine.new()
	l8.text = "I'll be here. Measuring."
	l8.emotion = "quiet"
	l8.next_line_index = -1
	lines.append(l8)

	# --- Line 9: Post-foundry — recognition ---
	var l9 := DialogueLine.new()
	l9.text = "It's clear, then. I felt the water drop. Didn't think the seals would hold after all this."
	l9.emotion = "quiet"
	l9.next_line_index = 10
	lines.append(l9)

	# --- Line 10: Signing the petition ---
	var l10 := DialogueLine.new()
	l10.text = "Give it here."
	l10.emotion = "firm"
	l10.next_line_index = 11
	lines.append(l10)

	# --- Line 11: Farewell — Stoneback idiom ---
	var l11 := DialogueLine.new()
	l11.text = "Still as the shelf, then. That's what we say when there's nothing left to fix and you're not ready to leave yet. Go on. I've gone soft enough for one tide."
	l11.emotion = "grief"
	l11.next_line_index = -1
	lines.append(l11)

	res.lines = lines
	return res

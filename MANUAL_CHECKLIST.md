# Manual Verification Checklist — Chapter 1 (Stoneback Shelf)

Headless runs cannot drive input, so a human must walk Embe through the rooms.
Launch from inside `new-game-project/`:

```bash
godot --path . res://scenes/world/chapter_01/room_arrival.tscn
```

Watch stdout for the `[RoomManager]` / `[DoorTrigger]` / `[RoomApproach]` traces.

## Movement & forms
- [ ] Embe moves left/right (A/D, arrows), jumps (Space/W).
- [ ] Walk into the WaterZone — buoyancy mode logs match the active form.
- [ ] Absorb (Q on an AbsorbableObject) swaps physics; release returns to basalt.

## Room transitions
- [ ] **Arrival → Approach:** walk into the door. Exactly **one**
      `Changing room → approach`, **one** `[RoomApproach] Re-armed 4 absorbable(s)`,
      **one** `[RoomApproach] Ready` — no escalation, no doubled lines.
- [ ] **After entering a room, Embe stays put** — it does **not** bounce straight
      back. You will see `'<door>' disarmed for spawn` then
      `'<door>' entered while disarmed — ignoring (spawn overlap)`. Embe should
      only transition again once **you walk back into the door** (which logs
      `'<door>' re-armed` on exit first).
- [ ] **Approach → Foundry** and back, **Approach → Arrival** and back: each
      crossing is a single, clean transition. The return door is the same door
      you spawned on, so it must arm only after you step off it.
- [ ] At no point do `[WaterZone]` / `entered` / `Re-armed` lines fire 2×.
- [ ] After several round trips the game still behaves identically (no creeping
      slowdown, no duplicated detections) — confirms no leaked Embe or rooms.

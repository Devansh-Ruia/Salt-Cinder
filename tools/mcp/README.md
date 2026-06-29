# Salt & Cinder Godot MCP

`salt_cinder_godot` is a Salt & Cinder Codex MCP server for repeatable Godot inspection and limited runtime validation. The server source is tracked in this repo at `tools/mcp/salt_cinder_godot_mcp.py`. It exists because Salt & Cinder has project-specific rules that generic file search misses: the wrapper repository is not the game repository, Embe is bootstrapped persistently, rooms are registered through `RoomManager`, forms are `MaterialProfile` resources, and Chapter 1 teaching depends on runtime signals.

## Nested Repo Warning

The game repository is `C:/Users/super/Desktop/Desktop/saltandcinder/new-game-project`, not the wrapper `saltandcinder/` directory. Active Codex MCP config now lives at `C:/Users/super/.codex/config.toml`, and active command rules live at `C:/Users/super/.codex/rules/salt_cinder.rules`. Project-local `.codex/config.toml` and `.codex/rules/` are intentionally not used.

## Tool List

- Project and convention inspection: `project_summary`, `agents_digest`, `inspect_project_godot`
- Static Godot inspection: `inspect_scene`, `inspect_material_profiles`, `inspect_room_registry`, `inspect_inputs`, `inspect_physics_layers`
- Architecture checks: `inspect_bootstrap_integrity`, `inspect_teaching_route`
- Logs and runtime validation: `parse_godot_log`, `list_recent_runtime_logs`, `godot_version`, `godot_check_script`, `godot_run_chapter_01`, `godot_run_scene`
- Repository status: `git_status`

## Safety Model

The server is not a gameplay editing layer. Inspection tools read only inside `new-game-project/`. Runtime tools use local subprocess calls and may write logs only under `logs/mcp/`. The server never deletes files, commits changes, edits scenes, edits scripts, changes physics layers, or rewrites resources.

Godot runtime tools require prompt approval in the user-level Codex config because they run local commands. The user-level config hard-binds the server to the Salt & Cinder project root with `cwd` and `SALT_CINDER_PROJECT_ROOT`; the repo-tracked script also resolves the same root when launched from `tools/mcp/`.

## Codex Loading

Codex loads the MCP from `C:/Users/super/.codex/config.toml`. The active server entry points directly to the repo-tracked source:

```toml
[mcp_servers.salt_cinder_godot]
command = "uv"
args = [
  "run",
  "--with",
  "mcp[cli]",
  "python",
  "C:/Users/super/Desktop/Desktop/saltandcinder/new-game-project/tools/mcp/salt_cinder_godot_mcp.py"
]
cwd = "C:/Users/super/Desktop/Desktop/saltandcinder/new-game-project"

[mcp_servers.salt_cinder_godot.env]
SALT_CINDER_PROJECT_ROOT = "C:/Users/super/Desktop/Desktop/saltandcinder/new-game-project"
```

If Codex MCP status tooling is available, run `codex mcp get salt_cinder_godot` to confirm that the server is visible and points at the repo script. With MCP Inspector, point the command at the same `uv run --with mcp[cli] python C:/Users/super/Desktop/Desktop/saltandcinder/new-game-project/tools/mcp/salt_cinder_godot_mcp.py` startup command.

## Godot Validation

Use `godot_version` first to confirm the Godot binary is available. Use `godot_check_script` for a focused syntax check, for example `scripts/entities/embe_controller.gd`. Use `godot_run_chapter_01` or `godot_run_scene` only after approval; both stop after a timeout and store output in `logs/mcp/`.

## Known Limitations

Static scene analysis cannot prove puzzle comprehension, camera framing, or runtime signal timing. Godot `.tscn` parsing is text-based and intentionally conservative. The runtime tools depend on a working local Godot binary on `PATH` or a supplied executable path.

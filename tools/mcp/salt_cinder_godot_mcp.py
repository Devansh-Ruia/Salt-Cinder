from __future__ import annotations

import re
import subprocess
from datetime import datetime
from pathlib import Path
from typing import Any

from mcp.server.fastmcp import FastMCP


SERVER_INSTRUCTIONS = """Salt & Cinder Godot MCP. Use this server for Godot-specific inspection and runtime validation only. Prefer read-only tools before edits. Do not use this server to write gameplay files. Preserve the nested `new-game-project/` repo boundary, persistent Embe bootstrap architecture, RoomManager room registry, MaterialProfile-driven forms, signal-based communication, AGENTS.md conventions, and physics layer discipline. Runtime boot checks are more reliable than static guesses.

Use project_summary before architectural changes. Use inspect_bootstrap_integrity, inspect_material_profiles, inspect_room_registry, inspect_inputs, inspect_physics_layers, and inspect_teaching_route before changing Chapter 1 puzzle flow. Use Godot runtime tools after edits when available. Treat warnings separately from errors. Report exact commands, logs, and limitations."""

EXPECTED_INPUTS = ["move_left", "move_right", "jump", "interact", "absorb_release"]
EXPECTED_MATERIALS = ["basalt", "driftwood", "coral", "seaglass"]
CORE_DIRS = [
    "scripts/core",
    "scripts/components",
    "scripts/entities",
    "scripts/ui",
    "scripts/world",
    "scenes/world/chapter_01",
    "scenes/entities",
    "scenes/ui",
    "scenes/components",
    "resources",
    "assets",
    "tests",
]

PROJECT_ROOT = Path(__file__).resolve().parents[2]
mcp = FastMCP("salt_cinder_godot", instructions=SERVER_INSTRUCTIONS)


def _rel(path: Path) -> str:
    try:
        return path.resolve().relative_to(PROJECT_ROOT).as_posix()
    except ValueError:
        return str(path)


def _read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def _read_project_file(relative_path: str) -> str:
    return _read_text(PROJECT_ROOT / relative_path)


def _exists(relative_path: str) -> bool:
    return (PROJECT_ROOT / relative_path).exists()


def _safe_resolve(user_path: str, *, suffix: str | None = None, must_exist: bool = True) -> Path:
    if not user_path or not str(user_path).strip():
        raise ValueError("Path is required.")

    raw = str(user_path).strip()
    if raw.startswith("res://"):
        candidate = PROJECT_ROOT / raw.removeprefix("res://")
    else:
        path = Path(raw)
        candidate = path if path.is_absolute() else PROJECT_ROOT / path

    resolved = candidate.resolve(strict=False)
    try:
        resolved.relative_to(PROJECT_ROOT)
    except ValueError as exc:
        raise ValueError(f"Path must stay inside project root: {user_path}") from exc

    if suffix and resolved.suffix.lower() != suffix.lower():
        raise ValueError(f"Path must end with {suffix}: {user_path}")
    if must_exist and not resolved.exists():
        raise FileNotFoundError(f"Path does not exist: {_rel(resolved)}")
    if must_exist and not resolved.is_file():
        raise ValueError(f"Path must be a file: {_rel(resolved)}")
    return resolved


def _to_res_path(path: Path) -> str:
    return "res://" + path.resolve().relative_to(PROJECT_ROOT).as_posix()


def _parse_attrs(text: str) -> dict[str, str]:
    return {match.group(1): match.group(2) for match in re.finditer(r'(\w+)="([^"]*)"', text)}


def _sections(text: str) -> dict[str, list[str]]:
    sections: dict[str, list[str]] = {}
    current = ""
    for line in text.splitlines():
        header = re.match(r"^\[([^\]]+)\]\s*$", line.strip())
        if header:
            current = header.group(1)
            sections.setdefault(current, [])
            continue
        sections.setdefault(current, []).append(line)
    return sections


def _section_kv(lines: list[str]) -> dict[str, str]:
    data: dict[str, str] = {}
    for line in lines:
        if line.strip().startswith(";"):
            continue
        match = re.match(r"^([A-Za-z0-9_./-]+)\s*=\s*(.+?)\s*$", line.strip())
        if match:
            data[match.group(1)] = match.group(2)
    return data


def _strip_godot_value(value: str) -> str:
    value = value.strip()
    if value.startswith('"') and value.endswith('"'):
        return value[1:-1]
    return value


def _load_project_godot() -> tuple[str, dict[str, list[str]]]:
    path = PROJECT_ROOT / "project.godot"
    text = _read_text(path) if path.exists() else ""
    return text, _sections(text)


def _project_godot_summary() -> dict[str, Any]:
    text, sections = _load_project_godot()
    application = _section_kv(sections.get("application", []))
    autoloads = {
        key: _strip_godot_value(value).lstrip("*")
        for key, value in _section_kv(sections.get("autoload", [])).items()
    }
    input_actions = _parse_input_actions(text)
    physics_layers = _parse_physics_layers(text)
    features = application.get("config/features", "")
    version_match = re.search(r'"([^"]+)"', features)
    return {
        "application": {key: _strip_godot_value(value) for key, value in application.items()},
        "main_scene": _strip_godot_value(application.get("run/main_scene", "")) or None,
        "autoloads": autoloads,
        "input_actions": input_actions,
        "physics_layers": physics_layers,
        "godot_version": version_match.group(1) if version_match else None,
    }


def _parse_input_actions(project_text: str) -> list[str]:
    sections = _sections(project_text)
    actions: list[str] = []
    for line in sections.get("input", []):
        match = re.match(r"^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*\{", line.strip())
        if match:
            actions.append(match.group(1))
    return actions


def _parse_physics_layers(project_text: str) -> dict[str, str]:
    layers: dict[str, str] = {}
    for match in re.finditer(r'2d_physics/layer_(\d+)\s*=\s*"([^"]*)"', project_text):
        layers[match.group(1)] = match.group(2)
    return layers


def _list_agents_files() -> list[Path]:
    return sorted(PROJECT_ROOT.rglob("AGENTS.md"))


def _line_hits(text: str, pattern: str, *, flags: int = re.IGNORECASE, limit: int = 50) -> list[dict[str, Any]]:
    hits: list[dict[str, Any]] = []
    regex = re.compile(pattern, flags)
    for number, line in enumerate(text.splitlines(), start=1):
        if regex.search(line):
            hits.append({"line": number, "text": line.strip()})
            if len(hits) >= limit:
                break
    return hits


def _scene_files(relative_dir: str) -> list[Path]:
    base = PROJECT_ROOT / relative_dir
    if not base.exists():
        return []
    return sorted(base.rglob("*.tscn"))


def _parse_ext_resources(text: str) -> list[dict[str, str]]:
    resources: list[dict[str, str]] = []
    for match in re.finditer(r"^\[ext_resource\s+([^\]]+)\]", text, flags=re.MULTILINE):
        resources.append(_parse_attrs(match.group(1)))
    return resources


def _parse_nodes(text: str) -> list[dict[str, Any]]:
    nodes: list[dict[str, Any]] = []
    for match in re.finditer(r"^\[node\s+([^\]]+)\]", text, flags=re.MULTILINE):
        attrs = _parse_attrs(match.group(1))
        groups: list[str] = []
        group_match = re.search(r"groups=\[([^\]]*)\]", match.group(1))
        if group_match:
            groups = re.findall(r'"([^"]+)"', group_match.group(1))
        nodes.append(
            {
                "name": attrs.get("name"),
                "type": attrs.get("type"),
                "parent": attrs.get("parent"),
                "instance": attrs.get("instance"),
                "groups": groups,
            }
        )
    return nodes


def _resolve_resource_path(path_value: str) -> Path | None:
    if not path_value or not path_value.startswith("res://"):
        return None
    return (PROJECT_ROOT / path_value.removeprefix("res://")).resolve(strict=False)


def _parse_scene_file(path: Path) -> dict[str, Any]:
    text = _read_text(path)
    ext_resources = _parse_ext_resources(text)
    nodes = _parse_nodes(text)
    script_paths = sorted(
        resource["path"]
        for resource in ext_resources
        if resource.get("type") == "Script" and resource.get("path")
    )
    missing: list[str] = []
    for resource in ext_resources:
        res_path = _resolve_resource_path(resource.get("path", ""))
        if res_path and not res_path.exists():
            missing.append(resource["path"])
    groups = sorted({group for node in nodes for group in node.get("groups", [])})
    return {
        "scene_path": _rel(path),
        "root_node_name_type": nodes[0] if nodes else None,
        "external_resources": ext_resources,
        "scripts_referenced": script_paths,
        "node_names_types": nodes,
        "groups": groups,
        "missing_referenced_resources_scripts": sorted(missing),
        "warnings": _scene_warnings(path, nodes, missing),
    }


def _scene_warnings(path: Path, nodes: list[dict[str, Any]], missing: list[str]) -> list[str]:
    warnings: list[str] = []
    if not nodes:
        warnings.append("No [node] entries detected.")
    if missing:
        warnings.append("One or more referenced resources/scripts are missing.")
    if path.name.startswith("room_") and 'res://scenes/entities/embe/embe.tscn' in _read_text(path):
        warnings.append("Room scene appears to instance Embe; this may violate the persistent bootstrap pattern.")
    return warnings


def _parse_tres_fields(text: str) -> dict[str, str]:
    fields: dict[str, str] = {}
    for line in text.splitlines():
        match = re.match(r"^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+?)\s*$", line.strip())
        if match:
            fields[match.group(1)] = match.group(2)
    return fields


def _normalize_name(value: str) -> str:
    return re.sub(r"[^a-z0-9]", "", value.lower())


def _material_profile_files() -> list[Path]:
    resources = PROJECT_ROOT / "resources"
    if not resources.exists():
        return []
    files: list[Path] = []
    for path in sorted(resources.rglob("*.tres")):
        text = _read_text(path)
        if "MaterialProfile" in text or "material_profile.gd" in text:
            files.append(path)
    return files


def _inspect_material_file(path: Path) -> dict[str, Any]:
    text = _read_text(path)
    fields = _parse_tres_fields(text)
    material_name = _strip_godot_value(fields.get("material_name", ""))
    physics_keys = [
        key
        for key in fields
        if any(token in key.lower() for token in ["speed", "jump", "gravity", "can_", "fragile", "flammable", "reflective"])
    ]
    absorb_keys = [key for key in fields if "absorb" in key.lower() or "release" in key.lower()]
    warnings: list[str] = []
    if not material_name:
        warnings.append("No material_name field detected.")
    return {
        "path": _rel(path),
        "id_name_fields": {"material_name": material_name} if material_name else {},
        "form_material_identifier": material_name or path.stem,
        "movement_physics_like_fields": {key: fields[key] for key in physics_keys},
        "absorb_release_related_fields": {key: fields[key] for key in absorb_keys},
        "warnings": warnings,
    }


def _room_registry_entries() -> list[dict[str, str]]:
    manager = PROJECT_ROOT / "scripts/core/room_manager.gd"
    if not manager.exists():
        return []
    text = _read_text(manager)
    entries: list[dict[str, str]] = []
    for match in re.finditer(r'register_room\(\s*"([^"]+)"\s*,\s*"([^"]+)"\s*\)', text):
        entries.append({"room": match.group(1), "path": match.group(2)})
    return entries


def _safe_command_text(command: list[str]) -> str:
    return " ".join(command)


def _parse_log_text(text: str) -> dict[str, Any]:
    error_pattern = r"\b(error|failed|failure|fatal|cannot|can't|invalid call)\b|SCRIPT ERROR"
    warning_pattern = r"\b(warning|warn|push_warning)\b"
    parse_pattern = r"\b(parse error|parser error|expected|unexpected)\b"
    script_pattern = r"SCRIPT ERROR|Invalid call|Invalid get index|Attempt to|GDScript"
    load_pattern = r"Resource file not found|Failed loading resource|Can't load|Cannot open|scene.*not found"
    transition_pattern = r"Transition already in progress|Changing room|Room loaded|door_id .* not found"
    embe_dup_pattern = r"duplicate.*Embe|multiple.*Embe|Embe.*duplicate|already.*embe"
    absorbing_pattern = r"ABSORBING|absorb.*freeze|stuck.*absorb|absorb.*stuck"
    errors = _line_hits(text, error_pattern)
    warnings = _line_hits(text, warning_pattern)
    parse_errors = _line_hits(text, parse_pattern)
    script_errors = _line_hits(text, script_pattern)
    load_errors = _line_hits(text, load_pattern)
    transition_hints = _line_hits(text, transition_pattern)
    embe_dup_hints = _line_hits(text, embe_dup_pattern)
    absorbing_hints = _line_hits(text, absorbing_pattern)
    return {
        "errors": errors,
        "warnings": warnings,
        "parse_errors": parse_errors,
        "script_errors": script_errors,
        "scene_resource_load_errors": load_errors,
        "transition_loop_hints": transition_hints,
        "embe_duplication_hints": embe_dup_hints,
        "absorbing_freeze_hints": absorbing_hints,
        "summarized_counts": {
            "errors": len(errors),
            "warnings": len(warnings),
            "parse_errors": len(parse_errors),
            "script_errors": len(script_errors),
            "scene_resource_load_errors": len(load_errors),
            "transition_loop_hints": len(transition_hints),
            "embe_duplication_hints": len(embe_dup_hints),
            "absorbing_freeze_hints": len(absorbing_hints),
        },
    }


def _run_command(command: list[str], *, timeout: int | None = None, write_log: Path | None = None) -> dict[str, Any]:
    timed_out = False
    stdout = ""
    stderr = ""
    exit_code: int | None = None
    try:
        completed = subprocess.run(
            command,
            cwd=PROJECT_ROOT,
            capture_output=True,
            text=True,
            timeout=timeout,
            check=False,
        )
        stdout = completed.stdout
        stderr = completed.stderr
        exit_code = completed.returncode
    except subprocess.TimeoutExpired as exc:
        timed_out = True
        stdout = exc.stdout or ""
        stderr = exc.stderr or ""
    except FileNotFoundError as exc:
        exit_code = 127
        stderr = str(exc)

    combined = stdout
    if stderr:
        combined = combined + ("\n" if combined else "") + stderr
    if write_log:
        write_log.parent.mkdir(parents=True, exist_ok=True)
        write_log.write_text(combined, encoding="utf-8")
    result: dict[str, Any] = {
        "command": _safe_command_text(command),
        "exit_code": exit_code,
        "stdout": stdout,
        "stderr": stderr,
    }
    if timeout is not None:
        result["timeout_used"] = timed_out
    if write_log:
        result["log_path"] = _rel(write_log)
    return result


def _timestamp() -> str:
    return datetime.now().strftime("%Y%m%d_%H%M%S")


def _safe_log_name(value: str) -> str:
    cleaned = re.sub(r"[^A-Za-z0-9_.-]+", "_", value)
    return cleaned.strip("_")[:80] or "scene"


@mcp.tool()
def project_summary() -> dict[str, Any]:
    """Summarize the Salt & Cinder Godot project shape and nested repo status."""
    warnings: list[str] = []
    cwd = Path.cwd().resolve()
    parent = PROJECT_ROOT.parent
    wrapper_name = _normalize_name(parent.name)
    is_project = PROJECT_ROOT.name == "new-game-project" and (PROJECT_ROOT / "project.godot").exists()
    project = _project_godot_summary()
    agents_files = [_rel(path) for path in _list_agents_files()]
    core_dirs = {path: (PROJECT_ROOT / path).is_dir() for path in CORE_DIRS}
    tests_path = PROJECT_ROOT / "tests"
    tests_files = [path for path in tests_path.rglob("*") if path.is_file()] if tests_path.exists() else []
    if not is_project:
        warnings.append("Project root does not look like new-game-project with project.godot.")
    if wrapper_name != "saltcinder":
        warnings.append("Wrapper parent name does not normalize to Salt&Cinder.")
    if not (PROJECT_ROOT / ".git").exists():
        warnings.append(".git directory not found inside new-game-project.")
    if not project["main_scene"]:
        warnings.append("No run/main_scene detected in project.godot.")
    missing_inputs = [action for action in EXPECTED_INPUTS if action not in project["input_actions"]]
    if missing_inputs:
        warnings.append("Missing expected input actions: " + ", ".join(missing_inputs))
    return {
        "detected_current_working_directory": str(cwd),
        "project_root_path": str(PROJECT_ROOT),
        "appears_to_be_new_game_project": is_project,
        "wrapper_parent_detected": wrapper_name == "saltcinder",
        "wrapper_parent_path": str(parent),
        "new_game_project_git_exists": (PROJECT_ROOT / ".git").exists(),
        "project_godot_path": _rel(PROJECT_ROOT / "project.godot"),
        "detected_godot_version": project["godot_version"],
        "detected_main_scene": project["main_scene"],
        "autoloads": project["autoloads"],
        "input_actions": project["input_actions"],
        "detected_agents_md_files": agents_files,
        "core_directories_present": core_dirs,
        "tests_exists": tests_path.exists(),
        "tests_empty": tests_path.exists() and not tests_files,
        "warnings": warnings,
    }


@mcp.tool()
def agents_digest() -> dict[str, Any]:
    """Read AGENTS.md files and extract concise project conventions."""
    expected = ["AGENTS.md", "scripts/AGENTS.md", "scenes/AGENTS.md"]
    paths = _list_agents_files()
    warnings = [f"Missing expected guide: {path}" for path in expected if not _exists(path)]
    conventions: list[dict[str, Any]] = []
    for path in paths:
        text = _read_text(path)
        bullets: list[str] = []
        for pattern in [
            r"autoload|singleton|RoomManager|GameState",
            r"signal|signals",
            r"MaterialProfile|resource|\.tres",
            r"snake_case|PascalCase|typing|typed",
            r"scene|Node2D|Area2D|CharacterBody2D|TileMapLayer",
            r"physics layer|input action|embe",
        ]:
            hits = _line_hits(text, pattern, limit=4)
            bullets.extend(hit["text"] for hit in hits)
        conventions.append({"path": _rel(path), "conventions": sorted(set(bullets))[:18]})
    return {"paths": [_rel(path) for path in paths], "concise_extracted_conventions": conventions, "warnings": warnings}


@mcp.tool()
def inspect_project_godot() -> dict[str, Any]:
    """Parse project.godot for application, autoload, input, and layer data."""
    project = _project_godot_summary()
    missing_inputs = [action for action in EXPECTED_INPUTS if action not in project["input_actions"]]
    warnings = []
    if missing_inputs:
        warnings.append("Missing expected inputs: " + ", ".join(missing_inputs))
    return {
        "application_config": project["application"],
        "main_scene": project["main_scene"],
        "autoloads": project["autoloads"],
        "input_actions": project["input_actions"],
        "physics_layer_names": project["physics_layers"],
        "warnings": warnings,
    }


@mcp.tool()
def inspect_scene(scene_path: str) -> dict[str, Any]:
    """Inspect a .tscn scene without editing it."""
    path = _safe_resolve(scene_path, suffix=".tscn")
    return _parse_scene_file(path)


@mcp.tool()
def inspect_material_profiles() -> dict[str, Any]:
    """Scan resources/ for MaterialProfile .tres files and key physics fields."""
    profiles = [_inspect_material_file(path) for path in _material_profile_files()]
    found = {_normalize_name(profile["form_material_identifier"]) for profile in profiles}
    missing = [name for name in EXPECTED_MATERIALS if name not in found]
    warnings = []
    if missing:
        warnings.append("Missing expected MaterialProfile forms: " + ", ".join(missing))
    return {"profiles": profiles, "warnings": warnings}


@mcp.tool()
def inspect_room_registry() -> dict[str, Any]:
    """Inspect RoomManager room registry and world room scene references."""
    manager = PROJECT_ROOT / "scripts/core/room_manager.gd"
    text = _read_text(manager) if manager.exists() else ""
    entries = _room_registry_entries()
    missing: list[dict[str, str]] = []
    for entry in entries:
        path = _resolve_resource_path(entry["path"])
        if path and not path.exists():
            missing.append(entry)
    candidates: list[dict[str, Any]] = []
    for hit in _line_hits(text, r"res://.*\.tscn", limit=100):
        paths = re.findall(r'"(res://[^"]+\.tscn)"', hit["text"])
        for path_value in paths:
            candidates.append(
                {
                    "path": path_value,
                    "line": hit["line"],
                    "in_register_room_call": "register_room" in hit["text"],
                }
            )
    warnings = []
    non_registry = [item for item in candidates if not item["in_register_room_call"]]
    if missing:
        warnings.append("Room registry references missing scene paths.")
    if non_registry:
        warnings.append("Hardcoded scene path candidates outside register_room calls detected.")
    return {
        "room_manager_script_path": _rel(manager) if manager.exists() else None,
        "room_registry_entries": entries,
        "room_scene_files_under_scenes_world": [_rel(path) for path in _scene_files("scenes/world")],
        "missing_scene_paths_referenced_by_registry": missing,
        "hardcoded_scene_path_candidates": candidates,
        "warnings": warnings,
    }


@mcp.tool()
def inspect_inputs() -> dict[str, Any]:
    """Inspect expected Salt & Cinder input actions in project.godot."""
    project = _project_godot_summary()
    expected = {action: action in project["input_actions"] for action in EXPECTED_INPUTS}
    warnings = [f"Missing expected input action: {action}" for action, present in expected.items() if not present]
    return {"expected_actions": expected, "raw_action_names_found": project["input_actions"], "warnings": warnings}


@mcp.tool()
def inspect_physics_layers() -> dict[str, Any]:
    """Inspect named 2D physics layers and Embe collision settings."""
    project_text, _ = _load_project_godot()
    layers = _parse_physics_layers(project_text)
    embe_scene = PROJECT_ROOT / "scenes/entities/embe/embe.tscn"
    embe_text = _read_text(embe_scene) if embe_scene.exists() else ""
    embe_block = ""
    match = re.search(r'^\[node name="Embe"[^\]]*\](.*?)(?=^\[node|\Z)', embe_text, flags=re.MULTILINE | re.DOTALL)
    if match:
        embe_block = match.group(1)
    layer_match = re.search(r"collision_layer\s*=\s*(\d+)", embe_block)
    mask_match = re.search(r"collision_mask\s*=\s*(\d+)", embe_block)
    embe_layer = int(layer_match.group(1)) if layer_match else None
    embe_mask = int(mask_match.group(1)) if mask_match else None
    trigger_layers = {number: name for number, name in layers.items() if name in {"triggers", "interactables"}}
    risks: list[str] = []
    warnings: list[str] = []
    if layers.get("1") != "terrain" or layers.get("2") != "entities":
        warnings.append("Expected terrain/entities layer names are not in slots 1 and 2.")
    if layers.get("3") != "triggers" or layers.get("4") != "interactables":
        warnings.append("Expected triggers/interactables layer names are not in slots 3 and 4.")
    if embe_layer != 2:
        warnings.append("Embe collision_layer is not explicitly layer 2 (entities).")
    if embe_mask is None:
        risks.append("Embe collision_mask is omitted in the scene; Godot default behavior must be considered.")
    return {
        "named_2d_physics_layers": layers,
        "embe_collision_layer": embe_layer,
        "embe_collision_mask": embe_mask,
        "trigger_interactable_layer_names": trigger_layers,
        "likely_trigger_detection_risks": risks,
        "warnings_if_embe_layer_discipline_looks_suspicious": warnings,
    }


@mcp.tool()
def inspect_bootstrap_integrity() -> dict[str, Any]:
    """Inspect persistent Embe bootstrap and RoomManager transition integrity."""
    main = PROJECT_ROOT / "scenes/main.tscn"
    bootstrap = PROJECT_ROOT / "scripts/core/bootstrap.gd"
    manager = PROJECT_ROOT / "scripts/core/room_manager.gd"
    embe_scene = PROJECT_ROOT / "scenes/entities/embe/embe.tscn"
    controller = PROJECT_ROOT / "scripts/entities/embe_controller.gd"
    texts = {
        "main": _read_text(main) if main.exists() else "",
        "bootstrap": _read_text(bootstrap) if bootstrap.exists() else "",
        "manager": _read_text(manager) if manager.exists() else "",
        "embe_scene": _read_text(embe_scene) if embe_scene.exists() else "",
        "controller": _read_text(controller) if controller.exists() else "",
    }
    room_embeds = []
    for scene in _scene_files("scenes/world/chapter_01"):
        text = _read_text(scene)
        if "res://scenes/entities/embe/embe.tscn" in text:
            room_embeds.append(_rel(scene))
    persistent = all(
        [
            "res://scripts/core/bootstrap.gd" in texts["main"],
            "res://scenes/entities/embe/embe.tscn" in texts["main"],
            "change_room.call_deferred" in texts["bootstrap"],
            "_adopt_embe" in texts["manager"],
            "reparent(root)" in texts["manager"] or "root.add_child(_embe)" in texts["manager"],
        ]
    )
    warnings = []
    if room_embeds:
        warnings.append("One or more Chapter 1 rooms appear to embed Embe.")
    if "_is_transitioning" not in texts["manager"]:
        warnings.append("RoomManager transition re-entry guard not detected.")
    return {
        "persistent_embe_bootstrap_pattern_appears_present": persistent,
        "embe_scene_appears_to_use_embe_group": 'add_to_group("embe")' in texts["controller"] or 'groups=["embe"]' in texts["embe_scene"],
        "room_manager_appears_to_carry_reparent_embe": "_embe" in texts["manager"] and "_adopt_embe" in texts["manager"],
        "direct_room_debug_fallback_appears_present": "spawn_debug_player_if_absent" in texts["manager"],
        "duplication_risks": room_embeds,
        "transition_loop_risks": [] if "_is_transitioning" in texts["manager"] and "disarm_for_spawn" in texts["manager"] else ["Transition guard or spawn door disarm not detected."],
        "hardcoded_path_risks": [item for item in inspect_room_registry()["hardcoded_scene_path_candidates"] if not item["in_register_room_call"]],
        "warnings": warnings,
    }


@mcp.tool()
def inspect_teaching_route() -> dict[str, Any]:
    """Statically inspect Chapter 1 teaching cues and route comprehension risks."""
    room_scenes = _scene_files("scenes/world/chapter_01")
    room_data: list[dict[str, Any]] = []
    all_room_text = ""
    for scene in room_scenes:
        text = _read_text(scene)
        all_room_text += "\n" + text
        materials = sorted(set(re.findall(r"resources/materials/([A-Za-z0-9_]+)\.tres", text)))
        room_data.append({"path": _rel(scene), "materials_referenced": materials})

    teaching_paths = [
        "scripts/ui/teaching_director.gd",
        "scripts/ui/prompt_glyph.gd",
        "scripts/ui/form_indicator.gd",
        "scripts/components/absorbable_object.gd",
    ]
    teaching_text = "\n".join(_read_project_file(path) for path in teaching_paths if _exists(path))
    materials_text = "\n".join(_read_text(path) for path in _material_profile_files())
    flags = sorted(set(re.findall(r'"(taught_[A-Za-z0-9_]+)"', teaching_text)))
    coral_before_wall: bool | None = None
    foundry = PROJECT_ROOT / "scenes/world/chapter_01/room_foundry.tscn"
    uncertainty: list[str] = ["This is static analysis; runtime positioning, camera framing, and player comprehension require playtesting."]
    if foundry.exists():
        foundry_text = _read_text(foundry)
        coral = re.search(r'\[node name="CoralObject"[^\]]*\].*?position\s*=\s*Vector2\(([-\d.]+),\s*([-\d.]+)\)', foundry_text, re.DOTALL)
        wall = re.search(r'\[node name="ClimbWallBody"[^\]]*\].*?position\s*=\s*Vector2\(([-\d.]+),\s*([-\d.]+)\)', foundry_text, re.DOTALL)
        if coral and wall:
            coral_before_wall = float(coral.group(1)) <= float(wall.group(1))
        else:
            uncertainty.append("Could not confidently compare CoralObject and climb wall positions.")
    risks: list[str] = []
    if "can_float = true" not in materials_text:
        risks.append("No can_float MaterialProfile detected for driftwood teaching.")
    if "can_wall_climb = true" not in materials_text:
        risks.append("No can_wall_climb MaterialProfile detected for coral teaching.")
    if "_float_glyph" not in teaching_text or "_climb_glyph" not in teaching_text:
        risks.append("TeachingDirector float/climb glyph channels were not both detected.")
    return {
        "likely_chapter_1_route_scenes": room_data,
        "driftwood_teaching_cues_detected": {
            "resource": "driftwood.tres" in all_room_text and "Driftwood" in materials_text,
            "can_float": "can_float = true" in materials_text,
            "float_glyph": "_float_glyph" in teaching_text,
        },
        "coral_teaching_cues_detected": {
            "resource": "coral.tres" in all_room_text and "Coral" in materials_text,
            "can_wall_climb": "can_wall_climb = true" in materials_text,
            "climb_glyph": "_climb_glyph" in teaching_text,
        },
        "prompt_glyph_usage": _line_hits(teaching_text, r"PromptGlyph|PROMPT_GLYPH_SCENE|_make_glyph", limit=30),
        "one_shot_gamestate_teaching_flags": flags,
        "form_indicator_references": _line_hits(teaching_text, r"FormIndicator|FORM_INDICATOR_SCENE|form_indicator", limit=20),
        "coral_absorbable_appears_before_wall_climb": coral_before_wall,
        "comprehension_risks": risks,
        "uncertainty_notes": uncertainty,
    }


@mcp.tool()
def parse_godot_log(log_path: str) -> dict[str, Any]:
    """Parse a Godot log file inside the project for common Salt & Cinder issues."""
    path = _safe_resolve(log_path)
    parsed = _parse_log_text(_read_text(path))
    parsed["log_path"] = _rel(path)
    return parsed


@mcp.tool()
def list_recent_runtime_logs() -> dict[str, Any]:
    """List recent files under logs/ and logs/mcp/ only."""
    bases = [PROJECT_ROOT / "logs", PROJECT_ROOT / "logs/mcp"]
    seen: set[Path] = set()
    entries: list[dict[str, Any]] = []
    for base in bases:
        if not base.exists():
            continue
        for path in base.rglob("*"):
            if not path.is_file() or path in seen:
                continue
            seen.add(path)
            stat = path.stat()
            entries.append(
                {
                    "path": _rel(path),
                    "size": stat.st_size,
                    "modified_timestamp": datetime.fromtimestamp(stat.st_mtime).isoformat(timespec="seconds"),
                }
            )
    entries.sort(key=lambda item: item["modified_timestamp"], reverse=True)
    return {"paths": entries}


@mcp.tool()
def godot_version(godot_bin: str = "godot") -> dict[str, Any]:
    """Run godot --version from the project root."""
    return _run_command([godot_bin, "--version"])


@mcp.tool()
def godot_check_script(script_path: str, godot_bin: str = "godot") -> dict[str, Any]:
    """Run Godot's headless script syntax check for a project-local .gd script."""
    path = _safe_resolve(script_path, suffix=".gd")
    script_arg = script_path if script_path.startswith("res://") else _rel(path)
    result = _run_command([godot_bin, "--headless", "--check-only", "--script", script_arg])
    result["parsed_warnings_errors"] = _parse_log_text(result.get("stdout", "") + "\n" + result.get("stderr", ""))
    return result


@mcp.tool()
def godot_run_chapter_01(seconds: int = 8, godot_bin: str = "godot") -> dict[str, Any]:
    """Run Chapter 1's arrival scene briefly and write captured output under logs/mcp/."""
    timeout = max(1, min(int(seconds), 120))
    log_path = PROJECT_ROOT / "logs/mcp" / f"chapter_01_{_timestamp()}.log"
    command = [godot_bin, "--path", ".", "res://scenes/world/chapter_01/room_arrival.tscn"]
    result = _run_command(command, timeout=timeout, write_log=log_path)
    result["parsed_warnings_errors"] = _parse_log_text(_read_text(log_path))
    return result


@mcp.tool()
def godot_run_scene(scene_path: str, seconds: int = 8, godot_bin: str = "godot") -> dict[str, Any]:
    """Run a project-local .tscn scene briefly and write captured output under logs/mcp/."""
    path = _safe_resolve(scene_path, suffix=".tscn")
    timeout = max(1, min(int(seconds), 120))
    scene_arg = scene_path if scene_path.startswith("res://") else _to_res_path(path)
    log_path = PROJECT_ROOT / "logs/mcp" / f"scene_{_safe_log_name(scene_arg)}_{_timestamp()}.log"
    result = _run_command([godot_bin, "--path", ".", scene_arg], timeout=timeout, write_log=log_path)
    result["parsed_warnings_errors"] = _parse_log_text(_read_text(log_path))
    return result


@mcp.tool()
def git_status() -> dict[str, Any]:
    """Run git status --short from the nested game repository."""
    return _run_command(["git", "status", "--short"])


if __name__ == "__main__":
    mcp.run(transport="stdio")

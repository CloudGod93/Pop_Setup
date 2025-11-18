from __future__ import annotations

from pathlib import Path
from typing import Dict, Tuple

import yaml

from .models import Profile, Script


def load_scripts_config(config_path: Path | str) -> Dict[str, Script]:
    path = Path(config_path)
    if not path.exists():
        raise FileNotFoundError(f"Scripts config not found: {path}")
    data = yaml.safe_load(path.read_text()) or {}
    entries = data.get("scripts", [])
    scripts: Dict[str, Script] = {}
    for entry in entries:
        script = Script(
            id=str(entry["id"]),
            name=str(entry.get("name", entry["id"])),
            description=str(entry.get("description", "")),
            script_path=str(entry["script"]),
            check_path=entry.get("check"),
        )
        scripts[script.id] = script
    if not scripts:
        raise ValueError("No scripts defined in config")
    return scripts


def load_profiles_config(
    scripts: Dict[str, Script], config_path: Path | str
) -> Dict[str, Profile]:
    path = Path(config_path)
    if not path.exists():
        raise FileNotFoundError(f"Profiles config not found: {path}")
    data = yaml.safe_load(path.read_text()) or {}
    entries = data.get("profiles", {})
    profiles: Dict[str, Profile] = {}
    for profile_id, entry in entries.items():
        script_ids = entry.get("scripts", [])
        for script_id in script_ids:
            if script_id not in scripts:
                raise ValueError(
                    f"Profile '{profile_id}' references unknown script '{script_id}'"
                )
        profiles[profile_id] = Profile(
            id=profile_id,
            description=str(entry.get("description", "")),
            scripts=list(script_ids),
        )
    if not profiles:
        raise ValueError("No profiles defined in config")
    return profiles


def load_configs(base_path: Path) -> Tuple[Dict[str, Script], Dict[str, Profile]]:
    scripts = load_scripts_config(base_path / "configs" / "scripts.yml")
    profiles = load_profiles_config(scripts, base_path / "configs" / "profiles.yml")
    return scripts, profiles

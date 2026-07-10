from __future__ import annotations

from pathlib import Path
from typing import Any

import yaml


def load_config(path: Path) -> dict[str, Any]:
    data = yaml.safe_load(path.read_text(encoding="utf-8"))

    if not isinstance(data, dict):
        raise ValueError("mkdocs.yml must contain a YAML mapping.")

    return data


def iter_nav_targets(value: Any):
    if isinstance(value, str) and value.endswith(".md"):
        yield value
    elif isinstance(value, list):
        for item in value:
            yield from iter_nav_targets(item)
    elif isinstance(value, dict):
        for item in value.values():
            yield from iter_nav_targets(item)


def validate_nav_targets(config_path: Path, generated_root: Path) -> None:
    config = load_config(config_path)

    missing = sorted(
        target
        for target in iter_nav_targets(config.get("nav", []))
        if not (generated_root / target).exists()
    )

    if missing:
        formatted = "\n".join(f"  - {target}" for target in missing)
        raise ValueError(f"Missing MkDocs navigation targets:\n{formatted}")

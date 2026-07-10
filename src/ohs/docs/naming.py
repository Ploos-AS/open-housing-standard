from __future__ import annotations

import re
from pathlib import Path

EXCLUDED_DIR_NAMES = {
    "_legacy",
    "_template",
    "__pycache__",
    ".git",
    ".venv",
}

EXCLUDED_FILE_NAMES = {
    ".DS_Store",
    "OHS-001-MIGRATION-CHECKLIST.md",
}


def is_excluded(path: Path) -> bool:
    return (
        path.name in EXCLUDED_FILE_NAMES
        or any(part in EXCLUDED_DIR_NAMES for part in path.parts)
    )


def slugify_component(value: str) -> str:
    path = Path(value)
    suffix = path.suffix.lower()
    stem = path.stem if suffix else value

    stem = stem.lower().replace("_", "-").replace(" ", "-")
    stem = re.sub(r"[^a-z0-9.-]+", "-", stem)
    stem = re.sub(r"-+", "-", stem).strip("-")

    return f"{stem}{suffix}" if suffix else stem


def normalized_relative_path(path: Path) -> Path:
    return Path(*(slugify_component(part) for part in path.parts))

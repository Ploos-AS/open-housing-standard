from __future__ import annotations

import shutil
from pathlib import Path

from .naming import is_excluded, normalized_relative_path


def copy_file(source: Path, target: Path) -> None:
    if not source.exists() or is_excluded(source):
        return

    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, target)


def copy_tree(source: Path, target: Path) -> None:
    if not source.exists():
        return

    for item in source.rglob("*"):
        if is_excluded(item):
            continue

        relative = item.relative_to(source)

        if any(part in {"_legacy", "_template"} for part in relative.parts):
            continue

        destination = target / normalized_relative_path(relative)

        if item.is_dir():
            destination.mkdir(parents=True, exist_ok=True)
        elif item.is_file():
            copy_file(item, destination)

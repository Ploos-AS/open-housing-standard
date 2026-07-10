from __future__ import annotations

from pathlib import Path
from typing import Any


def page_title(path: Path) -> str:
    try:
        for line in path.read_text(encoding="utf-8").splitlines():
            if line.startswith("# "):
                return line[2:].strip()
    except UnicodeDecodeError:
        pass

    return path.stem.replace("-", " ").title()


def markdown_files(directory: Path) -> list[Path]:
    if not directory.exists():
        return []

    return sorted(
        path
        for path in directory.rglob("*.md")
        if path.is_file()
    )


def section(title: str, directory: Path, generated_root: Path) -> dict[str, Any] | None:
    pages = markdown_files(directory)
    if not pages:
        return None

    entries: list[dict[str, str]] = []
    for page in pages:
        entries.append(
            {
                page_title(page): page.relative_to(generated_root).as_posix(),
            }
        )

    return {title: entries}


def build_navigation(generated_root: Path) -> list[Any]:
    nav: list[Any] = [{"Home": "index.md"}]

    sections = (
        ("Standards", generated_root / "standards"),
        ("Reference Houses", generated_root / "reference-houses"),
        ("Architecture Decision Records", generated_root / "adr"),
        ("Project", generated_root / "project"),
        ("Workflows", generated_root / "workflows"),
        ("Checklists", generated_root / "checklists"),
    )

    for title, directory in sections:
        value = section(title, directory, generated_root)
        if value is not None:
            nav.append(value)

    return nav

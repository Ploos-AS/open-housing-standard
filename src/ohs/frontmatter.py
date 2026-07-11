from __future__ import annotations

import argparse
import re
from dataclasses import dataclass
from datetime import date
from pathlib import Path
from typing import Any

import yaml

OHS001_TITLES = {
    "01-introduction.md": ("1 — Introduction", True),
    "02-scope.md": ("2 — Scope", True),
    "03-normative-references.md": ("3 — Normative References", True),
    "04-terminology.md": ("4 — Terminology", True),
    "05-requirements.md": ("5 — Requirements", True),
    "06-standard-architecture.md": ("6 — Standard Architecture", True),
    "07-conformance.md": ("7 — Conformance", True),
    "08-governance.md": ("8 — Governance", True),
    "09-versioning.md": ("9 — Versioning", True),
    "appendix-a.md": ("Appendix A — Design Rationale", False),
    "appendix-b.md": ("Appendix B — Citation and Referencing", False),
}

REFERENCED_BY = [
    "OHS-100",
    "OHS-200",
    "OHS-300",
    "OHS-400",
    "OHS-500",
    "OHS-600",
    "OHS-700",
    "OHS-900",
]


@dataclass
class Result:
    changed: list[Path]
    errors: list[str]


def split_frontmatter(text: str) -> tuple[dict[str, Any], str]:
    if not text.startswith("---\n"):
        return {}, text

    end = text.find("\n---\n", 4)
    if end == -1:
        raise ValueError("Unterminated YAML frontmatter.")

    data = yaml.safe_load(text[4:end]) or {}
    if not isinstance(data, dict):
        raise ValueError("YAML frontmatter must be a mapping.")

    body = text[end + 5 :].removeprefix("\n")
    return data, body


def canonical_metadata(chapter: str, normative: bool) -> dict[str, Any]:
    return {
        "Document ID": "OHS-001",
        "Title": "Open Housing Standard",
        "Chapter": chapter,
        "Version": "1.0.0-draft.1",
        "Status": "Draft",
        "Category": "Core Specification",
        "Normative": "Yes" if normative else "No",
        "Depends On": ["OHS-000"],
        "Referenced By": REFERENCED_BY,
        "Publisher": "Open Housing Standard",
        "License": "CC BY-SA 4.0",
        "Language": "English",
        "Last Updated": date.today().isoformat(),
        "Next Review": "Before 1.0.0-rc.1",
    }


def dump_frontmatter(data: dict[str, Any]) -> str:
    rendered = yaml.safe_dump(
        data,
        allow_unicode=True,
        sort_keys=False,
        default_flow_style=False,
        width=100,
    ).rstrip()
    return f"---\n{rendered}\n---\n\n"


def normalize_heading_hierarchy(body: str, chapter: str) -> str:
    lines = body.splitlines()

    if chapter.startswith("Appendix "):
        prefix = chapter.split(" —", 1)[0].replace("Appendix ", "")
        pattern = re.compile(rf"^# ({re.escape(prefix)}\.\d+(?:\.\d+)*)\b")
    else:
        number = chapter.split(" ", 1)[0]
        pattern = re.compile(rf"^# ({re.escape(number)}\.\d+(?:\.\d+)*)\b")

    normalized = [("#" + line) if pattern.match(line) else line for line in lines]
    return "\n".join(normalized).rstrip() + "\n"


def normalize_file(
    path: Path,
    chapter: str,
    normative: bool,
    fix: bool,
) -> tuple[bool, str | None]:
    try:
        original = path.read_text(encoding="utf-8")
        existing, body = split_frontmatter(original)
    except (OSError, ValueError, yaml.YAMLError) as exc:
        return False, f"{path}: {exc}"

    metadata = canonical_metadata(chapter, normative)
    extras = {key: value for key, value in existing.items() if key not in metadata}
    metadata.update(extras)

    normalized = dump_frontmatter(metadata) + normalize_heading_hierarchy(body, chapter)

    if normalized == original:
        return False, None

    if fix:
        path.write_text(normalized, encoding="utf-8")

    return True, None


def process(root: Path, fix: bool) -> Result:
    directory = root / "standard" / "OHS-001"
    changed: list[Path] = []
    errors: list[str] = []

    if not directory.exists():
        return Result([], ["standard/OHS-001 does not exist."])

    for filename, (chapter, normative) in OHS001_TITLES.items():
        path = directory / filename
        if not path.exists():
            errors.append(f"Missing {path.relative_to(root)}")
            continue

        was_changed, error = normalize_file(path, chapter, normative, fix)
        if error:
            errors.append(error)
        elif was_changed:
            changed.append(path)

    return Result(changed, errors)


def discover_root() -> Path:
    current = Path.cwd().resolve()
    for candidate in (current, *current.parents):
        if (candidate / ".git").exists() and (candidate / "pyproject.toml").exists():
            return candidate
    raise SystemExit("Run inside the Open Housing Standard repository.")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="ohs-normalize-frontmatter",
        description="Normalize OHS-001 metadata and heading hierarchy.",
    )
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--check", action="store_true")
    group.add_argument("--fix", action="store_true")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    root = discover_root()
    result = process(root, fix=args.fix)

    for error in result.errors:
        print(f"ERROR: {error}")

    if result.changed:
        label = "Updated" if args.fix else "Needs normalization"
        for path in result.changed:
            print(f"{label}: {path.relative_to(root)}")
    else:
        print("OHS-001 frontmatter and heading hierarchy are consistent.")

    if result.errors or (result.changed and not args.fix):
        raise SystemExit(1)


if __name__ == "__main__":
    main()

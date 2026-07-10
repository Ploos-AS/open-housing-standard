#!/usr/bin/env bash
set -euo pipefail

# reset-ohs-docs-tooling.sh
#
# Replaces the entire src/ohs/docs package with one internally consistent
# implementation. This avoids further compatibility issues between partially
# migrated modules.
#
# Run from the repository root on the draft branch.

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "[!] Run this script inside the Git repository."
  exit 1
fi

mkdir -p src/ohs/docs tests/docs

# Back up the current docs tooling once.
if [[ ! -d src/ohs/docs.before-reset ]]; then
  cp -a src/ohs/docs src/ohs/docs.before-reset
fi

cat > src/ohs/docs/__init__.py <<'PY'
"""Documentation build tooling for Open Housing Standard."""
PY

cat > src/ohs/docs/paths.py <<'PY'
from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class ProjectPaths:
    root: Path
    docs: Path
    generated: Path
    site: Path
    mkdocs: Path

    @classmethod
    def discover(cls, start: Path | None = None) -> "ProjectPaths":
        current = (start or Path.cwd()).resolve()

        for candidate in (current, *current.parents):
            if (candidate / "pyproject.toml").exists() and (candidate / ".git").exists():
                return cls(
                    root=candidate,
                    docs=candidate / "docs",
                    generated=candidate / "docs" / "generated",
                    site=candidate / "site",
                    mkdocs=candidate / "mkdocs.yml",
                )

        raise RuntimeError(
            "Unable to locate repository root. Run inside the OHS repository."
        )
PY

cat > src/ohs/docs/naming.py <<'PY'
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
PY

cat > src/ohs/docs/copier.py <<'PY'
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
PY

cat > src/ohs/docs/links.py <<'PY'
from __future__ import annotations

import re
from pathlib import Path, PurePosixPath
from urllib.parse import urlsplit, urlunsplit

from .naming import slugify_component

INLINE_LINK = re.compile(
    r"(?P<prefix>!?\[[^\]]*\]\()"
    r"(?P<target>[^)\s]+)"
    r"(?P<suffix>(?:\s+['\"][^'\"]*['\"])?\))"
)


def normalize_relative_target(target: str) -> str:
    if target.startswith(("#", "mailto:", "tel:", "data:")):
        return target

    parsed = urlsplit(target)

    if parsed.scheme or parsed.netloc or not parsed.path or parsed.path.startswith("/"):
        return target

    path = PurePosixPath(parsed.path)
    normalized = "/".join(
        slugify_component(part)
        for part in path.parts
        if part not in ("", ".")
    )

    if parsed.path.startswith("./"):
        normalized = f"./{normalized}"

    return urlunsplit(("", "", normalized, parsed.query, parsed.fragment))


def rewrite_markdown_links(text: str) -> str:
    def replace(match: re.Match[str]) -> str:
        return (
            match.group("prefix")
            + normalize_relative_target(match.group("target"))
            + match.group("suffix")
        )

    return INLINE_LINK.sub(replace, text)


def rewrite_markdown_tree(root: Path) -> None:
    for path in root.rglob("*.md"):
        if not path.is_file():
            continue

        original = path.read_text(encoding="utf-8")
        rewritten = rewrite_markdown_links(original)

        if rewritten != original:
            path.write_text(rewritten, encoding="utf-8")
PY

cat > src/ohs/docs/navigation.py <<'PY'
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
PY

cat > src/ohs/docs/config.py <<'PY'
from __future__ import annotations

from pathlib import Path
from typing import Any

import yaml


def create_mkdocs_config(nav: list[Any]) -> dict[str, Any]:
    return {
        "site_name": "Open Housing Standard",
        "site_description": (
            "Open, vendor-neutral housing standards and reference designs"
        ),
        "repo_url": (
            "https://github.com/OpenHousingStandard/open-housing-standard"
        ),
        "repo_name": "OpenHousingStandard/open-housing-standard",
        "docs_dir": "docs/generated",
        "site_dir": "site",
        "theme": {
            "name": "material",
            "features": [
                "navigation.sections",
                "navigation.indexes",
                "navigation.top",
                "content.code.copy",
            ],
        },
        "markdown_extensions": [
            "admonition",
            "attr_list",
            "def_list",
            "footnotes",
            "md_in_html",
            "tables",
            {"toc": {"permalink": True}},
        ],
        "nav": nav,
    }


def write_mkdocs_config(path: Path, config: dict[str, Any]) -> None:
    content = yaml.safe_dump(
        config,
        allow_unicode=True,
        sort_keys=False,
        default_flow_style=False,
        width=100,
    )
    path.write_text(content, encoding="utf-8")
PY

cat > src/ohs/docs/validator.py <<'PY'
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
PY

cat > src/ohs/docs/builder.py <<'PY'
from __future__ import annotations

import shutil

from .config import create_mkdocs_config, write_mkdocs_config
from .copier import copy_file, copy_tree
from .links import rewrite_markdown_tree
from .navigation import build_navigation
from .paths import ProjectPaths
from .validator import validate_nav_targets


ROOT_PROJECT_FILES = {
    "ARCHITECTURE.md": "architecture.md",
    "ROADMAP.md": "roadmap.md",
    "CONTRIBUTING.md": "contributing.md",
    "CODE_OF_CONDUCT.md": "code-of-conduct.md",
    "CHANGELOG.md": "changelog.md",
}

ROOT_DOC_FILES = (
    "disclaimer.md",
    "reference-options.md",
    "repository-map.md",
    "tech-stack.md",
)


def reset_output(paths: ProjectPaths) -> None:
    if paths.generated.exists():
        shutil.rmtree(paths.generated)

    paths.generated.mkdir(parents=True)


def stage_sources(paths: ProjectPaths) -> None:
    copy_file(paths.root / "README.md", paths.generated / "index.md")

    for source_name, target_name in ROOT_PROJECT_FILES.items():
        copy_file(
            paths.root / source_name,
            paths.generated / "project" / target_name,
        )

    copy_tree(paths.root / "standard", paths.generated / "standards")
    copy_tree(paths.root / "reference", paths.generated / "reference-houses")
    copy_tree(paths.docs / "adr", paths.generated / "adr")
    copy_tree(paths.docs / "project", paths.generated / "project")
    copy_tree(paths.docs / "workflows", paths.generated / "workflows")
    copy_tree(paths.docs / "checklists", paths.generated / "checklists")
    copy_tree(paths.docs / "images", paths.generated / "images")

    for filename in ROOT_DOC_FILES:
        copy_file(
            paths.docs / filename,
            paths.generated / "project" / filename,
        )

    (paths.generated / ".generated").write_text(
        "Generated by the OHS documentation builder. "
        "Do not edit directly.\n",
        encoding="utf-8",
    )


def build(paths: ProjectPaths) -> None:
    reset_output(paths)
    stage_sources(paths)
    rewrite_markdown_tree(paths.generated)

    nav = build_navigation(paths.generated)
    config = create_mkdocs_config(nav)

    write_mkdocs_config(paths.mkdocs, config)
    validate_nav_targets(paths.mkdocs, paths.generated)
PY

cat > src/ohs/docs/cli.py <<'PY'
from __future__ import annotations

import argparse
import subprocess

from .builder import build
from .paths import ProjectPaths


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="ohs-build-docs",
        description="Generate and build the OHS documentation site.",
    )
    parser.add_argument(
        "--strict",
        action="store_true",
        help="Run 'mkdocs build --strict' after generation.",
    )
    parser.add_argument(
        "--serve",
        action="store_true",
        help="Run 'mkdocs serve' after generation.",
    )
    return parser.parse_args()


def run(command: list[str], cwd) -> None:
    completed = subprocess.run(command, cwd=cwd, check=False)
    if completed.returncode != 0:
        raise SystemExit(completed.returncode)


def main() -> None:
    args = parse_args()
    paths = ProjectPaths.discover()

    build(paths)

    print(f"Generated documentation at {paths.generated.relative_to(paths.root)}")
    print("Generated mkdocs.yml with PyYAML")

    if args.strict:
        run(["mkdocs", "build", "--strict"], paths.root)
    elif args.serve:
        run(["mkdocs", "serve"], paths.root)


if __name__ == "__main__":
    main()
PY

cat > tests/docs/test_config.py <<'PY'
from pathlib import Path

import yaml

from ohs.docs.config import create_mkdocs_config, write_mkdocs_config


def test_generated_yaml_is_parseable(tmp_path: Path) -> None:
    target = tmp_path / "mkdocs.yml"
    config = create_mkdocs_config(
        [{"Standards": [{"Title: With Colon": "standards/example.md"}]}]
    )

    write_mkdocs_config(target, config)
    loaded = yaml.safe_load(target.read_text(encoding="utf-8"))

    assert loaded["nav"][0]["Standards"][0]["Title: With Colon"] == (
        "standards/example.md"
    )
PY

cat > tests/docs/test_naming.py <<'PY'
from pathlib import Path

from ohs.docs.naming import normalized_relative_path, slugify_component


def test_slugify_component() -> None:
    assert slugify_component("DESIGN_PHILOSOPHY.md") == "design-philosophy.md"


def test_normalized_relative_path() -> None:
    assert normalized_relative_path(
        Path("OHS-001") / "01-Introduction.md"
    ) == Path("ohs-001") / "01-introduction.md"
PY

cat > tests/docs/test_links.py <<'PY'
from ohs.docs.links import normalize_relative_target, rewrite_markdown_links


def test_normalizes_relative_target() -> None:
    assert normalize_relative_target("OHS-000/README.md") == "ohs-000/readme.md"


def test_preserves_fragment() -> None:
    assert (
        normalize_relative_target("OHS-001/README.md#Scope")
        == "ohs-001/readme.md#Scope"
    )


def test_preserves_external_url() -> None:
    url = "https://example.org/OHS-000/README.md"
    assert normalize_relative_target(url) == url


def test_rewrites_markdown_link() -> None:
    assert rewrite_markdown_links(
        "[Editorial Guide](OHS-000/README.md)"
    ) == "[Editorial Guide](ohs-000/readme.md)"


def test_preserves_anchor_only_link() -> None:
    source = "[Scope](#scope)"
    assert rewrite_markdown_links(source) == source
PY

cat > tests/docs/test_validator.py <<'PY'
from pathlib import Path

import pytest
import yaml

from ohs.docs.validator import validate_nav_targets


def test_validator_accepts_existing_target(tmp_path: Path) -> None:
    generated = tmp_path / "generated"
    generated.mkdir()
    (generated / "index.md").write_text("# Home\n", encoding="utf-8")

    config = tmp_path / "mkdocs.yml"
    config.write_text(
        yaml.safe_dump({"nav": [{"Home": "index.md"}]}),
        encoding="utf-8",
    )

    validate_nav_targets(config, generated)


def test_validator_rejects_missing_target(tmp_path: Path) -> None:
    generated = tmp_path / "generated"
    generated.mkdir()

    config = tmp_path / "mkdocs.yml"
    config.write_text(
        yaml.safe_dump({"nav": [{"Missing": "missing.md"}]}),
        encoding="utf-8",
    )

    with pytest.raises(ValueError, match="missing.md"):
        validate_nav_targets(config, generated)
PY

echo "[*] Synchronizing environment..."
uv sync

echo "[*] Running tests..."
uv run pytest tests/docs

echo "[*] Running strict documentation build..."
uv run ohs-build-docs --strict

echo
echo "[✓] Documentation tooling reset successfully."
echo
echo "After confirming everything works:"
echo "  rm -rf src/ohs/docs.before-reset"
echo "  git status"
echo "  git diff --stat"
echo "  git diff"
echo "  git add -A"
echo '  git commit -m "Reset documentation tooling to canonical implementation"'
echo "  git push origin $(git branch --show-current)"

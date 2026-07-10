#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "[!] Run this script inside the Git repository."
  exit 1
fi

mkdir -p src/ohs/docs tests/docs

uv add pyyaml
uv add --dev pytest

cat > src/ohs/__init__.py <<'PY'
"""Open Housing Standard tooling."""
PY

cat > src/ohs/docs/__init__.py <<'PY'
"""Documentation tooling for Open Housing Standard."""
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
    mkdocs: Path

    @classmethod
    def discover(cls) -> "ProjectPaths":
        current = Path.cwd().resolve()
        for candidate in (current, *current.parents):
            if (candidate / "pyproject.toml").exists() and (candidate / ".git").exists():
                return cls(candidate, candidate / "docs", candidate / "docs" / "generated", candidate / "mkdocs.yml")
        raise RuntimeError("Repository root not found")
PY

cat > src/ohs/docs/naming.py <<'PY'
from __future__ import annotations
import re
from pathlib import Path

EXCLUDED_DIRS = {"_legacy", "_template", "__pycache__", ".git", ".venv"}
EXCLUDED_FILES = {".DS_Store", "OHS-001-MIGRATION-CHECKLIST.md"}

def excluded(path: Path) -> bool:
    return path.name in EXCLUDED_FILES or any(part in EXCLUDED_DIRS for part in path.parts)

def slug(value: str) -> str:
    p = Path(value)
    suffix = p.suffix.lower()
    stem = (p.stem if suffix else value).lower().replace("_", "-").replace(" ", "-")
    stem = re.sub(r"[^a-z0-9.-]+", "-", stem)
    stem = re.sub(r"-+", "-", stem).strip("-")
    return f"{stem}{suffix}" if suffix else stem

def normalized(path: Path) -> Path:
    return Path(*(slug(part) for part in path.parts))
PY

cat > src/ohs/docs/copier.py <<'PY'
from __future__ import annotations
import shutil
from pathlib import Path
from .naming import excluded, normalized

def copy_file(src: Path, dst: Path) -> None:
    if not src.exists() or excluded(src):
        return
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)

def copy_tree(src: Path, dst: Path) -> None:
    if not src.exists():
        return
    for item in src.rglob("*"):
        if excluded(item):
            continue
        rel = item.relative_to(src)
        target = dst / normalized(rel)
        if item.is_dir():
            target.mkdir(parents=True, exist_ok=True)
        elif item.is_file():
            copy_file(item, target)
PY

cat > src/ohs/docs/navigation.py <<'PY'
from __future__ import annotations
from pathlib import Path
from typing import Any

def title(path: Path) -> str:
    try:
        for line in path.read_text(encoding="utf-8").splitlines():
            if line.startswith("# "):
                return line[2:].strip()
    except UnicodeDecodeError:
        pass
    return path.stem.replace("-", " ").title()

def files(directory: Path) -> list[Path]:
    if not directory.exists():
        return []
    return sorted(p for p in directory.rglob("*.md") if p.is_file())

def section(name: str, directory: Path, root: Path) -> dict[str, Any] | None:
    pages = files(directory)
    if not pages:
        return None
    return {name: [{title(p): p.relative_to(root).as_posix()} for p in pages]}

def build(root: Path) -> list[Any]:
    nav: list[Any] = [{"Home": "index.md"}]
    for name, directory in (
        ("Standards", root / "standards"),
        ("Reference Houses", root / "reference-houses"),
        ("Architecture Decision Records", root / "adr"),
        ("Project", root / "project"),
        ("Workflows", root / "workflows"),
        ("Checklists", root / "checklists"),
    ):
        item = section(name, directory, root)
        if item:
            nav.append(item)
    return nav
PY

cat > src/ohs/docs/config.py <<'PY'
from __future__ import annotations
from pathlib import Path
from typing import Any
import yaml

def create(nav: list[Any]) -> dict[str, Any]:
    return {
        "site_name": "Open Housing Standard",
        "site_description": "Open, vendor-neutral housing standards and reference designs",
        "repo_url": "https://github.com/OpenHousingStandard/open-housing-standard",
        "repo_name": "OpenHousingStandard/open-housing-standard",
        "docs_dir": "docs/generated",
        "site_dir": "site",
        "theme": {"name": "material", "features": ["navigation.sections", "navigation.indexes", "navigation.top", "content.code.copy"]},
        "markdown_extensions": ["admonition", "attr_list", "def_list", "footnotes", "md_in_html", "tables", {"toc": {"permalink": True}}],
        "nav": nav,
    }

def write(path: Path, config: dict[str, Any]) -> None:
    path.write_text(yaml.safe_dump(config, allow_unicode=True, sort_keys=False, default_flow_style=False, width=100), encoding="utf-8")
PY

cat > src/ohs/docs/validator.py <<'PY'
from __future__ import annotations
from pathlib import Path
from typing import Any
import yaml

def iter_targets(value: Any):
    if isinstance(value, str) and value.endswith(".md"):
        yield value
    elif isinstance(value, list):
        for item in value:
            yield from iter_targets(item)
    elif isinstance(value, dict):
        for item in value.values():
            yield from iter_targets(item)

def validate(config_path: Path, generated_root: Path) -> None:
    data = yaml.safe_load(config_path.read_text(encoding="utf-8"))
    missing = sorted(target for target in iter_targets(data.get("nav", [])) if not (generated_root / target).exists())
    if missing:
        raise ValueError("Missing navigation targets:\n" + "\n".join(f"  - {m}" for m in missing))
PY

cat > src/ohs/docs/builder.py <<'PY'
from __future__ import annotations
import shutil
from .paths import ProjectPaths
from .copier import copy_file, copy_tree
from .navigation import build as build_nav
from .config import create as create_config, write as write_config
from .validator import validate

ROOT_FILES = {
    "ARCHITECTURE.md": "architecture.md",
    "ROADMAP.md": "roadmap.md",
    "CONTRIBUTING.md": "contributing.md",
    "CODE_OF_CONDUCT.md": "code-of-conduct.md",
    "CHANGELOG.md": "changelog.md",
}

def build(paths: ProjectPaths) -> None:
    if paths.generated.exists():
        shutil.rmtree(paths.generated)
    paths.generated.mkdir(parents=True)

    copy_file(paths.root / "README.md", paths.generated / "index.md")
    for src, dst in ROOT_FILES.items():
        copy_file(paths.root / src, paths.generated / "project" / dst)

    copy_tree(paths.root / "standard", paths.generated / "standards")
    copy_tree(paths.root / "reference", paths.generated / "reference-houses")
    copy_tree(paths.docs / "adr", paths.generated / "adr")
    copy_tree(paths.docs / "project", paths.generated / "project")
    copy_tree(paths.docs / "workflows", paths.generated / "workflows")
    copy_tree(paths.docs / "checklists", paths.generated / "checklists")
    copy_tree(paths.docs / "images", paths.generated / "images")

    for name in ("disclaimer.md", "reference-options.md", "repository-map.md", "tech-stack.md"):
        copy_file(paths.docs / name, paths.generated / "project" / name)

    nav = build_nav(paths.generated)
    write_config(paths.mkdocs, create_config(nav))
    validate(paths.mkdocs, paths.generated)
PY

cat > src/ohs/docs/cli.py <<'PY'
from __future__ import annotations
import argparse
import subprocess
from .builder import build
from .paths import ProjectPaths

def main() -> None:
    parser = argparse.ArgumentParser(prog="ohs-build-docs")
    parser.add_argument("--strict", action="store_true")
    parser.add_argument("--serve", action="store_true")
    args = parser.parse_args()

    paths = ProjectPaths.discover()
    build(paths)
    print(f"Generated documentation at {paths.generated.relative_to(paths.root)}")
    print("Generated mkdocs.yml with PyYAML")

    if args.strict:
        raise SystemExit(subprocess.run(["mkdocs", "build", "--strict"], cwd=paths.root).returncode)
    if args.serve:
        raise SystemExit(subprocess.run(["mkdocs", "serve"], cwd=paths.root).returncode)
PY

cat > tests/docs/test_config.py <<'PY'
from pathlib import Path
import yaml
from ohs.docs.config import create, write

def test_yaml_handles_colons(tmp_path: Path) -> None:
    target = tmp_path / "mkdocs.yml"
    config = create([{"Standards": [{"Title: With Colon": "standards/example.md"}]}])
    write(target, config)
    loaded = yaml.safe_load(target.read_text(encoding="utf-8"))
    assert loaded["nav"][0]["Standards"][0]["Title: With Colon"] == "standards/example.md"
PY

cat > tests/docs/test_naming.py <<'PY'
from pathlib import Path
from ohs.docs.naming import slug, normalized

def test_slug() -> None:
    assert slug("DESIGN_PHILOSOPHY.md") == "design-philosophy.md"

def test_normalized() -> None:
    assert normalized(Path("OHS-001") / "01-Introduction.md") == Path("ohs-001") / "01-introduction.md"
PY

python - <<'PY'
from pathlib import Path
path = Path("pyproject.toml")
text = path.read_text(encoding="utf-8")
entry = 'ohs-build-docs = "ohs.docs.cli:main"'
if entry not in text:
    if "[project.scripts]" in text:
        text = text.replace("[project.scripts]\n", "[project.scripts]\n" + entry + "\n", 1)
    else:
        text = text.rstrip() + "\n\n[project.scripts]\n" + entry + "\n"
    path.write_text(text, encoding="utf-8")
PY

rm -f scripts/build_docs.py scripts/build-docs.sh scripts/setup-generated-docs-pipeline.sh scripts/improve-generated-docs-pipeline.sh

touch .gitignore
grep -qxF "docs/generated/" .gitignore || printf '\n# Generated documentation\ndocs/generated/\n' >> .gitignore
grep -qxF "site/" .gitignore || printf 'site/\n' >> .gitignore

uv sync
uv run pytest tests/docs
uv run ohs-build-docs --strict

echo
echo "[✓] Python documentation tooling is ready."
echo "Use:"
echo "  uv run ohs-build-docs"
echo "  uv run ohs-build-docs --strict"
echo "  uv run ohs-build-docs --serve"
echo
echo "Then review and commit:"
echo "  git status"
echo "  git diff --stat"
echo "  git diff"
echo "  git add -A"
echo '  git commit -m "Replace documentation scripts with Python tooling"'
echo "  git push origin $(git branch --show-current)"

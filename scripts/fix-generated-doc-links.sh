#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

mkdir -p src/ohs/docs tests/docs

cat > src/ohs/docs/links.py <<'PY'
from __future__ import annotations

import re
from pathlib import Path, PurePosixPath
from urllib.parse import urlsplit, urlunsplit

from .naming import slugify_component

PATTERN = re.compile(
    r"(?P<prefix>!?\[[^\]]*\]\()"
    r"(?P<target>[^)\s]+)"
    r"(?P<suffix>(?:\s+['\"][^'\"]*['\"])?\))"
)

def normalize_relative_target(target: str) -> str:
    parsed = urlsplit(target)
    if parsed.scheme or parsed.netloc or not parsed.path or parsed.path.startswith("/"):
        return target
    if target.startswith(("#", "mailto:", "tel:", "data:")):
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
        target = match.group("target")
        return (
            match.group("prefix")
            + normalize_relative_target(target)
            + match.group("suffix")
        )
    return PATTERN.sub(replace, text)

def rewrite_markdown_tree(root: Path) -> None:
    for path in root.rglob("*.md"):
        original = path.read_text(encoding="utf-8")
        rewritten = rewrite_markdown_links(original)
        if rewritten != original:
            path.write_text(rewritten, encoding="utf-8")
PY

python - <<'PY'
from pathlib import Path

path = Path("src/ohs/docs/builder.py")
text = path.read_text(encoding="utf-8")

if "from .links import rewrite_markdown_tree\n" not in text:
    text = text.replace(
        "from .copier import copy_file, copy_tree\n",
        "from .copier import copy_file, copy_tree\n"
        "from .links import rewrite_markdown_tree\n",
    )

old = "    stage_sources(paths)\n\n    nav = build_navigation(paths.generated)\n"
new = (
    "    stage_sources(paths)\n"
    "    rewrite_markdown_tree(paths.generated)\n\n"
    "    nav = build_navigation(paths.generated)\n"
)

if old not in text:
    raise SystemExit("Could not find expected build sequence in builder.py")

path.write_text(text.replace(old, new), encoding="utf-8")
PY

cat > tests/docs/test_links.py <<'PY'
from ohs.docs.links import normalize_relative_target, rewrite_markdown_links

def test_normalizes_relative_target() -> None:
    assert normalize_relative_target("OHS-000/README.md") == "ohs-000/readme.md"

def test_preserves_fragment() -> None:
    assert normalize_relative_target("OHS-001/README.md#Scope") == "ohs-001/readme.md#Scope"

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

uv run pytest tests/docs
uv run ohs-build-docs --strict

echo
echo "[✓] Link rewriting added successfully."
echo "Next:"
echo "  git status"
echo "  git diff --stat"
echo "  git diff"
echo "  git add -A"
echo '  git commit -m "Rewrite generated documentation links"'
echo "  git push origin $(git branch --show-current)"

#!/usr/bin/env bash
set -euo pipefail

# fix-links-import.sh
#
# Removes the dependency on slugify_component from naming.py by making
# links.py self-contained.

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

cat > src/ohs/docs/links.py <<'PY'
from __future__ import annotations

import re
from pathlib import Path, PurePosixPath
from urllib.parse import urlsplit, urlunsplit

_INLINE_LINK = re.compile(
    r"(?P<prefix>!?\[[^\]]*\]\()"
    r"(?P<target>[^)\s]+)"
    r"(?P<suffix>(?:\s+['\"][^'\"]*['\"])?\))"
)


def _slugify_component(value: str) -> str:
    """Normalize one path component using the generated-doc naming rules."""

    path = Path(value)
    suffix = path.suffix.lower()
    stem = path.stem if suffix else value

    stem = stem.lower().replace("_", "-").replace(" ", "-")
    stem = re.sub(r"[^a-z0-9.-]+", "-", stem)
    stem = re.sub(r"-+", "-", stem).strip("-")

    return f"{stem}{suffix}" if suffix else stem


def normalize_relative_target(target: str) -> str:
    """Normalize the path portion of a relative Markdown link."""

    if target.startswith(("#", "mailto:", "tel:", "data:")):
        return target

    parsed = urlsplit(target)

    if (
        parsed.scheme
        or parsed.netloc
        or not parsed.path
        or parsed.path.startswith("/")
    ):
        return target

    path = PurePosixPath(parsed.path)
    normalized = "/".join(
        _slugify_component(part)
        for part in path.parts
        if part not in ("", ".")
    )

    if parsed.path.startswith("./"):
        normalized = f"./{normalized}"

    return urlunsplit(
        ("", "", normalized, parsed.query, parsed.fragment)
    )


def rewrite_markdown_links(text: str) -> str:
    """Rewrite relative inline Markdown links and image references."""

    def replace(match: re.Match[str]) -> str:
        return (
            match.group("prefix")
            + normalize_relative_target(match.group("target"))
            + match.group("suffix")
        )

    return _INLINE_LINK.sub(replace, text)


def rewrite_markdown_tree(root: Path) -> None:
    """Rewrite relative links in all generated Markdown files."""

    for path in root.rglob("*.md"):
        if not path.is_file():
            continue

        original = path.read_text(encoding="utf-8")
        rewritten = rewrite_markdown_links(original)

        if rewritten != original:
            path.write_text(rewritten, encoding="utf-8")
PY

echo "[*] Running tests..."
uv run pytest tests/docs

echo "[*] Running strict documentation build..."
uv run ohs-build-docs --strict

echo
echo "[✓] Link import issue fixed."
echo
echo "Next:"
echo "  rm -f src/ohs/docs/builder.py.before-link-rewrite"
echo "  git status"
echo "  git diff --stat"
echo "  git diff"
echo "  git add -A"
echo '  git commit -m "Fix documentation link normalization"'
echo "  git push origin $(git branch --show-current)"

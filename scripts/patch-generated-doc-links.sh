#!/usr/bin/env bash
set -euo pipefail

# patch-generated-doc-links.sh
#
# Robustly adds Markdown-link rewriting to the existing Python documentation
# builder without assuming an exact formatting/layout in builder.py.

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

BUILDER="src/ohs/docs/builder.py"

if [[ ! -f "$BUILDER" ]]; then
  echo "[!] Missing $BUILDER"
  exit 1
fi

mkdir -p src/ohs/docs tests/docs

cat > src/ohs/docs/links.py <<'PY'
from __future__ import annotations

import re
from pathlib import Path, PurePosixPath
from urllib.parse import urlsplit, urlunsplit

from .naming import slugify_component

_INLINE_LINK = re.compile(
    r"(?P<prefix>!?\[[^\]]*\]\()"
    r"(?P<target>[^)\s]+)"
    r"(?P<suffix>(?:\s+['\"][^'\"]*['\"])?\))"
)


def normalize_relative_target(target: str) -> str:
    """Normalize a relative Markdown target to generated filename rules."""

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
    """Rewrite links in all generated Markdown files."""

    for path in root.rglob("*.md"):
        if not path.is_file():
            continue

        original = path.read_text(encoding="utf-8")
        rewritten = rewrite_markdown_links(original)

        if rewritten != original:
            path.write_text(rewritten, encoding="utf-8")
PY

python - <<'PY'
from pathlib import Path
import ast

path = Path("src/ohs/docs/builder.py")
text = path.read_text(encoding="utf-8")

# Add import if missing.
import_line = "from .links import rewrite_markdown_tree\n"

if import_line not in text:
    lines = text.splitlines(keepends=True)

    insert_at = None
    for index, line in enumerate(lines):
        if line.startswith("from ."):
            insert_at = index + 1

    if insert_at is None:
        # Place after future/import block.
        insert_at = 0
        for index, line in enumerate(lines):
            if line.startswith(("from __future__", "import ", "from ")):
                insert_at = index + 1

    lines.insert(insert_at, import_line)
    text = "".join(lines)

# Parse to find build() and inject after a call to stage_sources().
tree = ast.parse(text)
build_node = next(
    (
        node
        for node in tree.body
        if isinstance(node, ast.FunctionDef) and node.name == "build"
    ),
    None,
)

if build_node is None:
    raise SystemExit("Could not find function build() in builder.py")

already_present = any(
    isinstance(node, ast.Expr)
    and isinstance(node.value, ast.Call)
    and getattr(node.value.func, "id", None) == "rewrite_markdown_tree"
    for node in ast.walk(build_node)
)

if not already_present:
    lines = text.splitlines(keepends=True)
    inserted = False

    # Use line numbers from AST and insert after stage_sources(...) statement.
    for statement in build_node.body:
        is_stage_sources = (
            isinstance(statement, ast.Expr)
            and isinstance(statement.value, ast.Call)
            and (
                getattr(statement.value.func, "id", None) == "stage_sources"
                or getattr(statement.value.func, "attr", None) == "stage_sources"
            )
        )

        if is_stage_sources:
            end_lineno = getattr(statement, "end_lineno", statement.lineno)
            indent = " " * (statement.col_offset)
            lines.insert(
                end_lineno,
                f"{indent}rewrite_markdown_tree(paths.generated)\n",
            )
            inserted = True
            break

    if not inserted:
        # Fallback: insert before first navigation/config generation line.
        for statement in build_node.body:
            source_segment = ast.get_source_segment(text, statement) or ""
            if "build_navigation" in source_segment or "mkdocs_configuration" in source_segment:
                line_index = statement.lineno - 1
                indent = " " * statement.col_offset
                lines.insert(
                    line_index,
                    f"{indent}rewrite_markdown_tree(paths.generated)\n",
                )
                inserted = True
                break

    if not inserted:
        raise SystemExit(
            "Could not find a safe insertion point in build(). "
            "Please inspect src/ohs/docs/builder.py."
        )

    text = "".join(lines)

path.write_text(text, encoding="utf-8")
print("[+] Patched src/ohs/docs/builder.py")
PY

cat > tests/docs/test_links.py <<'PY'
from ohs.docs.links import normalize_relative_target, rewrite_markdown_links


def test_normalizes_relative_target() -> None:
    assert (
        normalize_relative_target("OHS-000/README.md")
        == "ohs-000/readme.md"
    )


def test_preserves_fragment() -> None:
    assert (
        normalize_relative_target("OHS-001/README.md#Scope")
        == "ohs-001/readme.md#Scope"
    )


def test_preserves_external_url() -> None:
    url = "https://example.org/OHS-000/README.md"
    assert normalize_relative_target(url) == url


def test_rewrites_markdown_link() -> None:
    source = "[Editorial Guide](OHS-000/README.md)"
    expected = "[Editorial Guide](ohs-000/readme.md)"
    assert rewrite_markdown_links(source) == expected


def test_rewrites_image_link() -> None:
    source = "![Plan](Images/House_Plan.PNG)"
    expected = "![Plan](images/house-plan.png)"
    assert rewrite_markdown_links(source) == expected


def test_preserves_anchor_only_link() -> None:
    source = "[Scope](#scope)"
    assert rewrite_markdown_links(source) == source
PY

echo "[*] Running tests..."
uv run pytest tests/docs

echo "[*] Running strict documentation build..."
uv run ohs-build-docs --strict

echo
echo "[✓] Link rewriting patch applied successfully."
echo
echo "Next:"
echo "  git status"
echo "  git diff --stat"
echo "  git diff"
echo "  git add -A"
echo '  git commit -m "Rewrite generated documentation links"'
echo "  git push origin $(git branch --show-current)"

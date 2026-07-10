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

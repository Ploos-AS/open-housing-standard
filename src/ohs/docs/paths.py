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

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

#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

import yaml
from jinja2 import Environment, FileSystemLoader

ROOT = Path(__file__).resolve().parents[1]
TEMPLATES = ROOT / "templates"
REFERENCE = ROOT / "reference"


def main() -> int:
    env = Environment(loader=FileSystemLoader(TEMPLATES), autoescape=False)
    template = env.get_template("model_report.md.j2")

    for config in sorted(REFERENCE.glob("oh*/config/house.yaml")):
        data = yaml.safe_load(config.read_text(encoding="utf-8"))
        output = config.parents[1] / "docs" / "generated-report.md"
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(template.render(**data), encoding="utf-8")
        print(f"Wrote {output}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

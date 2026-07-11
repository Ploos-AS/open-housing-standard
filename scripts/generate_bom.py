#!/usr/bin/env python3
from __future__ import annotations

import csv
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]
REFERENCE = ROOT / "reference"


def main() -> int:
    for config in sorted(REFERENCE.glob("oh*/config/house.yaml")):
        data = yaml.safe_load(config.read_text(encoding="utf-8"))
        model_dir = config.parents[1]
        output = model_dir / "bom" / "summary.csv"
        output.parent.mkdir(parents=True, exist_ok=True)
        rows = [
            ["category", "item", "quantity", "unit", "notes"],
            ["area", "target_bra", data["areas"]["target_bra_m2"], "m2", "concept value"],
            [
                "technical",
                "dry_technical_room",
                data["rooms"]["dry_technical_room_m2"],
                "m2",
                "required",
            ],
            ["energy", "wood_stove", 1, "pcs", "standard"],
            ["energy", "heat_pump", 1, "pcs", "standard"],
            ["network", "structured_cabling", 1, "lot", "Cat6A or better"],
        ]
        with output.open("w", newline="", encoding="utf-8") as f:
            writer = csv.writer(f)
            writer.writerows(rows)
        print(f"Wrote {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
from __future__ import annotations

import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]
REFERENCE = ROOT / "reference"

REQUIRED_FEATURES = [
    "universal_design",
    "local_first_smart_home",
    "structured_network",
    "wood_stove",
]


def validate_house_config(path: Path) -> list[str]:
    errors: list[str] = []
    data = yaml.safe_load(path.read_text(encoding="utf-8"))

    if data["house"].get("floors") != 1:
        errors.append(f"{path}: OHS reference houses must be single-storey")

    tech = data.get("technical_zones", {}).get("dry_technical_room", {})
    if not tech.get("required"):
        errors.append(f"{path}: dry technical room is required")
    if tech.get("water_installations_allowed") is not False:
        errors.append(f"{path}: water installations must not be allowed in dry technical room")

    rooms = data.get("rooms", {})
    if float(rooms.get("dry_technical_room_m2", 0)) < 4.0:
        errors.append(f"{path}: dry technical room should be at least 4.0 m²")

    features = data.get("features", {})
    for feature in REQUIRED_FEATURES:
        if features.get(feature) is not True:
            errors.append(f"{path}: missing required feature {feature}")

    return errors


def main() -> int:
    paths = sorted(REFERENCE.glob("oh*/config/house.yaml"))
    if not paths:
        print("No reference house configs found", file=sys.stderr)
        return 1

    errors: list[str] = []
    for path in paths:
        errors.extend(validate_house_config(path))

    if errors:
        print("OHS validation failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    print(f"OHS validation passed for {len(paths)} reference houses.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

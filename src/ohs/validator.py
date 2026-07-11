"""Validation helpers for OHS reference models."""

from __future__ import annotations

from pathlib import Path

from .config import load_yaml

REQUIRED_FEATURES = {
    "universal_design",
    "technical_room",
    "wood_stove",
    "local_smart_home",
}


def validate_house_config(path: str | Path) -> list[str]:
    """Return a list of validation issues for a house config."""
    config = load_yaml(path)
    issues: list[str] = []

    if not config.get("name"):
        issues.append("Missing house name")
    if not config.get("gross_area_m2") and not config.get("area_m2"):
        issues.append("Missing gross_area_m2 or area_m2")

    features = config.get("features", {})
    if isinstance(features, dict):
        missing = sorted(feature for feature in REQUIRED_FEATURES if not features.get(feature))
        for feature in missing:
            issues.append(f"Missing required OHS feature: {feature}")

    return issues

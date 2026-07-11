from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]


def _configs() -> list[Path]:
    return sorted(ROOT.glob("reference-houses/oh*/config/house.yaml"))


def test_reference_models_exist():
    configs = _configs()
    assert {path.parents[1].name for path in configs} == {"oh90", "oh120", "oh150"}


def test_reference_models_have_dry_technical_room():
    for config in _configs():
        data = yaml.safe_load(config.read_text())
        assert data["rooms"]["dry_technical_room_m2"] >= 4.0
        assert data["technical_zones"]["dry_technical_room"]["water_installations_allowed"] is False


def test_reference_models_are_single_storey():
    for config in _configs():
        data = yaml.safe_load(config.read_text())
        assert data["house"]["floors"] == 1

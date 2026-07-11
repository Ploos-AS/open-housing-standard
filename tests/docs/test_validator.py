from pathlib import Path

import pytest
import yaml

from ohs.docs.validator import validate_nav_targets


def test_validator_accepts_existing_target(tmp_path: Path) -> None:
    generated = tmp_path / "generated"
    generated.mkdir()
    (generated / "index.md").write_text("# Home\n", encoding="utf-8")

    config = tmp_path / "mkdocs.yml"
    config.write_text(
        yaml.safe_dump({"nav": [{"Home": "index.md"}]}),
        encoding="utf-8",
    )

    validate_nav_targets(config, generated)


def test_validator_rejects_missing_target(tmp_path: Path) -> None:
    generated = tmp_path / "generated"
    generated.mkdir()

    config = tmp_path / "mkdocs.yml"
    config.write_text(
        yaml.safe_dump({"nav": [{"Missing": "missing.md"}]}),
        encoding="utf-8",
    )

    with pytest.raises(ValueError, match="missing.md"):
        validate_nav_targets(config, generated)

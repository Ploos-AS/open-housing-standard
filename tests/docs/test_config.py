from pathlib import Path

import yaml

from ohs.docs.config import create_mkdocs_config, write_mkdocs_config


def test_generated_yaml_is_parseable(tmp_path: Path) -> None:
    target = tmp_path / "mkdocs.yml"
    config = create_mkdocs_config([{"Standards": [{"Title: With Colon": "standards/example.md"}]}])

    write_mkdocs_config(target, config)
    loaded = yaml.safe_load(target.read_text(encoding="utf-8"))

    assert loaded["nav"][0]["Standards"][0]["Title: With Colon"] == ("standards/example.md")

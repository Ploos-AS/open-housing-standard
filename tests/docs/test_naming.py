from pathlib import Path

from ohs.docs.naming import normalized_relative_path, slugify_component


def test_slugify_component() -> None:
    assert slugify_component("DESIGN_PHILOSOPHY.md") == "design-philosophy.md"


def test_normalized_relative_path() -> None:
    assert (
        normalized_relative_path(Path("OHS-001") / "01-Introduction.md")
        == Path("ohs-001") / "01-introduction.md"
    )

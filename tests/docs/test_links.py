from ohs.docs.links import normalize_relative_target, rewrite_markdown_links


def test_normalizes_relative_target() -> None:
    assert normalize_relative_target("OHS-000/README.md") == "ohs-000/readme.md"


def test_preserves_fragment() -> None:
    assert (
        normalize_relative_target("OHS-001/README.md#Scope")
        == "ohs-001/readme.md#Scope"
    )


def test_preserves_external_url() -> None:
    url = "https://example.org/OHS-000/README.md"
    assert normalize_relative_target(url) == url


def test_rewrites_markdown_link() -> None:
    assert rewrite_markdown_links(
        "[Editorial Guide](OHS-000/README.md)"
    ) == "[Editorial Guide](ohs-000/readme.md)"


def test_preserves_anchor_only_link() -> None:
    source = "[Scope](#scope)"
    assert rewrite_markdown_links(source) == source

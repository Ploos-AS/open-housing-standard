from ohs.frontmatter import (
    canonical_metadata,
    normalize_heading_hierarchy,
    split_frontmatter,
)


def test_canonical_metadata_marks_appendix_informative() -> None:
    data = canonical_metadata("Appendix A — Design Rationale", False)
    assert data["Normative"] == "No"
    assert data["Depends On"] == ["OHS-000"]


def test_normalizes_numbered_subheadings() -> None:
    body = "# 8. Governance\n\n# 8.1 Purpose\n"
    result = normalize_heading_hierarchy(body, "8 — Governance")
    assert "## 8.1 Purpose" in result


def test_normalizes_appendix_subheadings() -> None:
    body = "# Appendix A — Design Rationale\n\n# A.1 Purpose\n"
    result = normalize_heading_hierarchy(body, "Appendix A — Design Rationale")
    assert "## A.1 Purpose" in result


def test_splits_frontmatter() -> None:
    text = "---\nDocument ID: OHS-001\n---\n\n# 1. Introduction\n"
    metadata, body = split_frontmatter(text)
    assert metadata["Document ID"] == "OHS-001"
    assert body.startswith("# 1. Introduction")

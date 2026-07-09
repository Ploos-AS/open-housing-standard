# ADR-0001: RFC-style standard documents

## Status

Accepted

## Context

OHS should be citable, reviewable and maintainable over many years. A single large Markdown file would be difficult to review and evolve.

## Decision

OHS standard documents are organized as numbered document families such as OHS-001, OHS-100 and OHS-200. Each document is split into small Markdown sections.

## Consequences

- Sections can be reviewed independently.
- Documents can be cited by document ID and section.
- Future standards can be added without renumbering the entire series.

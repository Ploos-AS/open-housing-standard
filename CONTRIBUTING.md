# Contributing to the Open Housing Standard

Thank you for your interest in contributing to the Open Housing Standard (OHS).

Our goal is to develop an open, vendor-neutral, long-lived standard for residential buildings through transparent technical collaboration.

## Principles

All contributions should support the following principles:

- Openness
- Vendor neutrality
- Long-term maintainability
- Repairability
- Interoperability
- Clear and testable requirements

## Before You Start

Please read:

- OHS-000
- OHS-001
- docs/project/EDITORIAL.md

## Types of Contributions

Contributions may include:

- Editorial improvements
- Clarifications
- New normative requirements
- New informative guidance
- Reference implementations
- Test cases
- Tooling improvements
- Documentation

## Workflow

1. Open an Issue.
2. Discuss the proposal.
3. Create a Pull Request.
4. Address review comments.
5. Merge after approval.

Large architectural changes SHOULD first be documented as an Architecture Decision Record (ADR).

## Editorial Requirements

Before submitting a Pull Request, run:

```bash
uv run ruff check .
uv run pytest
uv run ohs-maintain --check
uv run ohs-editorial --check
uv run ohs-build-docs --strict
```

All checks should pass.

## Licensing

Unless otherwise stated, contributions are accepted under the project's license.

# ADR-0004: Adopt OHS-000 as the Editorial Standard

- **Status:** Accepted
- **Date:** 2026-07-10

## Context

The OHS specification series requires consistent metadata, normative language, structure, lifecycle states, and editorial review practices.

Without a common editorial standard, independently developed OHS documents may become inconsistent, ambiguous, or difficult to validate.

## Decision

The project adopts **OHS-000 — Editorial and Documentation Style Guide** as the normative editorial foundation for the OHS specification series.

All normative OHS specifications must conform to OHS-000 unless an approved specification explicitly documents an exception.

## Consequences

- OHS documents use canonical YAML metadata.
- Normative keywords follow RFC 2119 and RFC 8174.
- Specification and chapter templates are maintained under `standard/OHS-000/`.
- Pull requests affecting specifications are reviewed for OHS-000 conformance.
- Existing draft documents may require editorial migration.

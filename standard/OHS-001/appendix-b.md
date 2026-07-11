---
Document ID: OHS-001
Title: Open Housing Standard
Chapter: Appendix B — Citation and Referencing
Version: 1.0.0-draft.1
Status: Draft
Category: Core Specification
Normative: 'No'
Depends On:
- OHS-000
Referenced By:
- OHS-100
- OHS-200
- OHS-300
- OHS-400
- OHS-500
- OHS-600
- OHS-700
- OHS-900
Publisher: Open Housing Standard
License: CC BY-SA 4.0
Language: English
Last Updated: '2026-07-11'
Next Review: Before 1.0.0-rc.1
---

# Appendix B — Citation and Referencing

## B.1 Purpose

This appendix provides guidance for citing, referencing, and identifying Open Housing Standard (OHS) specifications.

It is intended to ensure consistent references across documentation, software, research publications, regulatory documents, and project specifications.

This appendix is informative and does not define conformance requirements.

---

## B.2 General Principles

References to OHS specifications should include:

- specification identifier;
- version number;
- publication year;
- publication status where relevant.

Whenever practical, references should identify the exact version of the specification.

---

## B.3 Standard Identifier

Each specification is uniquely identified by its OHS number.

Examples:

```
OHS-001
OHS-100
OHS-200
OHS-300
```

Specification numbers shall remain stable once published.

---

## B.4 Version References

Version numbers should always be included.

Examples:

```
OHS-001 Version 1.0.0

OHS-100 Version 0.3.0

OHS-400 Version 2.1.1
```

Avoid references such as:

```
Latest OHS

Current OHS

Newest version
```

because they are ambiguous.

---

## B.5 Publication Status

When referring to unpublished specifications, the publication status should be included.

Examples:

```
OHS-100 Working Draft

OHS-300 Review Draft

OHS-600 Release Candidate

OHS-001 Stable
```

---

## B.6 Formal Citation

A formal citation should contain:

- project name;
- specification identifier;
- version;
- publication year.

Example:

```
Open Housing Standard.
OHS-001 Version 1.0.0 (2026).
```

---

## B.7 Repository References

Development versions may be referenced using repository locations.

Example:

```
Open Housing Standard Repository

draft branch

commit 4e12f18
```

Repository references shall not replace published version references in conformance claims.

---

## B.8 Referencing Sections

References should identify the specific section whenever practical.

Example:

```
OHS-001 Section 5.4

OHS-200 Section 7.2

OHS-400 Appendix A
```

Section references improve precision and reduce ambiguity.

---

## B.9 Cross References

Normative cross references should identify:

- specification number;
- section number.

Example:

```
See OHS-001 Section 5.6.

See OHS-200 Section 8.4.
```

Avoid references such as:

```
See the plumbing standard.

See the architecture document.
```

because document titles may evolve.

---

## B.10 ADR References

Architecture Decision Records should be referenced by ADR number.

Examples:

```
ADR-0001

ADR-0004

ADR-0012
```

Whenever practical, include the ADR title.

Example:

```
ADR-0003 — Three Reference House Sizes
```

---

## B.11 Reference Houses

Reference houses should be identified using their model identifiers.

Examples:

```
OH90

OH120

OH150
```

Avoid references based solely on descriptive names.

Example:

```
Ousdal Hus 120
```

The identifier remains stable even if descriptive names change.

---

## B.12 Reference Implementations

Reference implementations should identify:

- implementation name;
- supported specification;
- specification version.

Example:

```
Reference House OH120

Conforms to OHS-001 Version 1.0.0
```

---

## B.13 Software Implementations

Software tools implementing OHS should declare:

- supported OHS specification;
- supported version;
- implementation version.

Example:

```
Supports:

OHS-001 Version 1.0.0

OHS-400 Version 1.2.0
```

---

## B.14 Academic References

Academic publications should cite published specifications rather than repository drafts whenever possible.

Example:

```
Open Housing Standard.
OHS-001 Version 1.0.0 (2026).
```

---

## B.15 Regulatory References

When OHS specifications are referenced by regulations or contracts, the exact version should be identified.

Example:

```
This project shall conform to
Open Housing Standard OHS-200 Version 1.0.0.
```

This avoids ambiguity if newer versions are published.

---

## B.16 Change References

When discussing revisions between versions, references should identify both versions.

Example:

```
Changes from OHS-200 Version 1.0.0
to Version 1.1.0.
```

---

## B.17 Permanent References

Published OHS versions should remain permanently available.

References shall continue to resolve to the cited version even after newer versions have been published.

This principle supports long-term documentation and archival stability.

---

## B.18 Examples

Examples of recommended references:

```
Open Housing Standard.
OHS-001 Version 1.0.0 (2026).

See OHS-001 Section 5.4.

Reference House OH120.

ADR-0003 — Three Reference House Sizes.
```

Examples that should be avoided:

```
Latest OHS

Current Draft

Architecture Standard

The plumbing document

Newest version
```

These references are ambiguous and may become invalid over time.

---

## B.19 Persistent Identifiers

Future published versions of OHS may include persistent identifiers such as:

- DOI;
- permanent URLs;
- archival identifiers.

Persistent identifiers improve long-term citation stability.

---

## B.20 Summary

Consistent references improve interoperability, traceability, and long-term maintainability.

Every OHS specification should be uniquely identifiable, permanently referenceable, and unambiguous regardless of when it is read.

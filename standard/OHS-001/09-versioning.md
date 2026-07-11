# 9. Versioning

**Status:** Draft

**Normative**

---

# 9.1 Purpose

This section defines the versioning model used by all Open Housing Standard (OHS) specifications.

The objective is to provide predictable evolution, stable conformance targets, and transparent change management.

Unless explicitly stated otherwise, every published OHS specification SHALL follow this versioning model.

---

# 9.2 Version Number

Every OHS specification SHALL use Semantic Versioning.

Version numbers SHALL consist of three integers:

```
MAJOR.MINOR.PATCH
```

Example:

```
1.0.0
1.1.0
1.1.2
2.0.0
```

---

# 9.3 Major Version

A new MAJOR version SHALL be published whenever one or more of the following occur:

- removal of a normative requirement;
- incompatible modification of a normative requirement;
- incompatible modification of a conformance requirement;
- incompatible changes affecting interoperability.

Implementations conforming to different MAJOR versions SHALL NOT automatically be considered mutually conformant.

---

# 9.4 Minor Version

A new MINOR version SHALL be published when:

- new requirements are added without breaking existing conforming implementations;
- informative guidance is expanded;
- additional optional features are introduced;
- new appendices are published.

Minor versions SHOULD remain backward compatible.

---

# 9.5 Patch Version

A PATCH version SHALL contain only:

- editorial corrections;
- clarification of existing text;
- correction of typographical errors;
- updated references;
- formatting improvements.

Patch versions SHALL NOT introduce new normative requirements.

---

# 9.6 Specification Status

Every published specification SHALL declare exactly one publication status.

The following lifecycle states are defined.

## Working Draft (WD)

A document under active development.

Working Drafts MAY change without notice.

Working Drafts SHALL NOT be used for conformance claims.

---

## Review Draft (RD)

A document submitted for public technical review.

Normative content SHOULD remain relatively stable.

Review Drafts MAY still change before publication.

---

## Release Candidate (RC)

A document believed to be technically complete.

Only corrections of identified defects SHOULD be accepted.

---

## Stable

A published specification intended for production use.

Stable specifications MAY be referenced in conformance claims.

---

## Maintenance

A Stable specification receiving editorial corrections or compatible updates.

Normative changes SHOULD be avoided.

---

## Deprecated

A specification that SHOULD no longer be used for new implementations.

Existing conforming implementations remain valid unless explicitly stated otherwise.

---

## Historical

A specification retained solely for historical reference.

Historical specifications SHALL NOT be used as the basis for new implementations.

---

# 9.7 Conformance Claims

Conformance claims SHALL identify the exact specification version.

Example:

```
Conforms to OHS-001 Version 1.0.0
```

The following statement SHALL NOT be used:

```
OHS Compatible
```

because it does not identify a specific specification or version.

---

# 9.8 Backward Compatibility

Backward compatibility SHOULD be maintained whenever practical.

Breaking changes SHALL require publication of a new MAJOR version.

Editorial improvements SHALL NOT invalidate existing conforming implementations.

---

# 9.9 Publication

Every published version SHALL receive:

- a unique version number;
- a publication date;
- a permanent identifier;
- a changelog.

Published versions SHALL remain permanently available.

---

# 9.10 Change Log

Every specification SHALL include a change history.

The change history SHALL distinguish between:

- normative changes;
- informative changes;
- editorial corrections.

---

# 9.11 Deprecation

When a specification is deprecated, the following SHALL be documented:

- the reason for deprecation;
- the replacement specification, if applicable;
- the effective date;
- migration guidance.

---

# 9.12 Citation

References to OHS specifications SHOULD include:

- specification number;
- version;
- publication year.

Example:

```
Open Housing Standard.
OHS-001 Version 1.0.0 (2026).
```

---

# 9.13 Repository

The official Open Housing Standard Git repository SHALL constitute the authoritative development source.

Published releases SHALL constitute the authoritative normative versions.

When differences exist between repository drafts and published releases, the published release SHALL take precedence.

---

# 9.14 Future Revisions

Future revisions of this versioning model SHALL themselves follow the governance process defined by OHS-001.

Changes to the versioning model SHALL require publication of a new MAJOR version of OHS-001.

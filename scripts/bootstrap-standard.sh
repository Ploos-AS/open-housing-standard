#!/usr/bin/env bash
set -euo pipefail

# bootstrap-standard.sh
# Bootstrap an RFC-style OHS standard document on a draft branch.
#
# Usage:
#   ./scripts/bootstrap-standard.sh
#   ./scripts/bootstrap-standard.sh OHS-100 "Architectural Rules"
#
# Defaults:
#   Document ID: OHS-001
#   Title: Open Housing Standard

DOC_ID="${1:-OHS-001}"
DOC_TITLE="${2:-Open Housing Standard}"
DRAFT_BRANCH="${DRAFT_BRANCH:-draft}"
VERSION="${VERSION:-1.0.0-draft.1}"
STATUS="${STATUS:-Draft}"
PUBLISHER="${PUBLISHER:-Open Housing Standard}"
LICENSE="${LICENSE:-CC BY-SA 4.0}"
LANGUAGE="${LANGUAGE:-English}"

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

echo "[*] Bootstrapping ${DOC_ID} — ${DOC_TITLE}"
echo "[*] Repository root: $ROOT"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "[!] This script must be run inside a Git repository."
  exit 1
fi

# Ensure scripts directory exists and copy this script into repo if run externally.
mkdir -p scripts

# Create or switch to draft branch.
if git show-ref --verify --quiet "refs/heads/${DRAFT_BRANCH}"; then
  echo "[*] Switching to existing branch: ${DRAFT_BRANCH}"
  git switch "${DRAFT_BRANCH}"
else
  echo "[*] Creating branch: ${DRAFT_BRANCH}"
  git switch -c "${DRAFT_BRANCH}"
fi

STD_DIR="standard/${DOC_ID}"
mkdir -p "$STD_DIR"

write_if_missing() {
  local file="$1"
  shift
  if [[ ! -f "$file" ]]; then
    cat > "$file"
    echo "[+] Created $file"
  else
    echo "[=] Kept existing $file"
    cat >/dev/null
  fi
}

# Main standard files.
write_if_missing "${STD_DIR}/README.md" <<EOF
# ${DOC_ID} — ${DOC_TITLE}

**Document ID:** ${DOC_ID}  
**Title:** ${DOC_TITLE}  
**Version:** ${VERSION}  
**Status:** ${STATUS}  
**Category:** Core Specification  
**Publisher:** ${PUBLISHER}  
**License:** ${LICENSE}  
**Language:** ${LANGUAGE}

## Abstract

${DOC_ID} defines the core framework for the Open Housing Standard.

This document is intended to be normative unless explicitly marked as informative.

## Contents

1. [Introduction](01-introduction.md)
2. [Scope](02-scope.md)
3. [Normative References](03-normative-references.md)
4. [Terminology](04-terminology.md)
5. [Design Principles](05-design-principles.md)
6. [Standard Architecture](06-standard-architecture.md)
7. [Conformance](07-conformance.md)
8. [Governance](08-governance.md)
9. [Versioning](09-versioning.md)
10. [Appendix A](appendix-a.md)
11. [Appendix B](appendix-b.md)
EOF

write_if_missing "${STD_DIR}/01-introduction.md" <<'EOF'
# 1. Introduction

## 1.1 Purpose

The Open Housing Standard (OHS) defines an open, vendor-neutral framework for designing homes that are durable, accessible, repairable, and technology-friendly.

The purpose of OHS is to establish a common set of architectural and technical principles that improve long-term quality, reduce lifecycle costs, and encourage interoperability between building systems and digital tools.

OHS is intended to serve as a reference for architects, engineers, builders, software developers, homeowners, educators, and organizations seeking an open approach to residential design.

## 1.2 Vision

> **To create homes that remain practical, maintainable, and desirable for generations.**

An OHS-compliant home is designed not only for the day it is built, but for decades of adaptation, maintenance, and technological evolution.

## 1.3 Mission

The mission of the Open Housing Standard is to:

- establish an open specification for residential design;
- promote long-term durability over short-term trends;
- encourage universal accessibility throughout the building lifecycle;
- support repairability and maintainability;
- enable local-first digital infrastructure;
- reduce unnecessary complexity;
- foster an open ecosystem of reference designs, tools, and community contributions.

## 1.4 Guiding Philosophy

OHS is founded on the belief that residential buildings should be designed as long-lived infrastructure rather than disposable consumer products.

An OHS-compliant home prioritizes:

- simplicity over unnecessary complexity;
- openness over proprietary lock-in;
- maintenance over replacement;
- resilience over optimization for a single scenario;
- lifecycle value over minimum initial cost.

The standard intentionally favors solutions that remain understandable, serviceable, and adaptable throughout the expected lifespan of the building.

## 1.5 Goals

The primary goals of OHS are to:

1. define a vendor-neutral housing standard;
2. improve long-term housing quality;
3. increase accessibility and adaptability;
4. simplify maintenance and future upgrades;
5. encourage open digital documentation;
6. support interoperable building information models (BIM);
7. establish reference house designs demonstrating best practices;
8. enable software tools that automate validation, documentation, and planning.

## 1.6 Non-Goals

OHS does **not** attempt to:

- replace national or local building regulations;
- prescribe architectural style;
- mandate specific manufacturers or commercial products;
- define structural engineering calculations;
- replace professional architectural or engineering judgment;
- guarantee regulatory approval in any jurisdiction.

Compliance with OHS does not imply compliance with local building codes or legal requirements.

## 1.7 Design Lifetime

OHS assumes that residential buildings should be designed for a service life significantly exceeding current construction trends.

Reference designs and recommendations are therefore evaluated using a target design lifetime of:

> **100 years or more.**

Long-term maintainability is considered equally important as initial construction cost.

## 1.8 Audience

This specification is intended for:

- architects;
- architectural technologists;
- structural and building engineers;
- residential builders;
- municipalities and public organizations;
- software developers;
- educators;
- homeowners;
- open-source contributors.

## 1.9 Relationship to Other Standards

OHS is designed to complement, not replace, existing standards and regulations.

Where appropriate, OHS may reference external standards relating to:

- accessibility;
- BIM;
- digital documentation;
- networking;
- energy efficiency;
- safety.

External standards remain authoritative within their respective domains.
EOF

write_if_missing "${STD_DIR}/02-scope.md" <<'EOF'
# 2. Scope

This section defines the intended scope of the Open Housing Standard.

## 2.1 In Scope

OHS covers the principles, requirements, reference designs, digital documentation practices, and open tooling used to define durable, accessible, repairable, and technology-friendly homes.

## 2.2 Out of Scope

OHS does not replace national building regulations, local planning requirements, structural engineering, professional architectural judgment, or product certification.

## 2.3 Intended Use

OHS is intended to be used as a reference standard for open residential design, reference houses, documentation workflows, and software-assisted validation.
EOF

write_if_missing "${STD_DIR}/03-normative-references.md" <<'EOF'
# 3. Normative References

This section lists external standards and specifications that are required for interpreting or implementing OHS.

At this draft stage, normative references are intentionally minimal.

Future OHS documents MAY reference standards related to:

- building information modeling;
- accessibility;
- energy performance;
- digital documentation;
- networking;
- safety;
- open file formats.
EOF

write_if_missing "${STD_DIR}/04-terminology.md" <<'EOF'
# 4. Terminology

## 4.1 Normative Language

The key words **MUST**, **MUST NOT**, **REQUIRED**, **SHOULD**, **SHOULD NOT**, **RECOMMENDED**, **MAY**, and **OPTIONAL** are to be interpreted as described in RFC 2119 and RFC 8174 when, and only when, they appear in all capitals.

## 4.2 OHS Terms

**Open Housing Standard (OHS)**  
The complete family of specifications, reference designs, schemas, documentation, and tools maintained by the Open Housing Standard project.

**Reference House**  
A house design published by the OHS project to demonstrate implementation of one or more OHS specifications.

**Technical Core**  
The dedicated physical and digital infrastructure zone that supports electrical, networking, automation, monitoring, and maintenance functions.

**Technical Zone**  
A defined area used to separate wet technical systems, dry technical systems, and climate systems.

**Local-first**  
A design principle where essential digital functions remain usable without mandatory cloud connectivity.
EOF

write_if_missing "${STD_DIR}/05-design-principles.md" <<'EOF'
# 5. Design Principles

OHS is based on a set of principles that guide all later requirements and reference designs.

## 5.1 Durability

Homes SHOULD be designed for long service life, maintainability, and adaptation.

## 5.2 Universal Accessibility

Homes SHOULD support use across life stages and changing physical abilities.

## 5.3 Repairability

Systems and components SHOULD be accessible, replaceable, and documented.

## 5.4 Standardization

Designs SHOULD prefer standard dimensions, open standards, and commonly available components.

## 5.5 Local-first Technology

Essential digital functions SHOULD work without mandatory cloud services.

## 5.6 Low Lifecycle Cost

Design decisions SHOULD consider construction cost, maintenance, energy use, replacement intervals, and end-of-life impact.
EOF

write_if_missing "${STD_DIR}/06-standard-architecture.md" <<'EOF'
# 6. Standard Architecture

The OHS specification family is organized into numbered documents.

## 6.1 Core Specification

- **OHS-001**: Open Housing Standard

## 6.2 Architectural Series

- **OHS-100**: Architectural Rules

## 6.3 Technical Series

- **OHS-200**: Technical Core
- **OHS-300**: Universal Design
- **OHS-400**: Energy & Sustainability
- **OHS-500**: Documentation & Digital Assets
- **OHS-600**: Reference Houses
- **OHS-700**: Compliance & Certification
- **OHS-900**: Glossary

## 6.4 Reference Designs

Reference houses demonstrate implementation of OHS requirements but are not themselves the full standard.
EOF

write_if_missing "${STD_DIR}/07-conformance.md" <<'EOF'
# 7. Conformance

A house, design, tool, or documentation package MAY claim conformance with one or more OHS specifications only when it satisfies the applicable normative requirements.

## 7.1 Conformance Claims

A conformance claim SHOULD identify:

- document ID;
- document version;
- conformance level, if applicable;
- implementation scope;
- known deviations.

Example:

> This design conforms to OHS-001 v1.0.0-draft.1 and partially implements OHS-200 v1.0.0-draft.1.

## 7.2 Partial Conformance

Partial conformance MAY be declared when the scope and limitations are clearly documented.
EOF

write_if_missing "${STD_DIR}/08-governance.md" <<'EOF'
# 8. Governance

The Open Housing Standard is developed as an open specification.

## 8.1 Proposal Process

Changes SHOULD be proposed through issues, discussions, pull requests, or architecture decision records.

## 8.2 Review

Normative changes SHOULD receive review before being merged.

## 8.3 Decision Records

Important decisions SHOULD be documented using Architecture Decision Records (ADRs).

## 8.4 Publication

Published drafts SHOULD be tagged and documented in the changelog.
EOF

write_if_missing "${STD_DIR}/09-versioning.md" <<'EOF'
# 9. Versioning

OHS documents use semantic versioning.

## 9.1 Version Format

Versions SHOULD use the format:

```text
MAJOR.MINOR.PATCH
```

Drafts MAY append a draft suffix, for example:

```text
1.0.0-draft.1
```

## 9.2 Compatibility

Breaking normative changes SHOULD increment the major version.

Backward-compatible additions SHOULD increment the minor version.

Editorial fixes SHOULD increment the patch version.
EOF

write_if_missing "${STD_DIR}/appendix-a.md" <<'EOF'
# Appendix A — Informative Examples

This appendix is informative.

Examples may be added to illustrate OHS concepts, reference houses, and conformance statements.
EOF

write_if_missing "${STD_DIR}/appendix-b.md" <<'EOF'
# Appendix B — Future Work

This appendix is informative.

Future work may include expanded conformance levels, reference house validation, and automated documentation generation.
EOF

# Changelog for the specific standard.
write_if_missing "${STD_DIR}/CHANGELOG.md" <<EOF
# Changelog — ${DOC_ID}

## ${VERSION}

- Initial RFC-style draft structure.
EOF

# Local milestone note.
mkdir -p docs/project/milestones
write_if_missing "docs/project/milestones/${DOC_ID}-draft.md" <<EOF
# Milestone: ${DOC_ID} Draft

## Goal

Publish ${DOC_ID} — ${DOC_TITLE} as a referable draft specification.

## Definition of Done

- All core chapters exist.
- Metadata is complete.
- MkDocs navigation includes the document.
- Draft is reviewed.
- Draft is tagged or released when ready.

## Suggested Issues

- ${DOC_ID}: Introduction
- ${DOC_ID}: Scope
- ${DOC_ID}: Normative References
- ${DOC_ID}: Terminology
- ${DOC_ID}: Design Principles
- ${DOC_ID}: Standard Architecture
- ${DOC_ID}: Conformance
- ${DOC_ID}: Governance
- ${DOC_ID}: Versioning
EOF

# Update mkdocs.yml conservatively if it exists and does not already mention DOC_ID.
if [[ -f mkdocs.yml ]]; then
  if ! grep -q "${DOC_ID}" mkdocs.yml; then
    echo "[*] Adding ${DOC_ID} to mkdocs.yml"
    cat >> mkdocs.yml <<EOF

# Added by scripts/bootstrap-standard.sh
# Review placement if your MkDocs nav is manually curated.
# ${DOC_ID}: standard/${DOC_ID}/README.md
EOF
  else
    echo "[=] mkdocs.yml already references ${DOC_ID}"
  fi
else
  echo "[*] Creating minimal mkdocs.yml"
  cat > mkdocs.yml <<EOF
site_name: Open Housing Standard
site_description: Open, vendor-neutral housing standard
repo_url: https://github.com/OpenHousingStandard/open-housing-standard

theme:
  name: material

nav:
  - Home: README.md
  - Standards:
      - ${DOC_ID}: standard/${DOC_ID}/README.md
EOF
fi

# Create a simple index if missing.
write_if_missing "standard/README.md" <<'EOF'
# Open Housing Standard Documents

This directory contains the numbered OHS specification series.

## Core

- [OHS-001 — Open Housing Standard](OHS-001/README.md)

## Series

- OHS-100 — Architectural Rules
- OHS-200 — Technical Core
- OHS-300 — Universal Design
- OHS-400 — Energy & Sustainability
- OHS-500 — Documentation & Digital Assets
- OHS-600 — Reference Houses
- OHS-700 — Compliance & Certification
- OHS-900 — Glossary
EOF

# Ensure script is tracked if this file path exists.
chmod +x scripts/bootstrap-standard.sh 2>/dev/null || true

echo
echo "[*] Bootstrap complete."
echo "[*] Current branch: $(git branch --show-current)"
echo
echo "Next commands:"
echo "  git status"
echo "  uv run mkdocs serve"
echo "  git add -A"
echo "  git commit -m \"Bootstrap ${DOC_ID} draft standard\""
echo "  git push -u origin ${DRAFT_BRANCH}"

#!/usr/bin/env bash
set -euo pipefail

# bootstrap-ohs-editorial.sh
#
# Creates the editorial infrastructure for the Open Housing Standard:
# - OHS-000 editorial standard
# - canonical metadata/specification templates
# - document lifecycle guidance
# - GitHub issue and pull-request templates
# - ADR recording the decision
# - conservative index and MkDocs hints
#
# Run from the repository root:
#   chmod +x scripts/bootstrap-ohs-editorial.sh
#   ./scripts/bootstrap-ohs-editorial.sh
#
# The script is idempotent: existing files are preserved unless noted.

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

echo "[*] Repository root: $ROOT"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "[!] This script must be run inside a Git repository."
  exit 1
fi

TODAY="${OHS_DATE:-$(date +%F)}"
VERSION="${OHS_EDITORIAL_VERSION:-1.0.0-draft.1}"
NEXT_REVIEW="${OHS_NEXT_REVIEW:-Before 1.0.0-rc.1}"

OHS000_DIR="standard/OHS-000"
ADR_DIR="docs/adr"
PR_DIR=".github/PULL_REQUEST_TEMPLATE"
ISSUE_DIR=".github/ISSUE_TEMPLATE"
MILESTONE_DIR="docs/project/milestones"

mkdir -p \
  "$OHS000_DIR" \
  "$ADR_DIR" \
  "$PR_DIR" \
  "$ISSUE_DIR" \
  "$MILESTONE_DIR" \
  scripts

write_if_missing() {
  local path="$1"
  if [[ -e "$path" ]]; then
    echo "[=] Preserving existing $path"
    cat >/dev/null
  else
    cat > "$path"
    echo "[+] Created $path"
  fi
}

append_block_once() {
  local file="$1"
  local marker="$2"
  local block="$3"

  touch "$file"

  if grep -Fq "$marker" "$file"; then
    echo "[=] $file already contains $marker"
  else
    printf "\n%s\n" "$block" >> "$file"
    echo "[+] Updated $file"
  fi
}

###############################################################################
# OHS-000 core document
###############################################################################

write_if_missing "$OHS000_DIR/README.md" <<EOF
---
Document ID: OHS-000
Title: Editorial and Documentation Style Guide
Chapter: Complete Specification

Version: ${VERSION}
Status: Draft

Category: Editorial Standard

Normative: Yes

Depends On: []

Referenced By:
  - OHS-001
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

Last Updated: ${TODAY}
Next Review: ${NEXT_REVIEW}
---

# OHS-000 — Editorial and Documentation Style Guide

## 1. Purpose

This specification defines the editorial conventions used throughout the Open Housing Standard (OHS) specification series.

Its purpose is to ensure consistency, readability, traceability, testability, and long-term maintainability across all OHS publications.

All normative OHS specifications **MUST** conform to this document unless an approved OHS specification explicitly defines an exception.

## 2. Conformance Language

The key words **MUST**, **MUST NOT**, **REQUIRED**, **SHALL**, **SHALL NOT**, **SHOULD**, **SHOULD NOT**, **RECOMMENDED**, **MAY**, and **OPTIONAL** are to be interpreted as described by RFC 2119 and RFC 8174 when, and only when, they appear in all capitals.

Normative keywords **MUST NOT** be capitalized for emphasis when they are not being used normatively.

## 3. Required Metadata

Every normative OHS document **MUST** begin with a YAML metadata block.

The metadata block **MUST** include:

- Document ID;
- Title;
- Chapter;
- Version;
- Status;
- Category;
- Normative;
- Depends On;
- Referenced By;
- Publisher;
- License;
- Language;
- Last Updated;
- Next Review.

Metadata field names **MUST** use the spelling and capitalization defined by [TEMPLATE.md](TEMPLATE.md).

## 4. Document Structure

A complete OHS specification **SHOULD** contain:

1. metadata;
2. title;
3. purpose or introduction;
4. scope;
5. normative references;
6. terminology;
7. normative requirements;
8. conformance criteria;
9. informative appendices, where needed;
10. change history.

A chapter file **MAY** contain only the sections relevant to that chapter.

## 5. Writing Style

Normative OHS text **MUST**:

- use clear and direct language;
- distinguish requirements from explanations;
- avoid marketing claims;
- avoid unnecessary adjectives;
- define specialized terms before relying on them;
- avoid ambiguous pronouns and undefined references;
- express one independently testable requirement per sentence where practical;
- use active voice where it improves clarity.

A requirement **SHOULD** identify the subject responsible for satisfying it.

## 6. Requirements

A normative requirement **MUST** be sufficiently precise to support review, implementation, or verification.

A normative requirement **SHOULD**:

- be objectively testable;
- remain vendor-neutral;
- avoid naming commercial products;
- avoid prescribing an implementation where a performance requirement is sufficient;
- state exceptions explicitly;
- avoid combining unrelated obligations.

Informative guidance **MUST NOT** silently introduce additional requirements.

## 7. Terminology

Terms defined by the OHS series **MUST** be used consistently.

A document that introduces a new technical term **MUST** define it in its terminology section or reference the OHS glossary.

Synonyms **SHOULD NOT** be used for defined terms when doing so could create ambiguity.

## 8. Normative and Informative Content

Content is normative unless it is explicitly marked as informative or appears in an informative appendix.

Examples, notes, rationales, and implementation guidance **SHOULD** be marked as informative.

An informative example **MUST NOT** override normative text.

## 9. Headings and Numbering

Top-level sections **MUST** use a single level-one Markdown heading.

Subsections **MUST** use consecutively deeper heading levels without skipping levels.

Numbered OHS chapters **SHOULD** use decimal section numbering.

## 10. Lists and Tables

Lists **SHOULD** be used for parallel items or discrete requirements.

Tables **MAY** be used where they improve comparison or readability.

A table **MUST NOT** be the only location of a critical normative requirement unless each relevant cell is unambiguous and testable.

## 11. Diagrams and Figures

Diagrams and figures are informative unless explicitly identified as normative.

Editable source files **SHOULD** be stored alongside or traceably linked to exported figures.

Each figure **SHOULD** include a descriptive caption and alternative text.

## 12. References

Normative references **MUST** appear in the normative references section of the specification that relies on them.

Informative sources **SHOULD** appear in an informative references section or appendix.

References **SHOULD** identify the publisher, title, version or date, and stable identifier where available.

## 13. File Naming

Markdown filenames **MUST** use lowercase ASCII characters and hyphens.

Chapter filenames **SHOULD** begin with a two-digit sequence number.

Examples:

\`\`\`text
01-introduction.md
02-scope.md
03-normative-references.md
\`\`\`

## 14. Versioning and Status

OHS documents **MUST** use semantic versioning.

Drafts **SHOULD** use:

\`\`\`text
1.0.0-draft.1
\`\`\`

Release candidates **SHOULD** use:

\`\`\`text
1.0.0-rc.1
\`\`\`

Stable publications **MUST NOT** use a draft or release-candidate suffix.

Allowed lifecycle states are defined in [DOCUMENT-LIFECYCLE.md](DOCUMENT-LIFECYCLE.md).

## 15. Change History

Each complete specification **MUST** maintain a changelog.

The changelog **MUST** identify:

- version;
- publication or revision date;
- material normative changes;
- major editorial changes;
- compatibility impact, where applicable.

## 16. Accessibility

Documentation **SHOULD** be usable with common assistive technologies.

Authors **SHOULD**:

- use descriptive link text;
- provide alternative text for meaningful images;
- avoid conveying meaning through color alone;
- use tables only for tabular data;
- maintain a logical heading hierarchy.

## 17. Language

The normative language of the OHS specification series is English unless a specification states otherwise.

Translations **MUST** identify the authoritative source version.

A translation **MUST NOT** claim authority over the source version unless formally approved through OHS governance.

## 18. Conformance

A document claiming to be part of the normative OHS specification series **MUST** comply with this specification.

Deviations **MUST** be documented and justified.

## 19. Change History

### ${VERSION}

- Initial editorial standard.
EOF

###############################################################################
# Supporting editorial documents
###############################################################################

write_if_missing "$OHS000_DIR/STYLE.md" <<'EOF'
# OHS Editorial Style

This document supplements OHS-000 with practical editorial guidance.

## Preferred style

- Prefer short, direct sentences.
- State the actor before the obligation.
- Use one normative keyword per independent requirement where practical.
- Separate rationale from normative requirements.
- Use consistent OHS terminology.
- Prefer measurable wording over subjective wording.

## Avoid

- Marketing language.
- Unqualified words such as “best”, “future-proof”, or “perfect”.
- Product-specific requirements where an open requirement is possible.
- Hidden requirements inside examples or notes.
- Multiple unrelated obligations in one sentence.

## Example

Preferred:

> A reference house **MUST** include a documented technical zone.

Avoid:

> Reference houses should include a modern and future-proof technical area that is easy to use and maintain.
EOF

write_if_missing "$OHS000_DIR/TEMPLATE.md" <<'EOF'
---
Document ID: OHS-XYZ
Title: Specification Title
Chapter: Complete Specification

Version: 1.0.0-draft.1
Status: Draft

Category: Specification Category

Normative: Yes

Depends On:
  - OHS-000

Referenced By: []

Publisher: Open Housing Standard

License: CC BY-SA 4.0

Language: English

Last Updated: YYYY-MM-DD
Next Review: Before 1.0.0-rc.1
---

# OHS-XYZ — Specification Title

## 1. Introduction

## 2. Scope

## 3. Normative References

## 4. Terminology

## 5. Requirements

## 6. Conformance

## 7. Security, Safety, and Privacy Considerations

## 8. Change History

### 1.0.0-draft.1

- Initial draft.
EOF

write_if_missing "$OHS000_DIR/CHAPTER-TEMPLATE.md" <<'EOF'
---
Document ID: OHS-XYZ
Title: Specification Title
Chapter: N — Chapter Title

Version: 1.0.0-draft.1
Status: Draft

Category: Specification Category

Normative: Yes

Depends On:
  - OHS-000

Referenced By: []

Publisher: Open Housing Standard

License: CC BY-SA 4.0

Language: English

Last Updated: YYYY-MM-DD
Next Review: Before 1.0.0-rc.1
---

# N. Chapter Title

## N.1 Purpose

## N.2 Requirements

## N.3 Conformance
EOF

write_if_missing "$OHS000_DIR/DOCUMENT-LIFECYCLE.md" <<'EOF'
# OHS Document Lifecycle

## Draft

Active development. Requirements may change without compatibility guarantees.

## Review Draft

The document is considered structurally complete and is undergoing technical and editorial review.

## Release Candidate

The document is believed to be suitable for stable publication. Only corrections and release-blocking changes should be accepted.

## Stable

The document is published and citable. Normative changes require a new compatible or breaking version.

## Superseded

A newer specification replaces the document. The superseded document remains available for historical reference.

## Withdrawn

The document is no longer recommended and has no approved replacement, or contains material defects that prevent continued use.

## Status transitions

A status change **SHOULD** be proposed through a pull request.

A transition to Release Candidate or Stable **SHOULD** include:

- completed technical review;
- completed editorial review;
- updated changelog;
- resolved normative ambiguities;
- validated internal links and metadata;
- an approved release decision.
EOF

write_if_missing "$OHS000_DIR/CHANGELOG.md" <<EOF
# Changelog — OHS-000

## ${VERSION} — ${TODAY}

- Established the OHS editorial standard.
- Defined canonical metadata.
- Defined normative writing conventions.
- Added specification and chapter templates.
- Defined the document lifecycle.
EOF

###############################################################################
# GitHub templates
###############################################################################

write_if_missing "$PR_DIR/specification.md" <<'EOF'
---
name: Specification change
about: Propose a normative or editorial change to an OHS specification
---

## Document

- Document ID:
- Version:
- Section(s):

## Change type

- [ ] Normative
- [ ] Editorial
- [ ] Informative
- [ ] Metadata
- [ ] Reference update
- [ ] Breaking change

## Summary

Describe the proposed change.

## Rationale

Explain why the change is needed.

## Conformance impact

Describe how implementations or conformance claims may be affected.

## Checklist

- [ ] The change follows OHS-000.
- [ ] Normative statements are testable.
- [ ] Terminology is defined or referenced.
- [ ] Normative and informative text are clearly separated.
- [ ] Metadata and changelog are updated.
- [ ] Internal links and references have been checked.
EOF

write_if_missing "$ISSUE_DIR/specification.yml" <<'EOF'
name: Specification issue
description: Report ambiguity, inconsistency, or an editorial problem in an OHS specification
title: "[Specification]: "
labels:
  - area:standard
body:
  - type: input
    id: document
    attributes:
      label: Document ID and version
      placeholder: OHS-001 v1.0.0-draft.1
    validations:
      required: true

  - type: input
    id: section
    attributes:
      label: Section
      placeholder: 4.2
    validations:
      required: true

  - type: textarea
    id: problem
    attributes:
      label: Problem
      description: Describe the ambiguity, inconsistency, or editorial issue.
    validations:
      required: true

  - type: textarea
    id: proposal
    attributes:
      label: Proposed resolution
      description: Suggest revised wording or another resolution.

  - type: checkboxes
    id: checks
    attributes:
      label: Checks
      options:
        - label: I checked the latest draft.
          required: true
        - label: I searched existing issues and discussions.
          required: true
EOF

write_if_missing "$ISSUE_DIR/change-proposal.yml" <<'EOF'
name: OHS change proposal
description: Propose a new normative requirement or a material change
title: "[Proposal]: "
labels:
  - proposal
body:
  - type: input
    id: target
    attributes:
      label: Target document
      placeholder: OHS-100
    validations:
      required: true

  - type: textarea
    id: proposal
    attributes:
      label: Proposal
      description: State the proposed requirement or change.
    validations:
      required: true

  - type: textarea
    id: rationale
    attributes:
      label: Rationale
      description: Explain the problem and why this change is appropriate.
    validations:
      required: true

  - type: textarea
    id: verification
    attributes:
      label: Verification
      description: Explain how the requirement can be tested or reviewed.

  - type: textarea
    id: compatibility
    attributes:
      label: Compatibility impact
      description: Identify possible breaking changes or migration needs.
EOF

###############################################################################
# ADR and milestone
###############################################################################

ADR_FILE="$ADR_DIR/0004-editorial-standard.md"
write_if_missing "$ADR_FILE" <<EOF
# ADR-0004: Adopt OHS-000 as the Editorial Standard

- **Status:** Accepted
- **Date:** ${TODAY}

## Context

The OHS specification series requires consistent metadata, normative language, structure, lifecycle states, and editorial review practices.

Without a common editorial standard, independently developed OHS documents may become inconsistent, ambiguous, or difficult to validate.

## Decision

The project adopts **OHS-000 — Editorial and Documentation Style Guide** as the normative editorial foundation for the OHS specification series.

All normative OHS specifications must conform to OHS-000 unless an approved specification explicitly documents an exception.

## Consequences

- OHS documents use canonical YAML metadata.
- Normative keywords follow RFC 2119 and RFC 8174.
- Specification and chapter templates are maintained under \`standard/OHS-000/\`.
- Pull requests affecting specifications are reviewed for OHS-000 conformance.
- Existing draft documents may require editorial migration.
EOF

write_if_missing "$MILESTONE_DIR/OHS-000-draft.md" <<EOF
# Milestone: OHS-000 Draft

## Goal

Publish OHS-000 — Editorial and Documentation Style Guide as a stable editorial foundation for the OHS series.

## Definition of Done

- Canonical metadata is approved.
- Normative language rules are approved.
- Specification and chapter templates are approved.
- Document lifecycle is approved.
- OHS-001 has been reviewed for OHS-000 conformance.
- Changelog is complete.
- Release candidate review is complete.
EOF

###############################################################################
# Index updates
###############################################################################

if [[ ! -f standard/README.md ]]; then
  cat > standard/README.md <<'EOF'
# Open Housing Standard Documents
EOF
  echo "[+] Created standard/README.md"
fi

append_block_once \
  "standard/README.md" \
  "OHS-000 — Editorial and Documentation Style Guide" \
  "## Editorial Standard

- [OHS-000 — Editorial and Documentation Style Guide](OHS-000/README.md)"

if [[ -f docs/adr/index.md ]]; then
  append_block_once \
    "docs/adr/index.md" \
    "ADR-0004" \
    "- [ADR-0004: Adopt OHS-000 as the Editorial Standard](0004-editorial-standard.md)"
fi

if [[ -f mkdocs.yml ]]; then
  if grep -Fq "OHS-000" mkdocs.yml; then
    echo "[=] mkdocs.yml already references OHS-000"
  else
    cat >> mkdocs.yml <<'EOF'

# OHS-000 navigation hint added by bootstrap-ohs-editorial.sh.
# Move this entry into the curated nav section if required:
# - OHS-000 Editorial Standard: standard/OHS-000/README.md
EOF
    echo "[+] Added OHS-000 navigation hint to mkdocs.yml"
  fi
fi

###############################################################################
# Optional metadata conformance reminder for OHS-001
###############################################################################

if [[ -d standard/OHS-001 ]]; then
  cat > "$OHS000_DIR/OHS-001-MIGRATION-CHECKLIST.md" <<'EOF'
# OHS-001 Editorial Migration Checklist

- [ ] Each chapter uses canonical OHS-000 metadata.
- [ ] `Depends On` includes OHS-000 where appropriate.
- [ ] Normative keywords are used only in uppercase and with RFC meaning.
- [ ] Informative examples and notes are explicitly identified.
- [ ] Requirements are testable.
- [ ] Defined terminology is used consistently.
- [ ] Changelog is updated.
- [ ] Internal links and references are valid.
EOF
  echo "[+] Created OHS-001 migration checklist"
fi

###############################################################################
# Validation summary
###############################################################################

echo
echo "[*] Validating generated structure..."

required_files=(
  "$OHS000_DIR/README.md"
  "$OHS000_DIR/STYLE.md"
  "$OHS000_DIR/TEMPLATE.md"
  "$OHS000_DIR/CHAPTER-TEMPLATE.md"
  "$OHS000_DIR/DOCUMENT-LIFECYCLE.md"
  "$OHS000_DIR/CHANGELOG.md"
  "$PR_DIR/specification.md"
  "$ISSUE_DIR/specification.yml"
  "$ISSUE_DIR/change-proposal.yml"
  "$ADR_FILE"
)

failed=0
for file in "${required_files[@]}"; do
  if [[ -f "$file" ]]; then
    echo "  [ok] $file"
  else
    echo "  [missing] $file"
    failed=1
  fi
done

if [[ "$failed" -ne 0 ]]; then
  echo "[!] One or more required files are missing."
  exit 1
fi

echo
echo "[✓] OHS editorial infrastructure is ready."
echo
echo "Review:"
echo "  git diff --stat"
echo "  git diff"
echo
echo "Test documentation:"
echo "  uv run mkdocs build --strict"
echo
echo "Commit:"
echo "  git add -A"
echo '  git commit -m "Add OHS-000 editorial infrastructure"'
echo "  git push origin $(git branch --show-current)"

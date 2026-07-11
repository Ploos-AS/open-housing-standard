from __future__ import annotations

import re
import argparse
import shutil
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Any

import yaml

EXPECTED_MODELS = ("oh90", "oh120", "oh150")
EXPECTED_OHS001 = (
    "01-introduction.md",
    "02-scope.md",
    "03-normative-references.md",
    "04-terminology.md",
    "05-requirements.md",
    "06-standard-architecture.md",
    "07-conformance.md",
    "08-governance.md",
    "09-versioning.md",
    "appendix-a.md",
    "appendix-b.md",
)

TEMPORARY_PATTERNS = (
    "*.before-*",
    "*.bak",
    "*.old",
    "*.orig",
)

KNOWN_TEMPORARY_FILES = (
    "src/ohs/docs/builder.py.before-link-rewrite",
    "scripts/replace-docs-builder-with-link-rewrite.sh",
    "scripts/fix-generated-doc-links.sh",
    "scripts/fix-links-import.sh",
    "scripts/patch-generated-doc-links.sh",
    "scripts/reset-ohs-docs-tooling.sh",
    "scripts/setup-generated-docs-pipeline.sh",
    "scripts/improve-generated-docs-pipeline.sh",
    "scripts/migrate-docs-tooling-to-python.sh",
)


@dataclass
class Finding:
    level: str
    area: str
    message: str


@dataclass
class Report:
    findings: list[Finding] = field(default_factory=list)
    changes: list[str] = field(default_factory=list)

    def error(self, area: str, message: str) -> None:
        self.findings.append(Finding("ERROR", area, message))

    def warn(self, area: str, message: str) -> None:
        self.findings.append(Finding("WARN", area, message))

    def ok(self, area: str, message: str) -> None:
        self.findings.append(Finding("OK", area, message))

    def changed(self, message: str) -> None:
        self.changes.append(message)

    @property
    def errors(self) -> int:
        return sum(item.level == "ERROR" for item in self.findings)

    @property
    def warnings(self) -> int:
        return sum(item.level == "WARN" for item in self.findings)


class Maintainer:
    def __init__(self, root: Path, fix: bool) -> None:
        self.root = root
        self.fix = fix
        self.report = Report()
        stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        self.backup_root = root / ".ohs-maintenance-backup" / stamp

    def rel(self, path: Path) -> str:
        return path.relative_to(self.root).as_posix()

    def backup(self, path: Path) -> None:
        if not path.exists():
            return
        target = self.backup_root / path.relative_to(self.root)
        target.parent.mkdir(parents=True, exist_ok=True)
        if path.is_dir():
            shutil.copytree(path, target, dirs_exist_ok=True)
        else:
            shutil.copy2(path, target)

    def write(self, path: Path, content: str) -> None:
        if path.exists() and path.read_text(encoding="utf-8") == content:
            return
        if path.exists():
            self.backup(path)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
        self.report.changed(f"Updated {self.rel(path)}")

    def remove(self, path: Path) -> None:
        if not path.exists():
            return
        self.backup(path)
        if path.is_dir():
            shutil.rmtree(path)
        else:
            path.unlink()
        self.report.changed(f"Archived and removed {self.rel(path)}")

    def move(self, source: Path, target: Path) -> None:
        if not source.exists():
            return
        self.backup(source)
        if target.exists():
            self.backup(target)
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(source), str(target))
        self.report.changed(f"Moved {self.rel(source)} -> {self.rel(target)}")

    def run(self) -> Report:
        self.normalize_ohs001()
        self.normalize_defaults()
        self.update_adr_index()
        self.check_roadmap()
        self.check_legacy()
        self.clean_temporary_files()
        self.check_root_contract()
        self.check_reference_models()
        return self.report

    def normalize_ohs001(self) -> None:
        area = "OHS-001"
        directory = self.root / "standard" / "OHS-001"
        if not directory.exists():
            self.report.error(area, "standard/OHS-001 is missing.")
            return

        old_five = directory / "05-design-principles.md"
        new_five = directory / "05-requirements.md"
        if old_five.exists() and not new_five.exists():
            text = old_five.read_text(encoding="utf-8")
            if text.lstrip().startswith("# 5. Requirements"):
                if self.fix:
                    self.move(old_five, new_five)
                else:
                    self.report.error(
                        area,
                        "05-design-principles.md contains Requirements and should be "
                        "renamed to 05-requirements.md.",
                    )

        self._promote_detailed_chapter(
            source=directory / "06-conformance.md",
            target=directory / "07-conformance.md",
            source_heading="# 6. Conformance",
            target_heading="# 7. Conformance",
            area=area,
        )
        self._promote_detailed_chapter(
            source=directory / "07-versioning.md",
            target=directory / "09-versioning.md",
            source_heading="# 7. Versioning",
            target_heading="# 9. Versioning",
            area=area,
        )

        duplicates = self._duplicate_chapter_numbers(directory)
        if duplicates:
            message = ", ".join(
                f"{number}: {', '.join(names)}" for number, names in sorted(duplicates.items())
            )
            self.report.error(area, f"Duplicate chapter numbers remain: {message}")
        else:
            self.report.ok(area, "Chapter numbers are unique.")

        missing = [filename for filename in EXPECTED_OHS001 if not (directory / filename).exists()]
        if missing:
            self.report.error(area, f"Missing canonical files: {', '.join(missing)}")
        else:
            self.report.ok(area, "Canonical chapter set is complete.")

        if self.fix:
            self._write_ohs001_index(directory)

    def _promote_detailed_chapter(
        self,
        source: Path,
        target: Path,
        source_heading: str,
        target_heading: str,
        area: str,
    ) -> None:
        if not source.exists():
            return

        source_text = source.read_text(encoding="utf-8")
        target_text = target.read_text(encoding="utf-8") if target.exists() else ""

        if len(source_text.strip()) <= len(target_text.strip()):
            self.report.warn(
                area,
                f"{self.rel(source)} exists but is not more detailed than "
                f"{self.rel(target)}; manual review recommended.",
            )
            return

        promoted = source_text.replace(source_heading, target_heading, 1)

        if self.fix:
            self.write(target, promoted.rstrip() + "\n")
            self.remove(source)
        else:
            self.report.error(
                area,
                f"{self.rel(source)} should be promoted into {self.rel(target)}.",
            )

    @staticmethod
    def _duplicate_chapter_numbers(directory: Path) -> dict[str, list[str]]:
        groups: dict[str, list[str]] = {}
        for path in directory.glob("[0-9][0-9]-*.md"):
            number = path.name[:2]
            groups.setdefault(number, []).append(path.name)
        return {number: sorted(names) for number, names in groups.items() if len(names) > 1}

    def _write_ohs001_index(self, directory: Path) -> None:
        content = """# OHS-001 — Open Housing Standard

**Version:** 1.0.0-draft.1

This directory contains the normative chapters of the Open Housing Standard
core specification.

## Contents

1. [Introduction](01-introduction.md)
2. [Scope](02-scope.md)
3. [Normative References](03-normative-references.md)
4. [Terminology](04-terminology.md)
5. [Requirements](05-requirements.md)
6. [Standard Architecture](06-standard-architecture.md)
7. [Conformance](07-conformance.md)
8. [Governance](08-governance.md)
9. [Versioning](09-versioning.md)
10. [Appendix A](appendix-a.md)
11. [Appendix B](appendix-b.md)
"""
        self.write(directory / "README.md", content)

    def normalize_defaults(self) -> None:
        area = "Defaults"
        old = self.root / "config" / "defaults.yaml"
        canonical = self.root / "config" / "defaults" / "ohs-defaults.yaml"

        if old.exists() and canonical.exists():
            self.report.error(
                area,
                "Two defaults sources exist: config/defaults.yaml and "
                "config/defaults/ohs-defaults.yaml.",
            )
            if self.fix:
                old_data = self._load_yaml(old)
                canonical_data = self._load_yaml(canonical)
                merged = self._deep_merge(canonical_data, old_data)

                # Preserve the canonical standard metadata while importing the
                # richer implementation defaults from the old root file.
                if isinstance(canonical_data.get("standard"), dict):
                    merged["standard"] = canonical_data["standard"]

                rendered = yaml.safe_dump(
                    merged,
                    sort_keys=False,
                    allow_unicode=True,
                    width=100,
                )
                self.write(canonical, rendered)
                self.remove(old)

        elif canonical.exists():
            self.report.ok(area, "Single canonical defaults source is present.")
        elif old.exists():
            self.report.warn(
                area,
                "Only config/defaults.yaml exists; canonical location should be "
                "config/defaults/ohs-defaults.yaml.",
            )
            if self.fix:
                self.move(old, canonical)
        else:
            self.report.error(area, "No defaults configuration was found.")

    @staticmethod
    def _load_yaml(path: Path) -> dict[str, Any]:
        data = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
        if not isinstance(data, dict):
            raise ValueError(f"{path} must contain a YAML mapping.")
        return data

    @classmethod
    def _deep_merge(
        cls,
        base: dict[str, Any],
        incoming: dict[str, Any],
    ) -> dict[str, Any]:
        result = dict(base)
        for key, value in incoming.items():
            if key in result and isinstance(result[key], dict) and isinstance(value, dict):
                result[key] = cls._deep_merge(result[key], value)
            elif key not in result:
                result[key] = value
            elif key == "defaults":
                result[key] = value
        return result

    def update_adr_index(self) -> None:
        area = "ADR"
        directory = self.root / "docs" / "adr"

        if not directory.exists():
            self.report.error(area, "docs/adr is missing.")
            return

        adr_files = sorted(directory.glob("[0-9][0-9][0-9][0-9]-*.md"))
        entries: list[str] = []
        numbering_errors = False

        for path in adr_files:
            filename_number = path.name[:4]
            title = self._first_heading(path)
            match = re.match(r"ADR-(\d{4})\b", title)

            if match is None:
                numbering_errors = True
                self.report.error(
                    area,
                    f"{self.rel(path)} has no valid ADR number in its heading.",
                )
            elif match.group(1) != filename_number:
                numbering_errors = True
                self.report.error(
                    area,
                    f"{self.rel(path)} heading uses ADR-{match.group(1)}, "
                    f"but the filename uses ADR-{filename_number}.",
                )

                if self.fix:
                    corrected = re.sub(
                        r"^# ADR-\d{4}\b",
                        f"# ADR-{filename_number}",
                        path.read_text(encoding="utf-8"),
                        count=1,
                    )
                    self.write(path, corrected)
                    title = self._first_heading(path)

            entries.append(f"- [{title}]({path.name})")

        desired = (
            "# Architecture Decision Records\n\n"
            "This directory records significant architectural and project decisions.\n\n"
            "## Records\n\n" + "\n".join(entries) + "\n"
        )
        index = directory / "index.md"

        if not index.exists() or index.read_text(encoding="utf-8") != desired:
            self.report.error(area, "ADR index does not match the ADR files.")
            if self.fix:
                self.write(index, desired)
        elif not numbering_errors:
            self.report.ok(area, f"ADR index covers all {len(adr_files)} records.")

    @staticmethod
    def _first_heading(path: Path) -> str:
        for line in path.read_text(encoding="utf-8").splitlines():
            if line.startswith("# "):
                return line[2:].strip()
        return path.stem

    def check_roadmap(self) -> None:
        area = "Roadmap"
        path = self.root / "ROADMAP.md"
        if not path.exists():
            self.report.error(area, "ROADMAP.md is missing.")
            return

        text = path.read_text(encoding="utf-8")
        stale = [model for model in ("Ousdal Hus 80", "Ousdal Hus 100") if model in text]
        expected = [f"Ousdal Hus {size}" for size in (90, 120, 150)]
        missing = [model for model in expected if model not in text]

        if stale or missing:
            self.report.error(
                area,
                "Reference-house sizes are stale or incomplete.",
            )
            if self.fix:
                text = text.replace("Ousdal Hus 80", "Ousdal Hus 90")
                text = text.replace("Ousdal Hus 100", "Ousdal Hus 120")

                # Avoid converting the existing 120 entry into a duplicate.
                lines = text.splitlines()
                model_lines = [
                    index
                    for index, line in enumerate(lines)
                    if line.strip().startswith("- Ousdal Hus ")
                ]
                replacements = (
                    "- Ousdal Hus 90",
                    "- Ousdal Hus 120",
                    "- Ousdal Hus 150",
                )
                for index, replacement in zip(model_lines, replacements, strict=False):
                    lines[index] = replacement
                text = "\n".join(lines).rstrip() + "\n"
                self.write(path, text)
        else:
            self.report.ok(area, "Roadmap matches OH90, OH120, and OH150.")

    def check_legacy(self) -> None:
        area = "Legacy"
        path = self.root / "standard" / "_legacy" / "README.md"
        required = ("legacy", "superseded", "do not")

        if not path.exists():
            self.report.warn(area, "Legacy directory has no README.")
            return

        text = path.read_text(encoding="utf-8").lower()
        if all(word in text for word in required):
            self.report.ok(area, "Legacy material is clearly marked.")
            return

        self.report.error(area, "Legacy README needs a clearer warning.")
        if self.fix:
            content = """# Legacy Standard Documents

> **Deprecated:** These documents are retained for historical reference only.

The files in this directory have been **superseded by the numbered OHS
specification series**. They are not normative, must not be used for new
conformance claims, and must not be edited as active standards.

Use the current specifications instead:

- OHS-001
- OHS-100
- OHS-200
- OHS-300
- OHS-400
- OHS-500
- OHS-600
- OHS-700
- OHS-900
"""
            self.write(path, content)

    def clean_temporary_files(self) -> None:
        area = "Temporary files"
        candidates: set[Path] = set()

        for pattern in TEMPORARY_PATTERNS:
            candidates.update(self.root.rglob(pattern))

        for relative in KNOWN_TEMPORARY_FILES:
            path = self.root / relative
            if path.exists():
                candidates.add(path)

        candidates = {
            path
            for path in candidates
            if ".git" not in path.parts
            and ".venv" not in path.parts
            and ".ohs-maintenance-backup" not in path.parts
        }

        if not candidates:
            self.report.ok(area, "No committed migration or backup artifacts found.")
            return

        for path in sorted(candidates):
            self.report.warn(area, f"Temporary artifact: {self.rel(path)}")
            if self.fix:
                self.remove(path)

    def check_root_contract(self) -> None:
        area = "Repository root"
        architecture = self.root / "ARCHITECTURE.md"
        if not architecture.exists():
            return

        text = architecture.read_text(encoding="utf-8")
        expected = (
            "CONTRIBUTING.md",
            "CODE_OF_CONDUCT.md",
            "CHANGELOG.md",
        )
        missing = [name for name in expected if name in text and not (self.root / name).exists()]
        if missing:
            self.report.warn(
                area,
                "ARCHITECTURE.md references missing root files: " + ", ".join(missing),
            )
        else:
            self.report.ok(area, "Root files match the architecture document.")

    def check_reference_models(self) -> None:
        area = "Reference houses"
        directory = self.root / "reference-houses"
        present = sorted(path.name for path in directory.glob("oh*") if path.is_dir())
        if tuple(present) != tuple(sorted(EXPECTED_MODELS)):
            self.report.error(
                area,
                f"Expected {EXPECTED_MODELS}, found {tuple(present)}.",
            )
        else:
            self.report.ok(area, "OH90, OH120, and OH150 are present.")

        versions: dict[str, str] = {}
        for model in EXPECTED_MODELS:
            config = directory / model / "config" / "house.yaml"
            if not config.exists():
                self.report.error(area, f"Missing {self.rel(config)}")
                continue
            data = self._load_yaml(config)
            version = str(
                data.get("schema_version")
                or data.get("schema-version")
                or data.get("version")
                or ""
            )
            versions[model] = version

        nonempty = {value for value in versions.values() if value}
        if len(nonempty) > 1:
            self.report.error(
                area,
                f"Reference-house schema versions differ: {versions}",
            )
        elif not nonempty:
            self.report.warn(
                area,
                "Reference-house configs do not declare a schema version.",
            )
        else:
            self.report.ok(area, f"Shared schema version: {next(iter(nonempty))}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="ohs-maintain",
        description="Check and safely normalize the OHS repository.",
    )
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument(
        "--check",
        action="store_true",
        help="Check repository health without modifying files (default).",
    )
    mode.add_argument(
        "--fix",
        action="store_true",
        help="Apply safe fixes and create timestamped backups.",
    )
    return parser.parse_args()


def print_report(report: Report, backup_root: Path | None = None) -> None:
    print("\nOHS Repository Health\n")
    for finding in report.findings:
        symbol = {"OK": "✓", "WARN": "!", "ERROR": "✗"}[finding.level]
        print(f"{symbol} [{finding.level}] {finding.area}: {finding.message}")

    if report.changes:
        print("\nChanges applied:")
        for change in report.changes:
            print(f"  - {change}")

    print(
        f"\nResult: {report.errors} error(s), "
        f"{report.warnings} warning(s), "
        f"{len(report.changes)} change(s)."
    )

    if backup_root is not None and backup_root.exists():
        print(f"Backups: {backup_root}")


def main() -> None:
    args = parse_args()
    root = Path.cwd().resolve()

    for candidate in (root, *root.parents):
        if (candidate / ".git").exists() and (candidate / "pyproject.toml").exists():
            root = candidate
            break
    else:
        raise SystemExit("Run ohs-maintain inside the OHS repository.")

    maintainer = Maintainer(root=root, fix=args.fix)
    report = maintainer.run()
    print_report(report, maintainer.backup_root if args.fix else None)

    if report.errors:
        raise SystemExit(1)


if __name__ == "__main__":
    main()

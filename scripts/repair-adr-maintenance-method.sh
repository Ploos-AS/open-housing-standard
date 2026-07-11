#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

FILE="src/ohs/maintenance.py"

if [[ ! -f "$FILE" ]]; then
  echo "[!] Missing $FILE"
  exit 1
fi

cp "$FILE" "${FILE}.before-adr-repair"

python - <<'PY'
from pathlib import Path

path = Path("src/ohs/maintenance.py")
text = path.read_text(encoding="utf-8")

if "\nimport re\n" not in text:
    marker = "import argparse\n"
    if marker not in text:
        raise SystemExit("Could not find import block in maintenance.py")
    text = text.replace(marker, marker + "import re\n", 1)

start_marker = "    def update_adr_index(self) -> None:\n"
end_marker = "    @staticmethod\n    def _first_heading"

start = text.find(start_marker)
end = text.find(end_marker, start)

if start == -1 or end == -1:
    raise SystemExit("Could not locate ADR maintenance methods")

replacement = '''    def update_adr_index(self) -> None:
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
            match = re.match(r"ADR-(\\d{4})\\b", title)

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
                        r"^# ADR-\\d{4}\\b",
                        f"# ADR-{filename_number}",
                        path.read_text(encoding="utf-8"),
                        count=1,
                    )
                    self.write(path, corrected)
                    title = self._first_heading(path)

            entries.append(f"- [{title}]({path.name})")

        desired = (
            "# Architecture Decision Records\\n\\n"
            "This directory records significant architectural and project decisions.\\n\\n"
            "## Records\\n\\n"
            + "\\n".join(entries)
            + "\\n"
        )
        index = directory / "index.md"

        if not index.exists() or index.read_text(encoding="utf-8") != desired:
            self.report.error(area, "ADR index does not match the ADR files.")
            if self.fix:
                self.write(index, desired)
        elif not numbering_errors:
            self.report.ok(area, f"ADR index covers all {len(adr_files)} records.")

'''

text = text[:start] + replacement + text[end:]
path.write_text(text, encoding="utf-8")
print("[+] Repaired update_adr_index()")
PY

uv run ruff format "$FILE"
uv run ruff check "$FILE"
uv run pytest tests/maintenance

echo
echo "[✓] ADR maintenance method repaired."
echo
echo "Run next:"
echo "  uv run ohs-maintain --fix"
echo "  uv run ruff check ."
echo "  uv run pytest"
echo "  uv run ohs-build-docs --strict"
echo
echo "After success:"
echo "  rm -f src/ohs/maintenance.py.before-adr-repair"
echo "  git add -A"
echo '  git commit -m "Validate and repair ADR numbering"'
echo "  git push origin draft"

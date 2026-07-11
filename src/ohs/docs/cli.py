from __future__ import annotations

import argparse
import subprocess

from .builder import build
from .paths import ProjectPaths


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="ohs-build-docs",
        description="Generate and build the OHS documentation site.",
    )
    parser.add_argument(
        "--strict",
        action="store_true",
        help="Run 'mkdocs build --strict' after generation.",
    )
    parser.add_argument(
        "--serve",
        action="store_true",
        help="Run 'mkdocs serve' after generation.",
    )
    return parser.parse_args()


def run(command: list[str], cwd) -> None:
    completed = subprocess.run(command, cwd=cwd, check=False)
    if completed.returncode != 0:
        raise SystemExit(completed.returncode)


def main() -> None:
    args = parse_args()
    paths = ProjectPaths.discover()

    build(paths)

    print(f"Generated documentation at {paths.generated.relative_to(paths.root)}")
    print("Generated mkdocs.yml with PyYAML")

    if args.strict:
        run(["mkdocs", "build", "--strict"], paths.root)
    elif args.serve:
        run(["mkdocs", "serve"], paths.root)


if __name__ == "__main__":
    main()

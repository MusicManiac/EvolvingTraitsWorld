#!/usr/bin/env python3
"""Sort ETW data files and commit any resulting formatting changes."""

import subprocess
from pathlib import Path

from sort_sandbox import find_sandbox_options, sorted_sandbox_options
from sort_translation_json import TRANSLATIONS_DIR, sorted_json


REPOSITORY_ROOT = Path(__file__).resolve().parent


def git(*arguments: str, capture_output: bool = False) -> subprocess.CompletedProcess:
    return subprocess.run(
        ["git", *arguments],
        cwd=REPOSITORY_ROOT,
        check=True,
        text=True,
        capture_output=capture_output,
    )


def relative_path(path: Path) -> str:
    return path.relative_to(REPOSITORY_ROOT).as_posix()


def ensure_targets_are_clean(sandbox_path: Path) -> None:
    result = git(
        "status",
        "--porcelain",
        "--untracked-files=all",
        "--",
        relative_path(sandbox_path),
        relative_path(TRANSLATIONS_DIR),
        capture_output=True,
    )

    if result.stdout:
        raise RuntimeError(
            "Sandbox or translation files already have uncommitted changes. "
            "Commit or stash them before creating an automatic sort commit.\n"
            + result.stdout.rstrip()
        )


def main() -> int:
    sandbox_path = find_sandbox_options()
    ensure_targets_are_clean(sandbox_path)

    sandbox_original = sandbox_path.read_text(encoding="utf-8")
    sandbox_formatted = sorted_sandbox_options(sandbox_original)

    json_outputs = []

    for path in sorted(TRANSLATIONS_DIR.rglob("*.json")):
        original = path.read_text(encoding="utf-8")
        json_outputs.append((path, original, sorted_json(original)))

    changed_sandbox = sandbox_original != sandbox_formatted
    changed_json = [
        (path, formatted)
        for path, original, formatted in json_outputs
        if original != formatted
    ]

    if not changed_sandbox and not changed_json:
        print("Sandbox options and translation JSON files are already sorted.")
        return 0

    changed_paths = []

    if changed_sandbox:
        sandbox_path.write_text(sandbox_formatted, encoding="utf-8")
        changed_paths.append(sandbox_path)

    for path, formatted in changed_json:
        path.write_text(formatted, encoding="utf-8")
        changed_paths.append(path)

    if changed_sandbox and changed_json:
        message = "misc: jsons and sandbox sort"
    elif changed_json:
        message = "misc: jsons sort"
    else:
        message = "misc: sandbox sort"

    git(
        "commit",
        "--only",
        "-m",
        message,
        "--",
        *(relative_path(path) for path in changed_paths),
    )
    print(f"Created commit: {message}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Sort ETW sandbox options and commit any resulting formatting changes."""

import subprocess
from pathlib import Path

from sort_sandbox import find_sandbox_options, sorted_sandbox_options


REPOSITORY_ROOT = Path(__file__).resolve().parent


def git(*arguments: str, capture_output: bool = False) -> subprocess.CompletedProcess:
    """Run Git in the repository and return the completed process."""
    return subprocess.run(
        ["git", *arguments],
        cwd=REPOSITORY_ROOT,
        check=True,
        text=True,
        capture_output=capture_output,
    )


def relative_path(path: Path) -> str:
    """Return a repository-relative path using Git path separators."""
    return path.relative_to(REPOSITORY_ROOT).as_posix()


def ensure_target_is_clean(sandbox_path: Path) -> None:
    """Require the sandbox options file to have no uncommitted changes."""
    result = git(
        "status",
        "--porcelain",
        "--untracked-files=all",
        "--",
        relative_path(sandbox_path),
        capture_output=True,
    )

    if result.stdout:
        raise RuntimeError(
            "The sandbox options file already has uncommitted changes. "
            "Commit or stash them before creating an automatic sort commit.\n"
            + result.stdout.rstrip()
        )


def main() -> int:
    """Sort sandbox options and commit them when their ordering changes."""
    sandbox_path = find_sandbox_options()
    ensure_target_is_clean(sandbox_path)

    sandbox_original = sandbox_path.read_text(encoding="utf-8")
    sandbox_formatted = sorted_sandbox_options(sandbox_original)

    changed_sandbox = sandbox_original != sandbox_formatted
    if not changed_sandbox:
        print("Sandbox options are already sorted.")
        return 0

    sandbox_path.write_text(sandbox_formatted, encoding="utf-8")
    message = "misc: sandbox sort"

    git(
        "commit",
        "--only",
        "-m",
        message,
        "--",
        relative_path(sandbox_path),
    )
    print(f"Created commit: {message}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

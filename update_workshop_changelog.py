#!/usr/bin/env python3
"""Generate the Steam Workshop changelog from the newest Markdown release."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parent
MARKDOWN_CHANGELOG_PATH = REPOSITORY_ROOT / "CHANGELOG.md"
WORKSHOP_CHANGELOG_PATH = REPOSITORY_ROOT / "changelog.txt"
CHANGELOG_URL = (
    "https://github.com/MusicManiac/EvolvingTraitsWorld/blob/main/CHANGELOG.md"
)
WORKSHOP_HEADER = (
    f"[url={CHANGELOG_URL}]"
    "(Properly formatted changelog can be found here)[/url]"
)
GENERATED_MARKER_PATTERN = re.compile(
    r"\s*<!-- generated:translation-stats baseline=[^ ]+ -->"
)
MARKDOWN_LINK_PATTERN = re.compile(r"(?<!!)\[([^\]]+)]\(([^)]+)\)")
BOLD_PATTERN = re.compile(r"\*\*(.+?)\*\*")
INLINE_CODE_PATTERN = re.compile(r"`([^`]+)`")


class ChangelogError(RuntimeError):
    """Describe a malformed or unavailable Markdown changelog."""


def newest_release(markdown: str) -> list[str]:
    """Return the lines belonging to the newest Markdown release."""
    lines = markdown.splitlines()
    headings = [index for index, line in enumerate(lines) if line.startswith("## ")]
    if not headings:
        raise ChangelogError("CHANGELOG.md does not contain a release heading.")
    start = headings[0]
    end = headings[1] if len(headings) > 1 else len(lines)
    return lines[start:end]


def markdown_line_to_bbcode(line: str) -> str:
    """Convert supported inline Markdown constructs to Steam BBCode."""
    converted = GENERATED_MARKER_PATTERN.sub("", line).rstrip()
    converted = MARKDOWN_LINK_PATTERN.sub(r"[url=\2]\1[/url]", converted)
    converted = BOLD_PATTERN.sub(r"[b]\1[/b]", converted)
    converted = INLINE_CODE_PATTERN.sub(r"[code]\1[/code]", converted)
    return converted


def generated_workshop_changelog(markdown: str) -> str:
    """Return the Steam changelog generated from the newest release."""
    release = newest_release(markdown)
    version = release[0].removeprefix("## ").strip()
    if not version:
        raise ChangelogError("The newest CHANGELOG.md release has no version.")

    body = []
    for line in release[1:]:
        if line.startswith("###### "):
            continue
        body.append(markdown_line_to_bbcode(line))
    while body and not body[0]:
        body.pop(0)
    while body and not body[-1]:
        body.pop()

    rendered = [WORKSHOP_HEADER, "", version, "", *body]
    return "\n".join(rendered) + "\n"


def parse_args() -> argparse.Namespace:
    """Parse command-line options."""
    parser = argparse.ArgumentParser(
        description="Generate changelog.txt from the newest CHANGELOG.md release."
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="report whether changelog.txt needs updating without writing it",
    )
    return parser.parse_args()


def main() -> int:
    """Update or verify the generated Steam Workshop changelog."""
    args = parse_args()
    try:
        markdown = MARKDOWN_CHANGELOG_PATH.read_text(encoding="utf-8")
        updated = generated_workshop_changelog(markdown)
        current = WORKSHOP_CHANGELOG_PATH.read_text(encoding="utf-8")
    except (OSError, ChangelogError) as error:
        print(error, file=sys.stderr)
        return 1

    if current == updated:
        print("Steam Workshop changelog is current.")
        return 0
    if args.check:
        print(
            "changelog.txt is outdated; run python update_workshop_changelog.py.",
            file=sys.stderr,
        )
        return 1

    WORKSHOP_CHANGELOG_PATH.write_text(updated, encoding="utf-8")
    print("Updated changelog.txt from the newest CHANGELOG.md release.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

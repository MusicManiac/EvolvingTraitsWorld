#!/usr/bin/env python3
"""Sort all Evolving Traits World translation JSON files by key."""

import argparse
import json
from pathlib import Path
from typing import Any, Iterable, Tuple


TRANSLATIONS_DIR = (
    Path(__file__).resolve().parent
    / "Contents"
    / "mods"
    / "Evolving Traits World"
    / "common"
    / "media"
    / "lua"
    / "shared"
    / "Translate"
)


def unique_object(pairs: Iterable[Tuple[str, Any]]) -> dict[str, Any]:
    """Build a JSON object while rejecting duplicate keys."""
    result = {}

    for key, value in pairs:
        if key in result:
            raise ValueError(f"Duplicate JSON key: {key}")
        result[key] = value

    return result


def sorted_json(text: str) -> str:
    data = json.loads(text, object_pairs_hook=unique_object)
    return json.dumps(data, ensure_ascii=False, indent=4, sort_keys=True) + "\n"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Sort translation JSON files alphabetically by key.",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="report unsorted files without changing them",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    json_files = sorted(TRANSLATIONS_DIR.rglob("*.json"))

    if not json_files:
        raise FileNotFoundError(f"No JSON files found under {TRANSLATIONS_DIR}")

    changed = []

    for path in json_files:
        original = path.read_text(encoding="utf-8")

        try:
            formatted = sorted_json(original)
        except (json.JSONDecodeError, ValueError) as error:
            raise ValueError(f"Could not process {path}: {error}") from error

        if formatted == original:
            continue

        changed.append(path)

        if not args.check:
            path.write_text(formatted, encoding="utf-8")

    action = "Would sort" if args.check else "Sorted"

    for path in changed:
        print(f"{action}: {path.relative_to(TRANSLATIONS_DIR)}")

    if args.check and changed:
        print(f"{len(changed)} file(s) are not sorted.")
        return 1

    print(f"Processed {len(json_files)} file(s); changed {len(changed)}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

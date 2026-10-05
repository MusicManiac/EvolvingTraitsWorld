#!/usr/bin/env python3
"""Update runtime translation percentages from Weblate statistics exports."""

from __future__ import annotations

import argparse
import json
import sys
from collections import defaultdict
from pathlib import Path
from typing import Any, Iterable


REPOSITORY_ROOT = Path(__file__).resolve().parent
STATS_DIRECTORY = REPOSITORY_ROOT / ".weblate-stats"
TRANSLATIONS_DIRECTORY = (
    REPOSITORY_ROOT
    / "Contents"
    / "mods"
    / "Evolving Traits World"
    / "common"
    / "media"
    / "lua"
    / "shared"
    / "Translate"
)
ENGLISH_UI_PATH = TRANSLATIONS_DIRECTORY / "EN" / "UI.json"
EXPECTED_COMPONENTS = {"moodles", "sandbox", "ui"}
STATS_KEY_PREFIX = "UI_ETW_TranslationStats_"
TOTAL_LINES_KEY = f"{STATS_KEY_PREFIX}Total"
LEGACY_STATS_KEY_PREFIXES = ("___translation_stats_",)


class TranslationStatsError(RuntimeError):
    """Describe malformed or incomplete Weblate statistics."""


def unique_object(pairs: Iterable[tuple[str, Any]]) -> dict[str, Any]:
    """Build a JSON object while rejecting duplicate keys."""
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise TranslationStatsError(f"Duplicate JSON key: {key}")
        result[key] = value
    return result


def load_json(path: Path) -> dict[str, Any]:
    """Load a JSON object from *path* with duplicate-key validation."""
    try:
        data = json.loads(
            path.read_text(encoding="utf-8"),
            object_pairs_hook=unique_object,
        )
    except (OSError, json.JSONDecodeError, TranslationStatsError) as error:
        raise TranslationStatsError(f"Could not load {path}: {error}") from error
    if not isinstance(data, dict):
        raise TranslationStatsError(f"Expected a JSON object in {path}.")
    return data


def target_languages() -> set[str]:
    """Return translation directory codes other than the English source."""
    return {
        path.name
        for path in TRANSLATIONS_DIRECTORY.iterdir()
        if path.is_dir() and path.name.upper() != "EN"
    }


def validated_count(value: Any, field: str, path: Path, language: str) -> int:
    """Return a validated non-negative integer statistics count."""
    if isinstance(value, bool) or not isinstance(value, int) or value < 0:
        raise TranslationStatsError(
            f"Expected a non-negative integer for {language}.{field} in {path}."
        )
    return value


def aggregate_statistics() -> dict[str, tuple[int, int, int]]:
    """Aggregate translated, needs-editing, and total Weblate counts."""
    totals: defaultdict[str, list[int]] = defaultdict(lambda: [0, 0, 0])
    components: set[str] = set()
    languages = target_languages()
    paths = sorted(STATS_DIRECTORY.glob("*.json"))
    if not paths:
        raise TranslationStatsError(f"No Weblate statistics found in {STATS_DIRECTORY}.")

    for path in paths:
        data = load_json(path)
        component = data.get("component")
        component_languages = data.get("languages")
        if not isinstance(component, str) or not component:
            raise TranslationStatsError(f"Missing component name in {path}.")
        if component in components:
            raise TranslationStatsError(f"Duplicate Weblate component {component!r}.")
        if not isinstance(component_languages, dict):
            raise TranslationStatsError(f"Missing languages object in {path}.")
        components.add(component)

        exported_languages = {
            code for code in component_languages if code.lower() != "en"
        }
        if exported_languages != languages:
            missing = sorted(languages - exported_languages)
            unexpected = sorted(exported_languages - languages)
            raise TranslationStatsError(
                f"Language mismatch in {path}: missing={missing}, unexpected={unexpected}."
            )

        for language in sorted(languages):
            statistics = component_languages[language]
            if not isinstance(statistics, dict):
                raise TranslationStatsError(
                    f"Expected an object for language {language} in {path}."
                )
            total = validated_count(statistics.get("total"), "total", path, language)
            translated = validated_count(
                statistics.get("translated"), "translated", path, language
            )
            needs_editing = validated_count(
                statistics.get("needs_editing"), "needs_editing", path, language
            )
            if translated > total:
                raise TranslationStatsError(
                    f"Translated count exceeds total for {language} in {path}."
                )
            if needs_editing > total or translated + needs_editing > total:
                raise TranslationStatsError(
                    f"Translated and needs-editing counts exceed total for {language} in {path}."
                )
            totals[language][0] += translated
            totals[language][1] += needs_editing
            totals[language][2] += total

    if components != EXPECTED_COMPONENTS:
        missing = sorted(EXPECTED_COMPONENTS - components)
        unexpected = sorted(components - EXPECTED_COMPONENTS)
        raise TranslationStatsError(
            f"Weblate component mismatch: missing={missing}, unexpected={unexpected}."
        )

    return {
        language: (counts[0], counts[1], counts[2])
        for language, counts in sorted(totals.items())
    }


def updated_english_ui() -> tuple[str, dict[str, str]]:
    """Return updated English UI JSON and the generated percentage values."""
    data = load_json(ENGLISH_UI_PATH)
    generated_prefixes = (STATS_KEY_PREFIX, *LEGACY_STATS_KEY_PREFIXES)
    for key in [key for key in data if key.startswith(generated_prefixes)]:
        del data[key]

    generated: dict[str, str] = {}
    statistics = aggregate_statistics()
    reported_totals = {total for _, _, total in statistics.values()}
    if len(reported_totals) != 1:
        totals_by_language = ", ".join(
            f"{language}={total}"
            for language, (_, _, total) in statistics.items()
        )
        raise TranslationStatsError(
            f"Weblate reported inconsistent total strings: {totals_by_language}."
        )

    total_lines = reported_totals.pop()
    data[TOTAL_LINES_KEY] = str(total_lines)
    generated["Total"] = str(total_lines)

    for language, (translated, needs_editing, total) in statistics.items():
        if total == 0:
            raise TranslationStatsError(f"Weblate reported zero total strings for {language}.")
        value = f"{translated * 100 / total:.1f}"
        key = f"{STATS_KEY_PREFIX}{language}"
        data[key] = value
        data[f"{STATS_KEY_PREFIX}NeedsEditing_{language}"] = (
            f"{needs_editing * 100 / total:.1f}"
        )
        generated[language] = value

    return (
        json.dumps(data, ensure_ascii=False, indent=4) + "\n",
        generated,
    )


def parse_args() -> argparse.Namespace:
    """Parse command-line options."""
    parser = argparse.ArgumentParser(
        description="Update EN/UI.json with aggregate Weblate completion percentages."
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="report whether EN/UI.json needs to be updated without changing it",
    )
    return parser.parse_args()


def main() -> int:
    """Update or verify generated translation completion metadata."""
    args = parse_args()
    try:
        updated, generated = updated_english_ui()
        current = ENGLISH_UI_PATH.read_text(encoding="utf-8")
    except (OSError, TranslationStatsError) as error:
        print(error, file=sys.stderr)
        return 1

    if current == updated:
        print("Translation completion metadata is current.")
        return 0
    if args.check:
        print(
            "Translation completion metadata is outdated; "
            "run python update_translation_stats.py.",
            file=sys.stderr,
        )
        return 1

    ENGLISH_UI_PATH.write_text(updated, encoding="utf-8")
    summary = ", ".join(
        f"Total={generated['Total']} lines"
        if language == "Total"
        else f"{language}={value}%"
        for language, value in generated.items()
    )
    print(f"Updated translation completion metadata: {summary}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

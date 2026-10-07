#!/usr/bin/env python3
"""Update runtime translation percentages from Weblate statistics exports."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
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
WORKSHOP_DESCRIPTION_PATH = REPOSITORY_ROOT / "workshopDesc.txt"
CHANGELOG_PATH = REPOSITORY_ROOT / "CHANGELOG.md"
EXPECTED_COMPONENTS = {"moodles", "sandbox", "ui"}
STATS_KEY_PREFIX = "UI_ETW_TranslationStats_"
TOTAL_LINES_KEY = f"{STATS_KEY_PREFIX}Total"
LEGACY_STATS_KEY_PREFIXES = ("___translation_stats_",)
WEBLATE_URL = "https://weblate.musicmaniac.dev/engage/evolving-traits-world-etw/"
CHANGELOG_MARKER = "generated:translation-stats"
WORKSHOP_LANGUAGES = (
    ("English", None),
    ("Italiano / Italian", "IT"),
    ("French / Français", "FR"),
    ("Español / Spanish", "ES"),
    ("簡体中文 / Simplified Chinese", "CN"),
    ("繁體中文 / Traditional Chinese", "CH"),
    ("Português Brasileiro / Brazilian Portuguese", "PTBR"),
    ("한국어 / Korean", "KO"),
    ("日本語 / Japanese", "JP"),
    ("Türkçe / Turkish", "TR"),
    ("Deutsch / German", "DE"),
    ("Українська / Ukrainian", "UA"),
    ("Русский / Russian", "RU"),
)


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


def load_json_text(text: str, source: str) -> dict[str, Any]:
    """Load a JSON object from text with duplicate-key validation."""
    try:
        data = json.loads(
            text,
            object_pairs_hook=unique_object,
        )
    except (json.JSONDecodeError, TranslationStatsError) as error:
        raise TranslationStatsError(f"Could not load {source}: {error}") from error
    if not isinstance(data, dict):
        raise TranslationStatsError(f"Expected a JSON object in {source}.")
    return data


def load_json(path: Path) -> dict[str, Any]:
    """Load a JSON file with duplicate-key validation."""
    try:
        text = path.read_text(encoding="utf-8")
    except OSError as error:
        raise TranslationStatsError(f"Could not load {path}: {error}") from error
    return load_json_text(text, str(path))


def git_output(arguments: list[str], operation: str) -> str:
    """Return UTF-8 output from a read-only Git command."""
    process = subprocess.run(
        ["git", *arguments],
        cwd=REPOSITORY_ROOT,
        capture_output=True,
        text=True,
        encoding="utf-8",
        check=False,
    )
    if process.returncode != 0:
        detail = process.stderr.strip() or process.stdout.strip()
        raise TranslationStatsError(f"Could not {operation}: {detail}")
    return process.stdout


def resolve_git_ref(ref: str) -> str:
    """Resolve a Git reference to a commit hash."""
    return git_output(
        ["rev-parse", "--verify", "--end-of-options", f"{ref}^{{commit}}"],
        f"resolve Git reference {ref!r}",
    ).strip()


def target_languages() -> set[str]:
    """Return translation directory codes other than the English source."""
    return {
        path.name
        for path in TRANSLATIONS_DIRECTORY.iterdir()
        if path.is_dir() and path.name.upper() != "EN"
    }


def validated_count(value: Any, field: str, source: str, language: str) -> int:
    """Return a validated non-negative integer statistics count."""
    if isinstance(value, bool) or not isinstance(value, int) or value < 0:
        raise TranslationStatsError(
            f"Expected a non-negative integer for {language}.{field} in {source}."
        )
    return value


def local_statistics_documents() -> list[tuple[str, dict[str, Any]]]:
    """Load Weblate statistics documents from the working tree."""
    paths = sorted(STATS_DIRECTORY.glob("*.json"))
    return [(str(path), load_json(path)) for path in paths]


def git_statistics_documents(ref: str) -> list[tuple[str, dict[str, Any]]]:
    """Load Weblate statistics documents from a Git reference."""
    commit = resolve_git_ref(ref)
    names = git_output(
        ["ls-tree", "--name-only", f"{commit}:.weblate-stats"],
        f"list Weblate statistics at {ref!r}",
    ).splitlines()
    json_names = sorted(name for name in names if name.endswith(".json"))
    documents = []
    for name in json_names:
        source = f"{ref}:.weblate-stats/{name}"
        text = git_output(
            ["show", f"{commit}:.weblate-stats/{name}"],
            f"read {source}",
        )
        documents.append((source, load_json_text(text, source)))
    return documents


def aggregate_statistics(
    documents: Iterable[tuple[str, dict[str, Any]]] | None = None,
) -> dict[str, tuple[int, int, int]]:
    """Aggregate translated, needs-editing, and total Weblate counts."""
    totals: defaultdict[str, list[int]] = defaultdict(lambda: [0, 0, 0])
    components: set[str] = set()
    languages = target_languages()
    loaded_documents = list(
        local_statistics_documents() if documents is None else documents
    )
    if not loaded_documents:
        raise TranslationStatsError(f"No Weblate statistics found in {STATS_DIRECTORY}.")

    for source, data in loaded_documents:
        component = data.get("component")
        component_languages = data.get("languages")
        if not isinstance(component, str) or not component:
            raise TranslationStatsError(f"Missing component name in {source}.")
        if component in components:
            raise TranslationStatsError(f"Duplicate Weblate component {component!r}.")
        if not isinstance(component_languages, dict):
            raise TranslationStatsError(f"Missing languages object in {source}.")
        components.add(component)

        exported_languages = {
            code for code in component_languages if code.lower() != "en"
        }
        if exported_languages != languages:
            missing = sorted(languages - exported_languages)
            unexpected = sorted(exported_languages - languages)
            raise TranslationStatsError(
                f"Language mismatch in {source}: missing={missing}, unexpected={unexpected}."
            )

        for language in sorted(languages):
            statistics = component_languages[language]
            if not isinstance(statistics, dict):
                raise TranslationStatsError(
                    f"Expected an object for language {language} in {source}."
                )
            total = validated_count(statistics.get("total"), "total", source, language)
            translated = validated_count(
                statistics.get("translated"), "translated", source, language
            )
            needs_editing = validated_count(
                statistics.get("needs_editing"), "needs_editing", source, language
            )
            if translated > total:
                raise TranslationStatsError(
                    f"Translated count exceeds total for {language} in {source}."
                )
            if needs_editing > total or translated + needs_editing > total:
                raise TranslationStatsError(
                    f"Translated and needs-editing counts exceed total for {language} in {source}."
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


def updated_english_ui(
    statistics: dict[str, tuple[int, int, int]],
) -> tuple[str, dict[str, str]]:
    """Return updated English UI JSON and the generated percentage values."""
    data = load_json(ENGLISH_UI_PATH)
    generated_prefixes = (STATS_KEY_PREFIX, *LEGACY_STATS_KEY_PREFIXES)
    for key in [key for key in data if key.startswith(generated_prefixes)]:
        del data[key]

    generated: dict[str, str] = {}
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


def completion_summary(generated: dict[str, str]) -> str:
    """Return a compact summary of generated translation percentages."""
    return ", ".join(
        f"Total={generated['Total']} lines"
        if language == "Total"
        else f"{language}={value}%"
        for language, value in generated.items()
    )


def updated_workshop_description(percentages: dict[str, str]) -> str:
    """Return workshopDesc.txt with current completion in descending order."""
    description = WORKSHOP_DESCRIPTION_PATH.read_text(encoding="utf-8")
    lines = description.splitlines(keepends=True)
    entries: list[tuple[str, str | None, str, int]] = []
    matched_indices: list[int] = []

    for order, (label, language) in enumerate(WORKSHOP_LANGUAGES):
        percentage = "100.0" if language is None else percentages.get(language)
        if percentage is None:
            raise TranslationStatsError(
                f"No generated translation percentage for workshop language {language}."
            )

        bullet = f"[*]{label}"
        pattern = re.compile(
            rf"{re.escape(bullet)}(?: \(\d+(?:\.\d+)?%\))?",
        )
        indices = [
            index
            for index, line in enumerate(lines)
            if pattern.fullmatch(line.rstrip("\r\n"))
        ]
        if len(indices) != 1:
            raise TranslationStatsError(
                f"Expected exactly one workshop language bullet {bullet!r}; "
                f"found {len(indices)}."
            )
        entries.append((label, language, percentage, order))
        matched_indices.append(indices[0])

    sorted_indices = sorted(matched_indices)
    first_index = sorted_indices[0]
    expected_indices = list(range(first_index, first_index + len(WORKSHOP_LANGUAGES)))
    if sorted_indices != expected_indices:
        raise TranslationStatsError(
            "Expected workshop language bullets to form one contiguous list."
        )

    english = next(entry for entry in entries if entry[1] is None)
    translations = sorted(
        (entry for entry in entries if entry[1] is not None),
        key=lambda entry: (-float(entry[2]), entry[3]),
    )
    for offset, (label, _, percentage, _) in enumerate((english, *translations)):
        index = first_index + offset
        line_ending = lines[index][len(lines[index].rstrip("\r\n")) :]
        lines[index] = f"[*]{label} ({percentage}%){line_ending}"

    return "".join(lines)


def first_changelog_release_range(lines: list[str]) -> tuple[int, int]:
    """Return the line range occupied by the newest Markdown release."""
    headings = [
        index for index, line in enumerate(lines) if line.startswith("## ")
    ]
    if not headings:
        raise TranslationStatsError(f"No release heading found in {CHANGELOG_PATH}.")
    start = headings[0]
    end = headings[1] if len(headings) > 1 else len(lines)
    return start, end


def newest_changelog_release_version(changelog: str) -> str:
    """Return the version named by the newest Markdown release heading."""
    lines = changelog.splitlines(keepends=True)
    start, _ = first_changelog_release_range(lines)
    return lines[start].removeprefix("## ").strip()


def pinned_changelog_baseline(changelog: str) -> str | None:
    """Return the baseline recorded in the newest generated changelog entry."""
    lines = changelog.splitlines(keepends=True)
    start, end = first_changelog_release_range(lines)
    pattern = re.compile(
        rf"<!-- {re.escape(CHANGELOG_MARKER)} baseline=([^ ]+) -->"
    )
    matches = [
        match.group(1)
        for line in lines[start:end]
        if (match := pattern.search(line)) is not None
    ]
    if len(matches) > 1:
        raise TranslationStatsError(
            "The newest changelog release has multiple generated translation entries."
        )
    return matches[0] if matches else None


def latest_release_tag() -> str:
    """Return the latest tag reachable from the current branch."""
    tag = git_output(
        ["describe", "--tags", "--abbrev=0"],
        "find the latest release tag",
    ).strip()
    if not tag:
        raise TranslationStatsError("Git did not report a release tag.")
    return tag


def select_baseline_tag(explicit_tag: str | None, changelog: str) -> str:
    """Choose an explicit, pinned, or latest release baseline tag."""
    baseline_tag = explicit_tag or pinned_changelog_baseline(changelog)
    if baseline_tag is None:
        baseline_tag = latest_release_tag()
    resolve_git_ref(baseline_tag)
    return baseline_tag


def release_translation_summary(
    current: dict[str, tuple[int, int, int]],
    baseline: dict[str, tuple[int, int, int]],
    baseline_tag: str,
) -> str | None:
    """Return a Markdown release summary for translation-count changes."""
    if current.keys() != baseline.keys():
        raise TranslationStatsError(
            "Current and baseline Weblate statistics contain different languages."
        )

    current_completed = sum(translated for translated, _, _ in current.values())
    baseline_completed = sum(translated for translated, _, _ in baseline.values())
    current_capacity = sum(total for _, _, total in current.values())
    baseline_capacity = sum(total for _, _, total in baseline.values())
    if current_capacity == 0 or baseline_capacity == 0:
        raise TranslationStatsError("Weblate reported zero aggregate translation capacity.")
    if (
        current_completed == baseline_completed
        and current_capacity == baseline_capacity
    ):
        return None

    current_source_totals = {total for _, _, total in current.values()}
    baseline_source_totals = {total for _, _, total in baseline.values()}
    if len(current_source_totals) != 1 or len(baseline_source_totals) != 1:
        raise TranslationStatsError(
            "Weblate statistics report inconsistent source totals."
        )

    delta = current_completed - baseline_completed
    language_deltas = {
        language: current[language][0] - baseline[language][0]
        for language in current
    }
    gained_languages = sorted(
        (language for language, change in language_deltas.items() if change > 0),
        key=lambda language: (-language_deltas[language], language),
    )
    lost_languages = sorted(
        (language for language, change in language_deltas.items() if change < 0),
        key=lambda language: (-abs(language_deltas[language]), language),
    )
    current_source_total = current_source_totals.pop()
    baseline_source_total = baseline_source_totals.pop()
    baseline_percent = (
        (baseline_completed + baseline_source_total)
        * 100
        / (baseline_capacity + baseline_source_total)
    )
    current_percent = (
        (current_completed + current_source_total)
        * 100
        / (current_capacity + current_source_total)
    )
    entry_word = "entry" if abs(delta) == 1 else "entries"
    if delta > 0:
        affected_languages = gained_languages
        if lost_languages:
            affected_languages = sorted(
                (*gained_languages, *lost_languages),
                key=lambda language: (-abs(language_deltas[language]), language),
            )
            opening = f"Translations had a net gain of {delta} completed {entry_word}"
        else:
            opening = f"Translations gained {delta} completed {entry_word}"
    elif delta < 0:
        affected_languages = lost_languages
        opening = (
            f"Translations have a net loss of {abs(delta)} completed {entry_word}"
        )
    else:
        affected_languages = sorted(
            (*gained_languages, *lost_languages),
            key=lambda language: (-abs(language_deltas[language]), language),
        )
        opening = "Translation completion has no net change in completed entries"

    language_word = "language" if len(affected_languages) == 1 else "languages"
    language_changes = ", ".join(
        f"{language_deltas[language]:+d} {language}"
        for language in affected_languages
    )

    return (
        f"{opening} across {len(affected_languages)} {language_word} "
        f"since {baseline_tag}: {language_changes}. Overall completion changed from "
        f"{baseline_percent:.2f}% to {current_percent:.2f}%. "
        f"[Contribute or fix few lines on Weblate]({WEBLATE_URL})."
    )


def updated_changelog(
    changelog: str,
    current: dict[str, tuple[int, int, int]],
    baseline: dict[str, tuple[int, int, int]],
    baseline_tag: str,
) -> tuple[str, str | None]:
    """Return CHANGELOG.md with one idempotent generated translation entry."""
    lines = changelog.splitlines(keepends=True)
    start, end = first_changelog_release_range(lines)
    marker_pattern = re.compile(
        rf"<!-- {re.escape(CHANGELOG_MARKER)} baseline=[^ ]+ -->"
    )
    release_lines = [
        line for line in lines[start:end] if marker_pattern.search(line) is None
    ]
    summary = release_translation_summary(current, baseline, baseline_tag)
    if summary is not None:
        release_version = release_lines[0].removeprefix("## ").strip()
        if release_version == baseline_tag:
            raise TranslationStatsError(
                f"The newest CHANGELOG.md release is the baseline {baseline_tag}; "
                "add the new release heading before generating its translation entry."
            )
        newline = "\r\n" if "\r\n" in changelog else "\n"
        generated_line = (
            f"  - {summary} "
            f"<!-- {CHANGELOG_MARKER} baseline={baseline_tag} -->{newline}"
        )
        translations_indices = [
            index
            for index, line in enumerate(release_lines)
            if line.rstrip("\r\n") == "- Translations:"
        ]
        if len(translations_indices) > 1:
            raise TranslationStatsError(
                "The newest changelog release has multiple Translations sections."
            )
        if translations_indices:
            release_lines.insert(translations_indices[0] + 1, generated_line)
        else:
            while release_lines and not release_lines[-1].strip():
                release_lines.pop()
            release_lines.extend(
                [
                    newline,
                    f"- Translations:{newline}",
                    generated_line,
                    newline,
                ]
            )

    return "".join((*lines[:start], *release_lines, *lines[end:])), summary


def parse_args() -> argparse.Namespace:
    """Parse command-line options."""
    parser = argparse.ArgumentParser(
        description=(
            "Update generated Weblate percentages and the newest Markdown "
            "changelog entry."
        )
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="report whether generated files need updating without writing them",
    )
    parser.add_argument(
        "--baseline-tag",
        help=(
            "release tag to compare against; defaults to the baseline pinned in "
            "the generated entry or the latest reachable tag"
        ),
    )
    parser.add_argument(
        "--weblate-branch",
        nargs="?",
        const="origin/weblate",
        metavar="REF",
        help=(
            "preview using statistics from REF without merging or writing; "
            "defaults to origin/weblate and implies --check"
        ),
    )
    return parser.parse_args()


def main() -> int:
    """Update or verify generated translation completion metadata."""
    args = parse_args()
    try:
        changelog = CHANGELOG_PATH.read_text(encoding="utf-8")
        if args.weblate_branch is None:
            statistics = aggregate_statistics()
        else:
            statistics = aggregate_statistics(
                git_statistics_documents(args.weblate_branch)
            )
        baseline_tag = select_baseline_tag(args.baseline_tag, changelog)
        baseline_statistics = aggregate_statistics(
            git_statistics_documents(baseline_tag)
        )
        updated_ui, generated = updated_english_ui(statistics)
        updated_description = updated_workshop_description(generated)
        release_summary = release_translation_summary(
            statistics,
            baseline_statistics,
            baseline_tag,
        )
        detached_changelog_preview = (
            args.weblate_branch is not None
            and newest_changelog_release_version(changelog) == baseline_tag
            and release_summary is not None
        )
        if detached_changelog_preview:
            updated_markdown = changelog
        else:
            updated_markdown, release_summary = updated_changelog(
                changelog,
                statistics,
                baseline_statistics,
                baseline_tag,
            )
        current_ui = ENGLISH_UI_PATH.read_text(encoding="utf-8")
        current_description = WORKSHOP_DESCRIPTION_PATH.read_text(encoding="utf-8")
    except (OSError, TranslationStatsError) as error:
        print(error, file=sys.stderr)
        return 1

    outdated_paths = []
    if current_ui != updated_ui:
        outdated_paths.append(ENGLISH_UI_PATH)
    if current_description != updated_description:
        outdated_paths.append(WORKSHOP_DESCRIPTION_PATH)
    if changelog != updated_markdown or detached_changelog_preview:
        outdated_paths.append(CHANGELOG_PATH)

    if args.weblate_branch is not None:
        print(
            f"Weblate preview for {args.weblate_branch} against {baseline_tag}; "
            "no files were changed."
        )
        print(f"Generated percentages: {completion_summary(generated)}")
        if release_summary is None:
            print("Generated changelog entry: none (no completion-count change).")
        else:
            print(f"Generated changelog entry: {release_summary}")
            if detached_changelog_preview:
                print(
                    "CHANGELOG.md has no release newer than the baseline; the entry "
                    "is previewed without attaching it to a release."
                )
        sys.stdout.flush()

    if not outdated_paths:
        print("Generated translation files are current.")
        return 0
    if args.check or args.weblate_branch is not None:
        changed_names = ", ".join(path.name for path in outdated_paths)
        if args.weblate_branch is None:
            message = (
                f"Generated translation content would change in {changed_names}; "
                "run python update_translation_stats.py."
            )
        else:
            next_steps = (
                "draft the new CHANGELOG.md release heading, merge the Weblate "
                "branch, then run"
                if detached_changelog_preview
                else "merge the Weblate branch, then run"
            )
            message = (
                f"Merging {args.weblate_branch} would require changes in "
                f"{changed_names}; {next_steps} python update_translation_stats.py."
            )
        print(message, file=sys.stderr)
        return 1

    if current_ui != updated_ui:
        ENGLISH_UI_PATH.write_text(updated_ui, encoding="utf-8")
    if current_description != updated_description:
        WORKSHOP_DESCRIPTION_PATH.write_text(updated_description, encoding="utf-8")
    if changelog != updated_markdown:
        CHANGELOG_PATH.write_text(updated_markdown, encoding="utf-8")
    summary = completion_summary(generated)
    print(f"Updated translation completion percentages: {summary}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

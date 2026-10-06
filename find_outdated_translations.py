#!/usr/bin/env python3
"""Find or remove stale and obsolete ETW translations.

The translation version stored in each language is used as the initial point at
which all of that language's strings are considered current. Git history is
then replayed semantically: English value changes make a translation stale,
while later changes to the translated value make it current again. File moves,
sorting, and the legacy TXT-to-JSON conversion do not affect freshness.
Obsolete target keys are keys that no longer exist in the English source.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable, Sequence


REPOSITORY_ROOT = Path(__file__).resolve().parent
TRANSLATIONS_DIR = (
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
CORE_MOD_PREFIX = "Contents/mods/Evolving Traits World/"
VERSION_KEY = "UI_ETW_AAA_TranslationVersion"
LEGACY_ASSIGNMENT = re.compile(
    r'^\s*([A-Za-z0-9_]+)\s*=\s*"((?:\\.|[^"\\])*)"\s*,?\s*(?:--.*)?$'
)
LEGACY_ASSIGNMENT_START = re.compile(r"^\s*[A-Za-z0-9_]+\s*=")
JSON_ASSIGNMENT = re.compile(
    r'^\s*("(?:\\.|[^"\\])*")\s*:\s*("(?:\\.|[^"\\])*")\s*,?\s*$'
)
JSON_ASSIGNMENT_START = re.compile(r'^\s*"(?:\\.|[^"\\])*"\s*:')
VERSION_IN_SUBJECT = re.compile(r"^v?\.?([0-9]+\.[0-9]+\.[0-9]+)(?:\s|$)", re.I)
LEGACY_ENCODINGS = {
    "CH": ("big5", "gb18030"),
    "CN": ("gb18030",),
    "JP": ("cp932",),
    "KO": ("cp949",),
    "RU": ("cp1251",),
    "TR": ("cp1254", "cp1252"),
    "UA": ("cp1251",),
}

TranslationKey = tuple[str, str]
TranslationMap = dict[TranslationKey, str]


class TranslationHistoryError(RuntimeError):
    """Describe translation history that cannot be analyzed safely."""


@dataclass(frozen=True)
class LanguageReport:
    """Contain the history analysis result for one target language."""

    language: str
    version: str
    baseline_commit: str
    stale: tuple[dict[str, str], ...]
    missing: tuple[TranslationKey, ...]
    obsolete: tuple[TranslationKey, ...]


class GitRepository:
    """Provide cached, read-only access to translation snapshots in Git."""

    def __init__(self, root: Path) -> None:
        """Initialize access to the repository at *root*."""
        self.root = root
        self._snapshot_cache: dict[tuple[str, str], TranslationMap] = {}
        self._tree_cache: dict[str, dict[str, str]] = {}
        self._blob_cache: dict[str, bytes] = {}
        self.warnings: list[str] = []

    def run(self, arguments: Sequence[str], *, text: bool = True) -> str | bytes:
        """Run Git with *arguments* and return stdout or raise a clear error."""
        command = ["git", *arguments]
        result = subprocess.run(
            command,
            cwd=self.root,
            capture_output=True,
            text=text,
            check=False,
        )
        if result.returncode != 0:
            stderr = result.stderr if text else result.stderr.decode("utf-8", "replace")
            raise TranslationHistoryError(
                f"Git command failed: {' '.join(command)}\n{stderr.strip()}"
            )
        return result.stdout

    def resolve_commit(self, reference: str) -> str:
        """Resolve *reference* to a full commit hash."""
        output = self.run(["rev-parse", "--verify", f"{reference}^{{commit}}"])
        assert isinstance(output, str)
        return output.strip()

    def is_ancestor(self, ancestor: str, descendant: str) -> bool:
        """Return whether *ancestor* is reachable from *descendant*."""
        result = subprocess.run(
            ["git", "merge-base", "--is-ancestor", ancestor, descendant],
            cwd=self.root,
            capture_output=True,
            check=False,
        )
        if result.returncode not in (0, 1):
            raise TranslationHistoryError("Could not inspect Git commit ancestry.")
        return result.returncode == 0

    def resolve_release(self, version: str, target_commit: str) -> str:
        """Resolve a translation version to its release commit on target history."""
        for tag in (f"v.{version}", f"v{version}", version):
            try:
                commit = self.resolve_commit(f"refs/tags/{tag}")
            except TranslationHistoryError:
                continue
            if self.is_ancestor(commit, target_commit):
                self._ensure_first_parent(commit, target_commit, version)
                return commit

        output = self.run(
            [
                "log",
                "--first-parent",
                "--format=%H%x09%s",
                target_commit,
                "--fixed-strings",
                f"--grep={version}",
            ]
        )
        assert isinstance(output, str)
        for line in output.splitlines():
            commit, separator, subject = line.partition("\t")
            match = VERSION_IN_SUBJECT.match(subject.strip()) if separator else None
            if match and match.group(1) == version:
                return commit

        mod_info_pathspec = f":(glob){CORE_MOD_PREFIX}**/mod.info"
        candidates = self.run(
            [
                "log",
                "--first-parent",
                "--reverse",
                "--format=%H",
                f"-G^modversion={version}$",
                target_commit,
                "--",
                mod_info_pathspec,
            ]
        )
        assert isinstance(candidates, str)
        for commit in candidates.splitlines():
            result = subprocess.run(
                [
                    "git",
                    "grep",
                    "-l",
                    "-E",
                    f"^modversion={re.escape(version)}$",
                    commit,
                    "--",
                    mod_info_pathspec,
                ],
                cwd=self.root,
                capture_output=True,
                check=False,
            )
            if result.returncode == 0:
                return commit
            if result.returncode != 1:
                raise TranslationHistoryError(
                    f"Could not inspect mod.info for release {version}."
                )

        raise TranslationHistoryError(
            f"Could not map translation version {version!r} to a release commit."
        )

    def _ensure_first_parent(
        self, baseline_commit: str, target_commit: str, version: str
    ) -> None:
        """Require the release to be present on the target's first-parent history."""
        output = self.run(["rev-list", "--first-parent", target_commit])
        assert isinstance(output, str)
        if baseline_commit not in output.splitlines():
            raise TranslationHistoryError(
                f"Release {version} is not on {target_commit[:12]}'s first-parent history."
            )

    def commits_touching_language(
        self, baseline_commit: str, target_commit: str, language: str
    ) -> list[str]:
        """Return first-parent commits changing translation files for *language*."""
        pathspec = (
            f":(glob){CORE_MOD_PREFIX}**/Translate/{language.upper()}/*"
        )
        output = self.run(
            [
                "log",
                "--first-parent",
                "--reverse",
                "--format=%H",
                f"{baseline_commit}..{target_commit}",
                "--",
                pathspec,
            ]
        )
        assert isinstance(output, str)
        return [line for line in output.splitlines() if line]

    def latest_declared_version(self, target_commit: str, language: str) -> str:
        """Return the newest historical version marker for *language*."""
        pathspec = (
            f":(glob){CORE_MOD_PREFIX}**/Translate/{language.upper()}/*"
        )
        output = self.run(
            [
                "log",
                "--first-parent",
                "--format=%H",
                target_commit,
                "--",
                pathspec,
            ]
        )
        assert isinstance(output, str)
        for commit in output.splitlines():
            snapshot = self.translation_snapshot(commit, language)
            matches = [
                value
                for (_, key), value in snapshot.items()
                if key.lower() == VERSION_KEY.lower()
            ]
            if len(matches) > 1:
                raise TranslationHistoryError(
                    f"Expected at most one {VERSION_KEY} in {language} at "
                    f"{commit[:12]}, found {len(matches)}."
                )
            if matches:
                return validate_translation_version(matches[0], language)
        raise TranslationHistoryError(
            f"Could not find a historical {VERSION_KEY} for {language}."
        )

    def first_parent_order(self, baseline_commit: str, target_commit: str) -> dict[str, int]:
        """Map commits after *baseline_commit* to their chronological order."""
        output = self.run(
            [
                "rev-list",
                "--first-parent",
                "--reverse",
                f"{baseline_commit}..{target_commit}",
            ]
        )
        assert isinstance(output, str)
        return {commit: index for index, commit in enumerate(output.splitlines())}

    def translation_snapshot(self, commit: str, language: str) -> TranslationMap:
        """Load the active core translation map for *language* at *commit*."""
        language = language.upper()
        cache_key = (commit, language)
        if cache_key in self._snapshot_cache:
            return self._snapshot_cache[cache_key].copy()

        tree = self._commit_tree(commit)
        marker = f"/media/lua/shared/Translate/{language}/"
        candidates = [
            path
            for path in tree
            if marker in path
            and (path.endswith(".json") or path.endswith(f"_{language}.txt"))
        ]

        common_candidates = [path for path in candidates if "/common/media/" in path]
        if common_candidates:
            candidates = common_candidates

        snapshot: TranslationMap = {}
        for path in sorted(candidates):
            component = component_name(path, language)
            blob = self._read_blob(tree[path])
            values = parse_translation_blob(
                blob, f"{commit}:{path}", self.warnings
            )
            for key, value in values.items():
                snapshot[(component, key)] = value

        self._snapshot_cache[cache_key] = snapshot
        return snapshot.copy()

    def _commit_tree(self, commit: str) -> dict[str, str]:
        """Return core-mod paths and blob IDs for *commit*, with caching."""
        if commit in self._tree_cache:
            return self._tree_cache[commit]
        output = self.run(
            ["ls-tree", "-r", "-z", commit, "--", CORE_MOD_PREFIX], text=False
        )
        assert isinstance(output, bytes)
        tree: dict[str, str] = {}
        for record in output.split(b"\0"):
            if not record:
                continue
            metadata, separator, raw_path = record.partition(b"\t")
            if not separator:
                raise TranslationHistoryError(f"Unexpected ls-tree output at {commit}.")
            fields = metadata.split()
            if len(fields) != 3 or fields[1] != b"blob":
                continue
            tree[raw_path.decode("utf-8")] = fields[2].decode("ascii")
        self._tree_cache[commit] = tree
        return tree

    def _read_blob(self, object_id: str) -> bytes:
        """Read a Git blob by object ID, with content-addressed caching."""
        if object_id not in self._blob_cache:
            output = self.run(["cat-file", "blob", object_id], text=False)
            assert isinstance(output, bytes)
            self._blob_cache[object_id] = output
        return self._blob_cache[object_id]


def component_name(path: str, language: str) -> str:
    """Normalize historical and current filenames to a JSON component name."""
    stem = Path(path).stem
    suffix = f"_{language.upper()}"
    if stem.upper().endswith(suffix):
        stem = stem[: -len(suffix)]
    return f"{stem}.json"


def decode_blob(blob: bytes, path: str) -> str:
    """Decode a translation blob without silently replacing invalid bytes."""
    language_match = re.search(r"/Translate/([^/]+)/", path)
    language = language_match.group(1).upper() if language_match else ""
    encodings = ["utf-8-sig"]
    if blob.startswith((b"\xff\xfe", b"\xfe\xff")):
        encodings.append("utf-16")
    encodings.extend(("utf-8", *LEGACY_ENCODINGS.get(language, ("cp1252",))))
    for encoding in encodings:
        try:
            return blob.decode(encoding)
        except UnicodeDecodeError:
            continue
    raise TranslationHistoryError(f"Historical translation is not UTF-8: {path}")


def unique_object(pairs: Iterable[tuple[str, Any]]) -> dict[str, Any]:
    """Build a JSON object while rejecting duplicate keys."""
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"Duplicate JSON key: {key}")
        result[key] = value
    return result


def parse_translation_blob(
    blob: bytes, path: str, warnings: list[str]
) -> dict[str, str]:
    """Parse a current JSON or historical Lua-table translation blob."""
    text = decode_blob(blob, path)
    if path.endswith(".json"):
        try:
            data = json.loads(text, object_pairs_hook=unique_object)
        except (json.JSONDecodeError, ValueError) as error:
            data = parse_relaxed_json(text, path)
            warnings.append(f"Parsed malformed historical JSON line-by-line: {path}: {error}")
        if not isinstance(data, dict):
            raise TranslationHistoryError(f"Translation JSON is not an object: {path}")
        return {str(key): str(value) for key, value in data.items()}
    return parse_legacy_translation(text, path, warnings)


def parse_relaxed_json(text: str, path: str) -> dict[str, str]:
    """Recover one-line JSON string entries from malformed historical files."""
    result: dict[str, str] = {}
    candidate_lines = 0
    parsed_lines = 0
    for line in text.splitlines():
        if not JSON_ASSIGNMENT_START.match(line):
            continue
        candidate_lines += 1
        match = JSON_ASSIGNMENT.match(line)
        if not match:
            continue
        parsed_lines += 1
        key = json.loads(match.group(1))
        value = json.loads(match.group(2))
        result[str(key)] = str(value)
    if not result or parsed_lines < candidate_lines:
        raise TranslationHistoryError(
            f"Could not safely recover malformed historical JSON: {path}"
        )
    return result


def parse_legacy_translation(
    text: str, path: str, warnings: list[str]
) -> dict[str, str]:
    """Parse single-line string assignments from a legacy PZ translation table."""
    result: dict[str, str] = {}
    assignment_lines = 0
    parsed_lines = 0
    for line_number, line in enumerate(text.splitlines(), start=1):
        start_match = LEGACY_ASSIGNMENT_START.match(line)
        if start_match and line[start_match.end() :].lstrip().startswith('"'):
            assignment_lines += 1
        match = LEGACY_ASSIGNMENT.match(line)
        if match:
            parsed_lines += 1
            result[match.group(1)] = unescape_lua_string(
                match.group(2), path, line_number
            )
            continue
        if not start_match or not line[start_match.end() :].lstrip().startswith('"'):
            continue

        key_match = re.match(r"^\s*([A-Za-z0-9_]+)", line)
        assert key_match is not None
        raw_value = line[start_match.end() :].lstrip()[1:]
        if raw_value.endswith('",'):
            raw_value = raw_value[:-2]
        elif raw_value.endswith('"'):
            raw_value = raw_value[:-1]
        result[key_match.group(1)] = raw_value
        parsed_lines += 1
        warnings.append(f"Recovered malformed legacy assignment: {path}:{line_number}")
    if not result or parsed_lines < assignment_lines:
        raise TranslationHistoryError(
            f"Could not safely parse every assignment in legacy translation: {path}"
        )
    return result


def unescape_lua_string(value: str, path: str, line_number: int) -> str:
    """Decode the Lua escapes used by legacy translation string literals."""
    escapes = {
        "a": "\a",
        "b": "\b",
        "f": "\f",
        "n": "\n",
        "r": "\r",
        "t": "\t",
        "v": "\v",
        "\\": "\\",
        '"': '"',
        "'": "'",
    }
    output: list[str] = []
    index = 0
    while index < len(value):
        character = value[index]
        if character != "\\":
            output.append(character)
            index += 1
            continue
        index += 1
        if index >= len(value):
            raise TranslationHistoryError(f"Trailing escape in {path}:{line_number}")
        escaped = value[index]
        if escaped in escapes:
            output.append(escapes[escaped])
            index += 1
            continue
        if escaped == "x" and index + 2 < len(value):
            digits = value[index + 1 : index + 3]
            if re.fullmatch(r"[0-9A-Fa-f]{2}", digits):
                output.append(chr(int(digits, 16)))
                index += 3
                continue
        if escaped.isdigit():
            match = re.match(r"[0-9]{1,3}", value[index:])
            assert match is not None
            output.append(chr(int(match.group(0), 10)))
            index += len(match.group(0))
            continue
        raise TranslationHistoryError(
            f"Unsupported Lua escape \\{escaped} in {path}:{line_number}"
        )
    return "".join(output)


def semantic_changes(before: TranslationMap, after: TranslationMap) -> set[TranslationKey]:
    """Return keys whose presence or value differs between two snapshots."""
    return {
        key
        for key in before.keys() | after.keys()
        if before.get(key) != after.get(key) or (key in before) != (key in after)
    }


def is_metadata_key(key: TranslationKey) -> bool:
    """Return whether a key is translator metadata rather than game text."""
    name = key[1].lower()
    return (
        name == VERSION_KEY.lower()
        or "note_to_" in name
        or name.startswith("___note")
    )


def is_version_key(key: TranslationKey) -> bool:
    """Return whether a key stores the target language's version marker."""
    return key[1].lower() == VERSION_KEY.lower()


def validate_translation_version(value: str, language: str) -> str:
    """Validate and return a language's declared translation version."""
    version = value.strip()
    if not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", version):
        raise TranslationHistoryError(
            f"Invalid translation version {version!r} in {language}."
        )
    return version


def translation_version(
    repository: GitRepository,
    snapshot: TranslationMap,
    language: str,
    target_commit: str,
) -> str:
    """Read the current marker or recover its last value from Git history."""
    matches = [value for (_, key), value in snapshot.items() if key.lower() == VERSION_KEY.lower()]
    if len(matches) > 1:
        raise TranslationHistoryError(
            f"Expected at most one {VERSION_KEY} in {language}, found {len(matches)}."
        )
    if matches:
        return validate_translation_version(matches[0], language)
    return repository.latest_declared_version(target_commit, language)


def analyze_language(
    repository: GitRepository,
    language: str,
    target_commit: str,
) -> LanguageReport:
    """Replay source and target history and report stale translations."""
    current_source = repository.translation_snapshot(target_commit, "EN")
    current_target = repository.translation_snapshot(target_commit, language)
    version = translation_version(repository, current_target, language, target_commit)
    baseline = repository.resolve_release(version, target_commit)
    baseline_source = repository.translation_snapshot(baseline, "EN")
    baseline_target = repository.translation_snapshot(baseline, language)

    source_commits = repository.commits_touching_language(baseline, target_commit, "EN")
    target_commits = repository.commits_touching_language(baseline, target_commit, language)
    order = repository.first_parent_order(baseline, target_commit)
    events: dict[str, set[str]] = {}
    for commit in source_commits:
        events.setdefault(commit, set()).add("source")
    for commit in target_commits:
        events.setdefault(commit, set()).add("target")

    stale_since: dict[TranslationKey, str] = {}
    previous_source = baseline_source
    previous_target = baseline_target

    for commit in sorted(events, key=order.__getitem__):
        event_types = events[commit]
        if "source" in event_types:
            source = repository.translation_snapshot(commit, "EN")
            for key in semantic_changes(previous_source, source):
                if (
                    key in source
                    and previous_target.get(key, "") != ""
                    and not is_metadata_key(key)
                ):
                    stale_since[key] = commit
                elif key not in source:
                    stale_since.pop(key, None)
            previous_source = source

        if "target" in event_types:
            target = repository.translation_snapshot(commit, language)
            for key in semantic_changes(previous_target, target):
                stale_since.pop(key, None)
            previous_target = target

    if previous_source != current_source:
        raise TranslationHistoryError(
            f"English history replay for {language} did not reach the target snapshot."
        )
    if previous_target != current_target:
        raise TranslationHistoryError(
            f"Target history replay for {language} did not reach the target snapshot."
        )

    stale = tuple(
        {
            "file": key[0],
            "key": key[1],
            "source": current_source[key],
            "translation": current_target[key],
            "source_changed_at": stale_since[key],
        }
        for key in sorted(stale_since)
        if (
            key in current_source
            and current_target.get(key, "") != ""
            and not is_metadata_key(key)
        )
    )
    source_keys = {key for key in current_source if not is_metadata_key(key)}
    target_translation_keys = {
        key
        for key, value in current_target.items()
        if value != "" and not is_metadata_key(key)
    }
    target_cleanup_keys = {
        key for key in current_target if not is_version_key(key)
    }
    missing = tuple(sorted(source_keys - target_translation_keys))
    obsolete = tuple(sorted(target_cleanup_keys - current_source.keys()))
    return LanguageReport(
        language=language,
        version=version,
        baseline_commit=baseline,
        stale=stale,
        missing=missing,
        obsolete=obsolete,
    )


def available_languages() -> list[str]:
    """Return current non-English translation directory names."""
    if not TRANSLATIONS_DIR.is_dir():
        raise TranslationHistoryError(f"Translation directory not found: {TRANSLATIONS_DIR}")
    return sorted(
        path.name.upper()
        for path in TRANSLATIONS_DIR.iterdir()
        if path.is_dir() and path.name.upper() != "EN"
    )


def select_languages(requested: Sequence[str] | None) -> list[str]:
    """Validate requested languages or select every current target language."""
    available = available_languages()
    if not requested:
        return available
    selected = sorted({language.upper() for language in requested})
    unknown = [language for language in selected if language not in available]
    if unknown:
        raise TranslationHistoryError(
            f"Unknown language(s): {', '.join(unknown)}. Available: {', '.join(available)}"
        )
    return selected


def load_current_json(path: Path) -> dict[str, Any]:
    """Load a working-tree JSON object while rejecting duplicate keys."""
    try:
        data = json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=unique_object)
    except (json.JSONDecodeError, ValueError) as error:
        raise TranslationHistoryError(f"Could not parse {path}: {error}") from error
    if not isinstance(data, dict):
        raise TranslationHistoryError(f"Translation JSON is not an object: {path}")
    return data


def apply_reports(
    reports: Sequence[LanguageReport], target_commit: str
) -> tuple[int, int]:
    """Delete reported stale and obsolete keys from target JSON files."""
    repository = GitRepository(REPOSITORY_ROOT)
    if repository.resolve_commit("HEAD") != target_commit:
        raise TranslationHistoryError("--apply requires --to-ref to resolve to HEAD.")

    removals: dict[Path, list[tuple[str, str, str]]] = {}
    for report in reports:
        target_snapshot = repository.translation_snapshot(
            target_commit, report.language
        )
        for item in report.stale:
            path = TRANSLATIONS_DIR / report.language / item["file"]
            removals.setdefault(path, []).append(
                ("stale", item["key"], item["translation"])
            )
        for filename, key in report.obsolete:
            path = TRANSLATIONS_DIR / report.language / filename
            expected = target_snapshot.get((filename, key))
            if expected is None:
                raise TranslationHistoryError(
                    f"Obsolete key disappeared from target snapshot: {path}: {key}"
                )
            removals.setdefault(path, []).append(("obsolete", key, expected))

    validated: dict[Path, dict[str, Any]] = {}
    for path, items in removals.items():
        data = load_current_json(path)
        for kind, key, expected in items:
            if key not in data:
                continue
            if str(data[key]) != expected:
                raise TranslationHistoryError(
                    "Working-tree translation changed since HEAD; refusing to delete: "
                    f"{path}: {key}"
                )
        validated[path] = data

    stale_deleted = 0
    obsolete_deleted = 0
    for path, data in validated.items():
        for kind, key, _ in removals[path]:
            if key not in data:
                continue
            del data[key]
            if kind == "stale":
                stale_deleted += 1
            else:
                obsolete_deleted += 1
        path.write_text(
            json.dumps(data, ensure_ascii=False, indent=4, sort_keys=True) + "\n",
            encoding="utf-8",
        )

    if validated:
        result = subprocess.run(
            [sys.executable, str(REPOSITORY_ROOT / "sort_translation_json.py")],
            cwd=REPOSITORY_ROOT,
            check=False,
        )
        if result.returncode != 0:
            raise TranslationHistoryError(
                "sort_translation_json.py failed after applying changes."
            )
    return stale_deleted, obsolete_deleted


def report_as_json(
    reports: Sequence[LanguageReport], target_ref: str, target_commit: str
) -> str:
    """Serialize reports to stable, machine-readable JSON."""
    payload = {
        "target_ref": target_ref,
        "target_commit": target_commit,
        "languages": {
            report.language: {
                "translation_version": report.version,
                "baseline_commit": report.baseline_commit,
                "stale": list(report.stale),
                "missing": [
                    {"file": filename, "key": key} for filename, key in report.missing
                ],
                "obsolete": [
                    {"file": filename, "key": key} for filename, key in report.obsolete
                ],
            }
            for report in reports
        },
    }
    return json.dumps(payload, ensure_ascii=False, indent=2) + "\n"


def print_human_report(reports: Sequence[LanguageReport], target_commit: str) -> None:
    """Print a concise report followed by stale keys grouped by language."""
    print(f"Compared translations with {target_commit[:12]}")
    for report in reports:
        print(
            f"{report.language}: version {report.version} ({report.baseline_commit[:12]}), "
            f"stale={len(report.stale)}, missing={len(report.missing)}, "
            f"obsolete={len(report.obsolete)}"
        )
        for item in report.stale:
            print(
                f"  {item['file']}:{item['key']} "
                f"(English changed at {item['source_changed_at'][:12]})"
            )


def parse_args() -> argparse.Namespace:
    """Parse command-line options."""
    parser = argparse.ArgumentParser(
        description=(
            "Find translations made stale by English changes since each language's "
            "declared ETW version. Dry-run is the default."
        )
    )
    parser.add_argument(
        "--language",
        action="append",
        help="analyze one language code; repeat for multiple languages",
    )
    parser.add_argument(
        "--to-ref",
        default="HEAD",
        help="Git revision containing the English source to compare against (default: HEAD)",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="write the report as JSON",
    )
    parser.add_argument(
        "--apply",
        action="store_true",
        help=(
            "delete stale and obsolete target keys from the working tree; "
            "requires --to-ref HEAD"
        ),
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="show details for malformed historical files recovered during analysis",
    )
    return parser.parse_args()


def main() -> int:
    """Run translation history analysis and optionally remove stale keys."""
    args = parse_args()
    if args.json and hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    try:
        repository = GitRepository(REPOSITORY_ROOT)
        target_commit = repository.resolve_commit(args.to_ref)
        languages = select_languages(args.language)
        reports = [
            analyze_language(repository, language, target_commit)
            for language in languages
        ]

        if args.json:
            print(report_as_json(reports, args.to_ref, target_commit), end="")
        else:
            print_human_report(reports, target_commit)

        normalized_warnings = list(
            dict.fromkeys(
                re.sub(r"\b[0-9a-f]{40}:", "", warning)
                for warning in repository.warnings
            )
        )
        if args.verbose:
            for warning in normalized_warnings:
                print(f"warning: {warning}", file=sys.stderr)
        elif normalized_warnings:
            print(
                "warning: recovered "
                f"{len(normalized_warnings)} malformed historical translation pattern(s); "
                "use --verbose for details.",
                file=sys.stderr,
            )

        if args.apply:
            stale_deleted, obsolete_deleted = apply_reports(reports, target_commit)
            print(
                f"Deleted {stale_deleted} stale and {obsolete_deleted} obsolete "
                "translation key(s).",
                file=sys.stderr if args.json else sys.stdout,
            )
        else:
            print(
                "Dry-run only; use --apply to delete stale and obsolete target keys.",
                file=sys.stderr if args.json else sys.stdout,
            )
        return 0
    except TranslationHistoryError as error:
        print(f"error: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())

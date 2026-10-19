#!/usr/bin/env python3
"""Check the front matter of dataset posts in _posts/.

Jekyll's error messages point at the template that failed (usually index.html),
not at the post whose front matter caused the failure.
This script checks each post directly and names the file and line at fault.

Problems that break the site build (or are certainly mistakes) are errors and
make the script exit nonzero.
Problems that only make a dataset display badly are warnings.

Usage: python check_posts.py [FILE ...]
With no arguments, every post in _posts/ is checked.
"""

import datetime
import os
import re
import sys
from pathlib import Path

import yaml

REPO_ROOT = Path(__file__).resolve().parents[2]
POSTS_DIR = REPO_ROOT / "_posts"

# Jekyll only treats files named YYYY-MM-DD-slug.ext as posts.
# Anything else in _posts/ (e.g., template.md) is silently skipped by Jekyll.
POST_NAME = re.compile(r"^(\d{4})-(\d{2})-(\d{2})-[^.]+\.(md|markdown)$")

REQUIRED_KEYS = ["layout", "categories", "title", "website", "echoes", "extras"]
OPTIONAL_KEYS = ["scanner", "fmriprep", "afni"]
SCANNERS = ["3T", "7T"]
# Extras that _layouts/dataset.html knows how to label.
EXTRAS = ["asl", "complex", "norf", "physio", "single-echo"]

IN_GITHUB_ACTIONS = os.environ.get("GITHUB_ACTIONS") == "true"


class Report:
    def __init__(self):
        self.n_errors = 0
        self.n_warnings = 0

    def _emit(self, level, path, line, message):
        rel = path.relative_to(REPO_ROOT).as_posix() if path.is_relative_to(REPO_ROOT) else path.as_posix()
        where = f"{rel}:{line}" if line else rel
        print(f"{level.upper()}: {where}: {message}")
        if IN_GITHUB_ACTIONS:
            loc = f"file={rel},line={line}" if line else f"file={rel}"
            message = message.replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")
            print(f"::{level} {loc}::{message}")

    def error(self, path, line, message):
        self.n_errors += 1
        self._emit("error", path, line, message)

    def warning(self, path, line, message):
        self.n_warnings += 1
        self._emit("warning", path, line, message)


def is_url(value):
    return isinstance(value, str) and re.match(r"^https?://\S+$", value) is not None


def split_front_matter(path, text, report):
    """Return (front matter text, line number of its first line) or None."""
    lines = text.splitlines()
    if not lines or lines[0].rstrip() != "---":
        report.error(
            path, 1,
            "File must start with a '---' line to open the front matter. "
            "Without it, Jekyll treats the whole file as plain content.",
        )
        return None
    for i, line in enumerate(lines[1:], start=1):
        if line.rstrip() == "---":
            return "\n".join(lines[1:i]), 2
    report.error(path, 1, "Front matter is opened with '---' but never closed with a second '---' line.")
    return None


def key_lines(node, first_line):
    """Map each top-level key to its line number, and find duplicate keys."""
    lines, duplicates = {}, []
    for key_node, _ in node.value:
        key = key_node.value
        line = key_node.start_mark.line + first_line
        if key in lines:
            duplicates.append((key, line))
        else:
            lines[key] = line
    return lines, duplicates


def check_post(path, report):
    match = POST_NAME.match(path.name)
    if not match:
        if re.match(r"^\d{4}-", path.name):
            report.error(
                path, None,
                "File name must look like YYYY-MM-DD-name.md. "
                "Jekyll will silently skip this file.",
            )
        return
    try:
        datetime.date(*(int(g) for g in match.groups()[:3]))
    except ValueError:
        report.error(path, None, "File name does not start with a valid date (YYYY-MM-DD).")

    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError as err:
        report.error(path, None, f"File is not valid UTF-8: {err}")
        return

    split = split_front_matter(path, text, report)
    if split is None:
        return
    fm_text, first_line = split

    try:
        node = yaml.compose(fm_text)
        data = yaml.safe_load(fm_text)
    except yaml.YAMLError as err:
        mark = getattr(err, "problem_mark", None) or getattr(err, "context_mark", None)
        line = mark.line + first_line if mark else None
        problem = getattr(err, "problem", None) or str(err)
        report.error(
            path, line,
            f"Front matter is not valid YAML ({problem}). "
            "Values containing ':' or starting with a quote or '[' usually need to be wrapped in quotes.",
        )
        return

    if not isinstance(data, dict):
        report.error(path, first_line, "Front matter must be a set of 'key: value' lines.")
        return

    lines, duplicates = key_lines(node, first_line)
    for key, line in duplicates:
        report.error(path, line, f"Key '{key}' appears more than once; only the last one is used.")

    for key in data:
        if key not in REQUIRED_KEYS + OPTIONAL_KEYS:
            report.warning(
                path, lines.get(key),
                f"Unknown key '{key}' (is it a typo?). "
                f"Known keys are: {', '.join(REQUIRED_KEYS + OPTIONAL_KEYS)}.",
            )

    for key in REQUIRED_KEYS:
        if key not in data:
            message = f"Required key '{key}' is missing."
            if key in ("echoes", "extras"):
                message += (
                    f" Add '{key}: []' if there are none. A missing value breaks the index page "
                    "with 'concat filter requires an array argument'."
                )
            report.error(path, None, message)

    for key in ("layout", "categories"):
        if key in data and data[key] != "dataset":
            report.error(
                path, lines.get(key),
                f"'{key}' must be 'dataset' (got {data[key]!r}); "
                "otherwise the post will not appear in the dataset table.",
            )

    if "title" in data and not (isinstance(data["title"], str) and data["title"].strip()):
        report.error(path, lines.get("title"), "'title' must be a non-empty string.")

    for key in ("website", "fmriprep", "afni"):
        value = data.get(key)
        if value is None:
            if key == "website" and key in data:
                report.error(path, lines.get(key), "'website' is empty; it must be the dataset's URL.")
            continue
        if not is_url(value):
            report.error(path, lines.get(key), f"'{key}' must be a URL starting with http:// or https:// (got {value!r}).")

    # index.html combines every post's echoes and extras with Liquid's `concat`,
    # which fails the whole build if any post's value is not a list,
    # and then `sort`s them, which fails if the items are of mixed types.
    if "echoes" in data:
        echoes = data["echoes"]
        line = lines.get("echoes")
        if not isinstance(echoes, list):
            report.error(
                path, line,
                f"'echoes' must be a list such as [3] or [3, 4] (got {echoes!r}). "
                "A missing or non-list value breaks the index page with "
                "'concat filter requires an array argument'.",
            )
        elif any(not isinstance(e, int) or isinstance(e, bool) for e in echoes):
            report.error(
                path, line,
                f"'echoes' must contain only whole numbers, without quotes (got {echoes!r}).",
            )
        elif not echoes:
            report.warning(path, line, "'echoes' is empty, so the dataset will not show a number of echoes.")
        elif any(e < 3 for e in echoes):
            report.warning(path, line, f"'echoes' includes fewer than 3 echoes ({echoes!r}); this site only lists datasets with 3 or more.")

    if "extras" in data:
        extras = data["extras"]
        line = lines.get("extras")
        if not isinstance(extras, list):
            report.error(
                path, line,
                f"'extras' must be a list; use [] if there are none (got {extras!r}). "
                "A missing or non-list value breaks the index page with "
                "'concat filter requires an array argument'.",
            )
        elif any(not isinstance(e, str) for e in extras):
            report.error(path, line, f"'extras' must contain only text values (got {extras!r}).")
        else:
            for extra in extras:
                if extra not in EXTRAS:
                    report.warning(
                        path, line,
                        f"Unknown extra '{extra}'; the dataset page will show a blank entry for it. "
                        f"Known extras are: {', '.join(EXTRAS)}.",
                    )

    if "scanner" not in data or data["scanner"] is None:
        report.warning(path, lines.get("scanner"), "'scanner' is not set, so the dataset will not appear under 3T or 7T.")
    elif data["scanner"] not in SCANNERS:
        report.warning(
            path, lines.get("scanner"),
            f"'scanner' is {data['scanner']!r}; the index table only has columns for {', '.join(SCANNERS)}.",
        )


def main(argv):
    if argv:
        paths = [Path(p).resolve() for p in argv]
    else:
        paths = sorted(p for p in POSTS_DIR.iterdir() if p.is_file())

    report = Report()
    for path in paths:
        check_post(path, report)

    print(f"\nChecked {len(paths)} file(s): {report.n_errors} error(s), {report.n_warnings} warning(s).")
    return 1 if report.n_errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

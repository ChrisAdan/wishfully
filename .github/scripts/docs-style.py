#!/usr/bin/env python3
"""Checks Markdown files against the CI-enforced rows of the AGENTS.md pattern table.

Ignored: fenced code blocks, inline code spans and blockquotes (maintainer quotes).
Exits 1 and prints file:line for each violation. Standard library only.
"""
import pathlib
import re
import sys

SKIP_DIRS = {".git", ".build", ".swiftpm", "node_modules", "DerivedData"}
RULES = [
    ("em dash (row 1)", re.compile("—")),
    ("'X's own Y' (row 2)", re.compile(r"\b\w+['’]s own\b", re.IGNORECASE)),
    ("change tracking (row 3)", re.compile(r"\b(formerly|previously|no longer|used to)\b", re.IGNORECASE)),
    ("'gate' (row 25)", re.compile(r"\bgat(e|es|ed|ing)\b", re.IGNORECASE)),
]
FIRST_PERSON = (
    "first person (row 4)",
    re.compile(r"\bI(?:'m|'ve|'d|'ll)?\b|(?i:\b(?:me|my|mine|we|we're|we've|our|ours|us)\b)"),
)
FIRST_PERSON_EXEMPT = ("docs/decisions/",)
INLINE_CODE = re.compile(r"`[^`]*`")


def markdown_files(root):
    for path in sorted(root.rglob("*.md")):
        relative = path.relative_to(root)
        if not SKIP_DIRS.intersection(relative.parts):
            yield relative.as_posix(), path


def check(name, path):
    rules = list(RULES)
    if not name.startswith(FIRST_PERSON_EXEMPT):
        rules.append(FIRST_PERSON)
    problems = []
    in_fence = False
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        stripped = line.lstrip()
        if stripped.startswith("```"):
            in_fence = not in_fence
            continue
        if in_fence or stripped.startswith(">"):
            continue
        prose = INLINE_CODE.sub("", line)
        for rule_name, pattern in rules:
            if pattern.search(prose):
                problems.append(f"{name}:{number}: {rule_name}: {line.strip()}")
    return problems


def main():
    root = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
    problems = [problem for name, path in markdown_files(root) for problem in check(name, path)]
    for problem in problems:
        print(problem)
    if problems:
        print(f"\n{len(problems)} style violation(s). See the pattern table in AGENTS.md.")
        return 1
    print("Docs style: all Markdown files pass.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

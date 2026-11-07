#!/usr/bin/env python3
"""Checks Markdown files against the mechanical rules in docs/STYLE.md.

Text inside fenced code blocks and inline code spans is ignored. Exits 1 and
prints file:line for each violation.
"""
import pathlib
import re
import subprocess
import sys

RULES = [
    ("em dash", re.compile("—")),
    ("'X's own Y' construction", re.compile(r"\b\w+['’]s own\b", re.IGNORECASE)),
    ("change-tracking language", re.compile(r"\b(formerly|previously|no longer|used to)\b", re.IGNORECASE)),
]
FIRST_PERSON = ("first person", re.compile(r"\b(I|I'm|I've|I'd|I'll|me|my|mine|we|we're|we've|our|ours|us)\b"))
FIRST_PERSON_EXEMPT = ("docs/decisions/",)
INLINE_CODE = re.compile(r"`[^`]*`")


def markdown_files():
    out = subprocess.run(["git", "ls-files", "-z", "*.md"], capture_output=True, check=True)
    return [p for p in out.stdout.decode().split("\0") if p]


def check(path):
    rules = list(RULES)
    if not path.startswith(FIRST_PERSON_EXEMPT):
        rules.append(FIRST_PERSON)
    problems = []
    in_fence = False
    for number, line in enumerate(pathlib.Path(path).read_text(encoding="utf-8").splitlines(), start=1):
        if line.lstrip().startswith("```"):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        prose = INLINE_CODE.sub("", line)
        for name, pattern in rules:
            if pattern.search(prose):
                problems.append(f"{path}:{number}: {name}: {line.strip()}")
    return problems


def main():
    problems = [problem for path in markdown_files() for problem in check(path)]
    for problem in problems:
        print(problem)
    if problems:
        print(f"\n{len(problems)} style violation(s). See docs/STYLE.md.")
        return 1
    print("Docs style: all Markdown files pass.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

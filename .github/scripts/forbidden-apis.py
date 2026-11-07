#!/usr/bin/env python3
"""Fails CI when source code uses a forbidden API (AGENTS.md, section 2).

Covers Swift, Python and shell files. Comment lines are skipped. This file is
exempt from its own scan because it lists the patterns. Standard library only.
"""
import pathlib
import re
import sys

SKIP_DIRS = {".git", ".build", ".swiftpm", "node_modules", "DerivedData"}
SELF = pathlib.PurePosixPath(".github/scripts/forbidden-apis.py")

FORBIDDEN = {
    ".swift": [
        r"\bProcess\s*\(", r"\bNSTask\b", r"\bposix_spawn", r"\bsystem\s*\(", r"\bpopen\s*\(",
        r"\bexecv\w*\s*\(", r"\bexecl\w*\s*\(", r"\bdlopen\b", r"\bdlsym\b", r"\bNSExpression\b",
        r"\bJSContext\b", r"\bevaluateJavaScript\b", r"\bNSAppleScript\b", r"\bNSSelectorFromString\b",
        r"Selector\s*\(\s*\(", r"\bunarchiveObject\b",
    ],
    ".py": [
        r"\bsubprocess\b", r"\bos\.system\b", r"\bos\.popen\b", r"\bos\.exec\w*", r"\bos\.spawn\w*",
        r"(?<![\w.])eval\s*\(", r"(?<![\w.])exec\s*\(", r"\bpickle\b", r"\bmarshal\b", r"\bshelve\b",
        r"\byaml\.load\s*\(", r"__import__\s*\(", r"\bctypes\b", r"\bimport\s+pty\b",
    ],
    ".sh": [
        r"(^|[;&|]\s*)eval\b", r"\|\s*(ba|z)?sh\b", r"source\s+<\(",
    ],
}
COMMENT_PREFIX = {".swift": "//", ".py": "#", ".sh": "#"}


def source_files(root):
    for path in sorted(root.rglob("*")):
        relative = path.relative_to(root)
        if path.is_file() and path.suffix in FORBIDDEN and not SKIP_DIRS.intersection(relative.parts):
            yield pathlib.PurePosixPath(relative.as_posix()), path


def scan(relative, path):
    patterns = [re.compile(p) for p in FORBIDDEN[path.suffix]]
    comment = COMMENT_PREFIX[path.suffix]
    problems = []
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        if line.lstrip().startswith(comment):
            continue
        for pattern in patterns:
            if pattern.search(line):
                problems.append(f"{relative}:{number}: forbidden API `{pattern.pattern}`: {line.strip()}")
    return problems


def main():
    root = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
    problems = [
        problem
        for relative, path in source_files(root)
        if relative != SELF
        for problem in scan(relative, path)
    ]
    for problem in problems:
        print(problem)
    if problems:
        print(f"\n{len(problems)} forbidden API use(s). See AGENTS.md, section 2.")
        return 1
    print("Forbidden APIs: none found.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

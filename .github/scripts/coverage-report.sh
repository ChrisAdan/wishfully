#!/usr/bin/env bash
# Prints line coverage for a Swift package's sources (tests excluded) and its
# test count, to the log and to the GitHub job summary. Run after
# `swift test --enable-code-coverage`.
set -euo pipefail

PACKAGE="${1:?usage: coverage-report.sh <package-path>}"
BIN="$(swift build --package-path "$PACKAGE" --show-bin-path)"
TEST_BINARY="$(find "$BIN" -maxdepth 1 -name '*PackageTests.xctest' | head -n 1)"
PROFDATA="$BIN/codecov/default.profdata"

REPORT="$(llvm-cov report "$TEST_BINARY" -instr-profile "$PROFDATA" -ignore-filename-regex='(/Tests/|/\.build/)')"
TESTS="$(grep -rhoE '@Test\b' "$PACKAGE/Tests" | wc -l | tr -d ' ')"

echo "$REPORT"
echo "Test functions: $TESTS"
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    {
        echo "### Coverage: $(basename "$PACKAGE")"
        echo "Test functions: $TESTS"
        echo '```'
        echo "$REPORT"
        echo '```'
    } >> "$GITHUB_STEP_SUMMARY"
fi

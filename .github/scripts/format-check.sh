#!/usr/bin/env bash
# Checks formatting of every tracked Swift file, one file per SwiftFormat process.
#
# Why one file at a time: SwiftFormat's Linux build intermittently segfaults
# (exit 139) when it formats many files in parallel on multi-core CI runners.
# Serial runs avoid its internal concurrency. As a second line of defence, a
# file whose check *crashes* is retried once, and the retry is logged loudly.
# A genuine formatting violation is never retried: it fails the build.
set -uo pipefail

status=0
while IFS= read -r -d '' file; do
    swiftformat --lint --quiet "$file"
    rc=$?
    if [ "$rc" -eq 139 ]; then
        echo "::warning file=$file::SwiftFormat crashed (segfault); retrying once"
        swiftformat --lint --quiet "$file"
        rc=$?
    fi
    if [ "$rc" -ne 0 ]; then
        echo "::error file=$file::Formatting check failed (exit $rc). Run 'swiftformat .' locally."
        status=1
    fi
done < <(git ls-files -z -- '*.swift')

exit "$status"

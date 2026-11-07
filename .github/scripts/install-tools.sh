#!/usr/bin/env bash
# Installs the CI guardrail tools at pinned versions, verifying each download
# against a SHA-256 checksum recorded here. A tampered or swapped release fails
# the build instead of running. This file is the single source of truth for
# tool versions; update a version and its checksum together.
set -euo pipefail

BIN_DIR="${1:?usage: install-tools.sh <bin-dir>}"
mkdir -p "$BIN_DIR"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

SWIFTFORMAT_VERSION="0.64.6"
SWIFTFORMAT_SHA256="5b9b03a383409a4bf60b0cacd6b18fb36fc3fbacd8b8af156a2865b80ff20ebe"

SWIFTLINT_VERSION="0.65.1"
SWIFTLINT_SHA256="caeed6f4a679c35539ffaf124f6c4ab4a8416917f7d8796279dc52b74026059d"

GITLEAKS_VERSION="8.30.1"
GITLEAKS_SHA256="551f6fc83ea457d62a0d98237cbad105af8d557003051f41f3e7ca7b3f2470eb"

# fetch <url> <sha256> <output-file>
fetch() {
    curl --fail --silent --show-error --location --retry 3 --output "$3" "$1"
    echo "$2  $3" | sha256sum --check --quiet
}

fetch "https://github.com/nicklockwood/SwiftFormat/releases/download/${SWIFTFORMAT_VERSION}/swiftformat_linux.zip" \
    "$SWIFTFORMAT_SHA256" "$WORK/swiftformat.zip"
unzip -q -o "$WORK/swiftformat.zip" -d "$WORK/swiftformat"
install -m 0755 "$WORK/swiftformat/swiftformat_linux" "$BIN_DIR/swiftformat"

fetch "https://github.com/realm/SwiftLint/releases/download/${SWIFTLINT_VERSION}/swiftlint_linux_amd64.zip" \
    "$SWIFTLINT_SHA256" "$WORK/swiftlint.zip"
unzip -q -o "$WORK/swiftlint.zip" -d "$WORK/swiftlint"
install -m 0755 "$WORK/swiftlint/swiftlint-static" "$BIN_DIR/swiftlint"

fetch "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz" \
    "$GITLEAKS_SHA256" "$WORK/gitleaks.tar.gz"
tar -xzf "$WORK/gitleaks.tar.gz" -C "$WORK" gitleaks
install -m 0755 "$WORK/gitleaks" "$BIN_DIR/gitleaks"

echo "Installed: swiftformat ${SWIFTFORMAT_VERSION}, swiftlint ${SWIFTLINT_VERSION}, gitleaks ${GITLEAKS_VERSION}"

#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/triple-space-comma-tests.XXXXXX")"
trap 'rm -rf "$TEST_DIR"' EXIT

swiftc \
    "$ROOT_DIR/Sources/TripleSpaceCommaCore/SpaceTapDetector.swift" \
    "$ROOT_DIR/Tests/TripleSpaceCommaCoreTests/SpaceTapDetectorTests.swift" \
    -o "$TEST_DIR/SpaceTapDetectorTests"

"$TEST_DIR/SpaceTapDetectorTests"

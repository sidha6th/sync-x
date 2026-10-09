#!/usr/bin/env bash
set -euo pipefail

expected="${1:?usage: check_version.sh <version>}"

pubspec_version="$(grep -E '^version:' pubspec.yaml | head -1 | awk '{print $2}')"

if [[ "$pubspec_version" != "$expected" ]]; then
  echo "pubspec.yaml version is '$pubspec_version', tag says '$expected'" >&2
  exit 1
fi

if ! grep -qE "^## +${expected//./\\.}( |$)" CHANGELOG.md; then
  echo "CHANGELOG.md has no '## $expected' section" >&2
  exit 1
fi

echo "version $expected: pubspec and CHANGELOG agree"

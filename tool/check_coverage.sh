#!/usr/bin/env bash
set -euo pipefail

min="${COVERAGE_MIN:-0}"
lcov="coverage/lcov.info"

if [[ ! -f "$lcov" ]]; then
  echo "$lcov not found; run flutter test --coverage first" >&2
  exit 1
fi

read -r hit found < <(
  awk -F: '
    /^LH:/ { hit += $2 }
    /^LF:/ { found += $2 }
    END { print hit+0, found+0 }
  ' "$lcov"
)

if (( found == 0 )); then
  echo "no lines found in $lcov" >&2
  exit 1
fi

pct=$(( hit * 100 / found ))
echo "coverage: ${hit}/${found} lines = ${pct}% (gate: ${min}%)"

if (( pct < min )); then
  echo "coverage ${pct}% is below gate ${min}%" >&2
  exit 1
fi

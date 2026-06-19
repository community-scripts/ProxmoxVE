#!/usr/bin/env bash
# Copyright (c) 2021-2026 community-scripts ORG
# License: MIT
#
# Flags ct/*.sh update_script blocks that mutate config/data destructively
# without calling create_backup. Used in CI / local review before merge.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CT_DIR="${ROOT}/ct"
FAIL=0
CHECKED=0
FLAGGED=0

check_file() {
  local file="$1"
  local base content block
  base="$(basename "$file")"
  content="$(<"$file")"
  [[ "$content" == *"function update_script"* ]] || return 0
  CHECKED=$((CHECKED + 1))

  block="$(python3 - "$file" <<'PY'
import re, sys
text = open(sys.argv[1]).read()
m = re.search(r'function update_script\(\).*?(?=^function |\Z)', text, re.S | re.M)
print(m.group() if m else "")
PY
)"

  [[ -n "$block" ]] || return 0
  [[ "$block" == *"create_backup"* ]] && return 0

  if echo "$block" | grep -qE 'sed -i|\.env|settings\.(py|json)|config\.(json|yml|yaml)|/etc/[^ ]+\.(conf|env)'; then
    if echo "$block" | grep -qE 'rm -rf|find .* -delete|mv .*\.(bak|old)'; then
      echo "MISSING create_backup: ct/${base}"
      FLAGGED=$((FLAGGED + 1))
      FAIL=1
    fi
  fi
}

for f in "$CT_DIR"/*.sh; do
  [[ -f "$f" ]] || continue
  check_file "$f"
done

echo "Checked ${CHECKED} update scripts, flagged ${FLAGGED} without create_backup"
exit "$FAIL"

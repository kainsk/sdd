#!/usr/bin/env bash
# sdd-link-index — build a backlink index of all ID references in specs/
# Usage: sdd-link-index.sh [specs-dir] > specs/link-index.md
set -euo pipefail

SPECS="${1:-${SDD_SPECS:-specs}}"
[[ -d "$SPECS" ]] || { echo "fatal: no specs dir: $SPECS" >&2; exit 2; }

DEFS=$(mktemp); MENTIONS=$(mktemp)
trap 'rm -f "$DEFS" "$MENTIONS"' EXIT

# Definitions: id <tab> file:line
grep -rnE '^##+ (ART|ENT|INV|EVT|FEA|SCN)-[0-9]{3}([^0-9]|$)' "$SPECS" \
  | awk -F: '{
      match($0, /(ART|ENT|INV|EVT|FEA|SCN)-[0-9]+/)
      id = substr($0, RSTART, RLENGTH)
      printf "%s\t%s:%s\n", id, $1, $2
    }' \
  | sort > "$DEFS"

# Mentions: id <tab> file:line (skip NNN placeholders, definition headings, and 4+-digit sequences like invoice numbers)
grep -rnE '(ART|ENT|INV|EVT|FEA|SCN)-[0-9]+' "$SPECS" \
  | grep -v 'NNN' \
  | awk -F: '{
      line = $0
      sub(/^[^:]+:[0-9]+:/, "", line)
      if (line ~ /^##+ (ART|ENT|INV|EVT|FEA|SCN)-/) next
      while (match(line, /(ART|ENT|INV|EVT|FEA|SCN)-[0-9]+/)) {
        id = substr(line, RSTART, RLENGTH)
        # Only accept exact 3-digit IDs (len = 7: 3 letters + dash + 3 digits)
        if (length(id) == 7) {
          printf "%s\t%s:%s\n", id, $1, $2
        }
        line = substr(line, RSTART + RLENGTH)
      }
    }' \
  | sort -u > "$MENTIONS"

TODAY=$(date +%Y-%m-%d)

cat <<EOF
<!-- L0: Auto-generated backlink index of all ID references in specs/ — do not edit -->

# Link index

> Auto-generated $(printf '%s' "$TODAY"). Do not edit manually. Rebuild with \`/sdd:housekeeping\` or \`sdd link-index specs > specs/link-index.md\`.

## Definitions

EOF

awk -F'\t' '{ printf "- \`%s\` — %s\n", $1, $2 }' "$DEFS"

cat <<EOF

## Backlinks

EOF

# Group mentions by ID (MENTIONS is already sorted)
prev_id=""
while IFS=$'\t' read -r id loc; do
  [[ -z "$id" ]] && continue
  if [[ "$id" != "$prev_id" ]]; then
    [[ -n "$prev_id" ]] && echo ""
    echo "### \`$id\`"
    prev_id="$id"
  fi
  echo "- \`$loc\`"
done < "$MENTIONS"
echo

cat <<EOF

## Dangling references

EOF

comm -23 \
  <(awk -F'\t' '{print $1}' "$MENTIONS" | sort -u) \
  <(awk -F'\t' '{print $1}' "$DEFS"     | sort -u) \
  | while IFS= read -r id; do
      [[ -z "$id" ]] && continue
      echo "- \`$id\` — referenced but not defined"
    done

echo

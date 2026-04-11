#!/usr/bin/env bash
# sdd-validate — integrity check for SDD specs/ tree
# Usage: sdd-validate.sh [specs-dir]
# Exits 0 if clean, 1 if errors, 2 if misuse.
set -euo pipefail

SPECS="${1:-${SDD_SPECS:-specs}}"
ERR=0
WARN=0

say_err()  { printf 'ERROR: %s\n' "$*" >&2; ERR=$((ERR+1)); }
say_warn() { printf 'WARN:  %s\n' "$*" >&2; WARN=$((WARN+1)); }

[[ -d "$SPECS" ]] || { echo "fatal: no specs dir: $SPECS" >&2; exit 2; }

# --- Locate constitution ---
CONST=""
for cand in "$SPECS/constitution.md" "$SPECS"/*/constitution.md; do
  [[ -f "$cand" ]] && { CONST="$cand"; break; }
done
[[ -n "$CONST" ]] || { say_err "constitution.md not found under $SPECS"; exit 1; }

# --- Extract YAML frontmatter scalar ---
yaml_scalar() {
  local file="$1" key="$2"
  awk -v k="$key" '
    BEGIN { in_fm=0 }
    /^---$/ { in_fm = (in_fm == 0) ? 1 : 2; next }
    in_fm == 1 && $0 ~ "^[[:space:]]*" k ":" {
      sub("^[[:space:]]*" k ":[[:space:]]*", "")
      gsub(/["'"'"']/, "")
      sub(/[[:space:]]*$/, "")
      print; exit
    }
  ' "$file"
}

CONST_VER=$(yaml_scalar "$CONST" version)
[[ -n "$CONST_VER" ]] || say_err "$CONST has no version in frontmatter"
echo "constitution: $CONST ($CONST_VER)"

# --- Version handshake on L1/L2 ---
while IFS= read -r file; do
  [[ "$file" == "$CONST" ]] && continue
  # Look for "constitution: X" under depends_on
  depver=$(awk '
    BEGIN { in_fm=0; in_dep=0 }
    /^---$/ { in_fm = (in_fm == 0) ? 1 : 2; next }
    in_fm != 1 { next }
    /^depends_on:/ { in_dep=1; next }
    in_dep && /^[[:space:]]+constitution:/ {
      sub("^[[:space:]]+constitution:[[:space:]]*", "")
      gsub(/["'"'"']/, "")
      sub(/[[:space:]]*$/, "")
      print; exit
    }
    in_dep && /^[^[:space:]]/ { in_dep=0 }
  ' "$file")
  if [[ -n "$depver" && "$depver" != "$CONST_VER" ]]; then
    say_err "$file: depends_on.constitution=$depver but constitution is $CONST_VER"
  fi
done < <(find "$SPECS" -name '*.md' \
           ! -name 'link-index.md' \
           ! -name 'scorecard.md' \
           ! -name 'evolve-log.md')

# --- Collect definitions and references ---
DEFS_FILE=$(mktemp); REFS_FILE=$(mktemp); DEF_PAIRS=$(mktemp)
ORPHAN_MENTIONS=$(mktemp); INV_ORPHAN_MENTIONS=$(mktemp)
trap 'rm -f "$DEFS_FILE" "$REFS_FILE" "$DEF_PAIRS" "$ORPHAN_MENTIONS" "$INV_ORPHAN_MENTIONS"' EXIT

# Definition = "### ID —" or "### ID" at line start
grep -rnE '^##+ (ART|ENT|INV|EVT|FEA|SCN)-[0-9]{3}([^0-9]|$)' "$SPECS" \
  | awk -F: '{ match($0, /(ART|ENT|INV|EVT|FEA|SCN)-[0-9]+/); id=substr($0, RSTART, RLENGTH); print id }' \
  | sort > "$DEFS_FILE"

# Full pairs: id|file:line (for duplicate detection)
grep -rnE '^##+ (ART|ENT|INV|EVT|FEA|SCN)-[0-9]{3}([^0-9]|$)' "$SPECS" \
  | awk -F: '{ match($0, /(ART|ENT|INV|EVT|FEA|SCN)-[0-9]+/); id=substr($0, RSTART, RLENGTH); print id "|" $1 ":" $2 }' \
  > "$DEF_PAIRS"

# References = any ID occurrence. Filter: exactly 3 digits (len=7), skip NNN placeholders.
grep -rhoE '(ART|ENT|INV|EVT|FEA|SCN)-[0-9]+' "$SPECS" \
  | awk 'length($0) == 7' \
  | grep -vE 'NNN' \
  | sort -u > "$REFS_FILE"

# --- Duplicate IDs ---
DUPS=$(awk -F'|' '{print $1}' "$DEF_PAIRS" | sort | uniq -d)
if [[ -n "$DUPS" ]]; then
  while IFS= read -r d; do
    locs=$(awk -F'|' -v id="$d" '$1==id {print $2}' "$DEF_PAIRS" | tr '\n' ' ')
    say_err "duplicate ID $d at: $locs"
  done <<< "$DUPS"
fi

# --- Dangling references ---
while IFS= read -r ref; do
  [[ -z "$ref" ]] && continue
  grep -qxF -- "$ref" "$DEFS_FILE" || say_warn "dangling reference: $ref (used but not defined)"
done < "$REFS_FILE"

# --- RFC 2119 in articles ---
# Scan each ART block up to the next ### heading (any kind).
while IFS= read -r line; do
  file=$(awk -F: '{print $1}' <<< "$line")
  lno=$(awk -F: '{print $2}' <<< "$line")
  id=$(grep -oE '(ART|ENT|INV|EVT|FEA|SCN)-[0-9]+' <<< "$line")
  block=$(awk -v start="$lno" '
    NR == start { in_block = 1; print; next }
    in_block && /^### / { exit }
    in_block { print }
  ' "$file")
  if ! grep -qE '\b(MUST|MUST NOT|SHOULD|SHOULD NOT|MAY)\b' <<< "$block"; then
    say_warn "$file:$lno article $id — no RFC 2119 keyword in block"
  fi
done < <(grep -rnE '^### ART-[0-9]{3}([^0-9]|$)' "$SPECS" || true)

# --- Orphan entities (ENT-NNN defined but not mentioned in any scenario file) ---
# Single-pass: collect all ENT-NNN mentions from scenario files once, then diff.
{
  find "$SPECS" -name '*.md' -path '*scenario*' 2>/dev/null | while IFS= read -r sf; do
    [[ -z "$sf" ]] && continue
    grep -hoE 'ENT-[0-9]{3}' "$sf" 2>/dev/null || true
  done
} | awk 'length($0) == 7' | sort -u > "$ORPHAN_MENTIONS"

while IFS= read -r id; do
  [[ "$id" =~ ^ENT ]] || continue
  grep -qxF -- "$id" "$ORPHAN_MENTIONS" \
    || say_warn "orphan entity: $id (defined but not referenced by any scenario)"
done < "$DEFS_FILE"

# --- Security gate trace ---
# ART articles with `Категория: security` MUST cite at least one SCN-NNN in their
# enforcement field — security decisions need observable verification.
# Heuristic: read the block from "### ART-NNN" to next "### " heading.
while IFS= read -r line; do
  file=$(awk -F: '{print $1}' <<< "$line")
  lno=$(awk -F: '{print $2}' <<< "$line")
  id=$(grep -oE 'ART-[0-9]{3}' <<< "$line" | head -1)
  block=$(awk -v start="$lno" '
    NR == start { in_block = 1; print; next }
    in_block && /^### / { exit }
    in_block { print }
  ' "$file")
  if grep -qE '\*\*Категория:\*\*[[:space:]]+`security`' <<< "$block" \
     || grep -qE '\*\*Category:\*\*[[:space:]]+`security`' <<< "$block"; then
    if ! grep -qE 'SCN-[0-9]{3}' <<< "$block"; then
      say_warn "$file:$lno article $id (category: security) — should cite a SCN-NNN in enforcement for observable verification"
    fi
  fi
done < <(grep -rnE '^### ART-[0-9]{3}([^0-9]|$)' "$SPECS" || true)

# --- Orphan invariants (INV-NNN defined but not mentioned in any scenario file) ---
# Symmetric to orphan entities. Invariants without scenario coverage are aspirational —
# they exist in the domain model but no observable behavior tests them.
{
  find "$SPECS" -name '*.md' -path '*scenario*' 2>/dev/null | while IFS= read -r sf; do
    [[ -z "$sf" ]] && continue
    grep -hoE 'INV-[0-9]{3}' "$sf" 2>/dev/null || true
  done
} | awk 'length($0) == 7' | sort -u > "$INV_ORPHAN_MENTIONS"

while IFS= read -r id; do
  [[ "$id" =~ ^INV ]] || continue
  grep -qxF -- "$id" "$INV_ORPHAN_MENTIONS" \
    || say_warn "orphan invariant: $id (defined but not referenced by any scenario)"
done < "$DEFS_FILE"

# --- Pattern file caps (cog-inspired pattern routing) ---
MEMORY_DIR="${SDD_MEMORY:-memory}"
PATTERNS_CORE="$MEMORY_DIR/patterns.md"
PATTERNS_SAT_DIR="$MEMORY_DIR/patterns"
PATTERNS_CORE_MAX_LINES=70
PATTERNS_CORE_MAX_BYTES=5632   # 5.5 KB
PATTERNS_SAT_MAX_LINES=30

if [[ -f "$PATTERNS_CORE" ]]; then
  p_lines=$(wc -l < "$PATTERNS_CORE" | awk '{print $1}')
  p_bytes=$(wc -c < "$PATTERNS_CORE" | awk '{print $1}')
  echo "core patterns: $PATTERNS_CORE ($p_lines lines, $p_bytes bytes)"
  if [[ "$p_lines" -gt "$PATTERNS_CORE_MAX_LINES" ]]; then
    say_err "$PATTERNS_CORE exceeds HARD cap: $p_lines lines (max $PATTERNS_CORE_MAX_LINES)"
  fi
  if [[ "$p_bytes" -gt "$PATTERNS_CORE_MAX_BYTES" ]]; then
    say_err "$PATTERNS_CORE exceeds HARD cap: $p_bytes bytes (max $PATTERNS_CORE_MAX_BYTES = 5.5KB)"
  fi
fi

if [[ -d "$PATTERNS_SAT_DIR" ]]; then
  while IFS= read -r sat; do
    [[ -z "$sat" ]] && continue
    s_lines=$(wc -l < "$sat" | awk '{print $1}')
    if [[ "$s_lines" -gt "$PATTERNS_SAT_MAX_LINES" ]]; then
      say_warn "$sat exceeds SOFT cap: $s_lines lines (max $PATTERNS_SAT_MAX_LINES)"
    fi
  done < <(find "$PATTERNS_SAT_DIR" -type f -name '*.md' 2>/dev/null)
fi

printf '\nsummary: %d errors, %d warnings\n' "$ERR" "$WARN"
[[ $ERR -eq 0 ]]

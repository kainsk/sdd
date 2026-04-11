#!/usr/bin/env bash
# sdd-scorecard — compute spec health metrics
# Usage: sdd-scorecard.sh [specs-dir] > specs/scorecard.md
set -eu

SPECS="${1:-${SDD_SPECS:-specs}}"
[[ -d "$SPECS" ]] || { echo "fatal: no specs dir: $SPECS" >&2; exit 2; }

count_defs() {
  { grep -rhE "^##+ $1-[0-9]{3}([^0-9]|\$)" "$SPECS" 2>/dev/null || true; } | wc -l | awk '{print $1+0}'
}

ART=$(count_defs ART)
ENT=$(count_defs ENT)
INV=$(count_defs INV)
EVT=$(count_defs EVT)
FEA=$(count_defs FEA)
SCN=$(count_defs SCN)

count_kw() {
  { grep -rhoE "\\b$1\\b" "$SPECS" 2>/dev/null || true; } | wc -l | awk '{print $1+0}'
}

MUST=$(count_kw 'MUST')
MUSTNOT=$(count_kw 'MUST NOT')
SHOULD=$(count_kw 'SHOULD')
MAY=$(count_kw 'MAY')

# Orphan entities: defined ENT-NNN not mentioned in any scenario file
orphan_count=0
defined_ents=$({ grep -rhoE 'ENT-[0-9]{3}' "$SPECS" 2>/dev/null || true; } \
  | awk 'length($0) == 7' | sort -u)
scenario_files=$(find "$SPECS" -name '*.md' -path '*scenario*' 2>/dev/null || true)
if [[ -n "$defined_ents" ]]; then
  while IFS= read -r id; do
    [[ -z "$id" ]] && continue
    found=0
    if [[ -n "$scenario_files" ]]; then
      while IFS= read -r scen; do
        if grep -qF "$id" "$scen" 2>/dev/null; then found=1; break; fi
      done <<< "$scenario_files"
    fi
    [[ $found -eq 0 ]] && orphan_count=$((orphan_count+1))
  done <<< "$defined_ents"
fi

# Articles without enforcement field
art_no_enforce=$({
  find "$SPECS" -name '*.md' -print0 2>/dev/null | while IFS= read -r -d '' f; do
    awk '
      /^### ART-[0-9]{3}/ { if (in_a && !has) print id; in_a=1; has=0; id=$2; next }
      in_a && /^### / { if (!has) print id; in_a=0; next }
      in_a && /^[[:space:]]*[-*]?[[:space:]]*\*?\*?(Контроль|enforcement|Enforcement)\*?\*?:/ { has=1 }
      END { if (in_a && !has) print id }
    ' "$f"
  done
} | sort -u | wc -l | awk '{print $1+0}')

ratio() {
  local a="$1" b="$2"
  if [[ "$b" -eq 0 ]]; then echo "n/a"; else LC_ALL=C awk "BEGIN{printf \"%.2f\", $a/$b}"; fi
}

pct() {
  local a="$1" b="$2"
  if [[ "$b" -eq 0 ]]; then echo "n/a"; else LC_ALL=C awk "BEGIN{printf \"%.0f%%\", ($a/$b)*100}"; fi
}

# --- Pattern file stats (cog-inspired pattern routing) ---
MEMORY_DIR="${SDD_MEMORY:-memory}"
PATTERNS_CORE_MAX_LINES=70
PATTERNS_CORE_MAX_BYTES=5632
PATTERNS_SAT_MAX_LINES=30

core_lines=0; core_bytes=0
if [[ -f "$MEMORY_DIR/patterns.md" ]]; then
  core_lines=$(wc -l < "$MEMORY_DIR/patterns.md" | awk '{print $1}')
  core_bytes=$(wc -c < "$MEMORY_DIR/patterns.md" | awk '{print $1}')
fi

sat_count=0; sat_total_lines=0; sat_over_cap=0
if [[ -d "$MEMORY_DIR/patterns" ]]; then
  while IFS= read -r sat; do
    [[ -z "$sat" ]] && continue
    sat_count=$((sat_count+1))
    l=$(wc -l < "$sat" | awk '{print $1}')
    sat_total_lines=$((sat_total_lines+l))
    [[ "$l" -gt "$PATTERNS_SAT_MAX_LINES" ]] && sat_over_cap=$((sat_over_cap+1))
  done < <(find "$MEMORY_DIR/patterns" -type f -name '*.md' 2>/dev/null)
fi

TODAY=$(date +%Y-%m-%d)

cat <<EOF
<!-- L0: Auto-generated spec health scorecard — do not edit -->

# Scorecard

> Auto-generated $TODAY. Do not edit manually. Rebuild with \`/sdd:housekeeping\` or \`sdd scorecard specs > specs/scorecard.md\`.

## Inventory

| Kind | Count |
|---|---|
| Articles (ART) | $ART |
| Entities (ENT) | $ENT |
| Invariants (INV) | $INV |
| Events (EVT) | $EVT |
| Features (FEA) | $FEA |
| Scenarios (SCN) | $SCN |

## Normative vocabulary (RFC 2119)

| Keyword | Count |
|---|---|
| MUST | $MUST |
| MUST NOT | $MUSTNOT |
| SHOULD | $SHOULD |
| MAY | $MAY |

## Ratios

| Metric | Value |
|---|---|
| Scenarios per feature | $(ratio "$SCN" "$FEA") |
| Invariants per entity | $(ratio "$INV" "$ENT") |
| Orphan entities | $orphan_count |
| Articles without enforcement field | $art_no_enforce |

## Patterns (cog-inspired routing)

| Metric | Value |
|---|---|
| Core lines / hard cap ($PATTERNS_CORE_MAX_LINES) | $core_lines ($(pct "$core_lines" "$PATTERNS_CORE_MAX_LINES")) |
| Core bytes / hard cap ($PATTERNS_CORE_MAX_BYTES) | $core_bytes ($(pct "$core_bytes" "$PATTERNS_CORE_MAX_BYTES")) |
| Satellite files | $sat_count |
| Satellite total lines | $sat_total_lines |
| Satellites over soft cap ($PATTERNS_SAT_MAX_LINES) | $sat_over_cap |

## Health signals

- **MUST-heavy vs MAY-heavy.** High MUST count indicates strict specs; heavy MAY indicates loose specs. Neither is inherently wrong — it should match the project's risk profile.
- **Orphan entities.** Entities defined in the domain but not referenced by any scenario are candidates for removal or for adding coverage.
- **Articles without enforcement.** Each article should have a concrete enforcement mechanism. A high count here means the Constitution is aspirational rather than operational.
- **Core patterns near cap.** If core lines > 80% of cap, start condensing or routing rules to satellites.
- **Empty satellites.** Satellite file count = 0 while the project has multiple bounded contexts means domain-specific rules live elsewhere (likely scattered).
EOF

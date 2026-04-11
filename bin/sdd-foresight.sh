#!/usr/bin/env bash
# sdd-foresight — surface convergence signals and blind spots across specs
# Usage: sdd-foresight.sh [specs-dir] > specs/foresight.md
set -eu

SPECS="${1:-${SDD_SPECS:-specs}}"
[[ -d "$SPECS" ]] || { echo "fatal: no specs dir: $SPECS" >&2; exit 2; }

MENTIONS=$(mktemp)
DEFS=$(mktemp)
trap 'rm -f "$MENTIONS" "$DEFS"' EXIT

# Collect unique (id, file) pairs — one line per file where the id appears.
while IFS= read -r f; do
  { grep -oE '(ART|ENT|INV|EVT|FEA|SCN)-[0-9]+' "$f" 2>/dev/null || true; } \
    | awk 'length($0) == 7' \
    | grep -vE 'NNN' \
    | sort -u \
    | awk -v F="$f" '{printf "%s\t%s\n", $0, F}'
done < <(find "$SPECS" -name '*.md' 2>/dev/null) > "$MENTIONS"

# Collect defined IDs.
{ grep -rhE '^##+ (ART|ENT|INV|EVT|FEA|SCN)-[0-9]{3}([^0-9]|$)' "$SPECS" 2>/dev/null || true; } \
  | awk '{
      match($0, /(ART|ENT|INV|EVT|FEA|SCN)-[0-9]+/)
      print substr($0, RSTART, RLENGTH)
    }' \
  | sort -u > "$DEFS"

TODAY=$(date +%Y-%m-%d)

cat <<EOF
<!-- L0: Convergence signals and blind spots across specs — nudges, not fixes -->

# Foresight — $TODAY

> Auto-generated. Диагностика, не лечение. Решения — за автором спек.

## Hot invariants (cited by 3+ files)

Инварианты, на которые ссылаются из трёх и более файлов, имеют высокий blast-radius: любое их изменение затрагивает много мест. Нуждаются в строжайшем ревью.

EOF

hot_inv=$(awk -F'\t' '$1 ~ /^INV-/ {a[$1]++} END { for (k in a) if (a[k] >= 3) print a[k] "\t" k }' "$MENTIONS" \
  | sort -rn)
if [[ -z "$hot_inv" ]]; then
  echo "_Нет._"
else
  echo "$hot_inv" | while IFS=$'\t' read -r cnt id; do
    echo "- \`$id\` — $cnt файлов"
  done
fi

cat <<EOF

## Hot articles (cited by 2+ files)

Статьи Конституции, на которые ссылаются из нескольких файлов — архитектурные hotspots. Менять с осторожностью.

EOF

hot_art=$(awk -F'\t' '$1 ~ /^ART-/ {a[$1]++} END { for (k in a) if (a[k] >= 2) print a[k] "\t" k }' "$MENTIONS" \
  | sort -rn)
if [[ -z "$hot_art" ]]; then
  echo "_Нет._"
else
  echo "$hot_art" | while IFS=$'\t' read -r cnt id; do
    echo "- \`$id\` — $cnt файлов"
  done
fi

cat <<EOF

## Dormant entities

Сущности, определённые в доменной модели, но не цитируемые ни одним сценарием. Кандидаты на удаление ИЛИ на добавление покрытия.

EOF

dormant=""
while IFS= read -r id; do
  [[ "$id" =~ ^ENT ]] || continue
  cnt=$(awk -F'\t' -v i="$id" '$1==i && $2 ~ /scenario/ {print $2}' "$MENTIONS" | sort -u | wc -l | awk '{print $1+0}')
  if [[ "$cnt" -eq 0 ]]; then
    dormant="$dormant- \`$id\` — нет scenario coverage\n"
  fi
done < "$DEFS"
if [[ -z "$dormant" ]]; then
  echo "_Нет._"
else
  printf '%b' "$dormant"
fi

cat <<EOF

## Thin scenario coverage

Feature с одним сценарием или без сценариев вообще — тонкое покрытие поведения. Обычно означает, что edge cases не описаны.

EOF

thin=""
while IFS= read -r f; do
  fea=$({ grep -cE '^## FEA-[0-9]{3}' "$f" 2>/dev/null || true; } | head -1)
  scn=$({ grep -cE '^### SCN-[0-9]{3}' "$f" 2>/dev/null || true; } | head -1)
  fea=${fea:-0}
  scn=${scn:-0}
  if [[ "$fea" -gt 0 ]] && [[ "$scn" -le "$fea" ]]; then
    thin="$thin- \`$f\` — features: $fea, scenarios: $scn\n"
  fi
done < <(find "$SPECS" -name '*.md' -path '*scenario*' 2>/dev/null)
if [[ -z "$thin" ]]; then
  echo "_Нет._"
else
  printf '%b' "$thin"
fi

cat <<EOF

## Priority distribution

Доминирование \`MAY\` означает мягкие спеки; доминирование \`MUST\` — жёсткие. Крайние соотношения — повод задуматься.

EOF

# Count priorities only inside scenario files (paths matching *scenario*)
must_c=0; should_c=0; may_c=0
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  m=$({ grep -cE '^- \*\*priority:\*\* `?MUST`?' "$f" 2>/dev/null || true; } | head -1)
  s=$({ grep -cE '^- \*\*priority:\*\* `?SHOULD`?' "$f" 2>/dev/null || true; } | head -1)
  y=$({ grep -cE '^- \*\*priority:\*\* `?MAY`?' "$f" 2>/dev/null || true; } | head -1)
  must_c=$((must_c + ${m:-0}))
  should_c=$((should_c + ${s:-0}))
  may_c=$((may_c + ${y:-0}))
done < <(find "$SPECS" -name '*.md' -path '*scenario*' 2>/dev/null)

echo "- MUST: $must_c"
echo "- SHOULD: $should_c"
echo "- MAY: $may_c"

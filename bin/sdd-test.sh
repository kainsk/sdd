#!/usr/bin/env bash
# sdd-test — regression tests for the SDD toolkit
# Usage: bash bin/sdd-test.sh    (or, when plugin is enabled in PATH: sdd test)
# Exits 0 if all pass, 1 otherwise.
#
# Safe by construction: never mutates real files in memory/ or the handbook;
# the test fixture is generated inline in mktemp, tests work on copies of it,
# everything is cleaned up via trap.
set -eu

# Run from repo root
SELF_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$SELF_DIR"

PASS=0
FAIL=0

# TTY-guarded colors (no escape noise in CI/pipes)
if [[ -t 1 ]]; then
  GREEN=$'\033[32m'; RED=$'\033[31m'; RESET=$'\033[0m'
else
  GREEN=''; RED=''; RESET=''
fi

pass()    { printf '  %sPASS%s  %s\n' "$GREEN" "$RESET" "$1"; PASS=$((PASS+1)); }
fail()    { printf '  %sFAIL%s  %s\n' "$RED" "$RESET" "$1"; FAIL=$((FAIL+1)); }
section() { printf '\n%s\n' "── $1 ──"; }

# Run a command, suppress its output, return its exit code via stdout.
run_exit() {
  local ec=0
  "$@" > /dev/null 2>&1 || ec=$?
  echo "$ec"
}

assert_exit() {
  local name="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    pass "$name"
  else
    fail "$name (expected exit $expected, got $actual)"
  fi
}

# Inline fixture generator. Creates a minimal valid spec tree in $1.
# Not a worked example — purely test infrastructure.
make_fixture() {
  local dir="$1"
  cat > "$dir/constitution.md" <<'CONST'
---
version: 1.0.0
effective_date: 2026-01-01
supersedes: null
ratified_by:
  - test
status: active
---

# Constitution — Test Fixture

## Preamble

Minimal self-contained fixture for sdd-toolkit regression tests.

## Glossary

- **Widget** — arbitrary domain object used by tests.

## Statements

### ART-001 — Single language

- **Категория:** `tech-stack`
- **Формулировка:**
  > Проект **MUST** использовать один язык реализации.
- **Обоснование:** fixture
- **Область:** весь код
- **Исключения:** none
- **Контроль:** CI
- **Приоритет:** `critical`
- **Добавлено в:** `1.0.0`
CONST

  cat > "$dir/domain.md" <<'DOMAIN'
---
version: 1.0.0
depends_on:
  constitution: 1.0.0
status: active
scope: test
---

# Domain — Test Fixture

## Entities

### ENT-001 — Widget

- **Kind:** `entity`
- **Описание:** test entity
- **Identity:** `id`
- **Поля:**
  | Имя | Тип | Optional | Описание | Ограничения |
  |---|---|---|---|---|
  | `id` | string | false | identifier | non-empty |
- **Инварианты:** `INV-001`

## Invariants

### INV-001

- **Entity:** `ENT-001`
- **Rule:** `Widget.id` **MUST** be non-empty.
- **Rationale:** fixture
- **Enforcement:** constructor
DOMAIN

  cat > "$dir/scenarios.md" <<'SCEN'
---
version: 1.0.0
depends_on:
  constitution: 1.0.0
  domain: 1.0.0
status: active
feature_area: test
---

# Scenarios — Test Fixture

## FEA-001 — Widget lifecycle

**Narrative:**
- **As a** test runner
- **I want** a minimal scenario
- **So that** regression tests have a baseline

### SCN-001 — Create Widget with valid id

- **priority:** `MUST`
- **actors:** [test]
- **tags:** [`@smoke`]
- **references:**
  - entities: [`ENT-001`]
  - invariants: [`INV-001`]

```gherkin
Given a Widget constructor
When a Widget is created with id "w-1"
Then the Widget has id "w-1"
```
SCEN
}

# Long-lived fixture for the whole test run.
FIXTURE_ROOT=$(mktemp -d)
make_fixture "$FIXTURE_ROOT"
FIXTURE="$FIXTURE_ROOT"

# Trap cleanup — FIXTURE_ROOT (global) + CLEANUP (per-section mktemp resources).
CLEANUP=""
cleanup() {
  rm -rf "$FIXTURE_ROOT" 2>/dev/null || true
  [[ -n "${CLEANUP:-}" ]] && rm -rf $CLEANUP 2>/dev/null || true
}
trap cleanup EXIT INT TERM

track() { CLEANUP="$CLEANUP $1"; }

# ─────────────────────────────────────────────────────────────
section "Script syntax"
for f in bin/sdd bin/sdd-*.sh; do
  if bash -n "$f" 2>/dev/null; then
    pass "syntax $f"
  else
    fail "syntax $f"
  fi
done

# ─────────────────────────────────────────────────────────────
section "Baseline: inline fixture is clean"
assert_exit "validate fixture → exit 0"   0 "$(run_exit bash bin/sdd-validate.sh "$FIXTURE")"
assert_exit "link-index fixture → exit 0" 0 "$(run_exit bash bin/sdd-link-index.sh "$FIXTURE")"
assert_exit "scorecard fixture → exit 0"  0 "$(run_exit bash bin/sdd-scorecard.sh "$FIXTURE")"
assert_exit "foresight fixture → exit 0"  0 "$(run_exit bash bin/sdd-foresight.sh "$FIXTURE")"

# ─────────────────────────────────────────────────────────────
section "Cap regression — core patterns hard cap (isolated via SDD_MEMORY)"
TMP_MEM=$(mktemp -d); track "$TMP_MEM"
mkdir -p "$TMP_MEM/patterns"
cp memory/patterns.md "$TMP_MEM/patterns.md"
if [[ -d memory/patterns ]]; then
  cp -R memory/patterns/. "$TMP_MEM/patterns/" 2>/dev/null || true
fi

yes "- filler line" | head -80 >> "$TMP_MEM/patterns.md"
ec=$(SDD_MEMORY="$TMP_MEM" run_exit bash bin/sdd-validate.sh "$FIXTURE")
assert_exit "inflated core patterns → exit 1" 1 "$ec"

cp memory/patterns.md "$TMP_MEM/patterns.md"
ec=$(SDD_MEMORY="$TMP_MEM" run_exit bash bin/sdd-validate.sh "$FIXTURE")
assert_exit "restored core patterns → exit 0" 0 "$ec"

rm -rf "$TMP_MEM"; CLEANUP=""

# ─────────────────────────────────────────────────────────────
section "Duplicate ID detection"
TMP_SPECS=$(mktemp -d); track "$TMP_SPECS"
cp -R "$FIXTURE"/. "$TMP_SPECS/"
cat >> "$TMP_SPECS/scenarios.md" <<'EOF'

### ART-001 — Duplicate test article

- **Категория:** `process`
- **Формулировка:** test **MUST** not appear in real specs
EOF
ec=$(run_exit bash bin/sdd-validate.sh "$TMP_SPECS")
assert_exit "duplicate ART-001 → exit 1" 1 "$ec"
rm -rf "$TMP_SPECS"; CLEANUP=""

# ─────────────────────────────────────────────────────────────
section "Dangling reference detection"
TMP_SPECS=$(mktemp -d); track "$TMP_SPECS"
cp -R "$FIXTURE"/. "$TMP_SPECS/"
cat >> "$TMP_SPECS/scenarios.md" <<'EOF'

### SCN-999 — Dangling ref test

- **references:** entities: [ENT-777]
EOF
out=$(bash bin/sdd-validate.sh "$TMP_SPECS" 2>&1 || true)
if grep -qF 'dangling reference: ENT-777' <<< "$out"; then
  pass "dangling ENT-777 reported"
else
  fail "dangling ENT-777 not reported"
fi
rm -rf "$TMP_SPECS"; CLEANUP=""

# ─────────────────────────────────────────────────────────────
section "Security gate trace"
TMP_SPECS=$(mktemp -d); track "$TMP_SPECS"
cp -R "$FIXTURE"/. "$TMP_SPECS/"
# Append a security ART without SCN reference — should warn
cat >> "$TMP_SPECS/constitution.md" <<'EOF'

### ART-002 — Network egress

- **Категория:** `security`
- **Формулировка:** Service **MUST NOT** make outbound network calls.
- **Контроль:** integration test
- **Приоритет:** `critical`
EOF
out=$(bash bin/sdd-validate.sh "$TMP_SPECS" 2>&1 || true)
if grep -qF 'article ART-002 (category: security)' <<< "$out"; then
  pass "security gate trace warns when no SCN cited"
else
  fail "security gate trace did not warn (output: $(echo "$out" | tail -5))"
fi

# Now add SCN reference in enforcement — should not warn
sed 's/integration test/integration test, see SCN-001/' "$TMP_SPECS/constitution.md" > "$TMP_SPECS/constitution.md.new"
mv "$TMP_SPECS/constitution.md.new" "$TMP_SPECS/constitution.md"
out=$(bash bin/sdd-validate.sh "$TMP_SPECS" 2>&1 || true)
if ! grep -qF 'article ART-002 (category: security)' <<< "$out"; then
  pass "security gate trace clears when SCN cited"
else
  fail "security gate trace did not clear after adding SCN reference"
fi
rm -rf "$TMP_SPECS"; CLEANUP=""

# ─────────────────────────────────────────────────────────────
section "Orphan invariant detection"
TMP_SPECS=$(mktemp -d); track "$TMP_SPECS"
cp -R "$FIXTURE"/. "$TMP_SPECS/"
# Strip the INV-001 reference from scenarios.md (without removing INV-001 itself from domain.md)
sed 's/invariants: \[`INV-001`\]/invariants: []/' "$TMP_SPECS/scenarios.md" > "$TMP_SPECS/scenarios.md.new"
mv "$TMP_SPECS/scenarios.md.new" "$TMP_SPECS/scenarios.md"
out=$(bash bin/sdd-validate.sh "$TMP_SPECS" 2>&1 || true)
if grep -qF 'orphan invariant: INV-001' <<< "$out"; then
  pass "orphan INV-001 reported"
else
  fail "orphan INV-001 not reported"
fi
rm -rf "$TMP_SPECS"; CLEANUP=""

# ─────────────────────────────────────────────────────────────
section "Version handshake mismatch"
TMP_SPECS=$(mktemp -d); track "$TMP_SPECS"
cp -R "$FIXTURE"/. "$TMP_SPECS/"
sed 's/constitution: 1.0.0/constitution: 9.9.9/' "$TMP_SPECS/domain.md" > "$TMP_SPECS/domain.md.new"
mv "$TMP_SPECS/domain.md.new" "$TMP_SPECS/domain.md"
ec=$(run_exit bash bin/sdd-validate.sh "$TMP_SPECS")
assert_exit "version mismatch → exit 1" 1 "$ec"
rm -rf "$TMP_SPECS"; CLEANUP=""

# ─────────────────────────────────────────────────────────────
section "SDD_MEMORY env var"
ec=$(SDD_MEMORY=/tmp/sdd-nonexistent-memory-dir run_exit bash bin/sdd-validate.sh "$FIXTURE")
assert_exit "SDD_MEMORY=nonexistent → exit 0 (silently skips)" 0 "$ec"
ec=$(SDD_MEMORY=memory run_exit bash bin/sdd-validate.sh "$FIXTURE")
assert_exit "SDD_MEMORY=memory → exit 0 (same as default)" 0 "$ec"

# ─────────────────────────────────────────────────────────────
section "L0 comments on handbook and command files"
handbook_files=(
  README.md CLAUDE.md glossary.md
  01-hierarchy/L0-constitution.md
  01-hierarchy/L1-domain-model.md
  01-hierarchy/L2-bdd-scenarios.md
  02-gherkin-md.md
  03-context-injection.md
  04-golden-rules.md
  05-automation.md
  06-patterns.md
  memory/patterns.md
)
for f in "${handbook_files[@]}"; do
  if [[ -f "$f" ]] && head -1 "$f" | grep -q '^<!-- L0:'; then
    pass "L0 comment: $f"
  else
    fail "missing L0 comment: $f"
  fi
done

for f in commands/*.md; do
  if head -1 "$f" | grep -q '^<!-- L0:'; then
    pass "L0 comment: $f"
  else
    fail "missing L0 comment: $f"
  fi
done

# ─────────────────────────────────────────────────────────────
section "Plugin manifest"
if [[ -f .claude-plugin/plugin.json ]]; then
  pass "plugin.json exists"
  if command -v python3 >/dev/null 2>&1; then
    python3 -c "import json,sys; json.load(open('.claude-plugin/plugin.json'))" 2>/dev/null \
      && pass "plugin.json is valid JSON" \
      || fail "plugin.json is invalid JSON"
  fi
else
  fail "plugin.json missing"
fi
if [[ -f .claude-plugin/marketplace.json ]]; then
  pass "marketplace.json exists"
  if command -v python3 >/dev/null 2>&1; then
    python3 -c "import json,sys; json.load(open('.claude-plugin/marketplace.json'))" 2>/dev/null \
      && pass "marketplace.json is valid JSON" \
      || fail "marketplace.json is invalid JSON"
  fi
else
  fail "marketplace.json missing"
fi

# ─────────────────────────────────────────────────────────────
section "Wrapper dispatch"
assert_exit "sdd help → exit 0"            0 "$(run_exit bash bin/sdd help)"
assert_exit "sdd validate → exit 0"        0 "$(run_exit bash bin/sdd validate "$FIXTURE")"
assert_exit "sdd test (self) syntax check" 0 "$(bash -n bin/sdd-test.sh && echo 0 || echo 1)"
assert_exit "sdd nonexistent-cmd → exit 2" 2 "$(run_exit bash bin/sdd nonexistent-cmd)"

# ─────────────────────────────────────────────────────────────
printf '\n'
if [[ $FAIL -eq 0 ]]; then
  printf '%sall tests passed%s: %d pass, %d fail\n' "$GREEN" "$RESET" "$PASS" "$FAIL"
  exit 0
else
  printf '%stests failed%s: %d pass, %d fail\n' "$RED" "$RESET" "$PASS" "$FAIL"
  exit 1
fi

#!/usr/bin/env bash
# sdd-install-hooks — install a git pre-commit hook that runs sdd validate
# Usage: bash bin/sdd-install-hooks.sh    (or: sdd install-hooks)
set -eu

if ! command -v git >/dev/null 2>&1; then
  echo "fatal: git not found on PATH" >&2
  exit 2
fi

HOOK_DIR="$(git rev-parse --git-path hooks 2>/dev/null || true)"
if [[ -z "$HOOK_DIR" ]]; then
  echo "fatal: not inside a git repo" >&2
  exit 2
fi

mkdir -p "$HOOK_DIR"
HOOK="$HOOK_DIR/pre-commit"

if [[ -f "$HOOK" ]]; then
  echo "existing hook found: $HOOK"
  printf 'overwrite? [y/N] '
  read -r ans
  case "$ans" in
    y|Y|yes|YES) ;;
    *) echo "aborted"; exit 0 ;;
  esac
fi

cat > "$HOOK" <<'HOOK_EOF'
#!/usr/bin/env bash
# Installed by sdd install-hooks (SDD plugin)
# Runs SDD validation against specs/ before allowing a commit.
# Bypass with: git commit --no-verify
set -eu

SPECS="${SDD_SPECS:-specs}"
[[ -d "$SPECS" ]] || exit 0  # no specs dir → nothing to check

if command -v sdd >/dev/null 2>&1; then
  if ! sdd validate "$SPECS"; then
    echo
    echo "SDD validation failed. Fix errors or commit with --no-verify."
    exit 1
  fi
elif [[ -x bin/sdd-validate.sh ]]; then
  if ! bash bin/sdd-validate.sh "$SPECS"; then
    echo
    echo "SDD validation failed. Fix errors or commit with --no-verify."
    exit 1
  fi
else
  echo "fatal: sdd not found in PATH and bin/sdd-validate.sh missing" >&2
  echo "SDD pre-commit hook cannot run. Install the plugin or commit with --no-verify." >&2
  exit 1
fi
HOOK_EOF

chmod +x "$HOOK"
echo "installed: $HOOK"
echo "validates: \$SDD_SPECS (default: specs)"
echo "bypass with: git commit --no-verify"

#!/bin/bash
# clasp-deploy-tracker.sh - Track GAS file edit -> push -> deploy state
# PostToolUse hook for Claude Code
#
# State transitions:
#   GAS file edit   -> needs-push
#   clasp push      -> needs-deploy (shows push reminder)
#   clasp deploy -i -> clear (done)
#
# State file: $CLAUDE_PROJECT_DIR/.clasp-deploy-state
#
# Args: $1 = tool name (Edit, Write, Bash)

TOOL_NAME="${1:-Bash}"
STATE_FILE="${CLAUDE_PROJECT_DIR:-.}/.clasp-deploy-state"
INPUT=$(cat)

# --- Extract field from JSON ---
extract_field() {
  local field="$1"
  local python_cmd=""
  if command -v python3 &>/dev/null; then python_cmd="python3";
  elif command -v python &>/dev/null; then python_cmd="python"; fi

  if [ -n "$python_cmd" ]; then
    echo "$INPUT" | $python_cmd -c "
import sys, json
try:
    data = json.load(sys.stdin)
    ti = data.get('tool_input', {})
    print(ti.get('$field', ''))
except:
    print('')
" 2>/dev/null || echo ""
  else
    echo "$INPUT" | sed -n "s/.*\"$field\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -1
  fi
}

# --- GAS source file detection ---
is_gas_file() {
  local path="$1"
  # GAS files: .ts, .js, .html (under src/), Code.gs etc
  if echo "$path" | grep -qiE '(src/.*\.(ts|js|html)|\.gs$|appsscript\.json)'; then
    return 0
  fi
  return 1
}

# --- Read state ---
read_state() {
  if [ -f "$STATE_FILE" ]; then
    cat "$STATE_FILE"
  else
    echo "clear"
  fi
}

# --- Write state ---
write_state() {
  echo "$1" > "$STATE_FILE"
}

# --- Clear state ---
clear_state() {
  rm -f "$STATE_FILE"
}

# ============================================================
# Edit / Write tool: detect GAS file edits
# ============================================================
if [ "$TOOL_NAME" = "Edit" ] || [ "$TOOL_NAME" = "Write" ]; then
  FILE_PATH=$(extract_field "file_path")
  if [ -n "$FILE_PATH" ] && is_gas_file "$FILE_PATH"; then
    CURRENT=$(read_state)
    if [ "$CURRENT" = "clear" ] || [ "$CURRENT" = "" ]; then
      write_state "needs-push"
      cat <<'EOF' >&2

GAS file change detected -> clasp push required
EOF
    fi
  fi
  exit 0
fi

# ============================================================
# Bash tool: detect clasp push / deploy
# ============================================================
if [ "$TOOL_NAME" = "Bash" ]; then
  COMMAND=$(extract_field "command")
  if [ -z "$COMMAND" ]; then
    exit 0
  fi

  # --- clasp deploy -i detected -> clear state (done) ---
  if echo "$COMMAND" | grep -qiE 'clasp\s+deploy\s+-i\s'; then
    clear_state
    cat <<'EOF' >&2

clasp deploy done -> reflected in production URL
EOF
    exit 0
  fi

  # --- clasp push detected -> transition to needs-deploy ---
  if echo "$COMMAND" | grep -qiE 'clasp\s+push'; then
    write_state "needs-deploy"
    cat <<'EOF' >&2

WARNING: clasp push done -> don't forget to deploy!

  push only updates @HEAD (dev version).
  To reflect in production URL:

    clasp deploy -i <deploymentID>

  Check deployment ID: clasp deployments
EOF
    exit 0
  fi
fi

exit 0

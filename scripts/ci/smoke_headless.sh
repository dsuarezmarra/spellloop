#!/usr/bin/env bash
# scripts/ci/smoke_headless.sh — Smoke test mínimo: verifica que los autoloads cargan
set -euo pipefail

if [[ -z "${GODOT_BIN:-}" ]]; then
  if command -v godot &>/dev/null; then
    GODOT_BIN="godot"
  else
    echo "❌ GODOT_BIN env var not set and 'godot' not in PATH."
    exit 2
  fi
fi

GUT_CMDLN="addons/gut/gut_cmdln.gd"

if [[ ! -f "$GUT_CMDLN" ]]; then
  echo "❌ GUT not found at $GUT_CMDLN"
  exit 3
fi

echo "💨 Running smoke tests (headless)..."

"$GODOT_BIN" --headless -s "res://$GUT_CMDLN" \
  -gtest=res://tests/test_smoke.gd \
  -gexit \
  -glog=2 \
  -gignore_pause

EXIT_CODE=$?
if [[ $EXIT_CODE -ne 0 ]]; then
  echo "❌ Smoke tests FAILED (exit code: $EXIT_CODE)"
  exit $EXIT_CODE
fi

echo "✅ Smoke tests PASSED"

#!/usr/bin/env bash
# scripts/ci/run_gut_headless.sh — Ejecuta todos los tests GUT en headless
set -euo pipefail

if [[ -z "${GODOT_BIN:-}" ]]; then
  # Intenta encontrar Godot en PATH
  if command -v godot &>/dev/null; then
    GODOT_BIN="godot"
  else
    echo "❌ GODOT_BIN env var not set and 'godot' not in PATH."
    echo "   Set GODOT_BIN=/path/to/godot or add godot to PATH."
    exit 2
  fi
fi

GUT_CMDLN="addons/gut/gut_cmdln.gd"

if [[ ! -f "$GUT_CMDLN" ]]; then
  echo "❌ GUT not found at $GUT_CMDLN"
  echo "   Run: git submodule update --init --recursive"
  exit 3
fi

echo "🧪 Running GUT tests (headless)..."
echo "   Godot: $GODOT_BIN"
echo "   Test dir: res://tests"

"$GODOT_BIN" --headless -s "res://$GUT_CMDLN" \
  -gdir=res://tests \
  -gexit \
  -glog=2 \
  -gignore_pause \
  -ginclude_subdirs \
  -gprefix=test_ \
  -gsuffix=.gd

EXIT_CODE=$?
if [[ $EXIT_CODE -ne 0 ]]; then
  echo "❌ GUT tests FAILED (exit code: $EXIT_CODE)"
  exit $EXIT_CODE
fi

echo "✅ GUT tests PASSED"

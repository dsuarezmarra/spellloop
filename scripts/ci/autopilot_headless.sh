#!/usr/bin/env bash
# scripts/ci/autopilot_headless.sh — Ejecuta el autopiloto de gameplay headless
# Simula partidas reales sin render, captura errores/crashes.
set -euo pipefail

if [[ -z "${GODOT_BIN:-}" ]]; then
  if command -v godot &>/dev/null; then
    GODOT_BIN="godot"
  else
    echo "❌ GODOT_BIN env var not set and 'godot' not in PATH."
    exit 2
  fi
fi

# Duración del autopiloto (segundos de wall-clock)
AUTOPILOT_TIMEOUT="${AUTOPILOT_TIMEOUT:-180}"  # 3 minutos por defecto
# Cuántos runs simular
AUTOPILOT_RUNS="${AUTOPILOT_RUNS:-2}"

echo "🤖 Running autopilot gameplay test (headless)..."
echo "   Godot: $GODOT_BIN"
echo "   Timeout: ${AUTOPILOT_TIMEOUT}s"
echo "   Runs: ${AUTOPILOT_RUNS}"

# Ejecutar la escena de autopiloto directamente
# El script AutopilotRunner.gd maneja todo: arrancar Game, simular input, monitorizar errores
timeout "$AUTOPILOT_TIMEOUT" "$GODOT_BIN" --headless \
  --main-pack "" \
  -s "res://tests/autopilot/AutopilotRunner.gd" \
  -- \
  --autopilot-runs="$AUTOPILOT_RUNS" \
  --autopilot-duration=120 \
  --autopilot-headless=true \
  2>&1 | tee autopilot_output.log

EXIT_CODE=${PIPESTATUS[0]}

# Analizar output para errores críticos
if grep -qi "AUTOPILOT_FAIL" autopilot_output.log 2>/dev/null; then
  echo "❌ Autopilot detected FAILURES — check autopilot_output.log"
  cat autopilot_output.log | grep -i "AUTOPILOT_FAIL\|ERROR\|CRASH\|bug_detected"
  exit 1
fi

if [[ $EXIT_CODE -eq 124 ]]; then
  echo "⚠️  Autopilot timed out after ${AUTOPILOT_TIMEOUT}s (may indicate hang/infinite loop)"
  exit 1
fi

if [[ $EXIT_CODE -ne 0 ]]; then
  echo "❌ Autopilot crashed (exit code: $EXIT_CODE)"
  exit $EXIT_CODE
fi

# Buscar el reporte generado
if grep -qi "AUTOPILOT_PASS" autopilot_output.log 2>/dev/null; then
  echo "✅ Autopilot PASSED — all runs completed without errors"
else
  echo "⚠️  Autopilot finished but no PASS/FAIL marker found — review output"
fi

rm -f autopilot_output.log

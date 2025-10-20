#!/bin/bash
# Script para ejecutar pruebas de movimiento
# Este script ejecuta Godot y captura los logs específicos de movimiento

echo "================================"
echo "🧪 TEST DE MOVIMIENTO SPELLLOOP"
echo "================================"
echo ""
echo "Iniciando Godot con proyecto..."
echo ""

cd "C:\git\spellloop\project"

# Ejecutar Godot en headless con timeout de 15 segundos
# Captura logs para buscar "move_world" o errores relacionados
timeout 15 &"C:\Users\Usuario\Downloads\Godot_v4.5.1-stable_win64.exe" --headless 2>&1 | tee test_output.log | grep -E "(move_world|Invalid call|ERROR:|WARN:|Nonexistent function|ChunksRoot|Chunks activos|Sistema de chunks)" 

echo ""
echo "================================"
echo "✅ TEST COMPLETADO"
echo "================================"

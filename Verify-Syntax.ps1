#!/usr/bin/env pwsh
<#
Verificador de sintaxis GDScript
Busca errores comunes en los archivos de sistema
#>

$errors = @()
$warnings = @()

function Check-File {
    param([string]$path, [string]$name)
    
    Write-Host "`n🔍 Verificando $name..." -ForegroundColor Cyan
    
    if (-not (Test-Path $path)) {
        $errors += "$name: ARCHIVO NO EXISTE"
        Write-Host "❌ Archivo no existe" -ForegroundColor Red
        return
    }
    
    $content = Get-Content $path -Raw
    
    # Verificación 1: Balanceo de llaves
    $open_braces = ($content | Select-String -Pattern '{' -AllMatches).Matches.Count
    $close_braces = ($content | Select-String -Pattern '}' -AllMatches).Matches.Count
    
    if ($open_braces -ne $close_braces) {
        $errors += "$name: Llaves desbalanceadas (abren: $open_braces, cierran: $close_braces)"
        Write-Host "❌ Llaves desbalanceadas" -ForegroundColor Red
    }
    
    # Verificación 2: Balanceo de paréntesis
    $open_parens = ($content | Select-String -Pattern '\(' -AllMatches).Matches.Count
    $close_parens = ($content | Select-String -Pattern '\)' -AllMatches).Matches.Count
    
    if ($open_parens -ne $close_parens) {
        $errors += "$name: Paréntesis desbalanceados (abren: $open_parens, cierran: $close_parens)"
        Write-Host "❌ Paréntesis desbalanceados" -ForegroundColor Red
    }
    
    # Verificación 3: Sintaxis de class_name
    if ($content -match 'class_name\s+(\w+)') {
        Write-Host "✅ class_name encontrado: $($matches[1])" -ForegroundColor Green
    }
    
    # Verificación 4: Funciones con await sin sintaxis correcta
    $problematic_awaits = $content | Select-String -Pattern 'await\s+[^(]' | Select-String -v 'get_tree()' -NotMatch
    if ($problematic_awaits) {
        Write-Host "⚠️ Posibles awaits problemáticos encontrados" -ForegroundColor Yellow
    }
    
    # Verificación 5: extends Node
    if ($content -match 'extends\s+(\w+)') {
        Write-Host "✅ extends encontrado: $($matches[1])" -ForegroundColor Green
    }
    
    Write-Host "✅ Verificación completada" -ForegroundColor Green
}

# Archivos a verificar
$files = @(
    @{ path = "c:\Users\dsuarez1\git\spellloop\project\scripts\core\InfiniteWorldManager.gd"; name = "InfiniteWorldManager.gd" },
    @{ path = "c:\Users\dsuarez1\git\spellloop\project\scripts\core\BiomeGenerator.gd"; name = "BiomeGenerator.gd" },
    @{ path = "c:\Users\dsuarez1\git\spellloop\project\scripts\core\ChunkCacheManager.gd"; name = "ChunkCacheManager.gd" },
    @{ path = "c:\Users\dsuarez1\git\spellloop\project\scripts\core\ItemManager.gd"; name = "ItemManager.gd" }
)

Write-Host "="*60
Write-Host "🔍 VERIFICADOR DE SINTAXIS GDSCRIPT"
Write-Host "="*60

foreach ($file in $files) {
    Check-File $file.path $file.name
}

Write-Host "`n" + "="*60
Write-Host "📊 RESUMEN"
Write-Host "="*60

if ($errors.Count -eq 0) {
    Write-Host "✅ SIN ERRORES DETECTADOS" -ForegroundColor Green
} else {
    Write-Host "❌ ERRORES ENCONTRADOS:" -ForegroundColor Red
    foreach ($error in $errors) {
        Write-Host "  - $error" -ForegroundColor Red
    }
}

Write-Host "`n✅ Verificación completada"

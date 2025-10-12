# Validador de Proyecto Spellloop en PowerShell
Write-Host "🔍 VALIDANDO PROYECTO SPELLLOOP" -ForegroundColor Green
Write-Host "=" * 40
Write-Host ""

$projectPath = Get-Location
$errors = @()
$warnings = @()
$validatedFiles = @()

# Función para validar archivos
function Test-FileExists {
    param([string]$Path, [string]$Description)
    
    if (Test-Path $Path) {
        Write-Host "  ✅ $Description" -ForegroundColor Green
        $global:validatedFiles += $Path
        return $true
    } else {
        Write-Host "  ❌ $Description - No encontrado" -ForegroundColor Red
        $global:errors += "$Description - No encontrado: $Path"
        return $false
    }
}

# Validar project.godot
Write-Host "🔧 VALIDANDO ARCHIVO PROYECTO" -ForegroundColor Cyan
Write-Host "-" * 30

if (Test-Path "project.godot") {
    Write-Host "  ✅ project.godot encontrado" -ForegroundColor Green
    
    $projectContent = Get-Content "project.godot" -Raw
    
    # Verificar autoloads
    $autoloads = @(
        "GameManager", "SaveManager", "AudioManager", 
        "InputManager", "UIManager", "Localization", "DungeonSystem"
    )
    
    foreach ($autoload in $autoloads) {
        if ($projectContent -like "*$autoload*") {
            Write-Host "    ✅ Autoload $autoload configurado" -ForegroundColor Green
        } else {
            Write-Host "    ❌ Autoload $autoload faltante" -ForegroundColor Red
            $errors += "Autoload $autoload faltante"
        }
    }
} else {
    Write-Host "  ❌ project.godot no encontrado" -ForegroundColor Red
    $errors += "project.godot no encontrado"
}

Write-Host ""

# Validar autoloads
Write-Host "📜 VALIDANDO ARCHIVOS AUTOLOAD" -ForegroundColor Cyan
Write-Host "-" * 35

$autoloadFiles = @{
    "GameManager" = "scripts\core\GameManager.gd"
    "SaveManager" = "scripts\core\SaveManager.gd"
    "AudioManager" = "scripts\core\AudioManagerSimple.gd"
    "InputManager" = "scripts\core\InputManager.gd"
    "UIManager" = "scripts\core\UIManager.gd"
    "Localization" = "scripts\core\Localization.gd"
    "DungeonSystem" = "scripts\dungeon\DungeonSystem.gd"
}

foreach ($autoload in $autoloadFiles.GetEnumerator()) {
    Test-FileExists $autoload.Value $autoload.Key | Out-Null
}

Write-Host ""

# Validar sistema de dungeons
Write-Host "🏰 VALIDANDO SISTEMA DUNGEONS" -ForegroundColor Cyan
Write-Host "-" * 35

$dungeonFiles = @{
    "DungeonGenerator" = "scripts\dungeon\DungeonGenerator.gd"
    "RoomManager" = "scripts\dungeon\RoomManager.gd"
    "RewardSystem" = "scripts\dungeon\RewardSystem.gd"
    "RoomData" = "scripts\dungeon\RoomData.gd"
}

foreach ($file in $dungeonFiles.GetEnumerator()) {
    Test-FileExists $file.Value $file.Key | Out-Null
}

Write-Host ""

# Validar UI
Write-Host "🖥️ VALIDANDO INTERFAZ" -ForegroundColor Cyan
Write-Host "-" * 25

$uiFiles = @{
    "MinimapUI" = "scripts\ui\MinimapUI.gd"
}

foreach ($file in $uiFiles.GetEnumerator()) {
    Test-FileExists $file.Value $file.Key | Out-Null
}

Write-Host ""

# Validar tests
Write-Host "🧪 VALIDANDO TESTS" -ForegroundColor Cyan
Write-Host "-" * 20

$testFiles = @{
    "TestDungeonScene" = "scripts\test\TestDungeonScene.gd"
    "TestScript" = "scripts\test\TestScript.gd"
    "TestDungeonScene.tscn" = "scenes\test\TestDungeonScene.tscn"
}

foreach ($file in $testFiles.GetEnumerator()) {
    Test-FileExists $file.Value $file.Key | Out-Null
}

Write-Host ""

# Validar que no existan referencias obsoletas
Write-Host "🔍 VERIFICANDO REFERENCIAS OBSOLETAS" -ForegroundColor Cyan
Write-Host "-" * 40

$obsoleteRefs = @("scripts/systems/", "WizardSpriteLoader", "FunkoPopEnemy")
$gdFiles = Get-ChildItem -Path "scripts" -Recurse -Filter "*.gd"

foreach ($gdFile in $gdFiles) {
    $content = Get-Content $gdFile.FullName -Raw -ErrorAction SilentlyContinue
    
    if ($content) {
        $hasObsolete = $false
        foreach ($ref in $obsoleteRefs) {
            if ($content -like "*$ref*") {
                Write-Host "  ⚠️ $($gdFile.Name): Referencia obsoleta '$ref'" -ForegroundColor Yellow
                $warnings += "$($gdFile.Name): Referencia obsoleta '$ref'"
                $hasObsolete = $true
            }
        }
        
        if (-not $hasObsolete) {
            Write-Host "  ✅ $($gdFile.Name): Sin referencias obsoletas" -ForegroundColor Green
        }
    }
}

Write-Host ""

# Mostrar resultados
Write-Host "=" * 50
Write-Host "📊 RESULTADOS DE VALIDACIÓN" -ForegroundColor Magenta
Write-Host "=" * 50

Write-Host "✅ Archivos validados: $($validatedFiles.Count)" -ForegroundColor Green
Write-Host "⚠️ Advertencias: $($warnings.Count)" -ForegroundColor Yellow
Write-Host "❌ Errores: $($errors.Count)" -ForegroundColor Red

if ($warnings.Count -gt 0) {
    Write-Host ""
    Write-Host "⚠️ ADVERTENCIAS:" -ForegroundColor Yellow
    foreach ($warning in $warnings) {
        Write-Host "  $warning" -ForegroundColor Yellow
    }
}

if ($errors.Count -gt 0) {
    Write-Host ""
    Write-Host "❌ ERRORES:" -ForegroundColor Red
    foreach ($error in $errors) {
        Write-Host "  $error" -ForegroundColor Red
    }
} else {
    Write-Host ""
    Write-Host "🎉 ¡PROYECTO VALIDADO SIN ERRORES!" -ForegroundColor Green
    Write-Host "El proyecto está listo para ejecutar en Godot 4.5" -ForegroundColor Green
}

Write-Host ""
Write-Host "📋 SIGUIENTES PASOS:" -ForegroundColor Cyan
Write-Host "1. Abrir Godot 4.5" -ForegroundColor White
Write-Host "2. Importar project.godot" -ForegroundColor White
Write-Host "3. Presionar F5 para ejecutar" -ForegroundColor White
Write-Host "4. Revisar consola para tests automáticos" -ForegroundColor White
Write-Host ""

Read-Host -Prompt "Presiona Enter para continuar"
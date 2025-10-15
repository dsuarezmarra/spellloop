# Script para convertir export() a @export en archivos .gd para Godot 4

$projectPath = "c:\Users\dsuarez1\git\spellloop\project"

# Buscar todos los archivos .gd en scripts/
$gdFiles = Get-ChildItem -Path "$projectPath\scripts" -Filter "*.gd" -Recurse

foreach ($file in $gdFiles) {
    Write-Host "Procesando: $($file.FullName)"
    
    # Leer contenido del archivo
    $content = Get-Content $file.FullName -Raw
    
    # Aplicar reemplazos para Godot 4
    $content = $content -replace 'export\(([^)]+)\)\s+var\s+([^=]+)(\s*=.*)?', '@export var $2$3'
    $content = $content -replace '^export\s+var\s+', '@export var '
    
    # Escribir el archivo modificado
    Set-Content $file.FullName -Value $content -NoNewline
}

Write-Host "Conversión completada para todos los archivos .gd"
# Script para capturar logs de Godot a archivo
$godot_path = "godot"  # Asume que Godot está en PATH
$project_path = "c:\Users\dsuarez1\git\spellloop\project"
$output_file = "c:\Users\dsuarez1\git\spellloop\godot_debug_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

Write-Host "Iniciando Godot y capturando logs en: $output_file"
Write-Host "Espera a que se abra la escena y luego cierra Godot..."
Write-Host ""

# Ejecutar Godot y redirigir TODO el output (stdout y stderr)
& $godot_path --path $project_path 2>&1 | Tee-Object -FilePath $output_file

Write-Host ""
Write-Host "Logs guardados en: $output_file"
Write-Host "Abriendo archivo..."

# Abrir el archivo en el editor predeterminado
Invoke-Item $output_file

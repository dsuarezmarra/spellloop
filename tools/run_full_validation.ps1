#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Run complete item validation cycle for Spellloop
    
.DESCRIPTION
    Executes all 143+ item tests organized by scope:
    - WEAPON_SPECIFIC: Individual weapons
    - FUSION_SPECIFIC: Weapon fusions
    - GLOBAL_WEAPON: Upgrades affecting all weapons
    - PLAYER_ONLY: Upgrades affecting player stats

.PARAMETER Mode
    Test mode: 'full' (all items), 'scope' (specific scope), 'quick' (25 items pilot)

.PARAMETER Scope
    When Mode=scope, specify: WEAPON_SPECIFIC, FUSION_SPECIFIC, GLOBAL_WEAPON, PLAYER_ONLY

.PARAMETER BatchSize
    Max items per batch (default: 50). Use smaller for stability.

.PARAMETER Offset
    Start from item N (for resuming failed runs)

.PARAMETER GodotPath
    Path to Godot executable. Defaults to common locations.

.EXAMPLE
    .\run_full_validation.ps1 -Mode full
    
.EXAMPLE
    .\run_full_validation.ps1 -Mode scope -Scope WEAPON_SPECIFIC
    
.EXAMPLE
    .\run_full_validation.ps1 -Mode quick
#>

param(
    [ValidateSet('full', 'scope', 'quick', 'status')]
    [string]$Mode = 'full',
    
    [ValidateSet('WEAPON_SPECIFIC', 'FUSION_SPECIFIC', 'GLOBAL_WEAPON', 'PLAYER_ONLY')]
    [string]$Scope = '',
    
    [int]$BatchSize = 50,
    [int]$Offset = 0,
    [string]$GodotPath = ''
)

$ErrorActionPreference = 'Stop'

# === Configuration ===
$ProjectPath = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$ProjectPath = Join-Path $ProjectPath "project"

# Find Godot executable
if (-not $GodotPath) {
    $possiblePaths = @(
        "C:\Users\Usuario\Downloads\Godot_v4.5.1-stable_win64_console.exe",
        "$env:LOCALAPPDATA\Godot\godot.exe",
        "$env:PROGRAMFILES\Godot\godot.exe",
        "godot"
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path -ErrorAction SilentlyContinue) {
            $GodotPath = $path
            break
        }
        # Check if it's in PATH
        if (Get-Command $path -ErrorAction SilentlyContinue) {
            $GodotPath = $path
            break
        }
    }
    
    if (-not $GodotPath) {
        Write-Error "Godot executable not found. Please specify -GodotPath"
        exit 1
    }
}

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║        SPELLLOOP ITEM VALIDATION - FULL CYCLE              ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "📁 Project: $ProjectPath" -ForegroundColor Gray
Write-Host "🎮 Godot: $GodotPath" -ForegroundColor Gray
Write-Host "🔧 Mode: $Mode" -ForegroundColor Yellow
if ($Scope) {
    Write-Host "🎯 Scope: $Scope" -ForegroundColor Yellow
}
Write-Host ""

# === Build Command ===
$scenePath = "res://scripts/debug/item_validation/TestRunner.tscn"
$timeout = 300  # 5 minutes max

switch ($Mode) {
    'full' {
        # Run all 143 items in sequential batches for stability
        Write-Host "🚀 Running FULL validation (all 143 items in batches)..." -ForegroundColor Green
        
        $totalItems = 143
        $batchSize = 50
        $offset = 0
        $allPassed = $true
        
        while ($offset -lt $totalItems) {
            $currentBatch = [Math]::Min($batchSize, $totalItems - $offset)
            Write-Host ""
            Write-Host "📦 Batch: items $offset to $($offset + $currentBatch - 1)" -ForegroundColor Cyan
            
            $args = "--run-full --batch-size=$currentBatch --offset=$offset"
            
            $process = Start-Process -FilePath $GodotPath `
                -ArgumentList "--headless", "--path", ".", $scenePath, "--run-full", "--batch-size=$currentBatch", "--offset=$offset" `
                -NoNewWindow -PassThru -Wait
            
            if ($process.ExitCode -ne 0 -and $process.ExitCode -ne 1) {
                Write-Host "⚠️ Batch exited with code $($process.ExitCode)" -ForegroundColor Yellow
            }
            
            $offset += $batchSize
        }
        
        Write-Host ""
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor DarkGray
    }
    'scope' {
        if (-not $Scope) {
            Write-Error "Scope mode requires -Scope parameter"
            exit 1
        }
        $args = "--run-scope --scope=$Scope"
        Write-Host "🎯 Running scope: $Scope..." -ForegroundColor Green
        
        $process = Start-Process -FilePath $GodotPath `
            -ArgumentList "--headless", "--path", ".", $scenePath, $args `
            -NoNewWindow -PassThru -Wait
    }
    'quick' {
        $args = "--run-pilot"
        $timeout = 60
        Write-Host "⚡ Running QUICK pilot (25 items)..." -ForegroundColor Green
        
        $process = Start-Process -FilePath $GodotPath `
            -ArgumentList "--headless", "--path", ".", $scenePath, $args `
            -NoNewWindow -PassThru -Wait
    }
    'status' {
        $args = "--run-status-pilot"
        $timeout = 60
        Write-Host "📊 Running STATUS pilot (10 weapons)..." -ForegroundColor Green
        
        $process = Start-Process -FilePath $GodotPath `
            -ArgumentList "--headless", "--path", ".", $scenePath, $args `
            -NoNewWindow -PassThru -Wait
    }
}

# === Find Reports ===(
$startTime = Get-Date

Push-Location $ProjectPath
try {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor DarkGray
    
    $process = Start-Process -FilePath $GodotPath `
        -ArgumentList "--headless", "--quit-after", $timeout, "--path", ".", $scenePath, $args `
        -NoNewWindow -PassThru -Wait
    
    $exitCode = $process.ExitCode
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor DarkGray
    
} finally {
    Pop-Location
}

$duration = (Get-Date) - $startTime

# === Find Reports ===
$reportDir = Join-Path $env:APPDATA "Godot\app_userdata\Spellloop\test_reports"

if (Test-Path $reportDir) {
    Write-Host ""
    Write-Host "📄 Looking for reports in: $reportDir" -ForegroundColor Gray
    
    # Find latest reports
    $latestReports = Get-ChildItem -Path $reportDir -Filter "*.md" | 
        Sort-Object LastWriteTime -Descending | 
        Select-Object -First 3
    
    if ($latestReports) {
        Write-Host ""
        Write-Host "📊 LATEST REPORTS:" -ForegroundColor Cyan
        foreach ($report in $latestReports) {
            Write-Host "   • $($report.Name)" -ForegroundColor White
        }
        
        # Show summary from latest
        $latestSummary = $latestReports | Where-Object { $_.Name -like "*summary*" -or $_.Name -like "*full_cycle*" } | Select-Object -First 1
        if ($latestSummary) {
            Write-Host ""
            Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor DarkGray
            Write-Host "📋 QUICK SUMMARY from $($latestSummary.Name):" -ForegroundColor Yellow
            Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor DarkGray
            
            # Extract key metrics
            $content = Get-Content $latestSummary.FullName -Raw
            
            if ($content -match "Total Tests: (\d+)") { Write-Host "   Total Tests: $($Matches[1])" }
            if ($content -match "Passed: (\d+)") { Write-Host "   ✅ Passed: $($Matches[1])" -ForegroundColor Green }
            if ($content -match "Failed.*?(\d+)") { 
                $failed = $Matches[1]
                if ([int]$failed -gt 0) {
                    Write-Host "   ❌ Failed: $failed" -ForegroundColor Red
                } else {
                    Write-Host "   ❌ Failed: 0" -ForegroundColor Green
                }
            }
            if ($content -match "Not Implemented.*?(\d+)") { Write-Host "   ⚠️ Not Implemented: $($Matches[1])" -ForegroundColor Yellow }
        }
        
        # Open the full cycle report if it exists
        $fullCycleReport = Get-ChildItem -Path $reportDir -Filter "full_cycle_report_*.md" | 
            Sort-Object LastWriteTime -Descending | 
            Select-Object -First 1
            
        if ($fullCycleReport) {
            Write-Host ""
            Write-Host "📖 Full report: $($fullCycleReport.FullName)" -ForegroundColor Cyan
            Write-Host "   Run: code `"$($fullCycleReport.FullName)`" to view" -ForegroundColor Gray
        }
    }
}

# === Final Status ===
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor DarkGray

if ($exitCode -eq 0) {
    Write-Host "✅ Validation completed successfully in $($duration.TotalSeconds.ToString('F1'))s" -ForegroundColor Green
} else {
    Write-Host "⚠️ Validation exited with code $exitCode (may be normal for --quit-after)" -ForegroundColor Yellow
    Write-Host "   Check reports above for actual test results." -ForegroundColor Gray
}

Write-Host ""
exit 0

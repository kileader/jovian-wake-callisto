[CmdletBinding()]
param(
    [ValidateSet('play', 'check', 'test', 'windows', 'web', 'capture')]
    [string]$Action = 'play',
    [string]$GodotPath = $env:CALLISTO_GODOT
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not $GodotPath) {
    $installed = Get-Command godot, godot4 -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($installed) { $GodotPath = $installed.Source }
}
if (-not $GodotPath) {
    foreach ($relative in @('.tools\godot\Godot_v4.7.2-stable_win64_console.exe', '..\spiritbound\.tools\godot\Godot_v4.7.2-stable_win64_console.exe', '..\range-club\.tools\godot\Godot_v4.7.2-stable_win64_console.exe')) {
        $candidate = Join-Path $projectRoot $relative
        if (Test-Path -LiteralPath $candidate) { $GodotPath = (Resolve-Path -LiteralPath $candidate).Path; break }
    }
}
if (-not $GodotPath -or -not (Test-Path -LiteralPath $GodotPath)) {
    throw 'Godot 4 was not found. Set CALLISTO_GODOT or pass -GodotPath with your Godot executable path.'
}

switch ($Action) {
    'play' { & $GodotPath --path $projectRoot }
    'check' { & $GodotPath --headless --path $projectRoot --editor --import --quit }
    'test' { & $GodotPath --headless --path $projectRoot --script res://tests/run_playground.gd }
    'windows' {
        New-Item -ItemType Directory -Path (Join-Path $projectRoot 'builds\windows') -Force | Out-Null
        & $GodotPath --headless --path $projectRoot --export-release 'Windows Desktop'
    }
    'web' {
        New-Item -ItemType Directory -Path (Join-Path $projectRoot 'builds\web') -Force | Out-Null
        & $GodotPath --headless --path $projectRoot --export-release 'Web'
    }
    'capture' {
        New-Item -ItemType Directory -Path (Join-Path $projectRoot 'artifacts') -Force | Out-Null
        & $GodotPath --path $projectRoot --script res://tests/capture_views.gd
    }
}
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

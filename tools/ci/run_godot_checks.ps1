param(
    [string]$GodotExe = "c:\School\Aminomon\tools\godot\Godot_v4.5.1-stable_win64.exe",
    [switch]$RunExport,
    [string]$UserDataDir = "c:\School\Aminomon\Aminomon\.godot_ci_userdata"
)

$ErrorActionPreference = "Stop"
$projectPath = "c:\School\Aminomon\Aminomon"

if (!(Test-Path $GodotExe)) {
    throw "Godot executable not found at: $GodotExe"
}

New-Item -Path $UserDataDir -ItemType Directory -Force | Out-Null
$candidateLogDirs = @(
    (Join-Path $UserDataDir "logs"),
    (Join-Path $UserDataDir "Aminomon\logs"),
    (Join-Path $UserDataDir "app_userdata\Aminomon\logs")
)
foreach ($logDir in $candidateLogDirs) {
    New-Item -Path $logDir -ItemType Directory -Force | Out-Null
}
$logFile = Join-Path $UserDataDir "godot_ci.log"

$commonArgs = @(
    "--headless",
    "--path", $projectPath,
    "--user-data-dir", $UserDataDir,
    "--log-file", $logFile
)

Write-Host "Running smoke tests..."
& $GodotExe @commonArgs -s res://scripts/SmokeTest.gd
if ($null -eq $LASTEXITCODE) {
    $LASTEXITCODE = 0
}
if ([int]$LASTEXITCODE -ne 0) {
    throw "Smoke tests failed with exit code $LASTEXITCODE."
}

if ($RunExport) {
    Write-Host "Running Windows export sanity check..."
    $templateRoot = Join-Path $env:APPDATA "Godot\export_templates\4.5.1.stable"
    $debugTemplate = Join-Path $templateRoot "windows_debug_x86_64.exe"
    $releaseTemplate = Join-Path $templateRoot "windows_release_x86_64.exe"
    if (!(Test-Path $debugTemplate) -or !(Test-Path $releaseTemplate)) {
        throw "Missing Godot export templates for 4.5.1.stable. Expected files:`n$debugTemplate`n$releaseTemplate"
    }
    New-Item -Path "$projectPath\build" -ItemType Directory -Force | Out-Null
    & $GodotExe @commonArgs --export-release "Windows Desktop" "build/Aminomon.exe"
    if ($null -eq $LASTEXITCODE) {
        $LASTEXITCODE = 0
    }
    if ([int]$LASTEXITCODE -ne 0) {
        throw "Godot export failed with exit code $LASTEXITCODE."
    }
    if (!(Test-Path "$projectPath\build\Aminomon.exe")) {
        throw "Export failed: Aminomon/build/Aminomon.exe was not created."
    }
}

Write-Host "Godot checks completed."

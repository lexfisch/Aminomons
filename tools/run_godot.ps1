param(
    [string]$GodotExe = "c:\School\Aminomon\tools\godot\Godot_v4.5.1-stable_win64.exe",
    [string]$ProjectPath = "c:\School\Aminomon\Aminomon",
    [string]$UserDataDir = "c:\School\Aminomon\Aminomon\.godot_userdata_local",
    [switch]$Headless,
    [switch]$Editor,
    [string]$Script = "",
    [int]$QuitAfter = 0
)

$ErrorActionPreference = "Stop"

if (!(Test-Path $GodotExe)) {
    throw "Godot executable not found at: $GodotExe"
}

if (!(Test-Path $ProjectPath)) {
    throw "Godot project path not found at: $ProjectPath"
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
$logFile = Join-Path $UserDataDir "godot_runtime.log"

$args = @(
    "--path", $ProjectPath,
    "--user-data-dir", $UserDataDir,
    "--log-file", $logFile
)

if ($Headless) {
    $args += "--headless"
}

if ($Editor) {
    $args += "--editor"
}

if ($QuitAfter -gt 0) {
    $args += @("--quit-after", "$QuitAfter")
}

if ($Script -ne "") {
    $args += @("-s", $Script)
}

Write-Host "Launching Godot with user-data-dir: $UserDataDir"
Write-Host "Runtime log file: $logFile"

& $GodotExe @args

$exitCode = 0
if ($null -ne $LASTEXITCODE) {
    $exitCode = [int]$LASTEXITCODE
}
if ($exitCode -ne 0) {
    throw "Godot exited with code $exitCode."
}

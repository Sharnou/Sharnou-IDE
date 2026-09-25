param(
    [string]$ProjectRoot = "",
    [ValidateSet("validate","compile","self-test","runtime-test","run")]
    [string]$Command = "validate",
    [int]$RuntimeTestSeconds = 300
)

$ErrorActionPreference = "Stop"
if ([string]::IsNullOrWhiteSpace($ProjectRoot)) { $ProjectRoot = (Get-Location).Path }
$ProjectRoot = [IO.Path]::GetFullPath($ProjectRoot)
$ideRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$compiler = Join-Path $ideRoot "Compile-Spp.ps1"
$manifest = Join-Path $ProjectRoot "Tools\SharnouIDE\honour-war.spp.json"
$source = Join-Path $ProjectRoot "Tools\SharnouIDE\project\main.spp"
$output = Join-Path $ProjectRoot "Build\Runtime\honour-war.sppc.json"

function Find-Engine([string]$root) {
    @(
        (Join-Path $root "Build\Runtime\SharnouEngine.exe"),
        (Join-Path $root "Tools\SharnouIDE\runtime\SharnouEngine.exe"),
        (Join-Path $root "Engine\SharnouEngine\bin\SharnouEngine.exe")
    ) | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
}

function Validate-Contract {
    if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) { throw "Sharnou Project Protocol manifest is missing." }
    $m = Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json
    if ($m.ide.id -ne "Sharnou-IDE") { throw "IDE identity mismatch." }
    if ($m.engine.id -ne "SharnouEngine") { throw "Engine identity mismatch." }
    if ($m.build_policy.network_downloads -ne $false) { throw "External downloads are forbidden." }
    if ($m.build_policy.external_tool_bootstrap -ne $false) { throw "External tool bootstrap is forbidden." }
    Write-Host "PASS: Sharnou IDE project contract."
}

function Compile-Project {
    if (-not (Test-Path -LiteralPath $compiler -PathType Leaf)) { throw "SPP compiler missing." }
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw "Honour War SPP source missing." }
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $compiler -Source $source -Output $output
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

Validate-Contract
if ($Command -eq "validate") { exit 0 }
Compile-Project
if ($Command -eq "compile") { exit 0 }

$engine = Find-Engine $ProjectRoot
if (-not $engine) { throw "SharnouEngine.exe is not present in configured runtime candidates." }
$env:SHARNOU_IDE_SESSION = "1"
Set-Location -LiteralPath $ProjectRoot

switch ($Command) {
    "self-test" { & $engine "--self-test"; exit $LASTEXITCODE }
    "runtime-test" { & $engine "--runtime-test=$RuntimeTestSeconds"; exit $LASTEXITCODE }
    "run" { & $engine; exit $LASTEXITCODE }
}
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
$bridge = Join-Path $ideRoot "EngineBridge.ps1"
$manifest = Join-Path $ProjectRoot "Tools\SharnouIDE\honour-war.spp.json"
$source = Join-Path $ProjectRoot "Tools\SharnouIDE\project\main.spp"
$output = Join-Path $ProjectRoot "Build\Runtime\honour-war.sppc.json"

function Validate-Contract {
    if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) { throw "Sharnou Project Protocol manifest is missing." }
    $m = Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json
    if ($m.project.id -ne "honour-war") { throw "Project identity mismatch." }
    if ($m.ide.id -ne "Sharnou-IDE") { throw "IDE identity mismatch." }
    if ($m.ide.repository -ne "https://github.com/Sharnou/Sharnou-IDE") { throw "Honour War is not bound to the canonical Sharnou IDE repository." }
    if ($m.engine.id -ne "SharnouEngine") { throw "Engine identity mismatch." }
    if ($m.build_policy.network_downloads -ne $false) { throw "External downloads are forbidden." }
    if ($m.build_policy.external_tool_bootstrap -ne $false) { throw "External tool bootstrap is forbidden." }
    $forbidden = @("Visual Studio","MSBuild","Windows SDK","CMake","vcpkg","Unity","Unreal Engine")
    foreach ($name in $forbidden) {
        if ($m.forbidden_project_dependencies -notcontains $name) { throw "Required forbidden dependency is missing from project policy: $name" }
    }
    Write-Host "PASS: Sharnou IDE -> Sharnou Engine project contract."
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

if (-not (Test-Path -LiteralPath $bridge -PathType Leaf)) { throw "Sharnou Engine bridge missing: $bridge" }
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $bridge -ProjectRoot $ProjectRoot -Command $Command -RuntimeTestSeconds $RuntimeTestSeconds
exit $LASTEXITCODE

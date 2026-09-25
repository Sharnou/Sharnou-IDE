param(
    [string]$ProjectRoot = "",
    [ValidateSet("validate","convert","compile","self-test","runtime-test","run")]
    [string]$Command = "validate",
    [int]$RuntimeTestSeconds = 300
)

$ErrorActionPreference = "Stop"
if ([string]::IsNullOrWhiteSpace($ProjectRoot)) { $ProjectRoot = (Get-Location).Path }
$ProjectRoot = [IO.Path]::GetFullPath($ProjectRoot)
$ideRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$compiler = Join-Path $ideRoot "Compile-Spp.ps1"
$converter = Join-Path $ideRoot "Convert-All-IDE-Projects.ps1"
$bridge = Join-Path $ideRoot "EngineBridge.ps1"
$manifest = Join-Path $ProjectRoot "Tools\SharnouIDE\honour-war.spp.json"
$integration = Join-Path $ProjectRoot "Tools\SharnouIDE\sharnou-ide-engine.integration.json"
$source = Join-Path $ProjectRoot "Tools\SharnouIDE\project\main.spp"
$output = Join-Path $ProjectRoot "Build\Runtime\honour-war.sppc.json"

function Validate-Contract {
    if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) { throw "Sharnou Project Protocol manifest is missing." }
    if (-not (Test-Path -LiteralPath $integration -PathType Leaf)) { throw "Sharnou IDE/Engine integration contract is missing." }
    $m = Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json
    $i = Get-Content -LiteralPath $integration -Raw | ConvertFrom-Json
    if ($m.project.id -ne "honour-war" -or $m.canonical_identity.project_id -ne "honour-war" -or $m.canonical_identity.canonical -ne $true) { throw "Canonical Honour War identity mismatch." }
    if ($m.ide.id -ne "Sharnou-IDE" -or $i.ide.id -ne "Sharnou-IDE") { throw "IDE identity mismatch." }
    if ($m.engine.id -ne "SharnouEngine" -or $i.engine.id -ne "SharnouEngine") { throw "Engine identity mismatch." }
    if ($m.ide.repository -ne "https://github.com/Sharnou/Sharnou-IDE") { throw "Honour War is not bound to the canonical Sharnou IDE repository." }
    if ($m.engine.repository -ne "https://github.com/Sharnou/Sharnou-Engine") { throw "Honour War is not bound to the canonical Sharnou Engine repository." }
    if ($m.visual_format_policy.accepted_texture_formats.Count -ne 1 -or $m.visual_format_policy.accepted_texture_formats[0] -ne ".avif") { throw "Honour War texture policy is not AVIF-only." }
    if ($i.asset_policy.accepted_generated_raster_formats.Count -ne 1 -or $i.asset_policy.accepted_generated_raster_formats[0] -ne ".AVIF") { throw "Integration visual policy is not AVIF-only." }
    if ($m.build_policy.network_downloads -ne $false -or $m.build_policy.external_tool_bootstrap -ne $false -or $m.build_policy.external_ide_authoring -ne $false) { throw "External downloads/bootstrap/IDE authoring are forbidden." }
    if ($i.external_tool_policy.downloads -ne $false -or $i.external_tool_policy.bootstrap -ne $false) { throw "External tool downloads/bootstrap are forbidden." }
    $forbidden = @("Visual Studio","MSBuild","Windows SDK","CMake","vcpkg","Unity","Unreal Engine")
    foreach ($name in $forbidden) {
        if ($m.forbidden_project_dependencies -notcontains $name) { throw "Required forbidden dependency is missing from project policy: $name" }
        if ($i.external_tool_policy.forbidden -notcontains $name) { throw "Required forbidden dependency is missing from integration policy: $name" }
    }
    Write-Host "PASS: canonical honour-war -> Sharnou-IDE -> SharnouEngine contract."
}

function Convert-LegacyIdeMetadata {
    if (-not (Test-Path -LiteralPath $converter -PathType Leaf)) { throw "IDE conversion controller missing." }
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $converter -ProjectRoot $ProjectRoot
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

function Compile-Project {
    if (-not (Test-Path -LiteralPath $compiler -PathType Leaf)) { throw "SPP compiler missing." }
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw "Honour War SPP source missing." }
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $compiler -Source $source -Output $output
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

Validate-Contract
# Automatic migration is always performed before authoring/runtime operations.
Convert-LegacyIdeMetadata
if ($Command -eq "convert" -or $Command -eq "validate") { exit 0 }
Compile-Project
if ($Command -eq "compile") { exit 0 }

if (-not (Test-Path -LiteralPath $bridge -PathType Leaf)) { throw "Sharnou Engine bridge missing: $bridge" }
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $bridge -ProjectRoot $ProjectRoot -Command $Command -RuntimeTestSeconds $RuntimeTestSeconds
exit $LASTEXITCODE

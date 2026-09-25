param(
    [Parameter(Mandatory=$true)][string]$ProjectRoot,
    [ValidateSet("self-test","runtime-test","run")][string]$Command = "self-test",
    [int]$RuntimeTestSeconds = 300
)
$ErrorActionPreference = "Stop"
$ProjectRoot = [IO.Path]::GetFullPath($ProjectRoot)
$contractPath = Join-Path $PSScriptRoot "..\engine\sharnou-engine.contract.json"
if (-not (Test-Path -LiteralPath $contractPath -PathType Leaf)) { throw "Sharnou Engine contract missing: $contractPath" }
$contract = Get-Content -LiteralPath $contractPath -Raw | ConvertFrom-Json
if ($contract.engine_id -ne "SharnouEngine") { throw "Engine contract identity mismatch." }
if ($contract.ide_id -ne "Sharnou-IDE") { throw "IDE contract identity mismatch." }
if ($contract.integration.project_id -ne "honour-war") { throw "Canonical project identity mismatch." }
if ($contract.asset_policy.texture_extensions_allowed.Count -ne 1 -or $contract.asset_policy.texture_extensions_allowed[0] -ne ".avif") { throw "Sharnou Engine texture policy is not AVIF-only." }

$manifestPath = Join-Path $ProjectRoot "Tools\SharnouIDE\honour-war.spp.json"
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) { throw "Honour War Sharnou Project Protocol manifest missing." }
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
if ($manifest.canonical_identity.project_id -ne "honour-war" -or $manifest.canonical_identity.canonical -ne $true) { throw "Honour War is not identified as the canonical Honour War project." }
if ($manifest.ide.repository -ne "https://github.com/Sharnou/Sharnou-IDE") { throw "Honour War is not bound to the canonical Sharnou IDE repository." }
if ($manifest.engine.id -ne "SharnouEngine") { throw "Honour War engine binding is not Sharnou Engine." }
if ($manifest.visual_format_policy.accepted_texture_formats.Count -ne 1 -or $manifest.visual_format_policy.accepted_texture_formats[0] -ne ".avif") { throw "Honour War texture policy is not AVIF-only." }
if ($manifest.build_policy.network_downloads -ne $false -or $manifest.build_policy.external_tool_bootstrap -ne $false -or $manifest.build_policy.external_ide_authoring -ne $false) { throw "External downloads/bootstrap/IDE authoring are forbidden." }

$engine = $null
foreach ($relative in $manifest.engine.runtime_candidates) {
    $candidate = Join-Path $ProjectRoot ($relative -replace '/', '\\')
    if (Test-Path -LiteralPath $candidate -PathType Leaf) { $engine = $candidate; break }
}
if (-not $engine) { throw "SharnouEngine.exe not found in an approved runtime location. Sharnou IDE will not install or download a compiler/toolchain." }

$env:SHARNOU_IDE_SESSION = "1"
$env:SHARNOU_IDE_REPOSITORY = "https://github.com/Sharnou/Sharnou-IDE"
$env:SHARNOU_ENGINE_ID = "SharnouEngine"
$env:SHARNOU_PROJECT_ID = "honour-war"
Set-Location -LiteralPath $ProjectRoot
switch ($Command) {
    "self-test" { & $engine "--self-test" }
    "runtime-test" { & $engine ("--runtime-test=" + [int]$RuntimeTestSeconds) }
    "run" { & $engine }
}
exit $LASTEXITCODE

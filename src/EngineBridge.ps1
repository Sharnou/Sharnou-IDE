param(
    [Parameter(Mandatory=$true)][string]$ProjectRoot,
    [ValidateSet("self-test","runtime-test","run")][string]$Command = "self-test",
    [int]$RuntimeTestSeconds = 300
)
$ErrorActionPreference = "Stop"
$ProjectRoot = [IO.Path]::GetFullPath($ProjectRoot)
$contractPath = Join-Path $PSScriptRoot "..enginesharnou-engine.contract.json"
if (-not (Test-Path -LiteralPath $contractPath -PathType Leaf)) { throw "Sharnou Engine contract missing: $contractPath" }
$contract = Get-Content -LiteralPath $contractPath -Raw | ConvertFrom-Json
if ($contract.engine_id -ne "SharnouEngine") { throw "Engine contract identity mismatch." }
if ($contract.ide_id -ne "Sharnou-IDE") { throw "IDE contract identity mismatch." }
if ($contract.integration.project_id -ne "honour-war") { throw "Canonical project identity mismatch." }
if ($contract.asset_policy.accepted_input_formats -ne "*") { throw "Engine asset intake is not format-neutral." }
if ($contract.asset_policy.automatic_conversion -ne $true) { throw "Engine automatic conversion is disabled." }
if (@($contract.asset_policy.runtime_3d_scene_formats) -notcontains ".gltf" -or @($contract.asset_policy.runtime_3d_scene_formats) -notcontains ".glb") { throw "glTF/GLB runtime contract is incomplete." }
if (@($contract.asset_policy.runtime_3d_texture_formats) -notcontains ".ktx2") { throw "KTX2 runtime texture contract is incomplete." }
if (@($contract.asset_policy.runtime_2d_formats) -notcontains ".avif") { throw "AVIF runtime visual contract is incomplete." }
if ($contract.asset_policy.glTF_texture_extension -ne "KHR_texture_basisu") { throw "KHR_texture_basisu contract is missing." }

$manifestPath = Join-Path $ProjectRoot "ToolsSharnouIDEhonour-war.spp.json"
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) { throw "Honour War Sharnou Project Protocol manifest missing." }
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
if ($manifest.canonical_identity.project_id -ne "honour-war" -or $manifest.canonical_identity.canonical -ne $true) { throw "Honour War is not identified as the canonical Honour War project." }
if ($manifest.ide.repository -ne "https://github.com/Sharnou/Sharnou-IDE") { throw "Honour War is not bound to the canonical Sharnou IDE repository." }
if ($manifest.engine.id -ne "SharnouEngine") { throw "Honour War engine binding is not Sharnou Engine." }
if ($manifest.asset_format_policy.accepted_input_formats -ne "*") { throw "Honour War asset intake is not format-neutral." }
if ($manifest.asset_format_policy.automatic_conversion -ne $true) { throw "Honour War automatic asset conversion is disabled." }
if (@($manifest.asset_format_policy.runtime_3d_scene_formats) -notcontains ".gltf" -or @($manifest.asset_format_policy.runtime_3d_scene_formats) -notcontains ".glb") { throw "Honour War glTF/GLB runtime contract is incomplete." }
if (@($manifest.asset_format_policy.runtime_3d_texture_formats) -notcontains ".ktx2") { throw "Honour War KTX2 runtime contract is incomplete." }
if (@($manifest.asset_format_policy.runtime_2d_formats) -notcontains ".avif") { throw "Honour War AVIF runtime contract is incomplete." }
if ($manifest.build_policy.network_downloads -ne $false -or $manifest.build_policy.external_tool_bootstrap -ne $false -or $manifest.build_policy.external_ide_authoring -ne $false) { throw "External downloads/bootstrap/IDE authoring are forbidden." }

$engine = $null
foreach ($relative in $manifest.engine.runtime_candidates) {
    $candidate = Join-Path $ProjectRoot ($relative -replace '/', '\')
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

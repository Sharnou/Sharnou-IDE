$ErrorActionPreference = "Stop"
$ideRoot = [IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) ".."))
$ideEntry = Join-Path $ideRoot "src\SharnouIDE.ps1"
$bridgeEntry = Join-Path $ideRoot "src\EngineBridge.ps1"
$contract = Join-Path $ideRoot "engine\sharnou-engine.contract.json"
foreach ($required in @($ideEntry, $bridgeEntry, $contract, (Join-Path $ideRoot "src\Compile-Spp.ps1"), (Join-Path $ideRoot "src\Convert-All-IDE-Projects.ps1"))) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "IDE integration test prerequisite missing: $required" }
}

$fixture = Join-Path ([IO.Path]::GetTempPath()) ("sharnou-ide-path-test-" + [Guid]::NewGuid().ToString("N"))
$toolsRoot = Join-Path $fixture "Tools\SharnouIDE"
$sourceRoot = Join-Path $toolsRoot "project"
$runtimeRoot = Join-Path $fixture "Build\Runtime"
New-Item -ItemType Directory -Force -Path $sourceRoot, $runtimeRoot | Out-Null

try {
    $forbidden = @(
        ("Visual" + " Studio"), ("MS" + "Build"), ("Windows " + "SDK"),
        ("C" + "Make"), ("v" + "cpkg"), ("Un" + "ity"), ("Unreal " + "Engine")
    )
    $manifest = [ordered]@{
        schema = "sharnou-project/2"
        canonical_identity = @{ project_id = "honour-war"; canonical = $true }
        project = @{ id = "honour-war"; name = "Honour War" }
        ide = @{ id = "Sharnou-IDE"; repository = "https://github.com/Sharnou/Sharnou-IDE" }
        engine = @{ id = "SharnouEngine"; repository = "https://github.com/Sharnou/Sharnou-Engine"; runtime_candidates = @("Build/Runtime/SharnouEngine.exe") }
        asset_format_policy = @{
            accepted_input_formats = "*"
            automatic_conversion = $true
            runtime_3d_scene_formats = @(".gltf", ".glb")
            runtime_3d_texture_formats = @(".ktx2")
            runtime_2d_formats = @(".avif")
        }
        build_policy = @{ network_downloads = $false; external_tool_bootstrap = $false; external_ide_authoring = $false }
        forbidden_project_dependencies = $forbidden
    }
    $integration = [ordered]@{
        ide = @{ id = "Sharnou-IDE" }
        engine = @{ id = "SharnouEngine" }
        asset_policy = @{ accepted_input_formats = "*"; conversion = "automatic" }
        formats = @{
            "3d_scene" = @(".gltf", ".glb")
            "3d_textures" = @(".ktx2")
            ui_2d = @(".avif")
        }
        external_tool_policy = @{ downloads = $false; bootstrap = $false; forbidden = $forbidden }
    }
    $encoding = [Text.UTF8Encoding]::new($false)
    [IO.File]::WriteAllText((Join-Path $toolsRoot "honour-war.spp.json"), ($manifest | ConvertTo-Json -Depth 12), $encoding)
    [IO.File]::WriteAllText((Join-Path $toolsRoot "sharnou-ide-engine.integration.json"), ($integration | ConvertTo-Json -Depth 12), $encoding)
    [IO.File]::WriteAllText((Join-Path $sourceRoot "main.spp"), ("project_bind honour-war" + [Environment]::NewLine), $encoding)

    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $ideEntry -ProjectRoot $fixture -Command validate
    if ($LASTEXITCODE -ne 0) { throw "SharnouIDE validate command failed: $LASTEXITCODE" }
    $bytecode = Join-Path $runtimeRoot "honour-war.sppc.json"
    if (-not (Test-Path -LiteralPath $bytecode -PathType Leaf)) { throw "SPP bytecode was not created at the canonical runtime path: $bytecode" }

    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $bridgeEntry -ProjectRoot $fixture -Command validate
    if ($LASTEXITCODE -ne 0) { throw "EngineBridge validate command failed: $LASTEXITCODE" }

    Write-Host "PASS: SharnouIDE project paths, SPP output path, EngineBridge contract path, and canonical manifest path."
}
finally {
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}

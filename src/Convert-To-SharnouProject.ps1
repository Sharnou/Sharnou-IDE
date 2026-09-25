param(
    [Parameter(Mandatory=$true)][string]$ProjectRoot,
    [string]$Output = ".sharnou/honour-war.migration.json"
)
$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath($ProjectRoot)
$outPath = [IO.Path]::GetFullPath((Join-Path $root $Output))
$legacyPatterns = @("*.sln","*.slnx","*.vcxproj","*.vcxproj.filters","*.code-workspace","*.project","*.cproject")
$found = New-Object System.Collections.Generic.List[string]
foreach($pattern in $legacyPatterns){
    Get-ChildItem -LiteralPath $root -Recurse -File -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like $pattern -and $_.FullName -notmatch "[\\/]\.git[\\/]" -and $_.FullName -notmatch "[\\/]\.sharnou[\\/]" } |
        ForEach-Object { $found.Add($_.FullName.Substring($root.Length).TrimStart('\','/')) }
}
$doc = [ordered]@{
    schema = "sharnou-migration/1"
    project_id = "honour-war"
    target_ide = "Sharnou-IDE"
    target_engine = "SharnouEngine"
    automatic_project_level_conversion = $true
    external_ide_execution = $false
    external_tool_download = $false
    legacy_project_metadata = @($found | Sort-Object -Unique)
    conversion = [ordered]@{
        source_metadata = "discovered project metadata"
        output = ".sharnou/honour-war.migration.json"
        runtime_authority = "SharnouEngine"
        authoring_authority = "Sharnou-IDE"
        texture_format = ".AVIF only"
    }
}
New-Item -ItemType Directory -Force -Path (Split-Path $outPath) | Out-Null
$doc | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $outPath -Encoding utf8
Write-Host "PASS: project metadata migrated to Sharnou-IDE protocol: $outPath"
if($found.Count -gt 0){ Write-Host ("Imported metadata entries: " + $found.Count) }

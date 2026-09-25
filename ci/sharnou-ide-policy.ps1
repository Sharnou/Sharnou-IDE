$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) ".."))
$violations = New-Object System.Collections.Generic.List[string]
$forbidden = @("CMakeLists.txt","CMakePresets.json","vcpkg.json","*.sln","*.slnx","*.vcxproj","*.vcxproj.filters")
foreach($pattern in $forbidden){
  Get-ChildItem -LiteralPath $root -Recurse -File -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -like $pattern -and $_.FullName -notmatch "[\\/]legacy[\\/]" } | ForEach-Object { $violations.Add("FORBIDDEN BUILD FILE: $($_.FullName)") }
}

$extensions=@(".ps1",".cmd",".bat",".yml",".yaml",".cpp",".c",".cc",".h",".hpp")
$patterns=@("(?i)\bmsbuild(\.exe)?\b","(?i)\bdevenv(\.exe)?\b","(?i)\bvcpkg(\.exe)?\b","(?i)\bcmake(\.exe)?\b","(?i)\bUnity(\.exe)?\b","(?i)\bUnrealBuildTool(\.exe)?\b")
Get-ChildItem -LiteralPath $root -Recurse -File -Force -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch "[\\/]legacy[\\/]" -and $_.FullName -notmatch "sharnou-ide-policy\.ps1$" -and $extensions -contains $_.Extension.ToLowerInvariant() } | ForEach-Object {
  $path=$_.FullName; $content=Get-Content -LiteralPath $path -Raw
  foreach($pattern in $patterns){ if($content -match $pattern){ $violations.Add("FORBIDDEN TOOL REFERENCE: $path -> $pattern") } }
}

if($violations.Count -gt 0){ $violations | ForEach-Object { Write-Host $_ }; exit 1 }
Write-Host "PASS: Sharnou IDE repository policy."
Write-Host "PASS: No active Microsoft/Unity/Unreal/CMake/vcpkg build path detected."
Write-Host "PASS: No external programming-tool bootstrap is defined by the IDE."
exit 0
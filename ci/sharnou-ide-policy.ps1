$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) ".."))
$violations = New-Object System.Collections.Generic.List[string]
$forbiddenFiles = @("CMakeLists.txt","CMakePresets.json","vcpkg.json","Directory.Build.props","Directory.Build.targets","*.sln","*.slnx","*.vcxproj","*.vcxproj.filters")
foreach($pattern in $forbiddenFiles){
  Get-ChildItem -LiteralPath $root -Recurse -File -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like $pattern -and $_.FullName -notmatch "[\\/]legacy[\\/]" } |
    ForEach-Object { $violations.Add("FORBIDDEN ACTIVE BUILD FILE: $($_.FullName)") }
}

$extensions=@(".ps1",".cmd",".bat",".yml",".yaml",".cpp",".c",".cc",".h",".hpp")
$patterns=@(
  "(?i)\bmsbuild(\.exe)?\b",
  "(?i)\bdevenv(\.exe)?\b",
  "(?i)\bVisual Studio\b",
  "(?i)\bWindows SDK\b",
  "(?i)\bvcvars(\w*)?(\.bat)?\b",
  "(?i)\bcl(\.exe)?\s+",
  "(?i)\bvswhere(\.exe)?\b",
  "(?i)\bvcpkg(\.exe)?\b",
  "(?i)\bcmake(\.exe)?\b",
  "(?i)\bUnity(\.exe)?\b",
  "(?i)\bUnrealBuildTool(\.exe)?\b",
  "(?i)\bInvoke-WebRequest\b",
  "(?i)\bStart-BitsTransfer\b",
  "(?i)\bwinget\s+install\b",
  "(?i)\bchoco\s+install\b",
  "(?i)\bscoop\s+install\b",
  "(?i)\bdotnet\s+tool\s+install\b"
)
Get-ChildItem -LiteralPath $root -Recurse -File -Force -ErrorAction SilentlyContinue |
  Where-Object { $_.FullName -notmatch "[\\/]legacy[\\/]" -and $_.FullName -notmatch "sharnou-ide-policy\.ps1$" -and $extensions -contains $_.Extension.ToLowerInvariant() } |
  ForEach-Object {
    $path=$_.FullName; $content=Get-Content -LiteralPath $path -Raw
    foreach($pattern in $patterns){ if($content -match $pattern){ $violations.Add("FORBIDDEN TOOLCHAIN/DOWNLOAD REFERENCE: $path -> $pattern") } }
  }

if($violations.Count -gt 0){ $violations | ForEach-Object { Write-Host $_ }; exit 1 }
Write-Host "PASS: Sharnou IDE repository policy."
Write-Host "PASS: Visual Studio/MSBuild/Windows SDK/CMake/vcpkg/Unity/Unreal paths rejected."
Write-Host "PASS: External programming-tool bootstrap/download commands rejected."
exit 0
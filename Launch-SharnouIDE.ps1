param(
  [string]$ProjectRoot = "",
  [ValidateSet("validate","compile","self-test","runtime-test","run")]
  [string]$Command = "validate",
  [int]$RuntimeTestSeconds = 300
)
$ErrorActionPreference = "Stop"
if ([string]::IsNullOrWhiteSpace($ProjectRoot)) { $ProjectRoot = (Get-Location).Path }
$script = Join-Path (Join-Path $PSScriptRoot "src") "SharnouIDE.ps1"
if (-not (Test-Path -LiteralPath $script -PathType Leaf)) { throw "Sharnou IDE controller missing: $script" }
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $script -ProjectRoot $ProjectRoot -Command $Command -RuntimeTestSeconds $RuntimeTestSeconds
exit $LASTEXITCODE
$ErrorActionPreference = "Stop"
$root = [IO.Path]::GetFullPath((Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) ".."))
$violations = New-Object System.Collections.Generic.List[string]
$allowedVisual = @(".avif")
$rejectedVisual = @(".png", ".jpg", ".jpeg", ".webp", ".gif", ".bmp", ".tga", ".dds")

Get-ChildItem -LiteralPath $root -Recurse -File -Force -ErrorAction SilentlyContinue |
  Where-Object { $_.FullName -notmatch "[\\/]\.git[\\/]" -and $_.FullName -notmatch "[\\/]legacy[\\/]" -and $rejectedVisual -contains $_.Extension.ToLowerInvariant() } |
  ForEach-Object { $violations.Add("REJECTED VISUAL ASSET FORMAT: $($_.FullName)") }

if($violations.Count -gt 0){
  $violations | ForEach-Object { Write-Host $_ }
  exit 1
}
Write-Host "PASS: visual/image assets are AVIF-only."
exit 0

[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$resolved = & (Join-Path $PSScriptRoot 'Resolve-PinnedSharnouCompiler.ps1')
if (-not $resolved -or $resolved.ReleaseTag -ne 'R26.0-R2-R8') { throw 'Pinned compiler resolution did not return the expected release.' }

& (Join-Path $root 'ci/sharnou-ide-policy.ps1')
if (-not $?) { throw 'IDE policy validation failed.' }
& (Join-Path $root 'ci/sharnou-avif-policy.ps1')
if (-not $?) { throw 'IDE AVIF policy validation failed.' }

$output = Join-Path $root 'Build/PinnedCompiler/honour-war.sppc.json'
$source = Join-Path $root 'project/main.spp'
& (Join-Path $root 'src/Compile-Spp.ps1') -Source $source -Output $output
if (-not $?) { throw 'SPP validation/compilation failed.' }

Write-Host 'PASS: IDE policy and SPP authoring validation completed.' -ForegroundColor Green
Write-Warning 'The IDE controller is PowerShell and SPP; R26.0-R2-R8 does not compile .ps1 or .spp and does not produce a native SharnouIDE.exe.'
Write-Host 'Compiler pin was downloaded and verified; no IDE executable build is claimed.'

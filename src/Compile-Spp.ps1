[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string] $Source,
    [Parameter(Mandatory = $true)][string] $Output
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) {
    throw "SPP source not found: $Source"
}

$commands = @()
$lineNumber = 0

foreach ($rawLine in Get-Content -LiteralPath $Source) {
    $lineNumber++
    $line = ([string]$rawLine).Trim()
    if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith('//', [StringComparison]::Ordinal)) {
        continue
    }

    $matches = [regex]::Matches($line, '"([^"]*)"|\S+')
    $tokenList = New-Object System.Collections.ArrayList
    foreach ($match in $matches) {
        if ($match.Groups[1].Success) {
            [void]$tokenList.Add([string]$match.Groups[1].Value)
        } else {
            [void]$tokenList.Add([string]$match.Value)
        }
    }
    $tokens = $tokenList.ToArray()
    if ($tokens.Length -eq 0) { continue }

    switch -CaseSensitive ([string]$tokens[0]) {
        'project_bind' {
            if ($tokens.Length -ne 2) { throw "Line ${lineNumber}: project_bind requires a project id." }
            if ($tokens[1] -cne 'honour-war') { throw "Line ${lineNumber}: only canonical project 'honour-war' may be bound." }
            $commands += [pscustomobject]@{ op = 'project_bind'; project = [string]$tokens[1]; line = $lineNumber }
        }
        'generate_content' {
            if ($tokens.Length -ne 2 -or [string]::IsNullOrWhiteSpace([string]$tokens[1])) {
                throw "Line ${lineNumber}: generate_content requires a content domain."
            }
            $commands += [pscustomobject]@{ op = 'generate_content'; domain = [string]$tokens[1]; line = $lineNumber }
        }
        'actor_spawn' {
            if ($tokens.Length -ne 2) { throw "Line ${lineNumber}: actor_spawn requires an actor id." }
            $commands += [pscustomobject]@{ op = 'actor_spawn'; actor = [string]$tokens[1]; line = $lineNumber }
        }
        'set_pos' {
            if ($tokens.Length -ne 4) { throw "Line ${lineNumber}: set_pos requires x y z." }
            $culture = [Globalization.CultureInfo]::InvariantCulture
            $styles = [Globalization.NumberStyles]::Float
            [float]$x = 0
            [float]$y = 0
            [float]$z = 0
            if (-not [float]::TryParse([string]$tokens[1], $styles, $culture, [ref]$x)) { throw "Line ${lineNumber}: invalid x." }
            if (-not [float]::TryParse([string]$tokens[2], $styles, $culture, [ref]$y)) { throw "Line ${lineNumber}: invalid y." }
            if (-not [float]::TryParse([string]$tokens[3], $styles, $culture, [ref]$z)) { throw "Line ${lineNumber}: invalid z." }
            $commands += [pscustomobject]@{ op = 'set_pos'; x = $x; y = $y; z = $z; line = $lineNumber }
        }
        'bind_mesh' {
            if ($tokens.Length -ne 2) { throw "Line ${lineNumber}: bind_mesh requires a mesh id." }
            $commands += [pscustomobject]@{ op = 'bind_mesh'; mesh = [string]$tokens[1]; line = $lineNumber }
        }
        'texture_asset' {
            if ($tokens.Length -ne 2) { throw "Line ${lineNumber}: texture_asset requires an asset path." }
            $commands += [pscustomobject]@{ op = 'texture_asset'; asset = [string]$tokens[1]; line = $lineNumber }
        }
        'texture_avif' {
            if ($tokens.Length -ne 2) { throw "Line ${lineNumber}: texture_avif requires an asset path." }
            $asset = [string]$tokens[1]
            if ([IO.Path]::GetExtension($asset).ToLowerInvariant() -cne '.avif') {
                throw "Line ${lineNumber}: texture_avif requires a .avif asset."
            }
            $commands += [pscustomobject]@{ op = 'texture_avif'; asset = $asset; line = $lineNumber }
        }
        default {
            throw "Line ${lineNumber}: unknown SPP operation '$($tokens[0])'."
        }
    }
}

$document = [pscustomobject]@{
    schema = 'sharnou-bytecode/1'
    ide_id = 'Sharnou-IDE'
    engine_id = 'SharnouEngine'
    project_id = 'honour-war'
    source = [IO.Path]::GetFullPath($Source)
    commands = @($commands)
}
$json = ConvertTo-Json -InputObject $document -Depth 8
$outputDirectory = Split-Path -Parent ([IO.Path]::GetFullPath($Output))
New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
[IO.File]::WriteAllText([IO.Path]::GetFullPath($Output), [string]$json, $utf8NoBom)
Write-Host ("PASS: compiled {0} SPP commands -> {1}" -f $commands.Count, $Output)

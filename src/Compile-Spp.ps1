param(
    [Parameter(Mandatory=$true)][string]$Source,
    [Parameter(Mandatory=$true)][string]$Output
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) {
    throw "SPP source not found: $Source"
}

$commands = New-Object System.Collections.Generic.List[object]
$lineNumber = 0

foreach ($rawLine in Get-Content -LiteralPath $Source) {
    $lineNumber++
    $line = $rawLine.Trim()
    if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith("//")) {
        continue
    }

    $tokens = [regex]::Matches($line, '"([^"]*)"|\S+') | ForEach-Object {
        if ($_.Groups[1].Success) { $_.Groups[1].Value } else { $_.Value }
    }

    if ($tokens.Count -eq 0) { continue }

    switch ($tokens[0]) {
        "project_bind" {
            if ($tokens.Count -ne 2) { throw "Line $lineNumber: project_bind requires a project id." }
            if ($tokens[1] -ne "honour-war") { throw "Line $lineNumber: only canonical project 'honour-war' may be bound." }
            $commands.Add([ordered]@{ op="project_bind"; project=$tokens[1]; line=$lineNumber })
        }
        "generate_content" {
            if ($tokens.Count -ne 2 -or [string]::IsNullOrWhiteSpace($tokens[1])) {
                throw "Line $lineNumber: generate_content requires a content domain."
            }
            $commands.Add([ordered]@{ op="generate_content"; domain=$tokens[1]; line=$lineNumber })
        }
        "actor_spawn" {
            if ($tokens.Count -ne 2) { throw "Line $lineNumber: actor_spawn requires an actor id." }
            $commands.Add([ordered]@{ op="actor_spawn"; actor=$tokens[1]; line=$lineNumber })
        }
        "set_pos" {
            if ($tokens.Count -ne 4) { throw "Line $lineNumber: set_pos requires x y z." }
            $ci=[Globalization.CultureInfo]::InvariantCulture
            $ns=[Globalization.NumberStyles]::Float
            [float]$x=0; [float]$y=0; [float]$z=0
            if (-not [float]::TryParse($tokens[1],$ns,$ci,[ref]$x)) { throw "Line $lineNumber: invalid x." }
            if (-not [float]::TryParse($tokens[2],$ns,$ci,[ref]$y)) { throw "Line $lineNumber: invalid y." }
            if (-not [float]::TryParse($tokens[3],$ns,$ci,[ref]$z)) { throw "Line $lineNumber: invalid z." }
            $commands.Add([ordered]@{ op="set_pos"; x=$x; y=$y; z=$z; line=$lineNumber })
        }
        "bind_mesh" {
            if ($tokens.Count -ne 2) { throw "Line $lineNumber: bind_mesh requires a mesh id." }
            $commands.Add([ordered]@{ op="bind_mesh"; mesh=$tokens[1]; line=$lineNumber })
        }
        "texture_asset" {
            if ($tokens.Count -ne 2) { throw "Line $lineNumber: texture_asset requires an asset path." }
            $commands.Add([ordered]@{ op="texture_asset"; asset=$tokens[1]; line=$lineNumber })
        }
        "texture_avif" {
            if ($tokens.Count -ne 2) { throw "Line $lineNumber: texture_avif requires an asset path." }
            $asset=[string]$tokens[1]
            if ([IO.Path]::GetExtension($asset).ToLowerInvariant() -ne ".avif") {
                throw "Line $lineNumber: texture_avif requires a .avif asset."
            }
            $commands.Add([ordered]@{ op="texture_avif"; asset=$asset; line=$lineNumber })
        }
        default {
            throw "Line $lineNumber: unknown SPP operation '$($tokens[0])'."
        }
    }
}

$document=[ordered]@{
    schema="sharnou-bytecode/1"
    ide_id="Sharnou-IDE"
    engine_id="SharnouEngine"
    project_id="honour-war"
    source=[IO.Path]::GetFullPath($Source)
    commands=@($commands)
}

$dir=Split-Path -Parent $Output
New-Item -ItemType Directory -Force -Path $dir | Out-Null
[IO.File]::WriteAllText($Output,($document | ConvertTo-Json -Depth 8),(New-Object Text.UTF8Encoding($false)))
Write-Host "PASS: compiled $($commands.Count) SPP commands -> $Output"

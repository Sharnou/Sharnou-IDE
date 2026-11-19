[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string] $CompilerRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ideRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$bridgePath = Join-Path $ideRoot 'toolchain/Invoke-SharnouCompiler.ps1'
$compilerRootFull = [IO.Path]::GetFullPath($CompilerRoot)
$example = Join-Path $compilerRootFull 'Examples/ControlFlow/IfElse.sharnou'
if (-not (Test-Path -LiteralPath $bridgePath -PathType Leaf)) { throw "Compiler bridge is missing: $bridgePath" }
if (-not (Test-Path -LiteralPath $example -PathType Leaf)) { throw "Pinned compiler example is missing: $example" }

$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('sharnou-ide-compiler-bridge-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $testRoot | Out-Null
try {
    $outputPath = Join-Path $testRoot 'IfElse.exe'
    & $bridgePath -CompilerRoot $compilerRootFull -Source $example -Output $outputPath
    if (-not (Test-Path -LiteralPath $outputPath -PathType Leaf)) {
        throw 'Compiler bridge did not publish the verified executable.'
    }
    $outputHash = (Get-FileHash -LiteralPath $outputPath -Algorithm SHA256).Hash
    if ($outputHash -notmatch '^[0-9A-Fa-f]{64}$') { throw 'Compiler bridge output SHA-256 is malformed.' }

    $lines = @(& $outputPath 2>&1)
    $exitCode = $LASTEXITCODE
    $nl = [string][char]10
    $actual = (($lines | ForEach-Object { [string]$_ }) -join $nl).TrimEnd([char[]]@([char]13, [char]10))
    $expected = 'greater' + $nl + 'equal' + $nl + 'not equal branch'
    if ($exitCode -ne 0) { throw "Compiled native program exited with code $exitCode. Output=[$actual]." }
    if (-not [string]::Equals($actual, $expected, [StringComparison]::Ordinal)) {
        throw "Compiled native program output mismatch. Expected=[$expected]; actual=[$actual]."
    }
    Write-Host 'PASS: IDE bridge compiled and executed the pinned native Sharnou control-flow fixture.' -ForegroundColor Green

    # A rejected build must preserve the previously published output at the target path.
    $invalidSource = Join-Path $testRoot 'Invalid.sharnou'
    $preservedOutput = Join-Path $testRoot 'Preserved.exe'
    [IO.File]::WriteAllText($invalidSource, 'if 1 < 2 { print(1); }' + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllBytes($preservedOutput, [Text.Encoding]::ASCII.GetBytes('PRESERVE-OLD-OUTPUT'))
    $beforeHash = (Get-FileHash -LiteralPath $preservedOutput -Algorithm SHA256).Hash
    $rejected = $false
    try {
        & $bridgePath -CompilerRoot $compilerRootFull -Source $invalidSource -Output $preservedOutput
    } catch {
        $rejected = $true
    }
    if (-not $rejected) { throw 'Compiler bridge accepted invalid source unexpectedly.' }
    $afterHash = (Get-FileHash -LiteralPath $preservedOutput -Algorithm SHA256).Hash
    if ($afterHash -cne $beforeHash) { throw 'Rejected compilation overwrote the previous output.' }
    Write-Host 'PASS: failed compilation leaves the previous output unchanged.' -ForegroundColor Green

    $wrongExtensionRejected = $false
    try {
        & $bridgePath -CompilerRoot $compilerRootFull -Source $example -Output (Join-Path $testRoot 'WrongOutput.bin')
    } catch {
        $wrongExtensionRejected = $true
    }
    if (-not $wrongExtensionRejected) { throw 'Compiler bridge accepted a non-EXE output extension.' }
    Write-Host 'PASS: compiler bridge rejects output paths outside the PE32+ executable contract.' -ForegroundColor Green

    Write-Host 'Sharnou IDE compiler bridge tests: 3 passed, 0 failed.' -ForegroundColor Green
}
finally {
    if (Test-Path -LiteralPath $testRoot) {
        Remove-Item -LiteralPath $testRoot -Recurse -Force
    }
}

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string] $Source,
    [Parameter(Mandatory = $true)][string] $Output,
    [string] $CompilerRoot = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-GitBlobSha1 {
    param([Parameter(Mandatory = $true)][string] $Path)

    [byte[]]$raw = [IO.File]::ReadAllBytes($Path)
    $utf8 = [Text.UTF8Encoding]::new($false, $true)
    $text = $utf8.GetString($raw)
    if ($text.Length -gt 0 -and $text[0] -eq [char]0xFEFF) {
        $text = $text.Substring(1)
    }

    # Git stores text blobs with LF in this repository. Normalize Windows checkout
    # line endings before computing the canonical Git blob object id.
    $text = $text.Replace(([string][char]13 + [string][char]10), [string][char]10)
    $text = $text.Replace([string][char]13, [string][char]10)
    [byte[]]$contentBytes = $utf8.GetBytes($text)
    $headerText = ('blob {0}' -f $contentBytes.Length) + [char]0
    [byte[]]$headerBytes = [Text.Encoding]::ASCII.GetBytes($headerText)
    [byte[]]$payload = New-Object 'System.Byte[]' ($headerBytes.Length + $contentBytes.Length)
    [Array]::Copy($headerBytes, 0, $payload, 0, $headerBytes.Length)
    [Array]::Copy($contentBytes, 0, $payload, $headerBytes.Length, $contentBytes.Length)

    $sha1 = [Security.Cryptography.SHA1]::Create()
    try {
        return ([BitConverter]::ToString($sha1.ComputeHash($payload))).Replace('-', '').ToLowerInvariant()
    }
    finally {
        $sha1.Dispose()
    }
}

function Get-LogDetails {
    param([string] $Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return '' }
    $value = [string](Get-Content -LiteralPath $Path -Raw -ErrorAction SilentlyContinue)
    if ($value.Length -gt 4000) { $value = $value.Substring($value.Length - 4000) }
    return $value.Trim()
}

if ($env:OS -ne 'Windows_NT') {
    throw 'The Sharnou compiler bridge requires Windows.'
}
if ($PSVersionTable.PSVersion.Major -ne 5 -or $PSVersionTable.PSVersion.Minor -ne 1) {
    throw 'The Sharnou compiler bridge requires Windows PowerShell 5.1.'
}
if ([IntPtr]::Size -ne 8) {
    throw 'The Sharnou compiler bridge requires a 64-bit PowerShell process.'
}

$ideRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$contractPath = Join-Path $ideRoot 'toolchain/sharnou-compiler.contract.json'
if (-not (Test-Path -LiteralPath $contractPath -PathType Leaf)) {
    throw "Sharnou compiler contract is missing: $contractPath"
}
$contract = Get-Content -LiteralPath $contractPath -Raw | ConvertFrom-Json
if ($contract.schema -cne 'sharnou-ide-compiler-contract/1') {
    throw 'Unsupported Sharnou compiler integration contract schema.'
}
if ($contract.compiler_repository -cne 'Sharnou/Sharnou-Compiler') {
    throw 'Compiler repository identity does not match the approved Sharnou compiler.'
}
if ($contract.execution_model -cne 'stage0-powershell-dotnet-bootstrap') {
    throw 'The configured compiler execution model is not recognized.'
}
if ($contract.output.format -cne 'PE32+' -or $contract.output.machine -cne 'AMD64') {
    throw 'The configured compiler output contract is not AMD64 PE32+.'
}

if ([string]::IsNullOrWhiteSpace($CompilerRoot)) {
    if (-not [string]::IsNullOrWhiteSpace([string]$env:SHARNOU_COMPILER_ROOT)) {
        $CompilerRoot = [string]$env:SHARNOU_COMPILER_ROOT
    } else {
        $CompilerRoot = Join-Path (Split-Path -Parent $ideRoot) 'Sharnou-Compiler'
    }
}
$compilerRootFull = [IO.Path]::GetFullPath($CompilerRoot)
$compilerRelative = ([string]$contract.bootstrap_compiler.path).Replace('/', [string][IO.Path]::DirectorySeparatorChar)
$verifierRelative = ([string]$contract.pe_verifier.path).Replace('/', [string][IO.Path]::DirectorySeparatorChar)
$compilerPath = Join-Path $compilerRootFull $compilerRelative
$verifierPath = Join-Path $compilerRootFull $verifierRelative

foreach ($required in @($compilerPath, $verifierPath)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) {
        throw "Approved Sharnou compiler component is missing: $required. Set -CompilerRoot to a local Sharnou-Compiler checkout."
    }
}

$actualCompilerBlob = Get-GitBlobSha1 -Path $compilerPath
$expectedCompilerBlob = ([string]$contract.bootstrap_compiler.git_blob_sha1).ToLowerInvariant()
if ($actualCompilerBlob -cne $expectedCompilerBlob) {
    throw "Sharnou bootstrap compiler source identity mismatch. Expected Git blob $expectedCompilerBlob; received $actualCompilerBlob."
}
$actualVerifierBlob = Get-GitBlobSha1 -Path $verifierPath
$expectedVerifierBlob = ([string]$contract.pe_verifier.git_blob_sha1).ToLowerInvariant()
if ($actualVerifierBlob -cne $expectedVerifierBlob) {
    throw "Sharnou PE verifier source identity mismatch. Expected Git blob $expectedVerifierBlob; received $actualVerifierBlob."
}

$sourceFull = [IO.Path]::GetFullPath($Source)
if (-not (Test-Path -LiteralPath $sourceFull -PathType Leaf)) {
    throw "Sharnou source file does not exist: $sourceFull"
}
if ([IO.Path]::GetExtension($sourceFull) -ine [string]$contract.language.source_extension) {
    throw "The native Sharnou compiler accepts .sharnou source files, not '$([IO.Path]::GetExtension($sourceFull))'."
}

$outputFull = [IO.Path]::GetFullPath($Output)
if ([IO.Path]::GetExtension($outputFull) -ine [string]$contract.output.extension) {
    throw 'The native Sharnou compiler output path must use the .exe extension.'
}
$outputDirectory = Split-Path -Parent $outputFull
if ([string]::IsNullOrWhiteSpace($outputDirectory)) {
    throw 'The compiler output must resolve to a directory.'
}
New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null

$powerShellPath = Join-Path $PSHOME 'powershell.exe'
if (-not (Test-Path -LiteralPath $powerShellPath -PathType Leaf)) {
    throw "Windows PowerShell executable was not found: $powerShellPath"
}

$buildId = [Guid]::NewGuid().ToString('N')
$stagedOutput = Join-Path $outputDirectory ('.' + [IO.Path]::GetFileNameWithoutExtension($outputFull) + '.' + $buildId + '.stage.exe')
$compilerLog = $outputFull + '.compiler.log'
$verifierLog = $outputFull + '.verifier.log'

try {
    $compilerArguments = @(
        '-NoProfile',
        '-NonInteractive',
        '-ExecutionPolicy', 'Bypass',
        '-File', $compilerPath,
        '-Source', $sourceFull,
        '-Output', $stagedOutput
    )
    & $powerShellPath @compilerArguments *> $compilerLog
    $compilerExitCode = $LASTEXITCODE
    if ($compilerExitCode -ne 0) {
        $details = Get-LogDetails -Path $compilerLog
        throw "Sharnou compiler failed with exit code $compilerExitCode. $details"
    }
    if (-not (Test-Path -LiteralPath $stagedOutput -PathType Leaf)) {
        throw 'Sharnou compiler exited successfully without producing the staged executable.'
    }

    $verifierArguments = @(
        '-NoProfile',
        '-NonInteractive',
        '-ExecutionPolicy', 'Bypass',
        '-File', $verifierPath,
        '-Path', $stagedOutput
    )
    & $powerShellPath @verifierArguments *> $verifierLog
    $verifierExitCode = $LASTEXITCODE
    if ($verifierExitCode -ne 0) {
        $details = Get-LogDetails -Path $verifierLog
        throw "Independent Sharnou PE verification failed with exit code $verifierExitCode. $details"
    }

    # Promote only a verified executable. A failed compiler or PE verifier never
    # replaces an existing known-good output.
    if (Test-Path -LiteralPath $outputFull -PathType Leaf) {
        $backupPath = $outputFull + '.backup-' + $buildId
        [IO.File]::Replace($stagedOutput, $outputFull, $backupPath)
        if (Test-Path -LiteralPath $backupPath -PathType Leaf) {
            Remove-Item -LiteralPath $backupPath -Force
        }
    } else {
        [IO.File]::Move($stagedOutput, $outputFull)
    }

    $outputHash = (Get-FileHash -LiteralPath $outputFull -Algorithm SHA256).Hash
    $outputLength = (Get-Item -LiteralPath $outputFull).Length
    Write-Host ("PASS: verified AMD64 PE32+ executable: {0}" -f $outputFull) -ForegroundColor Green
    Write-Host ("Output bytes: {0}" -f $outputLength)
    Write-Host ("Output SHA-256: {0}" -f $outputHash)
    Write-Host ("Compiler log: {0}" -f $compilerLog)
    Write-Host ("PE verifier log: {0}" -f $verifierLog)
}
catch {
    if (Test-Path -LiteralPath $stagedOutput -PathType Leaf) {
        Remove-Item -LiteralPath $stagedOutput -Force -ErrorAction SilentlyContinue
    }
    throw
}
finally {
    if (Test-Path -LiteralPath $stagedOutput -PathType Leaf) {
        Remove-Item -LiteralPath $stagedOutput -Force -ErrorAction SilentlyContinue
    }
}

param(
  [Parameter(Mandatory)][string]$Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Load config from same folder as this script
$configPath = Join-Path $PSScriptRoot 'zet.config.ps1'
. $configPath

$archiveDir = Join-Path $ZetRoot 'Archive'
if (-not (Test-Path -LiteralPath $archiveDir)) {
  New-Item -ItemType Directory -Path $archiveDir | Out-Null
}

if (-not (Test-Path -LiteralPath $Path)) {
  throw "File not found: $Path"
}

$leaf = Split-Path -Leaf $Path
$dest = Join-Path $archiveDir $leaf

# If a file already exists with same name, append -2, -3...
if (Test-Path -LiteralPath $dest) {
  $base = [System.IO.Path]::GetFileNameWithoutExtension($leaf)
  $ext  = [System.IO.Path]::GetExtension($leaf)
  $i = 2
  do {
    $dest = Join-Path $archiveDir ("{0}-{1}{2}" -f $base, $i, $ext)
    $i++
  } while (Test-Path -LiteralPath $dest)
}

Move-Item -LiteralPath $Path -Destination $dest

# Return canonical destination path (single line)
(Resolve-Path -LiteralPath $dest).Path

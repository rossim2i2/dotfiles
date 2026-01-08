param(
  [Parameter(Mandatory)][string]$Path,
  [Parameter(Mandatory)][string]$NewTitle
)

. "C:\ZetScripts\zet.config.ps1"

function Strip-InlineTags([string]$s) { return ($s -replace '[@#][\p{L}\p{N}_\-]+','').Trim() }
function New-Slug([string]$s, [int]$maxLen) {
  $s = Strip-InlineTags $s
  if ([string]::IsNullOrWhiteSpace($s)) { $s = 'untitled' }
  $s = $s.ToLowerInvariant()
  $s = $s -replace '[\\/:*?"<>|]+',' '
  $s = ($s -replace '\s+',' ').Trim()
  $s = ($s -replace ' ','-').Trim('-')
  if ($s.Length -gt $maxLen) { $s = $s.Substring(0, $maxLen).Trim('-') }
  if ([string]::IsNullOrWhiteSpace($s)) { $s = 'untitled' }
  return $s
}

if (-not (Test-Path $Path)) { throw "File not found: $Path" }

$dir = Split-Path -Parent $Path
$base = Split-Path -Leaf $Path

# Expect: "yyyyMMddHHmmss - slug.md"
if ($base -notmatch '^(\d{14})\s-\s.+\.md$') {
  throw "Unexpected filename format. Expected 'yyyyMMddHHmmss - slug.md' got: $base"
}
$id = $Matches[1]

$slug = New-Slug -s $NewTitle -maxLen $MaxSlugLen
$newName = "$id - $slug.md"
$newPath = Join-Path $dir $newName

Rename-Item -Path $Path -NewName $newName

# Update YAML title in-place
$content = Get-Content -Path $newPath -Raw

# Replace title: "..."
$content = [regex]::Replace(
  $content,
  '(?m)^title:\s*".*"$',
  ('title: "' + ($NewTitle -replace '"','\"') + '"'),
  1
)

# Write back UTF-8 without BOM
[System.IO.File]::WriteAllText($newPath, $content, (New-Object System.Text.UTF8Encoding($false)))

$newPath

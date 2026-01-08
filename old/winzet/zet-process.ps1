param(
  [Parameter(Mandatory)][string]$Path,

  # Where to move it / what to become
  [Parameter(Mandatory)]
  [ValidateSet('archive','note','meeting','project','sync','inbox')]
  [string]$To,

  # Optional rename (also updates YAML title)
  [string]$Title = '',

  # Optional tags replacement (omit to keep existing)
  [string[]]$Tags,

  # If set, open the processed file in the current nvim (useful when calling from nvim)
  [switch]$OpenInNvim
)

. "C:\ZetScripts\zet.config.ps1"

function Ensure-Folders {
  param([string]$Root)
  foreach ($p in @('Inbox','Notes','Meetings','Projects','Syncs','Archive')) {
    $dir = Join-Path $Root $p
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
  }
}

function Strip-InlineTags([string]$s) {
  return ($s -replace '[@#][\p{L}\p{N}_\-]+','').Trim()
}

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

function Type-Folder([string]$Root, [string]$t) {
  switch ($t) {
    'inbox'   { Join-Path $Root 'Inbox' }
    'note'    { Join-Path $Root 'Notes' }
    'meeting' { Join-Path $Root 'Meetings' }
    'project' { Join-Path $Root 'Projects' }
    'sync'    { Join-Path $Root 'Syncs' }
    'archive' { Join-Path $Root 'Archive' }
  }
}

function Get-YamlBlock([string]$content) {
  # returns @{ yaml = '---...---'; body = '...'; hasYaml = bool }
  $m = [regex]::Match($content, '^\s*---\s*\r?\n([\s\S]*?)\r?\n---\s*\r?\n', [System.Text.RegularExpressions.RegexOptions]::Multiline)
  if (-not $m.Success) {
    return @{ hasYaml = $false; yaml = ''; body = $content }
  }
  $yaml = $m.Value
  $body = $content.Substring($m.Length)
  return @{ hasYaml = $true; yaml = $yaml; body = $body }
}

function Get-YamlField([string]$yaml, [string]$key) {
  $m = [regex]::Match($yaml, "(?m)^\s*$([regex]::Escape($key)):\s*`"?(.*?)`"?\s*$")
  if ($m.Success) { return $m.Groups[2].Value }
  return ''
}

function Set-YamlField([string]$yaml, [string]$key, [string]$value) {
  $escaped = $value -replace '"','\"'
  if ([regex]::IsMatch($yaml, "(?m)^\s*$([regex]::Escape($key)):\s*")) {
    return [regex]::Replace($yaml, "(?m)^\s*$([regex]::Escape($key)):\s*.*$", "$key: `"$escaped`"")
  }
  # insert before closing ---
  return [regex]::Replace($yaml, "(?m)^---\s*$", "---", 1) + "`r`n$key: `"$escaped`""
}

function Replace-TagsBlock([string]$yaml, [string[]]$tags) {
  # Replace entire tags: block with a normalized one
  $newBlock = "tags:`r`n"
  if ($null -eq $tags -or $tags.Count -eq 0) {
    $newBlock += "  - `r`n"
  } else {
    foreach ($t in $tags) { $newBlock += "  - `"$($t -replace '"','\"')`"`r`n" }
  }

  if ([regex]::IsMatch($yaml, "(?ms)^\s*tags:\s*\r?\n(?:\s{2}-.*\r?\n)*")) {
    return [regex]::Replace($yaml, "(?ms)^\s*tags:\s*\r?\n(?:\s{2}-.*\r?\n)*", $newBlock)
  }

  # no tags block: add before closing ---
  return ($yaml.TrimEnd() + "`r`n" + $newBlock + "`r`n")
}

# --- main ---
Ensure-Folders -Root $ZetRoot

if (-not (Test-Path $Path)) { throw "File not found: $Path" }

$content = Get-Content -Path $Path -Raw
$parts = Get-YamlBlock $content
if (-not $parts.hasYaml) { throw "No YAML frontmatter found in: $Path" }

$yaml = $parts.yaml
$body = $parts.body

$id = Get-YamlField $yaml 'id'
if ([string]::IsNullOrWhiteSpace($id)) {
  throw "Missing YAML field 'id' in: $Path"
}

$existingTitle = Get-YamlField $yaml 'title'
if ([string]::IsNullOrWhiteSpace($Title)) { $Title = $existingTitle }
if ([string]::IsNullOrWhiteSpace($Title)) { $Title = 'untitled' }

# Update YAML: type + title (and tags if provided)
$yaml = Set-YamlField $yaml 'type' $To
$yaml = Set-YamlField $yaml 'title' $Title

if ($PSBoundParameters.ContainsKey('Tags')) {
  $yaml = Replace-TagsBlock $yaml $Tags
}

# Ensure YAML wrapper stays intact (we may have appended fields)
if ($yaml -notmatch '^\s*---') { $yaml = "---`r`n$yaml" }
if ($yaml -notmatch '---\s*$') { $yaml = ($yaml.TrimEnd() + "`r`n---`r`n") }

# Create new file path
$slug = New-Slug -s $Title -maxLen $MaxSlugLen
$destDir = Type-Folder -Root $ZetRoot -t $To
$destName = "$id - $slug.md"
$destPath = Join-Path $destDir $destName

# Avoid collision
$counter = 2
while (Test-Path $destPath) {
  $destName = "$id - $slug-$counter.md"
  $destPath = Join-Path $destDir $destName
  $counter++
}

# Write new content to destination, then remove original (safer across volumes / OneDrive quirks)
$newContent = $yaml + $body
[System.IO.File]::WriteAllText($destPath, $newContent, (New-Object System.Text.UTF8Encoding($false)))

if ($destPath -ne (Resolve-Path $Path).Path) {
  Remove-Item -Path $Path
}

# Output the new path (for nvim integration)
$destPath

if ($OpenInNvim) {
  & nvim $destPath
}

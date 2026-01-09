
# C:\ZetScripts\zet-new.ps1
param(
  [Parameter(Mandatory)]
  [ValidateSet('inbox','note','meeting','project','sync')]
  [string]$Type,

  [string]$Title = 'untitled',

  [string[]]$Tags = @(),

  [switch]$OpenInNvim
)

Set-StrictMode -Version Latest
$ErrorActionPreferance = 'Stop'

# Always load config from teh same folder as this script
$configPath = Join-Path $PSScriptRoot 'zet.config.ps1'
if (-not (Test-Path $configPath)) {
    throw "Missing config file: $configPath"
  }

. @configPath

function Ensure-Folders {
  param([string]$Root)
  foreach ($p in @('Inbox','Notes','Meetings','Projects','Syncs','Archive')) {
    $dir = Join-Path $Root $p
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
  }
}

function Strip-InlineTags([string]$s) {
  # Remove @person and #tags anywhere in the title
  return ($s -replace '[@#][\p{L}\p{N}_\-]+','').Trim()
}

function New-Slug([string]$s, [int]$maxLen) {
  $s = Strip-InlineTags $s
  if ([string]::IsNullOrWhiteSpace($s)) { $s = 'untitled' }

  $s = $s.ToLowerInvariant()

  # Replace illegal filename chars with space
  $s = $s -replace '[\\/:*?"<>|]+',' '

  # Collapse whitespace
  $s = ($s -replace '\s+',' ').Trim()

  # Convert spaces to hyphens for slug
  $s = ($s -replace ' ','-')

  # Trim hyphens
  $s = $s.Trim('-')

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
  }
}

function New-Frontmatter([string]$id, [string]$type, [string]$title, [string[]]$tags, [string]$createdIso) {
@"
---
id: "$id"
type: "$type"
title: "$title"
created: "$createdIso"
tags:
$(
  if ($tags.Count -eq 0) { "  - " }
  else { ($tags | ForEach-Object { "  - ""$_""" }) -join "`r`n" }
)
---

"@
}

function New-Body([string]$type) {
  switch ($type) {
    'inbox'   { "## notes`r`n`r`n" }
    'note'    { "## notes`r`n`r`n## action items`r`n- [ ] `r`n`r`n" }
    'meeting' { "## notes`r`n`r`n## action items`r`n- [ ] `r`n`r`n" }
    'project' { "## notes`r`n`r`n## action items`r`n- [ ] `r`n`r`n" }
    'sync'    { "## talking points`r`n`r`n## notes`r`n`r`n## action items`r`n- [ ] `r`n`r`n" }
  }
}

Ensure-Folders -Root $ZetRoot

$now = Get-Date
$id = $now.ToString('yyyyMMddHHmmss')
$createdIso = $now.ToString('yyyy-MM-ddTHH:mm:ssK')

$slug = New-Slug -s $Title -maxLen $MaxSlugLen

$folder = Type-Folder -Root $ZetRoot -t $Type
$filename = "$id-$slug.md"
$path = Join-Path $folder $filename

# Avoid collision (rare, but possible if you create multiple in same second)
$counter = 2
while (Test-Path $path) {
  $filename = "$id-$slug-$counter.md"
  $path = Join-Path $folder $filename
  $counter++
}

$fm = New-Frontmatter -id $id -type $Type -title $Title -tags $Tags -createdIso $createdIso
$body = New-Body -type $Type

# Write UTF-8 without BOM
[System.IO.File]::WriteAllText($path, $fm + $body, (New-Object System.Text.UTF8Encoding($false)))

if (-not (Test-Path -LiteralPath $path)) {
    throw "Expected file was not created: $path"
}

$len = (Get-Item -LiteralPath $path).Length
if ($len -lt 10) {
    throw "File created but apprears empty (Lenght=$len): $path"
}

# Print ohe created path (useful for chaining)
(Resolve-Path -LiteralPath $path).Path

if ($OpenInNvim) {
  & nvim $path
}

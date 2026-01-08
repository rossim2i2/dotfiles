. "C:\ZetScripts\zet.config.ps1"

# Find open checkboxes in all markdown files
$pattern = '^\s*-\s*\[\s\]\s+'

Get-ChildItem -Path $ZetRoot -Recurse -File -Filter *.md |
  Select-String -Pattern $pattern |
  ForEach-Object {
    # Format: file:line: match
    "{0}:{1}: {2}" -f $_.Path, $_.LineNumber, $_.Line.Trim()
  }

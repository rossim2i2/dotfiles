Add-Type -AssemblyName Microsoft.VisualBasic

$title = [Microsoft.VisualBasic.Interaction]::InputBox(
  'Inbox title:',
  'Zet Inbox Capture',
  ''
)

if ([string]::IsNullOrWhiteSpace($title)) {
  $title = 'untitled'
}

& pwsh -NoProfile -File C:\ZetScripts\zet-new.ps1 -Type inbox -Title $title | Out-Null

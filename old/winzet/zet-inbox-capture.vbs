Set shell = CreateObject("WScript.Shell")
cmd = "pwsh -NoProfile -ExecutionPolicy Bypass -File ""C:\ZetScripts\zet-inbox-capture.ps1"""
shell.Run cmd, 0, False

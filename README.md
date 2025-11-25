### Run this once in Admin PowerShell to reset the script
```ps1
iwr "https://raw.githubusercontent.com/sakit333/sak-AI-Blocker/main/ai_blocker.ps1" -OutFile "$env:TEMP\ai_blocker.ps1"; Unblock-File "$env:TEMP\ai_blocker.ps1"; powershell -ExecutionPolicy Bypass -File "$env:TEMP\ai_blocker.ps1"
```
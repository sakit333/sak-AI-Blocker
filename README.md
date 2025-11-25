### Run this once in Admin PowerShell to reset the script
```ps1
Remove-Item "C:\ProgramData\AI_Blocker_Executed.flag" -Force -ErrorAction SilentlyContinue
```
- This will remove the run-once protection.
#### Run your script again with this single-line command
- Since your script is actually named ai_blocker.ps1, the correct command is:

```ps1
iwr "https://github.com/sakit333/sak-AI-Blocker/raw/refs/heads/main/ai_blocker.ps1" -OutFile "$env:TEMP\ai_blocker.ps1"; Unblock-File "$env:TEMP\ai_blocker.ps1"; Remove-Item "C:\ProgramData\AI_Blocker_Executed.flag" -Force -ErrorAction SilentlyContinue; powershell -ExecutionPolicy Bypass -File "$env:TEMP\ai_blocker.ps1"
```
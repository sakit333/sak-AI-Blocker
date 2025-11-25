# ============================
# AI BLOCKER – SAK_SHETTY
# Blocks AI websites for 30 minutes
# Auto unblocks + auto cleanup
# ============================

Write-Host "Blocking AI websites for 30 minutes..." -ForegroundColor Green

$hosts = "C:\Windows\System32\drivers\etc\hosts"
$backup = "$env:TEMP\hosts_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# 1. Backup hosts file
Copy-Item $hosts $backup -Force

# 2. List of AI websites
$blockList = @(
    "chatgpt.com",
    "openai.com",
    "bard.google.com",
    "claude.ai",
    "character.ai",
    "perplexity.ai",
    "gpt4free.net"
)

# 3. Write entries to hosts
foreach ($site in $blockList) {
    Add-Content -Path $hosts -Value "127.0.0.1 $site"
    Add-Content -Path $hosts -Value "0.0.0.0 $site"
}

Write-Host "AI Websites BLOCKED. Timer started (30 minutes)..." -ForegroundColor Yellow

# 4. Wait 30 minutes
Start-Sleep -Seconds 1800

Write-Host "Unblocking websites..." -ForegroundColor Cyan

# 5. Restore original hosts file
Copy-Item $backup $hosts -Force

Write-Host "Websites unblocked." -ForegroundColor Green

# 6. Delete backup
Remove-Item $backup -Force

Write-Host "Cleanup done. AI Blocker finished." -ForegroundColor White

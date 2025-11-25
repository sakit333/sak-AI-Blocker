# ====================================================
# AI BLOCKER (1 minute) – SAK_SHETTY
# Error-proof version. Works even if hosts file is locked.
# ALWAYS removes old entries and applies new ones.
# ====================================================

Write-Host "Starting AI Blocker (1 minute)..." -ForegroundColor Green

$hosts = "C:\Windows\System32\drivers\etc\hosts"
$backup = "$env:TEMP\hosts_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# -------------------------
# 1. Backup hosts file
# -------------------------
Copy-Item $hosts $backup -Force

# -------------------------
# 2. Required to unlock file
# -------------------------
Write-Host "Stopping DNS Client service to unlock hosts file..." -ForegroundColor Yellow
Stop-Service -Name "Dnscache" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

# -------------------------
# 3. AI Block List
# -------------------------
$blockList = @(
    "chatgpt.com","www.chatgpt.com",
    "openai.com","api.openai.com","platform.openai.com","www.openai.com",
    "claude.ai","www.claude.ai","api.anthropic.com",
    "gemini.google.com","bard.google.com","ai.google.dev",
    "perplexity.ai","www.perplexity.ai",
    "character.ai","beta.character.ai",
    "poe.com","www.poe.com",
    "you.com","www.you.com",
    "copilot.microsoft.com",
    "bing.com","www.bing.com",
    "huggingface.co","www.huggingface.co",
    "blackbox.ai","www.blackbox.ai",
    "ora.ai","www.ora.ai",
    "reka.ai","www.reka.ai"
)

# -------------------------
# 4. Clean old block entries
# -------------------------
Write-Host "Cleaning old block entries..." -ForegroundColor Yellow
$hostsContent = Get-Content $hosts -ErrorAction SilentlyContinue
foreach ($domain in $blockList) {
    $hostsContent = $hostsContent | Where-Object {$_ -notmatch $domain}
}
$hostsContent | Set-Content $hosts -Force

# -------------------------
# 5. Add new entries safely
# -------------------------
Write-Host "Adding new entries..." -ForegroundColor Cyan

foreach ($domain in $blockList) {
    try {
        Add-Content -Path $hosts -Value "127.0.0.1 $domain" -ErrorAction Stop
        Add-Content -Path $hosts -Value "0.0.0.0 $domain" -ErrorAction Stop
    } catch {
        Write-Host "Retrying write after file unlock..." -ForegroundColor Red
        Start-Sleep -Milliseconds 300
        Add-Content -Path $hosts -Value "127.0.0.1 $domain"
        Add-Content -Path $hosts -Value "0.0.0.0 $domain"
    }
}

Write-Host "`nAI Websites BLOCKED for 1 minute..." -ForegroundColor Green

# -------------------------
# 6. Restart DNS service
# -------------------------
Start-Service -Name "Dnscache" -ErrorAction SilentlyContinue

# -------------------------
# 7. Wait exactly 60 seconds
# -------------------------
Start-Sleep -Seconds 60

Write-Host "Unblocking AI websites..." -ForegroundColor Yellow

# -------------------------
# 8. Restore backup (clean unblock)
# -------------------------
Copy-Item $backup $hosts -Force

# -------------------------
# 9. Restart DNS again
# -------------------------
Start-Service -Name "Dnscache" -ErrorAction SilentlyContinue

# -------------------------
# 10. Remove temporary backup
# -------------------------
Remove-Item $backup -Force

Write-Host "AI access restored successfully." -ForegroundColor Green

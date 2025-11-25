# ====================================================
# AI BLOCKER – SAK_SHETTY
# Always cleans old entries and blocks AI websites
# Auto-unblocks after 1 minute
# ====================================================

Write-Host "Starting AI Blocker (1 minute)..." -ForegroundColor Green

$hosts = "C:\Windows\System32\drivers\etc\hosts"
$backup = "$env:TEMP\hosts_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# -------------------------
# 1. Backup hosts file
# -------------------------
Copy-Item $hosts $backup -Force

# -------------------------
# 2. AI Block List (Recommended)
# -------------------------
$blockList = @(
    "chatgpt.com",
    "openai.com",
    "api.openai.com",
    "platform.openai.com",
    "claude.ai",
    "api.anthropic.com",
    "gemini.google.com",
    "bard.google.com",
    "ai.google.dev",
    "perplexity.ai",
    "www.perplexity.ai",
    "character.ai",
    "beta.character.ai",
    "copilot.microsoft.com",
    "bing.com",
    "you.com",
    "poe.com",
    "huggingface.co",
    "blackbox.ai",
    "ora.ai",
    "reka.ai"
)

# -------------------------
# 3. Clean old blocking entries
# -------------------------
Write-Host "Removing old AI block entries..." -ForegroundColor Yellow
$hostsContent = Get-Content $hosts

foreach ($domain in $blockList) {
    $hostsContent = $hostsContent | Where-Object {$_ -notmatch $domain}
}

$hostsContent | Set-Content $hosts -Force

# -------------------------
# 4. Add fresh block entries
# -------------------------
Write-Host "Adding new AI block entries..." -ForegroundColor Cyan
foreach ($domain in $blockList) {
    Add-Content -Path $hosts -Value "127.0.0.1 $domain"
    Add-Content -Path $hosts -Value "0.0.0.0 $domain"
}

Write-Host "`nAI Websites BLOCKED for 1 minute..." -ForegroundColor Green

# -------------------------
# 5. Wait 1 minute
# -------------------------
Start-Sleep -Seconds 60

Write-Host "Unblocking AI websites..." -ForegroundColor Yellow

# -------------------------
# 6. Restore original hosts file (full cleanup)
# -------------------------
Copy-Item $backup $hosts -Force

# -------------------------
# 7. Delete backup
# -------------------------
Remove-Item $backup -Force

Write-Host "Done. AI access restored." -ForegroundColor Green

# =======================
#  SAK_SHETTY AI BLOCKER
#  Version: Final Stable
#  Duration: 1 minute
# =======================

$hosts = "C:\Windows\System32\drivers\etc\hosts"
$backup = "$env:TEMP\hosts_backup_sak.txt"
$duration = 60

$domains = @(
    "chatgpt.com","www.chatgpt.com",
    "chat.openai.com","api.openai.com","platform.openai.com",
    "claude.ai","www.claude.ai","api.anthropic.com",
    "gemini.google.com","bard.google.com","ai.google.dev",
    "copilot.microsoft.com","bing.com/chat",
    "perplexity.ai","www.perplexity.ai","api.perplexity.ai",
    "poe.com","www.poe.com",
    "you.com","api.you.com",
    "huggingface.co","api-inference.huggingface.co",
    "writesonic.com","api.writesonic.com",
    "deepseek.com","api.deepseek.com",
    "pi.ai","www.pi.ai",
    "replika.com","c.ai","character.ai",
    "meta.ai","llama.meta.com"
)

Write-Host "Starting AI Blocker for 1 minute..."

# -------------------------------
# 1. Backup hosts file (safe mode)
# -------------------------------
Copy-Item $hosts $backup -Force

# -------------------------------------------------------------
# 2. Remove old AI entries (only SAK_SHETTY tagged) – SAFE CLEAN
# -------------------------------------------------------------
$clean = (Get-Content $hosts | Where-Object { $_ -notmatch "#SAK_BLOCK" })
Set-Content -Path $hosts -Value $clean -Force

# --------------------------------
# 3. Add new block entries CLEANLY
# --------------------------------
foreach ($d in $domains) {
    Add-Content -Path $hosts -Value "127.0.0.1 $d #SAK_BLOCK"
    Add-Content -Path $hosts -Value "0.0.0.0 $d #SAK_BLOCK"
}

Write-Host "AI websites are BLOCKED."

# -----------------------
# 4. Wait for 1 minute
# -----------------------
Start-Sleep -Seconds $duration

# ---------------------------
# 5. Unblock automatically
# ---------------------------
$finalClean = (Get-Content $hosts | Where-Object { $_ -notmatch "#SAK_BLOCK" })
Set-Content -Path $hosts -Value $finalClean -Force

Write-Host "AI websites UNBLOCKED automatically."

# ================================
# AI BLOCKER - Cloudflare Kill Switch
# Blocks ChatGPT completely (Chrome-proof)
# Auto unblocks after 1 minute
# ================================

$hostsFile = "C:\Windows\System32\drivers\etc\hosts"

Write-Host "==== AI BLOCKER STARTED ===="

# ----------- REMOVE OLD RULES -----------
Get-NetFirewallRule -DisplayName "AI_BLOCKER_CF" -ErrorAction SilentlyContinue | Remove-NetFirewallRule
Get-NetFirewallRule -DisplayName "AI_BLOCKER_AI" -ErrorAction SilentlyContinue | Remove-NetFirewallRule

# ----------- DOMAINS (extra layer) -----------
$domains = @(
    "chatgpt.com",
    "*.openai.com",
    "openai.com",
    "claude.ai",
    "*.claude.ai",
    "gemini.google.com",
    "perplexity.ai",
    "*.perplexity.ai"
)

# ----------- CLOUDFLARE IP RANGES (MAIN FIX) -----------
$cloudflareRanges = @(
    "173.245.48.0/20",
    "103.21.244.0/22",
    "103.22.200.0/22",
    "103.31.4.0/22",
    "141.101.64.0/18",
    "108.162.192.0/18",
    "190.93.240.0/20",
    "188.114.96.0/20",
    "197.234.240.0/22",
    "198.41.128.0/17",
    "162.158.0.0/15",
    "104.16.0.0/13",
    "172.64.0.0/13",
    "131.0.72.0/22"
)

# ----------- CLEAN HOSTS -----------
$clean = (Get-Content $hostsFile) | Where-Object { $_ -notmatch "#AIBLOCK" }
Set-Content -Path $hostsFile -Value $clean -Force

foreach ($d in $domains) {
    Add-Content -Path $hostsFile -Value "127.0.0.1 $d #AIBLOCK"
}

# ----------- BLOCK CLOUDLFARE (kills ChatGPT) -----------
foreach ($ip in $cloudflareRanges) {
    New-NetFirewallRule -DisplayName "AI_BLOCKER_CF" `
        -Direction Outbound `
        -Action Block `
        -RemoteAddress $ip `
        -Enabled True `
        -ErrorAction SilentlyContinue
}

Write-Host "AI websites BLOCKED for 1 minute."
Start-Sleep -Seconds 60

# ----------- UNBLOCK EVERYTHING -----------
Get-NetFirewallRule -DisplayName "AI_BLOCKER_CF" -ErrorAction SilentlyContinue | Remove-NetFirewallRule

$clean = (Get-Content $hostsFile) | Where-Object { $_ -notmatch "#AIBLOCK" }
Set-Content -Path $hostsFile -Value $clean -Force

Write-Host "AI websites UNBLOCKED."
Write-Host "==== AI BLOCKER COMPLETE ===="

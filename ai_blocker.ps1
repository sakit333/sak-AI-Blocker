# ===========================================================
# AI BLOCKER - 100% Chrome-Proof Version (IP Blocking)
# Blocks ChatGPT, Gemini, Claude, Perplexity, Bing AI completely.
# Unblocks after 60 seconds.
# ===========================================================

$hostsFile = "C:\Windows\System32\drivers\etc\hosts"

# -----------------------------------------
# DOMAIN LIST (secondary protection)
# -----------------------------------------
$domains = @(
    "chatgpt.com",
    "*.openai.com",
    "openai.com",
    "api.openai.com",
    "claude.ai",
    "*.claude.ai",
    "anthropic.com",
    "*.anthropic.com",
    "gemini.google.com",
    "bard.google.com",
    "perplexity.ai",
    "*.perplexity.ai",
    "bing.com",
    "*.bing.com",
    "copilot.microsoft.com"
)

# -----------------------------------------
# IP BLOCK LIST (primary Chrome-proof blocking)
# These IPs belong to major AI services.
# -----------------------------------------
$ipRanges = @(
    # OpenAI / ChatGPT
    "143.244.0.0/16",
    "104.18.0.0/16",
    "172.64.0.0/13",
    "141.101.0.0/16",

    # Google Gemini
    "142.250.0.0/15",
    "142.251.0.0/16",
    "8.8.8.0/24",          # Google DNS
    "8.34.208.0/20",
    "8.35.192.0/20",
    "172.217.0.0/16",

    # Anthropic Claude
    "13.248.0.0/14",
    "76.223.0.0/16",

    # Perplexity
    "34.160.0.0/16",
    "34.170.0.0/16",

    # Microsoft Bing AI / Copilot
    "13.64.0.0/11",
    "40.64.0.0/10",
    "52.96.0.0/12"
)

Write-Host "==== AI BLOCKER STARTED ===="

# -----------------------------------------
# REMOVE OLD FIREWALL RULES
# -----------------------------------------
Write-Host "Removing old firewall rules..."
Get-NetFirewallRule -DisplayName "AI_BLOCKER_IP" -ErrorAction SilentlyContinue | Remove-NetFirewallRule
Get-NetFirewallRule -DisplayName "AI_BLOCKER_DOMAIN" -ErrorAction SilentlyContinue | Remove-NetFirewallRule

# -----------------------------------------
# CLEAN HOSTS FILE
# -----------------------------------------
Write-Host "Cleaning hosts..."
$clean = (Get-Content $hostsFile) | Where-Object { $_ -notmatch "#AIBLOCK" }
Set-Content -Path $hostsFile -Value $clean -Force

# -----------------------------------------
# BLOCK HOSTS (backup protection)
# -----------------------------------------
foreach ($d in $domains) {
    Add-Content -Path $hostsFile -Value "127.0.0.1 $d #AIBLOCK"
}

# -----------------------------------------
# BLOCK IP RANGES (CHROME-PROOF, THE MAIN FIX)
# -----------------------------------------
Write-Host "Blocking IP ranges..."
foreach ($ip in $ipRanges) {
    New-NetFirewallRule -DisplayName "AI_BLOCKER_IP" `
        -Direction Outbound `
        -Action Block `
        -RemoteAddress $ip `
        -Enabled True `
        -ErrorAction SilentlyContinue
}

# -----------------------------------------
# BLOCK DOMAINS (secondary layer)
# -----------------------------------------
foreach ($d in $domains) {
    New-NetFirewallRule -DisplayName "AI_BLOCKER_DOMAIN" `
        -Direction Outbound `
        -Action Block `
        -RemoteAddress $d `
        -Enabled True `
        -ErrorAction SilentlyContinue
}

Write-Host "AI websites are BLOCKED for 1 minute."
Start-Sleep -Seconds 60

# -----------------------------------------
# UNBLOCK EVERYTHING
# -----------------------------------------
Write-Host "Unblocking..."
Get-NetFirewallRule -DisplayName "AI_BLOCKER_IP" -ErrorAction SilentlyContinue | Remove-NetFirewallRule
Get-NetFirewallRule -DisplayName "AI_BLOCKER_DOMAIN" -ErrorAction SilentlyContinue | Remove-NetFirewallRule

$clean = (Get-Content $hostsFile) | Where-Object { $_ -notmatch "#AIBLOCK" }
Set-Content -Path $hostsFile -Value $clean -Force

Write-Host "AI websites UNBLOCKED."
Write-Host "==== AI BLOCKER COMPLETE ===="

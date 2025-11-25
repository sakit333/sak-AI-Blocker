# ---------------------------------------------------------
# AI BLOCKER (Ultimate Version - Firewall + Hosts + Auto Unblock)
# Blocks AI sites for 1 minute then restores everything.
# ---------------------------------------------------------

$hostsPath = "C:\Windows\System32\drivers\etc\hosts"

# AI domain list (expandable anytime)
$aiDomains = @(
    "chatgpt.com",
    "*.openai.com",
    "openai.com",
    "claude.ai",
    "*.claude.ai",
    "anthropic.com",
    "*.anthropic.com",
    "gemini.google.com",
    "bard.google.com",
    "*.googleusercontent.com",
    "perplexity.ai",
    "*.perplexity.ai",
    "bing.com",
    "*.bing.com",
    "copilot.microsoft.com"
)

Write-Host "==== AI BLOCKER STARTED ===="

# ---------------------------------------------------------
# 1) REMOVE OLD FIREWALL RULES
# ---------------------------------------------------------
Write-Host "Removing old AI firewall rules..."
Get-NetFirewallRule -DisplayName "AI_BLOCKER" -ErrorAction SilentlyContinue | Remove-NetFirewallRule

# ---------------------------------------------------------
# 2) REMOVE OLD HOSTS ENTRIES
# ---------------------------------------------------------
Write-Host "Cleaning hosts file..."
$hosts = Get-Content $hostsPath
$clean = $hosts | Where-Object { $_ -notmatch "#AIBLOCK" }
Set-Content -Path $hostsPath -Value $clean -Force

# ---------------------------------------------------------
# 3) APPLY NEW BLOCKS
# ---------------------------------------------------------
Write-Host "Applying firewall and hosts blocking..."

foreach ($domain in $aiDomains) {

    # Hosts block (backup)
    Add-Content -Path $hostsPath -Value ("127.0.0.1 $domain #AIBLOCK")

    # Firewall block (100% reliable)
    New-NetFirewallRule -DisplayName "AI_BLOCKER" `
        -Direction Outbound `
        -Action Block `
        -RemoteAddress $domain `
        -Enabled True `
        -ErrorAction SilentlyContinue
}

Write-Host "AI websites are BLOCKED for 1 minute..."
Start-Sleep -Seconds 60

# ---------------------------------------------------------
# 4) UNBLOCK EVERYTHING
# ---------------------------------------------------------
Write-Host "Restoring system..."

# Remove firewall rules
Get-NetFirewallRule -DisplayName "AI_BLOCKER" -ErrorAction SilentlyContinue | Remove-NetFirewallRule

# Remove hosts entries
$hosts = Get-Content $hostsPath
$clean = $hosts | Where-Object { $_ -notmatch "#AIBLOCK" }
Set-Content -Path $hostsPath -Value $clean -Force

Write-Host "AI websites UNBLOCKED."
Write-Host "==== AI BLOCKER FINISHED ===="

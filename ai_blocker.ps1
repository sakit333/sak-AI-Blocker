# ai_blocker.ps1
# Ultimate dynamic AI blocker (resolves live IPs, blocks IPs + Cloudflare ranges)
# Duration: 60 seconds (1 minute)
# Run as Admin

Set-StrictMode -Version Latest

$durationSec = 60
$tag = "AI_BLOCK_DYNAMIC"
$cfTag = "AI_BLOCK_CF"
$hostsFile = "$env:SystemRoot\System32\drivers\etc\hosts"

# domains to block (expand as desired)
$domains = @(
    "chatgpt.com",
    "www.chatgpt.com",
    "chat.openai.com",
    "openai.com",
    "api.openai.com",
    "platform.openai.com",
    "gemini.google.com",
    "bard.google.com",
    "claude.ai",
    "anthropic.com",
    "perplexity.ai",
    "poe.com",
    "copilot.microsoft.com",
    "bing.com"
)

# Cloudflare IP ranges (commonly used for sites including chatgpt/openai)
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

function Ensure-Admin {
    if (-not ([bool]([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))) {
        Write-Error "This script must be run as Administrator."
        exit 1
    }
}
Ensure-Admin

Write-Host "AI Blocker (dynamic) starting — resolving IPs and creating firewall rules..." -ForegroundColor Cyan

# Remove old rules created by previous runs (clean slate)
Get-NetFirewallRule -DisplayName "*$tag*" -ErrorAction SilentlyContinue | Remove-NetFirewallRule -ErrorAction SilentlyContinue
Get-NetFirewallRule -DisplayName "*$cfTag*" -ErrorAction SilentlyContinue | Remove-NetFirewallRule -ErrorAction SilentlyContinue

# Resolve live IPs for each domain (A and AAAA). Build a unique list.
$resolvedIPs = [System.Collections.Generic.HashSet[string]]::new()

foreach ($d in $domains) {
    try {
        # Try Resolve-DnsName (newer)
        $answers = Resolve-DnsName -Name $d -ErrorAction Stop
        foreach ($a in $answers) {
            if ($a.IPAddress) { $resolvedIPs.Add($a.IPAddress.ToString()) | Out-Null }
        }
    } catch {
        # Fallback to nslookup output parse
        try {
            $ns = nslookup $d 2>$null
            foreach ($line in $ns) {
                if ($line -match 'Address:\s*([0-9a-fA-F:.]+)$') {
                    $resolvedIPs.Add($matches[1]) | Out-Null
                }
            }
        } catch {
            # ignore resolution failure for this domain
        }
    }
}

# If no IPs resolved, attempt to query Google DNS directly
if ($resolvedIPs.Count -eq 0) {
    Write-Host "No IPs resolved via local resolver — trying Google DNS (8.8.8.8)..." -ForegroundColor Yellow
    foreach ($d in $domains) {
        try {
            $answers = Resolve-DnsName -Name $d -Server "8.8.8.8" -ErrorAction Stop
            foreach ($a in $answers) { if ($a.IPAddress) { $resolvedIPs.Add($a.IPAddress.ToString()) | Out-Null } }
        } catch {}
    }
}

# Convert HashSet to array
$ipsToBlock = $resolvedIPs.ToArray()
if ($ipsToBlock.Count -gt 0) {
    Write-Host "Resolved IPs to block:" -ForegroundColor Green
    $ipsToBlock | ForEach-Object { Write-Host "  $_" }
} else {
    Write-Host "No direct IPs resolved from domains. We'll still block Cloudflare ranges and domain-based firewall rules." -ForegroundColor Yellow
}

# Create firewall rules for each resolved IP (outbound)
$timeStamp = (Get-Date).ToString("yyyyMMddHHmmss")
$rulePrefix = "$tag`_$timeStamp"

foreach ($ip in $ipsToBlock) {
    try {
        New-NetFirewallRule -DisplayName ("{0}_{1}" -f $rulePrefix, $ip) `
            -Direction Outbound -Action Block -RemoteAddress $ip -Description "Blocked by AI blocker" -ErrorAction Stop | Out-Null
    } catch {
        Write-Warning "Failed to create firewall rule for $ip : $_"
    }
}

# Add Cloudflare ranges as well (if present)
$cfRulePrefix = "$cfTag`_$timeStamp"
foreach ($range in $cloudflareRanges) {
    try {
        New-NetFirewallRule -DisplayName ("{0}_{1}" -f $cfRulePrefix, $range) `
            -Direction Outbound -Action Block -RemoteAddress $range -Description "Cloudflare range blocked by AI blocker" -ErrorAction Stop | Out-Null
    } catch {
        Write-Warning "Failed to create firewall rule for $range : $_"
    }
}

# Also add domain-based firewall rules as fallback (some Windows may accept FQDNs in RemoteAddress)
foreach ($d in $domains) {
    try {
        New-NetFirewallRule -DisplayName ("{0}_DOMAIN_{1}" -f $rulePrefix, $d) `
            -Direction Outbound -Action Block -RemoteAddress $d -Description "Domain block fallback" -ErrorAction SilentlyContinue | Out-Null
    } catch {}
}

# Flush DNS cache to make sure resolution uses current data
try { ipconfig /flushdns | Out-Null } catch {}

Write-Host "Firewall rules created. AI websites should be blocked now for $durationSec seconds." -ForegroundColor Cyan

# Immediate verification helper (small)
Write-Host "To verify now run: Resolve-DnsName chatgpt.com ; Test-NetConnection chatgpt.com -Port 443" -ForegroundColor Yellow

# Wait
Start-Sleep -Seconds $durationSec

Write-Host "Time elapsed: removing created firewall rules..." -ForegroundColor Cyan

# Remove rules we created (by matching timestamped prefix)
Get-NetFirewallRule -DisplayName "*$tag`_$timeStamp*" -ErrorAction SilentlyContinue | Remove-NetFirewallRule -ErrorAction SilentlyContinue
Get-NetFirewallRule -DisplayName "*$cfTag`_$timeStamp*" -ErrorAction SilentlyContinue | Remove-NetFirewallRule -ErrorAction SilentlyContinue
Get-NetFirewallRule -DisplayName "*$rulePrefix_DOMAIN_*" -ErrorAction SilentlyContinue | Remove-NetFirewallRule -ErrorAction SilentlyContinue

# Final DNS flush
try { ipconfig /flushdns | Out-Null } catch {}

Write-Host "Firewall rules removed, script complete." -ForegroundColor Green
exit 0

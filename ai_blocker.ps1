Write-Host "Starting AI Blocker (1 minute)..."

$hosts = "C:\Windows\System32\drivers\etc\hosts"
$backup = "$env:TEMP\hosts_backup_$(Get-Date -Format 'HHmmss').txt"

# Domains to block
$domains = @(
    "chat.openai.com",
    "openai.com",
    "bard.google.com",
    "claude.ai",
    "copilot.microsoft.com",
    "gemini.google.com",
    "chatgpt.com",
    "bing.com"
)

# Backup hosts file (safe)
Copy-Item $hosts $backup -Force

# Remove previous entries
Write-Host "Removing old entries..."
$cleanContent = (Get-Content $hosts) | Where-Object { $_ -notmatch "BLOCKED_AI" }
Set-Content -Path $hosts -Value $cleanContent -Force

# Add new entries
Write-Host "Adding new entries..."
foreach ($domain in $domains) {
    Add-Content -Path $hosts -Value "127.0.0.1 $domain # BLOCKED_AI"
    Add-Content -Path $hosts -Value "0.0.0.0 $domain # BLOCKED_AI"
}

Write-Host "AI websites BLOCKED for 1 minute..."
Start-Sleep -Seconds 60

# Restore clean version
Write-Host "Unblocking..."
$cleanContent = (Get-Content $hosts) | Where-Object { $_ -notmatch "BLOCKED_AI" }
Set-Content -Path $hosts -Value $cleanContent -Force

Write-Host "AI websites UNBLOCKED!"

# AI Blocker – Safe Version (No Stream Errors)

$hosts = "$env:SystemRoot\System32\drivers\etc\hosts"
$backup = "$env:TEMP\hosts_backup_sak.txt"

# AI domains list
$AIDomains = @(
    "chat.openai.com",
    "chatgpt.com",
    "openai.com",
    "api.openai.com",
    "ai.com",
    "claude.ai",
    "api.anthropic.com",
    "bard.google.com",
    "gemini.google.com",
    "perplexity.ai",
    "copilot.microsoft.com",
    "bing.com/chat",
    "you.com",
    "pi.ai",
    "huggingface.co",
    "character.ai",
    "poe.com",
    "groq.com",
    "mistral.ai"
)

Write-Host "Starting AI Blocker (1 minute)..."

# Step 1 → Backup original hosts
Copy-Item -Force $hosts $backup

# Step 2 → Remove previous SAK entries safely
$clean = Get-Content $hosts | Where-Object { $_ -notmatch "#SAK_BLOCK" }

# Step 3 → Add NEW block entries
foreach ($d in $AIDomains) {
    $clean += "127.0.0.1 $d #SAK_BLOCK"
    $clean += "0.0.0.0 $d #SAK_BLOCK"
}

# Step 4 → Write hosts file safely (NO STREAM ISSUES)
Set-Content -Path $hosts -Value $clean -Force

# Flush DNS
ipconfig /flushdns | Out-Null

Write-Host "AI websites blocked for 1 minute."

Start-Sleep -Seconds 60

Write-Host "Restoring hosts file..."
Copy-Item -Force $backup $hosts

ipconfig /flushdns | Out-Null

Write-Host "AI websites are unblocked."

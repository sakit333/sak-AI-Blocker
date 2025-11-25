$hosts = "C:\Windows\System32\drivers\etc\hosts"

# Remove read-only attribute if set
attrib -r $hosts

# AI domains
$domains = @(
"chatgpt.com","openai.com","claude.ai","anthropic.com","bard.google.com",
"gemini.google.com","copilot.microsoft.com","you.com","perplexity.ai",
"grok.com","x.ai","huggingface.co","poe.com","writesonic.com",
"novelai.net","character.ai","blackbox.ai"
)

Write-Output "Starting AI Blocker (1 minute)..."

# REMOVE old entries
(Get-Content $hosts) | Where-Object {$_ -notmatch "#SAK_BLOCK"} | Set-Content $hosts

# ADD new block entries
foreach ($d in $domains) {
    Add-Content $hosts "127.0.0.1 $d #SAK_BLOCK"
    Add-Content $hosts "0.0.0.0 $d #SAK_BLOCK"
}

ipconfig /flushdns | Out-Null

Start-Sleep -Seconds 60

# RESTORE hosts file
(Get-Content $hosts) | Where-Object {$_ -notmatch "#SAK_BLOCK"} | Set-Content $hosts

ipconfig /flushdns | Out-Null

Write-Output "AI websites are UNBLOCKED."

<#
Simple GUI AI Blocker (Option 1 - Fixed)
Author : DevOps Engineer - SAK_SHETTY
Purpose: Block AI websites for 30 minutes with a simple WinForms GUI,
         password protection, logging, run-once flag, auto-unblock and auto-delete.
Notes  : Run PowerShell AS ADMIN. Put optional logo.png in same folder.
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Paths and logging
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir  = Split-Path -Parent $scriptPath
$logoFile   = Join-Path $scriptDir "logo.png"   # optional
$flagPath   = "$env:ProgramData\AI_Blocker_Executed.flag"
$logDir     = "$env:ProgramData\AI_Block_Logs"
if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
$logFile    = Join-Path $logDir ("AI_Block_Log_{0}.txt" -f (Get-Date -Format "yyyyMMdd_HHmmss"))

function Write-Log {
    param($msg)
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $msg"
    Add-Content -Path $logFile -Value $line
}

# Default domain list (Option 1)
$domains = @(
    "chatgpt.com","openai.com","platform.openai.com","api.openai.com",
    "claude.ai","anthropic.com","gemini.google.com","bard.google.com",
    "ai.google.dev","copilot.microsoft.com","bingapis.com","huggingface.co",
    "poe.com","perplexity.ai"
)

# Run-once protection
if (Test-Path $flagPath) {
    [System.Windows.Forms.MessageBox]::Show("This machine already ran the AI blocker once. Exiting.","AI Blocker - SAK_SHETTY",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
    exit
}
# Create flag now to avoid races
New-Item -Path $flagPath -ItemType File -Force | Out-Null

Write-Log "Script started."

#
# --- Password dialog (WinForms)
#
$pwdForm = New-Object System.Windows.Forms.Form
$pwdForm.Text = "SAK_SHETTY - Authorization"
$pwdForm.Size = New-Object System.Drawing.Size(380,150)
$pwdForm.StartPosition = "CenterScreen"
$pwdForm.FormBorderStyle = 'FixedDialog'
$pwdForm.MaximizeBox = $false

$lbl = New-Object System.Windows.Forms.Label
$lbl.Text = "Enter script password:"
$lbl.AutoSize = $true
$lbl.Location = New-Object System.Drawing.Point(12,12)
$pwdForm.Controls.Add($lbl)

$txt = New-Object System.Windows.Forms.TextBox
$txt.Location = New-Object System.Drawing.Point(15,36)
$txt.Width = 340
$txt.UseSystemPasswordChar = $true
$pwdForm.Controls.Add($txt)

$btn = New-Object System.Windows.Forms.Button
$btn.Text = "Submit"
$btn.Location = New-Object System.Drawing.Point(140,72)
$btn.Add_Click({
    if ($txt.Text -eq "sak_shetty") {
        $pwdForm.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $pwdForm.Close()
    } else {
        [System.Windows.Forms.MessageBox]::Show("Incorrect password.","Authorization Failed",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    }
})
$pwdForm.Controls.Add($btn)

$result = $pwdForm.ShowDialog()
if ($result -ne [System.Windows.Forms.DialogResult]::OK) {
    Write-Log "Password dialog canceled or wrong - exiting."
    if (Test-Path $flagPath) { Remove-Item $flagPath -Force -ErrorAction SilentlyContinue }
    exit
}
Write-Log "Password authenticated successfully."

#
# --- Build main GUI (simple)
#
$mainForm = New-Object System.Windows.Forms.Form
$mainForm.Text = "SAK_SHETTY - AI Blocker"
$mainForm.Size = New-Object System.Drawing.Size(440,220)
$mainForm.StartPosition = "CenterScreen"
$mainForm.FormBorderStyle = 'FixedDialog'
$mainForm.MaximizeBox = $false

# Logo (optional)
if (Test-Path $logoFile) {
    try {
        $picture = New-Object System.Windows.Forms.PictureBox
        $picture.SizeMode = 'Zoom'
        $picture.Location = New-Object System.Drawing.Point(12,12)
        $picture.Size = New-Object System.Drawing.Size(80,80)
        $picture.Image = [System.Drawing.Image]::FromFile($logoFile)
        $mainForm.Controls.Add($picture)
    } catch {
        Write-Log "Failed loading logo: $_"
    }
}

# Title label
$title = New-Object System.Windows.Forms.Label
$title.Text = "Block AI websites for 30 minutes"
$title.Font = New-Object System.Drawing.Font("Segoe UI",11,[System.Drawing.FontStyle]::Bold)
$title.AutoSize = $true
$title.Location = New-Object System.Drawing.Point(110,24)
$mainForm.Controls.Add($title)

# Status label
$status = New-Object System.Windows.Forms.Label
$status.Text = "Status: Ready"
$status.AutoSize = $true
$status.Location = New-Object System.Drawing.Point(110,60)
$mainForm.Controls.Add($status)

# Progress bar
$pb = New-Object System.Windows.Forms.ProgressBar
$pb.Location = New-Object System.Drawing.Point(20,100)
$pb.Size = New-Object System.Drawing.Size(390,20)
$pb.Minimum = 0
$pb.Maximum = 100
$pb.Value = 0
$mainForm.Controls.Add($pb)

# Start button
$startBtn = New-Object System.Windows.Forms.Button
$startBtn.Text = "Start Blocking"
$startBtn.Location = New-Object System.Drawing.Point(90,140)
$startBtn.Size = New-Object System.Drawing.Size(120,30)
$mainForm.Controls.Add($startBtn)

# Cancel button
$cancelBtn = New-Object System.Windows.Forms.Button
$cancelBtn.Text = "Cancel"
$cancelBtn.Location = New-Object System.Drawing.Point(240,140)
$cancelBtn.Size = New-Object System.Drawing.Size(120,30)
$mainForm.Controls.Add($cancelBtn)

# Timer for progress animation while applying rules
$animTimer = New-Object System.Windows.Forms.Timer
$animTimer.Interval = 150
$animCounter = 0

# Timer for countdown (used later)
$countdownTimer = New-Object System.Windows.Forms.Timer
$countdownTimer.Interval = 1000
$countdownRemaining = 0

# Helper functions for firewall operations (synchronous, UI-friendly)
function Block-Domain {
    param($domain)
    # Try RemoteFqdn first (works on newer Windows)
    try {
        New-NetFirewallRule -DisplayName ("BLOCK_AI_{0}" -f $domain) -Direction Outbound -Action Block -RemoteFqdn $domain -Profile Any -ErrorAction Stop
        Write-Log "Blocked (FQDN): $domain"
        return $true
    } catch {
        Write-Log "RemoteFqdn not supported or failed for $domain. Falling back to IPs."
    }

    # Fallback: resolve IPv4 addresses and block by IP
    try {
        $ips = @()
        try { $ips = [System.Net.Dns]::GetHostAddresses($domain) } catch { $ips = @() }
        $ips = $ips | Where-Object { $_.AddressFamily -eq 'InterNetwork' } | ForEach-Object { $_.IPAddressToString } | Select-Object -Unique

        if ($ips.Count -gt 0) {
            foreach ($ip in $ips) {
                try {
                    New-NetFirewallRule -DisplayName ("BLOCK_AI_{0}_{1}" -f $domain, $ip) -Direction Outbound -Action Block -RemoteAddress $ip -Profile Any -ErrorAction SilentlyContinue
                    Write-Log "Blocked (IP): $domain -> $ip"
                } catch {
                    Write-Log "ERROR creating IP rule for $domain -> $ip : $_"
                }
            }
            return $true
        } else {
            Write-Log "No IPv4 addresses resolved for $domain"
            return $false
        }
    } catch {
        Write-Log "Error resolving or blocking $domain : $_"
        return $false
    }
}

function Remove-AllRules {
    try {
        Get-NetFirewallRule | Where-Object { $_.DisplayName -like "BLOCK_AI_*" } | Remove-NetFirewallRule -ErrorAction SilentlyContinue
        Write-Log "Removed all BLOCK_AI_* rules"
    } catch {
        Write-Log "Error removing BLOCK_AI_* rules: $_"
    }
}

# Countdown window (simple): shows remaining time and runs countdown timer
function Show-CountdownWindow {
    $cdForm = New-Object System.Windows.Forms.Form
    $cdForm.Text = "AI Blocker - Timer"
    $cdForm.Size = New-Object System.Drawing.Size(360,140)
    $cdForm.StartPosition = "CenterScreen"
    $cdForm.FormBorderStyle = 'FixedDialog'
    $cdForm.MaximizeBox = $false

    $lbl1 = New-Object System.Windows.Forms.Label
    $lbl1.Text = "AI access will be restored in:"
    $lbl1.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Regular)
    $lbl1.AutoSize = $true
    $lbl1.Location = New-Object System.Drawing.Point(20,18)
    $cdForm.Controls.Add($lbl1)

    $lblTimer = New-Object System.Windows.Forms.Label
    $lblTimer.Text = "30:00"
    $lblTimer.Font = New-Object System.Drawing.Font("Segoe UI",18,[System.Drawing.FontStyle]::Bold)
    $lblTimer.AutoSize = $true
    $lblTimer.Location = New-Object System.Drawing.Point(20,50)
    $cdForm.Controls.Add($lblTimer)

    # Start countdown
    $countdownRemaining = 30 * 60
    $tick = New-Object System.Windows.Forms.Timer
    $tick.Interval = 1000
    $tick.Add_Tick({
        if ($countdownRemaining -le 0) {
            $tick.Stop()
            Write-Log "Countdown finished."
            # remove firewall rules synchronously
            Remove-AllRules
            Write-Log "Firewall rules removed."
            # delete flag
            if (Test-Path $flagPath) {
                try { Remove-Item $flagPath -Force -ErrorAction SilentlyContinue; Write-Log "Flag file deleted." } catch { Write-Log "Failed deleting flag: $_" }
            }
            # auto self-delete
            Write-Log "Initiating auto self-delete."
            Start-Sleep -Milliseconds 500
            cmd /c "del `"$scriptPath`""
            # close countdown window
            $cdForm.Close()
            return
        } else {
            $mins = [int]($countdownRemaining / 60)
            $secs = $countdownRemaining % 60
            $lblTimer.Text = ("{0:D2}:{1:D2}" -f $mins, $secs)
            $countdownRemaining--
        }
    })
    $tick.Start()
    $cdForm.ShowDialog() | Out-Null
}

# Start button click handler (synchronous blocking with UI DoEvents)
$startBtn.Add_Click({
    $startBtn.Enabled = $false
    $cancelBtn.Enabled = $false
    $status.Text = "Status: Applying firewall rules..."
    Write-Log "User started blocking. Beginning synchronous block loop."

    $total = $domains.Count
    if ($total -eq 0) { $total = 1 }
    $step = [math]::Floor(100 / $total)
    if ($step -lt 1) { $step = 1 }
    $progressValue = 0
    $pb.Value = 0
    $mainForm.Refresh()

    foreach ($d in $domains) {
        # update UI before blocking domain
        $status.Text = "Status: Blocking $d ..."
        Write-Log "Attempting to block $d"
        [System.Windows.Forms.Application]::DoEvents()

        $ok = Block-Domain -domain $d

        if ($ok) { $progressValue += $step } else { $progressValue += 1 }

        if ($progressValue -gt 100) { $progressValue = 100 }
        $pb.Value = $progressValue
        Write-Log "Progress update: $progressValue%"
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 150
    }

    # ensure progress is full
    $pb.Value = 100
    $status.Text = "Status: Rules applied. Starting countdown..."
    Write-Log "Blocking loop completed. Progress set to 100%."
    [System.Windows.Forms.Application]::DoEvents()

    # start countdown window (this blocks until finished)
    Show-CountdownWindow

    # After countdown window closes, close main form if still open
    if ($mainForm.Visible) { $mainForm.Close() }
})

# Cancel button click handler
$cancelBtn.Add_Click({
    Write-Log "User canceled before start. Exiting and removing flag."
    if (Test-Path $flagPath) { Remove-Item $flagPath -Force -ErrorAction SilentlyContinue }
    $mainForm.Close()
    exit
})

# Show main form
$mainForm.Add_Shown({ $mainForm.Activate() })
[void]$mainForm.ShowDialog()

# keep process alive while UI runs (for safety)
[System.Windows.Forms.Application]::DoEvents()

<#
===================================================================================
    SCRIPT NAME : BlockAI_30min_sak_shetty_advancedGUI.ps1
    AUTHOR      : DevOps Engineer - SAK_SHETTY
    PURPOSE     : Advanced GUI version: block AI websites for 30 minutes,
                 show polished GUI with logo, countdown, logging, password,
                 run-once flag, and auto-cleanup (flag + script delete).
    NOTES       : Run PowerShell AS ADMIN. Place "logo.png" in same folder (optional).
===================================================================================
#>

# ------------------- PREPARE ENV -------------------
[void][System.Reflection.Assembly]::LoadWithPartialName("presentationframework")
[void][System.Reflection.Assembly]::LoadWithPartialName("system.windows.forms")
[void][System.Reflection.Assembly]::LoadWithPartialName("system.drawing")

$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir  = Split-Path -Parent $scriptPath
$logoFile   = Join-Path $scriptDir "logo.png"   # put your logo.png here (optional)
$flagPath   = "$env:ProgramData\AI_Blocker_Executed.flag"
$logDir     = "$env:ProgramData\AI_Block_Logs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
$logFile    = Join-Path $logDir ("AI_Block_Log_{0}.txt" -f (Get-Date -Format "yyyyMMdd_HHmmss"))

function Write-Log {
    param($msg)
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $msg"
    Add-Content -Path $logFile -Value $line
}

# ------------------- RUN-ONLY-ONCE PROTECTION -------------------
if (Test-Path $flagPath) {
    [System.Windows.MessageBox]::Show("This script has already run once on this machine. Exiting.","AI Blocker - SAK_SHETTY",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Warning) | Out-Null
    exit
}
New-Item -Path $flagPath -ItemType File -Force | Out-Null

Write-Log "Script started. Preparing GUI."

# ------------------- PASSWORD DIALOG (WinForms) -------------------
Add-Type -AssemblyName System.Windows.Forms
$form = New-Object System.Windows.Forms.Form
$form.Text = "SAK_SHETTY - Authorization"
$form.Size = New-Object System.Drawing.Size(380,150)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false

$lbl = New-Object System.Windows.Forms.Label
$lbl.Text = "Enter script password:"
$lbl.AutoSize = $true
$lbl.Location = New-Object System.Drawing.Point(12,12)
$form.Controls.Add($lbl)

$txt = New-Object System.Windows.Forms.TextBox
$txt.Location = New-Object System.Drawing.Point(15,36)
$txt.Width = 340
$txt.UseSystemPasswordChar = $true
$form.Controls.Add($txt)

$btn = New-Object System.Windows.Forms.Button
$btn.Text = "Submit"
$btn.Location = New-Object System.Drawing.Point(140,72)
$btn.Add_Click({
    if ($txt.Text -eq "sak_shetty") {
        $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $form.Close()
    }
    else {
        [System.Windows.Forms.MessageBox]::Show("Incorrect password.","Authorization Failed",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    }
})
$form.Controls.Add($btn)

$result = $form.ShowDialog()
if ($result -ne [System.Windows.Forms.DialogResult]::OK) {
    Write-Log "Password dialog cancelled or incorrect. Exiting."
    exit
}
Write-Log "Password authentication successful."

# ------------------- AES-ENCRYPTED DOMAIN LIST (deobfuscate) -------------------
$EncryptedDomains = @"
U2FsdGVkX1+zQcdxGz7AmZ9C6QvCwDg9kPr6m6fnMaY=
U2FsdGVkX1+cNA40wIYHzdQ2xQKMkq1mJyI/JlaHu8k=
U2FsdGVkX1+CvBDQnw2kCqWtOrOr5/nCZivVOnQFV2M=
U2FsdGVkX1+gYo8UjjraX0RtT1/6XxC5hnDzPgNrSZ4=
U2FsdGVkX1+JsqI0F5IJTt6agA5i5sWFYA/FGnKJNMY=
U2FsdGVkX1+8bkihHn8JJw7jKODim90s33HBy3AyXao=
U2FsdGVkX1+S76kYf1ixjJ1lG/KXZ3MuItlgH7a9ZgU=
U2FsdGVkX1/8HHyFZGgkYlbDGj0eKc0EcygL2YFQ/Vo=
"@

# (simple local key & iv for local use)
$key = (1..32 | ForEach-Object { 65 }) # 32 x 'A'
$iv  = (1..16 | ForEach-Object { 66 }) # 16 x 'B'

$domains = @()
foreach ($enc in $EncryptedDomains) {
    try {
        $bytes = [Convert]::FromBase64String($enc)
        $aes = [System.Security.Cryptography.Aes]::Create()
        $aes.Key = $key
        $aes.IV  = $iv
        $aes.Padding = "PKCS7"
        $decryptor = $aes.CreateDecryptor()
        $plain = $decryptor.TransformFinalBlock($bytes,0,$bytes.Length)
        $domains += [System.Text.Encoding]::UTF8.GetString($plain)
    } catch {
        Write-Log "Failed decrypting domain entry: $_"
    }
}
Write-Log "Domain list decrypted: $($domains -join ', ')"

# ------------------- BUILD ADVANCED GUI (WPF via XAML) -------------------
$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="SAK_SHETTY — AI Blocker" Height="360" Width="620" WindowStartupLocation="CenterScreen" ResizeMode="NoResize">
  <Grid Background="#F4F7FB">
    <Grid.RowDefinitions>
      <RowDefinition Height="110"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="60"/>
    </Grid.RowDefinitions>

    <!-- Header -->
    <Border Grid.Row="0" Background="#0B5394" CornerRadius="0">
      <Grid>
        <StackPanel Orientation="Horizontal" VerticalAlignment="Center" Margin="18,12,12,12">
          <Image x:Name="LogoImage" Width="84" Height="84" Margin="0,0,12,0"/>
          <StackPanel>
            <TextBlock Text="SAK_SHETTY — EVENT AI BLOCKER" Foreground="White" FontSize="20" FontWeight="Bold"/>
            <TextBlock Text="Restrict AI site access for competition (30 minutes)" Foreground="#DDEEFF" FontSize="12"/>
          </StackPanel>
        </StackPanel>
      </Grid>
    </Border>

    <!-- Body -->
    <StackPanel Grid.Row="1" Margin="18">
      <TextBlock x:Name="StatusText" Text="Ready to block AI websites." FontSize="16" FontWeight="SemiBold" Margin="4"/>
      <Border Background="White" CornerRadius="6" Padding="12" Margin="0,10,0,0">
        <StackPanel>
          <TextBlock Text="Actions" FontWeight="Bold" Margin="0,0,0,6"/>
          <StackPanel Orientation="Horizontal" HorizontalAlignment="Left" Margin="0,6,0,0">
            <Button x:Name="StartBtn" Width="120" Height="36" Margin="0,0,12,0">Start Blocking</Button>
            <Button x:Name="CancelBtn" Width="120" Height="36">Cancel</Button>
          </StackPanel>

          <StackPanel Margin="0,12,0,0">
            <TextBlock Text="Progress" FontWeight="Bold" Margin="0,6,0,6"/>
            <ProgressBar x:Name="MainProgress" Height="18" Minimum="0" Maximum="100" Value="0" Width="540"/>
            <TextBlock x:Name="ProgressDetails" Text="Ready." Margin="0,6,0,0" FontStyle="Italic"/>
          </StackPanel>
        </StackPanel>
      </Border>
    </StackPanel>

    <!-- Footer -->
    <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center" Margin="0,0,18,0">
      <TextBlock Text="© DevOps Engineer - SAK_SHETTY" VerticalAlignment="Center" Margin="0,0,18,0"/>
    </StackPanel>
  </Grid>
</Window>
'@

# Parse XAML and create window
$reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Get named controls
$logoImg  = $window.FindName("LogoImage")
$status   = $window.FindName("StatusText")
$startBtn = $window.FindName("StartBtn")
$cancelBtn= $window.FindName("CancelBtn")
$progress = $window.FindName("MainProgress")
$pd       = $window.FindName("ProgressDetails")

# Load logo if present
if (Test-Path $logoFile) {
    try {
        $bmp = New-Object System.Windows.Media.Imaging.BitmapImage
        $bmp.BeginInit()
        $bmp.UriSource = (New-Object System.Uri($logoFile))
        $bmp.CacheOption = "OnLoad"
        $bmp.EndInit()
        $logoImg.Source = $bmp
    } catch {
        Write-Log "Failed loading logo image: $_"
    }
} else {
    Write-Log "Logo file not found at $logoFile — continuing without logo."
}

# Helper: Apply firewall rules job
function Start-ApplyRulesJob {
    param($domains, $logFile)
    Write-Log "Starting ApplyRules job..."
    $script = {
        param($domains, $logFile)
        foreach ($d in $domains) {
            try {
                New-NetFirewallRule -DisplayName ("BLOCK_AI_{0}" -f $d) -Direction Outbound -Action Block -RemoteAddress $d -Profile Any -ErrorAction SilentlyContinue
                Add-Content -Path $logFile -Value ("[{0}] Blocked: {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $d)
                Start-Sleep -Milliseconds 250
            } catch {
                Add-Content -Path $logFile -Value ("[{0}] ERROR blocking {1}: {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $d, $_)
            }
        }
        Add-Content -Path $logFile -Value ("[{0}] ApplyRules job completed." -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
    }
    return Start-Job -ScriptBlock $script -ArgumentList ($domains, $logFile)
}

# Helper: Remove firewall rules job
function Start-RemoveRulesJob {
    param($logFile)
    $script = {
        param($logFile)
        try {
            Get-NetFirewallRule | Where-Object { $_.DisplayName -like "BLOCK_AI_*" } | Remove-NetFirewallRule -ErrorAction SilentlyContinue
            Add-Content -Path $logFile -Value ("[{0}] RemoveRules job completed." -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
        } catch {
            Add-Content -Path $logFile -Value ("[{0}] ERROR removing rules: {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $_)
        }
    }
    return Start-Job -ScriptBlock $script -ArgumentList ($logFile)
}

# Variables for timers
$applyJob = $null
$animationTimer = New-Object System.Windows.Threading.DispatcherTimer
$animationTimer.Interval = [TimeSpan]::FromMilliseconds(150)

# Animation counter
$anim = 0

$animationTimer.Add_Tick({
    # animate progress while job is running
    if ($applyJob -ne $null -and $applyJob.State -eq "Running") {
        $anim = ($anim + 3) % 100
        $progress.Value = [int]$anim
        $pd.Text = "Applying rules... " + $progress.Value + "%"
    } elseif ($applyJob -ne $null -and $applyJob.State -ne "Running") {
        $animationTimer.Stop()
        $progress.Value = 100
        $pd.Text = "All rules applied."
        $status.Text = "AI websites blocked successfully."
        Write-Log "ApplyRules job finished (state: $($applyJob.State))."
        # start countdown window
        Start-CountdownWindow
    } else {
        # idle small animation
        $anim = ($anim + 1) % 100
        if ($progress.Value -lt 10) { $progress.Value = $anim }
    }
})

# Countdown window function
function Start-CountdownWindow {
    param()
    $durationSec = 30 * 60  # 30 minutes
    Write-Log "Starting countdown for $durationSec seconds."
    $cdXaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="AI Blocker - Timer" Height="180" Width="420" WindowStartupLocation="CenterScreen" ResizeMode="NoResize">
  <Grid Background="#FFFFFF">
    <StackPanel HorizontalAlignment="Center" VerticalAlignment="Center">
      <TextBlock Text="AI access is temporarily disabled" FontSize="16" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,0,0,6"/>
      <TextBlock x:Name="TimerText" Text="00:00:00" FontSize="28" FontWeight="Bold" Foreground="#0B5394" HorizontalAlignment="Center" Margin="0,6,0,6"/>
      <TextBlock Text="This window will close automatically when the timer ends." FontSize="12" HorizontalAlignment="Center" Foreground="#333"/>
    </StackPanel>
  </Grid>
</Window>
'@
    $reader2 = New-Object System.Xml.XmlNodeReader ([xml]$cdXaml)
    $cdWindow = [Windows.Markup.XamlReader]::Load($reader2)
    $timerText = $cdWindow.FindName("TimerText")
    $cdWindow.Show()

    $count = $durationSec
    $tick = New-Object System.Windows.Threading.DispatcherTimer
    $tick.Interval = [TimeSpan]::FromSeconds(1)
    $tick.Add_Tick({
        if ($count -le 0) {
            $tick.Stop()
            $cdWindow.Close()
            Write-Log "Countdown completed."
            # remove firewall rules (background)
            $rmJob = Start-RemoveRulesJob -logFile $logFile
            Wait-Job -Job $rmJob
            Receive-Job -Job $rmJob | Out-Null
            Remove-Job -Job $rmJob -Force -ErrorAction SilentlyContinue
            Write-Log "Firewall rules removed after countdown."
            # delete flag file
            if (Test-Path $flagPath) {
                try {
                    Remove-Item $flagPath -Force -ErrorAction SilentlyContinue
                    Write-Log "Flag file deleted."
                } catch {
                    Write-Log "Failed deleting flag: $_"
                }
            }
            # auto self-delete (use cmd to delete after process exits)
            Write-Log "Initiating auto self-delete."
            Start-Sleep -Milliseconds 500
            cmd /c "del `"$scriptPath`""
            # exit application
            [System.Windows.Application]::Current.Shutdown()
            return
        } else {
            $mins = [int]($count/60)
            $secs = $count % 60
            $timerText.Text = ("{0:D2}:{1:D2}" -f $mins, $secs)
            $count--
        }
    })
    $tick.Start()
}

# Start button click
$startBtn.Add_Click({
    $startBtn.IsEnabled = $false
    $cancelBtn.IsEnabled = $false
    $status.Text = "Applying firewall rules..."
    $pd.Text = "Preparing..."
    Write-Log "User clicked Start. Launching apply-rules job."

    # start apply job
    $applyJob = Start-ApplyRulesJob -domains $domains -logFile $logFile

    # begin animation timer
    $animationTimer.Start()
})

# Cancel button
$cancelBtn.Add_Click({
    $window.Close()
    Write-Log "User cancelled. Exiting."
    exit
})

# Show the window
$window.ShowDialog() | Out-Null

# Keep the script process alive until WPF shuts down
[System.Windows.Threading.Dispatcher]::Run()
